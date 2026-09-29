import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/inspection_models.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import '../services/pdf_service.dart';
import '../ui/app_theme.dart';
import '../widgets/annotated_image.dart';
import '../widgets/bridge_results_table.dart';

class ResultsScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final ImageAnalysis analysis;
  final BridgeFormData? bridgeData;
  final List<BridgeElementResult>? bridgeResults;
  final VoidCallback onNewInspection;

  const ResultsScreen({
    super.key,
    required this.imageBytes,
    required this.analysis,
    this.bridgeData,
    this.bridgeResults,
    required this.onNewInspection,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final int? _hoveredIndex = null;
  bool _isSaved = false;
  bool _isDbSaved = false;
  bool _isSavingDb = false;
  late List<BridgeElementResult>? _bridgeResults;
  int? _savedReportId;

  @override
  void initState() {
    super.initState();
    _bridgeResults = widget.bridgeResults == null
        ? null
        : List<BridgeElementResult>.from(widget.bridgeResults!);
    _savedReportId = DateTime.now().millisecondsSinceEpoch;
    _autoSaveReport();
    _persistDistressToMySQL();
  }

  Future<void> _persistDistressToMySQL() async {
    // 1. Guard against demo mode or failure results
    if (GeminiService.isDemoMode) {
      if (kDebugMode) {
        debugPrint(
          '[DISTRESS_DB] Skipping persistence: Gemini is in Demo Mode.',
        );
      }
      return;
    }

    // 2. Guard against empty issues or already saved
    if (widget.analysis.issues.isEmpty || _isDbSaved || _isSavingDb) {
      return;
    }

    final bridgeData = widget.bridgeData;
    if (bridgeData == null || bridgeData.bridgeId == null) {
      if (kDebugMode) {
        debugPrint(
          '[DISTRESS_DB] Skipping persistence: No bridgeData or bridgeId present.',
        );
      }
      return;
    }

    _isSavingDb = true;

    try {
      // 3. Resolve user UID
      final uid = await AuthService.getCurrentUid();
      if (uid == null || uid <= 0) {
        if (kDebugMode) {
          debugPrint(
            '[DISTRESS_DB] Skipping persistence: Authenticated user integer UID could not be determined.',
          );
        }
        _isSavingDb = false;
        return;
      }

      // 4. Resolve bridge_inspection_id belonging to the actual inspection session.
      // Do not silently associate distress with an arbitrary or latest inspection.
      final inspectionId = bridgeData.bridgeInspectionId;
      if (inspectionId == null || inspectionId <= 0) {
        if (kDebugMode) {
          debugPrint(
            '[DISTRESS_DB] Aborted persistence: No valid bridge_inspection_id provided for this inspection session (bridgeId=${bridgeData.bridgeId}). Attaching distress to an arbitrary inspection record is prohibited.',
          );
        }
        _isSavingDb = false;
        return;
      }

      // 5. Convert issues to entries
      // The app currently stores captured images in offline local reports (SharedPreferences / Report).
      // Since no backend file upload service exists to host image files on a server,
      // the images column is set to null (supported by schema) rather than storing a fictitious file path.
      final entries = widget.analysis.issues.map((issue) {
        return BridgeInspectionDistressEntry.fromIssueAndBridgeData(
          issue: issue,
          bridgeData: bridgeData,
          bridgeInspectionId: inspectionId,
          createdByUid: uid,
          imageIdentifier: null,
        );
      }).toList();

      // 6. Insert into database
      final success = await DatabaseService.insertBridgeInspectionDistress(
        entries,
      );
      if (success) {
        _isDbSaved = true;
        if (kDebugMode) {
          debugPrint(
            '[DISTRESS_DB] Successfully persisted ${entries.length} distress records to database_Bms.bridge_inspection_distress.',
          );
        }
      }
    } catch (e) {
      // 7. Non-blocking error handling without leaking credentials
      if (kDebugMode) {
        debugPrint(
          '[DISTRESS_DB] Error persisting distress records: ${e.runtimeType}: $e',
        );
      }
    } finally {
      _isSavingDb = false;
    }
  }

  Report _buildReport({bool includeImage = true}) {
    final issues = widget.analysis.issues;
    double maxD = 0, maxW = 0, totalA = 0, totalL = 0;
    for (var i in issues) {
      final d = double.tryParse(i.depth) ?? 0;
      final w = double.tryParse(i.width ?? '0') ?? 0;
      final l = double.tryParse(i.length ?? '0') ?? 0;
      if (d > maxD) maxD = d;
      if (w > maxW) maxW = w;
      totalA += (i.area ?? 0);
      totalL += l;
    }

    return Report(
      id: _savedReportId ?? DateTime.now().millisecondsSinceEpoch,
      title: widget.bridgeData != null
          ? widget.bridgeData!.span
          : 'Bridge Inspection',
      description: widget.analysis.summary,
      imageBase64: includeImage ? base64Encode(widget.imageBytes) : null,
      timestamp: DateTime.now().toString(),
      metrics: ReportMetrics(
        issueCount: issues.length,
        minDepth: 0,
        maxDepth: maxD,
        minWidth: 0,
        maxWidth: maxW,
        totalArea: totalA,
        totalLength: totalL,
      ),
      category: issues.isNotEmpty ? 'Issues Found' : 'Optimal',
      location: widget.bridgeData != null
          ? widget.bridgeData!.chainages
          : 'Site A',
      issues: issues,
      recommendations: widget.analysis.recommendations,
      bridgeData: widget.bridgeData,
      bridgeResults: _bridgeResults,
    );
  }

  Future<void> _autoSaveReport() async {
    final report = _buildReport(includeImage: true);
    await StorageService.saveReport(report);
    if (mounted) setState(() => _isSaved = true);
  }

  Future<void> _onBridgeResultsChanged(
    List<BridgeElementResult> updated,
  ) async {
    setState(() {
      _bridgeResults = updated;
      _isSaved = false;
    });
    await _autoSaveReport();
  }

  void _exportPdf() {
    PdfService.generateAndDownloadSingleReport(
      _buildReport(includeImage: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionCard(
            title: 'ANALYSIS IMAGE',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isSaved)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F8EF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppIcons.checkFilled,
                            size: 12,
                            color: AppColors.success,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Saved Offline',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                AnnotatedImageWidget(
                  imageBytes: widget.imageBytes,
                  issues: widget.analysis.issues,
                  hoveredIndex: _hoveredIndex,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (widget.bridgeData != null) ...[
            BridgeResultsTableWidget(
              bridgeData: widget.bridgeData!,
              results: _bridgeResults,
              onResultsChanged: _onBridgeResultsChanged,
            ),
            const SizedBox(height: 16),
          ],

          AppSectionCard(
            title: 'DETECTED DISTRESS',
            child: widget.analysis.issues.isEmpty
                ? const Text(
                    'No structural distress detected.',
                    style: AppTextStyles.muted,
                  )
                : Column(
                    children: widget.analysis.issues.asMap().entries.map((
                      entry,
                    ) {
                      final idx = entry.key;
                      final issue = entry.value;
                      return Container(
                        margin: EdgeInsets.only(
                          bottom: idx == widget.analysis.issues.length - 1
                              ? 0
                              : 12,
                        ),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'DISTRESS #${idx + 1}: ${issue.type.toUpperCase()}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightCyan,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${(issue.confidence * 100).toStringAsFixed(0)}% Confidence',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (issue.elementName != null &&
                                issue.elementName!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                issue.elementName!.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            const Text(
                              'MEASUREMENTS',
                              style: AppTextStyles.label,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: [
                                AppMetricCard(
                                  label: 'Length',
                                  value:
                                      issue.length == null ||
                                          issue.length!.isEmpty
                                      ? '—'
                                      : '${issue.length}m',
                                ),
                                AppMetricCard(
                                  label: 'Width',
                                  value:
                                      issue.width == null ||
                                          issue.width!.isEmpty
                                      ? '—'
                                      : '${issue.width}m',
                                ),
                                AppMetricCard(
                                  label: 'Depth / Thickness',
                                  value: issue.depth.isEmpty
                                      ? '—'
                                      : '${issue.depth}m',
                                ),
                                if (issue.area != null)
                                  AppMetricCard(
                                    label: 'Area',
                                    value:
                                        '${issue.area!.toStringAsFixed(3)}m²',
                                  ),
                                if (issue.quantityUnit != null &&
                                    issue.quantityValue != null)
                                  AppMetricCard(
                                    label: issue.quantityUnit!,
                                    value: '${issue.quantityValue}',
                                  ),
                              ],
                            ),
                            if (issue.description.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                issue.description,
                                style: AppTextStyles.muted,
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onNewInspection,
                  icon: const Icon(AppIcons.refresh, size: 16),
                  label: const Text('NEW INSPECTION'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppGradientButton(
                  label: 'EXPORT REPORT',
                  icon: AppIcons.pdf,
                  onPressed: _exportPdf,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
