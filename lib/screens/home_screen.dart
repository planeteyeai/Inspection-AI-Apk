import 'package:flutter/material.dart';

import '../models/inspection_models.dart';
import '../ui/app_theme.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onStartInspection;
  final VoidCallback onOpenReports;
  final BridgeFormData? lastBridgeData;
  final String inspectorName;

  const HomeScreen({
    super.key,
    required this.onStartInspection,
    required this.onOpenReports,
    this.lastBridgeData,
    this.inspectorName = 'Inspector',
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppBrandMark(compact: true),
            const SizedBox(height: 18),
            Text('$_greeting,', style: AppTextStyles.muted),
            Text(inspectorName, style: AppTextStyles.title),
            const SizedBox(height: 6),
            const Text(
              "Let's make our infrastructure safer with AI.",
              style: AppTextStyles.muted,
            ),
            const SizedBox(height: 20),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onStartInspection,
                borderRadius: BorderRadius.circular(20),
                child: Ink(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          AppIcons.play,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'START INSPECTION',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Project → Chainage → Bridge → AI Analysis',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(AppIcons.next, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppSectionCard(
              title: 'CURRENT PROJECT',
              subtitle: lastBridgeData == null
                  ? 'No active selection in this session'
                  : 'From the current session',
              child: lastBridgeData == null
                  ? const Text(
                      'Start an inspection to see project details here.',
                      style: AppTextStyles.muted,
                    )
                  : Column(
                      children: [
                        _infoRow('Project', lastBridgeData!.projectName),
                        _infoRow('Chainage', lastBridgeData!.chainages),
                        _infoRow(
                          'Bridge',
                          lastBridgeData!.bridgeId != null
                              ? '${lastBridgeData!.bridgeId}'
                              : '—',
                        ),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: AppStatusBadge(
                            label: 'In Progress',
                            tone: AppStatusTone.success,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 14),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: InkWell(
                onTap: onOpenReports,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(AppIcons.reports, color: AppColors.primary, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'View Reports',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(AppIcons.next, color: AppColors.primary, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              AppBrand.subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.muted.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    final display = value.trim().isEmpty ? '—' : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: AppTextStyles.label)),
          Expanded(
            child: Text(
              display,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
