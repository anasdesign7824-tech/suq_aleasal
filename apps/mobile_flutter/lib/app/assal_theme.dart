import 'package:flutter/material.dart';
import 'package:assalkom_design/assal_tokens.dart';

ThemeData buildAssalTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AssalColors.primary,
    brightness: Brightness.light,
    primary: AssalColors.primaryDark,
    onPrimary: Colors.white,
    secondary: AssalColors.secondary,
    surface: AssalColors.surface,
    onSurface: AssalColors.textPrimary,
    error: AssalColors.error,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AssalColors.background,
    fontFamily: AssalTypography.family,
    textTheme: const TextTheme(
      displayLarge: AssalTypography.display,
      headlineLarge: AssalTypography.heading1,
      headlineMedium: AssalTypography.heading2,
      titleLarge: AssalTypography.heading3,
      titleMedium: AssalTypography.title,
      bodyLarge: AssalTypography.bodyLarge,
      bodyMedium: AssalTypography.body,
      bodySmall: AssalTypography.bodySmall,
      labelLarge: AssalTypography.button,
      labelMedium: AssalTypography.label,
    ),
    cardTheme: CardThemeData(
      color: AssalColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AssalRadius.large),
        side: const BorderSide(color: AssalColors.border),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AssalColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: AssalSpacing.lg, vertical: AssalSpacing.md),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AssalRadius.medium),
        borderSide: const BorderSide(color: AssalColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AssalRadius.medium),
        borderSide: const BorderSide(color: AssalColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AssalRadius.medium),
        borderSide: const BorderSide(color: AssalColors.primaryDark, width: 1.5),
      ),
      hintStyle: AssalTypography.body.copyWith(color: AssalColors.textMuted),
    ),
  );
}
