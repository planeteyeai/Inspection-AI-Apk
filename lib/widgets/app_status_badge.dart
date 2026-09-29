import 'package:flutter/material.dart';

import '../ui/app_colors.dart';

enum AppStatusTone { success, warning, danger, info, neutral }

class AppStatusBadge extends StatelessWidget {
  final String label;
  final AppStatusTone tone;

  const AppStatusBadge({
    super.key,
    required this.label,
    this.tone = AppStatusTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      AppStatusTone.success => (const Color(0xFFE8F8EF), AppColors.success),
      AppStatusTone.warning => (const Color(0xFFFFF7ED), AppColors.warning),
      AppStatusTone.danger => (const Color(0xFFFEECEC), AppColors.danger),
      AppStatusTone.info => (AppColors.lightCyan, AppColors.primaryDark),
      AppStatusTone.neutral => (AppColors.softBlue, AppColors.muted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: colors.$2,
        ),
      ),
    );
  }
}
