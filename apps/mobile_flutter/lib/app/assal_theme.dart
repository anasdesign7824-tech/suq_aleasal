import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:assalkom_design/assal_tokens.dart';

const _assalInteractionOverlay = WidgetStatePropertyAll<Color?>(
  Color(0x269C5A00),
);

Widget _assalGradientButtonBackground(
  BuildContext context,
  Set<WidgetState> states,
  Widget? child,
) {
  final disabled = states.contains(WidgetState.disabled);
  return DecoratedBox(
    decoration: BoxDecoration(
      gradient: disabled
          ? const LinearGradient(
              colors: [AssalColors.border, AssalColors.surfaceVariant],
            )
          : AssalColors.darkGradient,
    ),
    child: child,
  );
}

ButtonStyle _assalGradientButtonStyle() => ButtonStyle(
      backgroundColor: const WidgetStatePropertyAll<Color?>(Colors.transparent),
      foregroundColor: const WidgetStatePropertyAll<Color?>(AssalColors.cream),
      overlayColor: _assalInteractionOverlay,
      elevation: const WidgetStatePropertyAll<double>(0),
      backgroundBuilder: _assalGradientButtonBackground,
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AssalRadius.medium),
        ),
      ),
      textStyle: const WidgetStatePropertyAll(AssalTypography.button),
    );

ThemeData buildAssalTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AssalColors.primary,
    brightness: Brightness.light,
    primary: AssalColors.primaryDark,
    onPrimary: Colors.white,
    secondary: AssalColors.secondary,
    onSecondary: Colors.white,
    surface: AssalColors.surface,
    onSurface: AssalColors.textPrimary,
    error: AssalColors.error,
  );

  final darkForeground = AssalTypography.body.copyWith(
    color: AssalColors.cream,
  );
  final darkNavigationLabel = AssalTypography.caption.copyWith(
    color: AssalColors.cream,
    fontWeight: FontWeight.w600,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AssalColors.background,
    fontFamily: AssalTypography.family,
    splashFactory: InkSparkle.splashFactory,
    hoverColor: AssalColors.primaryDark.withValues(alpha: .12),
    focusColor: AssalColors.primaryDark.withValues(alpha: .12),
    highlightColor: AssalColors.primaryDark.withValues(alpha: .08),
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
    appBarTheme: AppBarTheme(
      backgroundColor: AssalColors.deepBrown,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: AssalTypography.heading3.copyWith(
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AssalColors.primaryDark,
        systemNavigationBarIconBrightness: Brightness.light,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarContrastEnforced: false,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AssalColors.primaryDark,
      elevation: 0,
      shadowColor: Colors.transparent,
      labelTextStyle: WidgetStatePropertyAll(darkNavigationLabel),
      iconTheme: const WidgetStatePropertyAll<IconThemeData?>(
        IconThemeData(color: AssalColors.cream),
      ),
      overlayColor: _assalInteractionOverlay,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: AssalColors.primaryDark,
      useIndicator: true,
      selectedIconTheme: const IconThemeData(color: AssalColors.cream),
      unselectedIconTheme: const IconThemeData(color: AssalColors.cream),
      selectedLabelTextStyle: darkForeground,
      unselectedLabelTextStyle: darkForeground,
      groupAlignment: 0,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: AssalColors.cream,
      unselectedLabelColor: AssalColors.cream.withValues(alpha: .68),
      indicatorColor: AssalColors.honey,
      dividerColor: Colors.transparent,
      overlayColor: _assalInteractionOverlay,
      labelStyle: AssalTypography.button,
      unselectedLabelStyle: AssalTypography.button,
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AssalSpacing.lg,
        vertical: AssalSpacing.md,
      ),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AssalRadius.medium),
        borderSide: const BorderSide(color: AssalColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AssalRadius.medium),
        borderSide: const BorderSide(color: AssalColors.error, width: 1.5),
      ),
      hintStyle: AssalTypography.body.copyWith(color: AssalColors.textMuted),
      prefixIconColor: AssalColors.primaryDark,
      suffixIconColor: AssalColors.primaryDark,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: _assalGradientButtonStyle(),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: _assalGradientButtonStyle(),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AssalColors.deepBrown,
        overlayColor: AssalColors.primaryDark.withValues(alpha: .12),
        side: const BorderSide(color: AssalColors.deepBrown),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AssalRadius.medium),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AssalColors.deepBrown,
        overlayColor: AssalColors.primaryDark.withValues(alpha: .12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AssalRadius.medium),
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AssalColors.deepBrown,
        overlayColor: AssalColors.primaryDark.withValues(alpha: .12),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AssalColors.cream;
        return AssalColors.textMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AssalColors.deepBrown;
        }
        return AssalColors.border;
      }),
      overlayColor: _assalInteractionOverlay,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AssalColors.cream,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: AssalColors.cream,
      modalBarrierColor: Color(0x99000000),
      showDragHandle: true,
      dragHandleColor: AssalColors.deepBrown,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: AssalTypography.body.copyWith(color: AssalColors.textPrimary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AssalColors.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AssalRadius.medium),
          borderSide: const BorderSide(color: AssalColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AssalRadius.medium),
          borderSide: const BorderSide(color: AssalColors.primaryDark, width: 1.5),
        ),
      ),
    ),
  );
}
