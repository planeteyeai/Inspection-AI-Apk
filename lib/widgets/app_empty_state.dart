import 'package:flutter/material.dart';

import '../ui/app_colors.dart';
import '../ui/app_icons.dart';
import '../ui/app_text_styles.dart';

class AppEmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;

  const AppEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = AppIcons.information,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.border),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: AppTextStyles.screenTitle.copyWith(color: AppColors.muted)),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!, textAlign: TextAlign.center, style: AppTextStyles.muted),
            ],
          ],
        ),
      ),
    );
  }
}
