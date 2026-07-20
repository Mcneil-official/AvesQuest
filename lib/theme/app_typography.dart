import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static TextStyle _nunito({
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    double? letterSpacing,
    Color color = AppColors.onSurface,
  }) {
    return GoogleFonts.nunito(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static TextStyle displayLg({Color color = AppColors.onSurface}) => _nunito(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        height: 56 / 48,
        letterSpacing: -0.02 * 48,
        color: color,
      );

  static TextStyle headlineLg({Color color = AppColors.onSurface}) => _nunito(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 40 / 32,
        color: color,
      );

  static TextStyle headlineLgMobile({Color color = AppColors.onSurface}) => _nunito(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 36 / 28,
        color: color,
      );

  static TextStyle titleMd({Color color = AppColors.onSurface}) => _nunito(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 28 / 20,
        color: color,
      );

  static TextStyle bodyLg({Color color = AppColors.onSurface}) => _nunito(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 26 / 18,
        color: color,
      );

  static TextStyle bodyMd({Color color = AppColors.onSurface}) => _nunito(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 24 / 16,
        color: color,
      );

  static TextStyle labelSm({Color color = AppColors.onSurface}) => _nunito(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 16 / 12,
        letterSpacing: 0.05 * 12,
        color: color,
      );
}
