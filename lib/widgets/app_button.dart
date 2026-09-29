import 'package:flutter/material.dart';

import '../ui/app_colors.dart';
import '../ui/app_icons.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool secondary;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.secondary = false,
  });

  /// Primary teal/aqua gradient CTA.
  const AppButton.gradient({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
  }) : secondary = false;

  @override
  Widget build(BuildContext context) {
    if (secondary) {
      return OutlinedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: Icon(icon ?? AppIcons.next, size: 16),
        label: Text(label),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            gradient: onPressed == null || loading ? null : AppColors.primaryGradient,
            color: onPressed == null || loading ? AppColors.primary.withValues(alpha: 0.45) : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: onPressed == null
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
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

/// Backward-compatible alias used across existing screens.
class AppGradientButton extends AppButton {
  const AppGradientButton({
    super.key,
    required super.label,
    super.onPressed,
    super.icon,
    super.loading = false,
  }) : super.gradient();
}
