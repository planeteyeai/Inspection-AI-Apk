import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/inspection_models.dart';
import '../services/gemini_service.dart';
import '../ui/app_theme.dart';
import 'bridge_form_screen.dart';
import 'image_source_screen.dart';
import 'reports_dashboard_screen.dart';
import 'results_screen.dart';

/// Primary app shell after login: MAIN inspection + REPORTS only.
///
/// Inspection stages stay inside this screen (no separate destinations per step).
class InspectionMainScreen extends StatefulWidget {
  final Future<void> Function()? onLogout;

  const InspectionMainScreen({super.key, this.onLogout});

  @override
  State<InspectionMainScreen> createState() => _InspectionMainScreenState();
}

class _InspectionMainScreenState extends State<InspectionMainScreen> {
  /// 0 = Bridge/Structure form, 1 = AI capture, 2 = Results/Assessment
  int _phase = 0;
  bool _showReports = false;
  bool _isLoading = false;

  BridgeFormData? _bridgeFormData;
  Uint8List? _selectedImageBytes;
  ImageAnalysis? _distressReport;
  List<BridgeElementResult>? _bridgeResults;

  static const _stepLabels = ['BRIDGE', 'STRUCTURE', 'AI', 'RESULTS', 'ASSESS'];

  int get _stepIndex {
    switch (_phase) {
      case 0:
        return _bridgeFormData == null ? 0 : 1;
      case 1:
        return 2;
      case 2:
        return 4;
      default:
        return 0;
    }
  }

  void _onFormProceed(BridgeFormData data) {
    setState(() {
      _bridgeFormData = data;
      _phase = 1;
    });
  }

  Future<void> _onImageSelected(Uint8List bytes, String detectionTarget) async {
    setState(() {
      _selectedImageBytes = bytes;
      _isLoading = true;
    });

    try {
      final analysisFuture = GeminiService.analyzeImageDetails(
        bytes,
        'image/jpeg',
        targetIssueType: detectionTarget,
      );

      final bridgeResultsFuture = _bridgeFormData != null
          ? GeminiService.analyzeBridgeInspection(bytes, 'image/jpeg', _bridgeFormData!.elements)
          : Future.value(<BridgeElementResult>[]);

      final results = await Future.wait([analysisFuture, bridgeResultsFuture]);

      if (!mounted) return;
      setState(() {
        _distressReport = results[0] as ImageAnalysis;
        _bridgeResults = results[1] as List<BridgeElementResult>;
        _isLoading = false;
        _phase = 2;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to complete AI analysis. Please try again.')),
      );
    }
  }

  void _resetInspection() {
    setState(() {
      _showReports = false;
      _phase = 0;
      _bridgeFormData = null;
      _selectedImageBytes = null;
      _distressReport = null;
      _bridgeResults = null;
      _isLoading = false;
    });
  }

  void _openHome() {
    setState(() => _showReports = false);
  }

  void _openReports() {
    setState(() => _showReports = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: _isLoading
            ? _buildAiLoading()
            : Column(
                children: [
                  _buildHeader(),
                  if (!_showReports) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: AppStepIndicator(
                        steps: _stepLabels,
                        currentIndex: _stepIndex,
                      ),
                    ),
                  ],
                  Expanded(
                    child: _showReports
                        ? ReportsDashboardScreen(
                            onBack: _openHome,
                            embedInShell: true,
                          )
                        : AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: KeyedSubtree(
                              key: ValueKey<int>(_phase),
                              child: _buildPhaseBody(),
                            ),
                          ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: _isLoading
          ? null
          : NavigationBar(
              selectedIndex: _showReports ? 1 : 0,
              backgroundColor: AppColors.surface,
              indicatorColor: AppColors.lightCyan,
              onDestinationSelected: (index) {
                if (index == 0) {
                  _openHome();
                } else {
                  _openReports();
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(AppIcons.home),
                  selectedIcon: Icon(AppIcons.homeActive, color: AppColors.primary),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(AppIcons.reports),
                  selectedIcon: Icon(AppIcons.reportsActive, color: AppColors.primary),
                  label: 'Reports',
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 112,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  AppAssets.heroBridge,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.2),
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: const BoxDecoration(gradient: AppColors.softGradient),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppBrand.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              AppBrand.subtitle,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.onLogout != null)
                        IconButton(
                          tooltip: 'Logout',
                          onPressed: widget.onLogout,
                          icon: const Icon(AppIcons.logout, color: Colors.white, size: 20),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!_showReports)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                children: [
                  Text(
                    _phaseTitle,
                    style: AppTextStyles.screenTitle,
                  ),
                  const Spacer(),
                  if (_phase > 0)
                    TextButton(
                      onPressed: () => setState(() => _phase = _phase - 1),
                      child: const Text('Back'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String get _phaseTitle {
    switch (_phase) {
      case 0:
        return 'INSPECTION · Bridge & Structure';
      case 1:
        return 'INSPECTION · AI Capture';
      case 2:
        return 'INSPECTION · Results & Assessment';
      default:
        return 'INSPECTION';
    }
  }

  Widget _buildPhaseBody() {
    switch (_phase) {
      case 0:
        return BridgeFormScreen(onProceed: _onFormProceed);
      case 1:
        return ImageSourceScreen(
          bridgeData: _bridgeFormData,
          onImageSelected: _onImageSelected,
          onBack: () => setState(() => _phase = 0),
        );
      case 2:
        if (_selectedImageBytes == null || _distressReport == null) {
          return const AppEmptyState(
            title: 'No analysis yet',
            message: 'Complete AI inspection to see results here.',
            icon: AppIcons.results,
          );
        }
        return ResultsScreen(
          imageBytes: _selectedImageBytes!,
          analysis: _distressReport!,
          bridgeData: _bridgeFormData,
          bridgeResults: _bridgeResults,
          onNewInspection: _resetInspection,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAiLoading() {
    const steps = [
      'Processing image',
      'Detecting distress',
      'Calculating measurements',
      'Generating results',
    ];
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.softGradient),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text('AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
                ),
                const SizedBox(height: 18),
                Text(AppBrand.name, style: AppTextStyles.screenTitle),
                const SizedBox(height: 6),
                const Text(
                  'Analyzing structural condition...',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.muted,
                ),
                const SizedBox(height: 18),
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 18),
                ...steps.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(AppIcons.checkFilled, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
