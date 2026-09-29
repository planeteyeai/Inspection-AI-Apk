import 'package:flutter/material.dart';

import '../ui/app_assets.dart';
import '../ui/app_colors.dart';
import '../ui/app_icons.dart';
import '../ui/app_text_styles.dart';

/// Full-bleed landing hero that loads the user-provided bridge photograph.
///
/// Expected file: [AppAssets.heroBridge]
/// Until that file exists, shows a simple light placeholder (not a drawn bridge).
class BridgeHeroImage extends StatelessWidget {
  const BridgeHeroImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.heroBridge,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => const _HeroPlaceholder(),
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.softGradient),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.image, size: 48, color: AppColors.primary.withValues(alpha: 0.55)),
              const SizedBox(height: 14),
              const Text(
                'Add your bridge photograph',
                textAlign: TextAlign.center,
                style: AppTextStyles.screenTitle,
              ),
              const SizedBox(height: 8),
              Text(
                AppAssets.heroBridge,
                textAlign: TextAlign.center,
                style: AppTextStyles.muted.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
