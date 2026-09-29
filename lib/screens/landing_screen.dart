import 'package:flutter/material.dart';

import '../ui/app_theme.dart';

/// First screen: large real bridge photograph with a subtle teal overlay.
class LandingScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const LandingScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BridgeHeroImage(),
          DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.heroOverlay),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppBrandMark(light: true, showSubtitle: false),
                  const Spacer(),
                  Text(
                    AppBrand.name,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.6,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    AppBrand.subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.95),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    AppBrand.shortTagline,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 28),
                  AppGradientButton(
                    label: 'Get Started  →',
                    onPressed: onContinue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
