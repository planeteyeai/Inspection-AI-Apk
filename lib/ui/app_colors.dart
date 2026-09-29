import 'package:flutter/material.dart';

/// Light teal / aqua palette — AI ANALYZER design system.
class AppColors {
  static const Color primary = Color(0xFF18B8A6);
  static const Color aqua = Color(0xFF55D9D0);
  static const Color lightCyan = Color(0xFFBFEFF1);
  static const Color softBlue = Color(0xFFDCEEF4);
  static const Color canvas = Color(0xFFF4F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF17324D);
  static const Color muted = Color(0xFF6B7C8F);
  static const Color border = Color(0xFFD7E5EA);
  static const Color success = Color(0xFF35B779);
  static const Color warning = Color(0xFFF2A93B);
  static const Color danger = Color(0xFFE85B5B);
  static const Color primaryDark = Color(0xFF0E8F82);
  static const Color info = Color(0xFF3B82A0);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF18B8A6), Color(0xFF55D9D0)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient softGradient = LinearGradient(
    colors: [Color(0xFFE8F9F8), Color(0xFFF4F8FA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Subtle readability veil for hero photos (keeps the photograph visible).
  static LinearGradient heroOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      const Color(0xFF18B8A6).withValues(alpha: 0.12),
      const Color(0xFF17324D).withValues(alpha: 0.28),
      const Color(0xFF0E8F82).withValues(alpha: 0.48),
    ],
  );
}
