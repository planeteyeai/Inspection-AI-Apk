import 'package:flutter/material.dart';
import '../models/inspection_models.dart';
import '../ui/app_theme.dart';

const List<String> kTestKeys = [
  'UPV',
  'RHT',
  'HCP',
  'CD',
  'Core',
  'Profoscope',
  'Chemical Test',
  'GPR',
];

class BridgeResultsTableWidget extends StatefulWidget {
  final BridgeFormData bridgeData;
  final List<BridgeElementResult>? results;
  final bool isLoading;
  final ValueChanged<List<BridgeElementResult>>? onResultsChanged;

  const BridgeResultsTableWidget({
    super.key,
    required this.bridgeData,
    this.results,
    this.isLoading = false,
    this.onResultsChanged,
  });

  @override
  State<BridgeResultsTableWidget> createState() =>
      _BridgeResultsTableWidgetState();
}

class _BridgeResultsTableWidgetState extends State<BridgeResultsTableWidget> {
  late List<BridgeElementResult?> _editableResults;

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(covariant BridgeResultsTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.results != widget.results ||
        oldWidget.bridgeData.elements.length !=
            widget.bridgeData.elements.length) {
      _syncFromWidget();
    }
  }

  void _syncFromWidget() {
    final count = widget.bridgeData.elements.length;
    _editableResults = List<BridgeElementResult?>.generate(count, (i) {
      if (widget.results != null && i < widget.results!.length) {
        return widget.results![i];
      }
      return null;
    });
  }

  void _emitChanges() {
    final ready = _editableResults.whereType<BridgeElementResult>().toList();
    if (ready.length == widget.bridgeData.elements.length) {
      widget.onResultsChanged?.call(ready);
    }
  }

  Color _conditionColor(int r) {
    switch (r) {
      case 5:
        return const Color(0xFF047857);
      case 4:
        return const Color(0xFF0F766E);
      case 3:
        return const Color(0xFFD97706);
      case 2:
        return const Color(0xFFEA580C);
      default:
        return const Color(0xFFDC2626);
    }
  }

  Color _severityColor(String s) {
    // Preserves existing app severity labels: Immediate / Short-Term / Long-Term Requirement.
    if (s.contains('Immediate')) return const Color(0xFFDC2626);
    if (s.contains('Short')) return const Color(0xFFEA580C);
    if (s.contains('Long')) return const Color(0xFF0F766E);
    return const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17324D).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.softBlue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 10,
              children: [
                if (widget.bridgeData.projectName.isNotEmpty) ...[
                  _infoChip('PROJECT', widget.bridgeData.projectName),
                  Container(width: 1, height: 28, color: Colors.grey.shade300),
                ],
                if (widget.bridgeData.chainages.isNotEmpty) ...[
                  _infoChip('CHAINAGES', widget.bridgeData.chainages),
                  Container(width: 1, height: 28, color: Colors.grey.shade300),
                ],
                if (widget.bridgeData.bridgeId != null) ...[
                  _infoChip('BRIDGE ID', '${widget.bridgeData.bridgeId}'),
                  Container(width: 1, height: 28, color: Colors.grey.shade300),
                ],
                _infoChip('SPAN', widget.bridgeData.span),
                Container(width: 1, height: 28, color: Colors.grey.shade300),
                _infoChip(
                  'SUPERSTRUCTURE',
                  widget.bridgeData.typeOfSuperstructure,
                ),
                const Spacer(),
                if (widget.isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI ANALYZING...',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (widget.results != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Color(0xFF059669),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'AI ANALYSIS COMPLETE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
              dataRowMinHeight: 48,
              dataRowMaxHeight: 56,
              headingRowHeight: 46,
              columnSpacing: 16,
              horizontalMargin: 16,
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: Colors.grey.shade100,
                  width: 1,
                ),
              ),
              columns: [
                const DataColumn(
                  label: Text(
                    'ELEMENT',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    'DESCRIPTION',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    'RATING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFC2410C),
                    ),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    'SEVERITY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFC2410C),
                    ),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    'L (m)',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    'W (m)',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    'T (m)',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    'NOS',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    'UNIT',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    'VALUE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    'SCAF L',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    'SCAF W',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    'SCAF H',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    'SCAF (m³)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    'SUGGESTED RnR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF7E22CE),
                    ),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    'TEST Y/N',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                ),
                ...kTestKeys.map(
                  (key) => DataColumn(
                    label: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDFA),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF99F6E4)),
                      ),
                      child: Text(
                        key,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              rows: widget.bridgeData.elements.asMap().entries.map((entry) {
                final idx = entry.key;
                final el = entry.value;
                final res = idx < _editableResults.length
                    ? _editableResults[idx]
                    : null;

                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${idx + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            el.elementName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        el.description.isEmpty ? '—' : el.description,
                        style: TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    DataCell(
                      res != null
                          ? Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _conditionColor(
                                  res.conditionRating,
                                ).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _conditionColor(res.conditionRating),
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                '${res.conditionRating}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  color: _conditionColor(res.conditionRating),
                                ),
                              ),
                            )
                          : const Text('—'),
                    ),
                    DataCell(
                      res != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _severityColor(
                                  res.levelOfSeverity,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _severityColor(
                                    res.levelOfSeverity,
                                  ).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                res.levelOfSeverity,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: _severityColor(res.levelOfSeverity),
                                ),
                              ),
                            )
                          : const Text('—'),
                    ),
                    DataCell(
                      Text(
                        res?.distressLength?.toStringAsFixed(2) ?? '—',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                    DataCell(
                      Text(
                        res?.distressWidth?.toStringAsFixed(3) ?? '—',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                    DataCell(
                      Text(
                        res?.distressThickness?.toStringAsFixed(2) ?? '—',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                    DataCell(
                      Text(
                        res?.distressNos?.toString() ?? '—',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                    DataCell(
                      res != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.orange.shade200,
                                ),
                              ),
                              child: Text(
                                res.distressUnit,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            )
                          : const Text('—'),
                    ),
                    DataCell(
                      Text(
                        res?.distressValue.toStringAsFixed(2) ?? '—',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        res?.scaffoldingLength?.toStringAsFixed(2) ?? '—',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                    DataCell(
                      Text(
                        res?.scaffoldingWidth?.toStringAsFixed(2) ?? '—',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                    DataCell(
                      Text(
                        res?.scaffoldingHeight?.toStringAsFixed(2) ?? '—',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                    DataCell(
                      Text(
                        res?.scaffoldingCum.toStringAsFixed(2) ?? '—',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                    DataCell(
                      res != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAF5FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE9D5FF),
                                ),
                              ),
                              child: Text(
                                res.suggestedRnR,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF7E22CE),
                                ),
                              ),
                            )
                          : const Text('—'),
                    ),
                    DataCell(
                      res != null
                          ? (res.testingRecommendation
                                ? const Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Color(0xFF059669),
                                  )
                                : Icon(
                                    Icons.cancel,
                                    size: 16,
                                    color: Colors.grey.shade300,
                                  ))
                          : const Text('—'),
                    ),
                    ...kTestKeys.map((key) {
                      final isChecked = res?.testingOptions[key] ?? false;
                      return DataCell(
                        Checkbox(
                          value: isChecked,
                          activeColor: const Color(0xFF0D9488),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: res == null
                              ? null
                              : (val) {
                                  setState(() {
                                    final updated = Map<String, bool>.from(
                                      res.testingOptions,
                                    );
                                    updated[key] = val ?? false;
                                    _editableResults[idx] = res.copyWith(
                                      testingOptions: updated,
                                    );
                                  });
                                  _emitChanges();
                                },
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: Colors.grey.shade500,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? 'N/A' : value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
