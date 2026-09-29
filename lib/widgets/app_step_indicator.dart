import 'package:flutter/material.dart';

import '../ui/app_colors.dart';
import '../ui/app_icons.dart';

class AppStepIndicator extends StatelessWidget {
  final List<String> steps;
  final int currentIndex;

  const AppStepIndicator({
    super.key,
    required this.steps,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  AppIcons.next,
                  size: 14,
                  color: i <= currentIndex
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: i == currentIndex
                    ? AppColors.lightCyan
                    : i < currentIndex
                    ? AppColors.softBlue
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: i <= currentIndex
                      ? AppColors.primary.withValues(alpha: 0.45)
                      : AppColors.border,
                ),
              ),
              child: Text(
                steps[i],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: i <= currentIndex
                      ? AppColors.primaryDark
                      : AppColors.muted,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
