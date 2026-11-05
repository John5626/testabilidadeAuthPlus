import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  final baseTheme = ThemeData(
    fontFamily: 'Inter',
    colorScheme: ColorScheme.fromSeed(
      seedColor: StudyAppColors.accent,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: StudyAppColors.background,
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
  );

  return baseTheme.copyWith(
    textTheme: baseTheme.textTheme.apply(
      bodyColor: StudyAppColors.textPrimary,
      displayColor: StudyAppColors.textPrimary,
    ),
    colorScheme: baseTheme.colorScheme.copyWith(
      primary: StudyAppColors.accent,
      secondary: StudyAppColors.info,
      surface: StudyAppColors.surface,
      error: StudyAppColors.danger,
      onPrimary: Colors.white,
      onSurface: StudyAppColors.textPrimary,
      onSurfaceVariant: StudyAppColors.textSecondary,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: StudyAppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StudyAppSpacing.radiusMd),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StudyAppSpacing.radiusMd),
        borderSide: const BorderSide(color: StudyAppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StudyAppSpacing.radiusMd),
        borderSide: const BorderSide(color: StudyAppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StudyAppSpacing.radiusMd),
        borderSide: const BorderSide(color: StudyAppColors.accent, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StudyAppSpacing.radiusMd),
        borderSide: const BorderSide(color: StudyAppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(StudyAppSpacing.radiusMd),
        borderSide: const BorderSide(color: StudyAppColors.danger, width: 1.4),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: StudyAppColors.accent,
        foregroundColor: Colors.white,
        minimumSize: const Size(44, 46),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StudyAppSpacing.radiusMd),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: StudyAppColors.accent,
        minimumSize: const Size(44, 46),
        side: const BorderSide(color: StudyAppColors.borderStrong),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StudyAppSpacing.radiusMd),
        ),
      ),
    ),
  );
}

abstract final class StudyAppColors {
  static const navy = Color(0xFF071B45);
  static const navyDeep = Color(0xFF041B4F);
  static const navySoft = Color(0xFF102A63);
  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceTint = Color(0xFFE1E9FF);
  static const border = Color(0xFFD8E0EF);
  static const borderStrong = Color(0xFFA4B7DF);
  static const textPrimary = Color(0xFF0F2454);
  static const textSecondary = Color(0xFF667085);
  static const textMuted = Color(0xFF98A2B3);
  static const accent = Color(0xFF2563EB);
  static const accentSoft = Color(0xFF60A5FA);
  static const success = Color(0xFF12A66A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFDC2626);
  static const info = Color(0xFF3682FE);
}

abstract final class StudyAppSpacing {
  static const xs = 6.0;
  static const sm = 8.0;
  static const md = 10.0;
  static const lg = 16.0;
  static const xl = 21.0;
  static const xxl = 32.0;

  static const radiusSm = 4.0;
  static const radiusMd = 8.0;
  static const radiusLg = 16.0;
}
