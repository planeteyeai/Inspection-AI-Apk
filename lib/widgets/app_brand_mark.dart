import 'package:flutter/material.dart';

import '../ui/app_brand.dart';
import '../ui/app_colors.dart';

/// Geometric teal "A" brand mark — no raster logo required.
class AppBrandMark extends StatelessWidget {
  final bool compact;
  final bool showSubtitle;
  final bool light;

  const AppBrandMark({
    super.key,
    this.compact = false,
    this.showSubtitle = false,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = light ? Colors.white : AppColors.ink;
    final subColor = light ? Colors.white.withValues(alpha: 0.9) : AppColors.muted;
    final iconSize = compact ? 15.0 : 18.0;
    final titleSize = compact ? 15.0 : 22.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BrandGlyph(size: compact ? 30 : 38, letterSize: iconSize),
            SizedBox(width: compact ? 8 : 10),
            Text(
              AppBrand.name,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: titleColor,
              ),
            ),
          ],
        ),
        if (showSubtitle) ...[
          const SizedBox(height: 8),
          Text(
            AppBrand.subtitle,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: subColor, height: 1.35),
          ),
        ],
      ],
    );
  }
}

class _BrandGlyph extends StatelessWidget {
  final double size;
  final double letterSize;

  const _BrandGlyph({required this.size, required this.letterSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'A',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: letterSize,
        ),
      ),
    );
  }
}
