import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  static const title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    letterSpacing: 0.2,
  );
  static const screenTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
  );
  static const section = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    letterSpacing: 0.35,
  );
  static const label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.muted,
  );
  static const body = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
    height: 1.35,
  );
  static const muted = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
    height: 1.35,
  );
}
