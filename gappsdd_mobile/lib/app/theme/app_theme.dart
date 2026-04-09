import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Light mode color palette — "Arbor Ethos" warm naturals.
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

/// Dark mode color palette — same hue family, inverted luminance.
class AppColorsDark {
  static const surface = Color(0xFF1A1C16);
  static const surfaceLow = Color(0xFF22251D);
  static const surfaceHigh = Color(0xFF2E3128);
  static const surfaceHighest = Color(0xFF383B32);
  static const primary = Color(0xFFA8D398);
  static const primaryContainer = Color(0xFF2D4B22);
  static const onPrimary = Color(0xFF0E1F07);
  static const secondary = Color(0xFF8FA97A);
  static const tertiary = Color(0xFFD4A574);
  static const textPrimary = Color(0xFFE3E3DB);
  static const textMuted = Color(0xFFA0A59B);
  static const outline = Color(0xFF4A4F44);
  static const success = Color(0xFF7BB96A);
}

class AppTheme {
  static ThemeData light({TargetPlatform? platform}) {
    return _build(
      brightness: Brightness.light,
      surface: AppColors.surface,
      surfaceLow: AppColors.surfaceLow,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      textPrimary: AppColors.textPrimary,
      textMuted: AppColors.textMuted,
      outline: AppColors.outline,
      platform: platform,
    );
  }

  static ThemeData dark({TargetPlatform? platform}) {
    return _build(
      brightness: Brightness.dark,
      surface: AppColorsDark.surface,
      surfaceLow: AppColorsDark.surfaceLow,
      primary: AppColorsDark.primary,
      onPrimary: AppColorsDark.onPrimary,
      primaryContainer: AppColorsDark.primaryContainer,
      secondary: AppColorsDark.secondary,
      tertiary: AppColorsDark.tertiary,
      textPrimary: AppColorsDark.textPrimary,
      textMuted: AppColorsDark.textMuted,
      outline: AppColorsDark.outline,
      platform: platform,
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required Color surface,
    required Color surfaceLow,
    required Color primary,
    required Color onPrimary,
    required Color primaryContainer,
    required Color secondary,
    required Color tertiary,
    required Color textPrimary,
    required Color textMuted,
    required Color outline,
    TargetPlatform? platform,
  }) {
    final baseText = GoogleFonts.workSansTextTheme();
    final headline = GoogleFonts.manropeTextTheme(baseText);
    final targetPlatform = platform ?? TargetPlatform.android;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      platform: targetPlatform,
      scaffoldBackgroundColor: surface,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: surface,
        secondary: secondary,
        onSecondary: onPrimary,
        tertiary: tertiary,
        onTertiary: onPrimary,
        surface: surface,
        onSurface: textPrimary,
        outline: outline,
        error: const Color(0xFFBA1A1A),
        onError: const Color(0xFFFFFFFF),
      ),
      textTheme: headline.copyWith(
        displaySmall: GoogleFonts.manrope(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
          color: primary,
        ),
        headlineMedium: GoogleFonts.manrope(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: primary,
        ),
        titleLarge: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: primary,
        ),
        bodyLarge: GoogleFonts.workSans(
          fontSize: 15,
          height: 1.45,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.workSans(
          fontSize: 14,
          height: 1.45,
          color: textMuted,
        ),
        labelMedium: GoogleFonts.workSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: textMuted,
        ),
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: primary,
        scaffoldBackgroundColor: surface,
        barBackgroundColor: surfaceLow,
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: const FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: const CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: const FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: const FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: const FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
