import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const surface = Color(0xFFFCF9F0);
  static const surfaceLow = Color(0xFFF6F3EA);
  static const surfaceHigh = Color(0xFFE5E2DA);
  static const surfaceHighest = Color(0xFFEBE8DF);
  static const primary = Color(0xFF17340E);
  static const primaryContainer = Color(0xFF2D4B22);
  static const onPrimary = Color(0xFFFFFFFF);
  static const secondary = Color(0xFF53643B);
  static const tertiary = Color(0xFF432715);
  static const textPrimary = Color(0xFF1C1C17);
  static const textMuted = Color(0xFF5F655B);
  static const outline = Color(0xFFC3C8BC);
  static const success = Color(0xFF47673A);
}

class AppTheme {
  static ThemeData light() {
    final baseText = GoogleFonts.workSansTextTheme();
    final headline = GoogleFonts.manropeTextTheme(baseText);

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: const ColorScheme.light(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.surface,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onPrimary,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        outline: AppColors.outline,
      ),
      textTheme: headline.copyWith(
        displaySmall: GoogleFonts.manrope(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
          color: AppColors.primary,
        ),
        headlineMedium: GoogleFonts.manrope(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: AppColors.primary,
        ),
        titleLarge: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
        bodyLarge: GoogleFonts.workSans(
          fontSize: 15,
          height: 1.45,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.workSans(
          fontSize: 14,
          height: 1.45,
          color: AppColors.textMuted,
        ),
        labelMedium: GoogleFonts.workSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}