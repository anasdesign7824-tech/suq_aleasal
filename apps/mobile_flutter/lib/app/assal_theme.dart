import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:assalkom_design/assal_tokens.dart';

const _assalInteractionOverlay = WidgetStatePropertyAll<Color?>(
  Color(0x40F5A623),
);

Widget _assalGradientButtonBackground(
  BuildContext context,
  Set<WidgetState> states,
  Widget? child,
) {
  final disabled = states.contains(WidgetState.disabled);
  return ClipRRect(
    borderRadius: BorderRadius.circular(AssalRadius.medium),
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: disabled
            ? const LinearGradient(
                colors: [AssalColors.surfaceVariant, AssalColors.border],
              )
            : AssalColors.darkGradient,
      ),
      child: child,
    ),
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
      textStyle: const WidgetStatePropertyAll<TextStyle?>(AssalTypography.button),
    );

ThemeData buildAssalTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AssalColors.primary,
    brightness: Brightness.dark,
    primary: AssalColors.primaryDark,
    onPrimary: AssalColors.cream,
    secondary: AssalColors.secondary,
    onSecondary: AssalColors.cream,
    surface: AssalColors.surface,
    onSurface: AssalColors.textPrimary,
    error: AssalColors.error,
    surfaceTint: Colors.transparent,
  );

  final darkForeground = AssalTypography.body.copyWith(color: AssalColors.cream);
  final darkCaption = AssalTypography.caption.copyWith(
    color: AssalColors.textSecondary,
  );
  final darkNavigationLabel = AssalTypography.caption.copyWith(
    color: AssalColors.textSecondary,
    fontWeight: FontWeight.w700,
  );
  const darkIcon = IconThemeData(color: AssalColors.textPrimary);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AssalColors.background,
    canvasColor: AssalColors.surface,
    fontFamily: AssalTypography.family,
    splashFactory: InkSparkle.splashFactory,
    hoverColor: AssalColors.primary.withValues(alpha: .12),
    focusColor: AssalColors.primary.withValues(alpha: .12),
    highlightColor: AssalColors.primary.withValues(alpha: .08),
    disabledColor: AssalColors.textMuted,
    overlayColor: AssalColors.primary.withValues(alpha: .10),
    dividerColor: AssalColors.border,
    textTheme: TextTheme(
      displayLarge: AssalTypography.display.copyWith(color: AssalColors.textPrimary),
      headlineLarge: AssalTypography.heading1.copyWith(color: AssalColors.textPrimary),
      headlineMedium: AssalTypography.heading2.copyWith(color: AssalColors.textPrimary),
      headlineSmall: AssalTypography.heading3.copyWith(color: AssalColors.textPrimary),
      titleLarge: AssalTypography.heading3.copyWith(color: AssalColors.textPrimary),
      titleMedium: AssalTypography.title.copyWith(color: AssalColors.textPrimary),
      titleSmall: AssalTypography.subtitle.copyWith(color: AssalColors.textSecondary),
      bodyLarge: AssalTypography.bodyLarge.copyWith(color: AssalColors.textSecondary),
      bodyMedium: AssalTypography.body.copyWith(color: AssalColors.textSecondary),
      bodySmall: AssalTypography.bodySmall.copyWith(color: AssalColors.textMuted),
      labelLarge: AssalTypography.button.copyWith(color: AssalColors.cream),
      labelMedium: AssalTypography.label.copyWith(color: AssalColors.textSecondary),
      labelSmall: AssalTypography.caption.copyWith(color: AssalColors.textMuted),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AssalColors.surface,
      foregroundColor: AssalColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: AssalTypography.heading3.copyWith(color: AssalColors.textPrimary),
      iconTheme: darkIcon,
      actionsIconTheme: darkIcon,
      scrolledUnderElevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AssalColors.background,
        systemNavigationBarIconBrightness: Brightness.light,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarContrastEnforced: false,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AssalColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AssalColors.honeyLight,
      elevation: 0,
      shadowColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return darkNavigationLabel.copyWith(
          color: selected ? AssalColors.primaryLight : AssalColors.textMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AssalColors.primaryLight : AssalColors.textMuted,
        );
      }),
      overlayColor: _assalInteractionOverlay,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AssalColors.surface,
      indicatorColor: AssalColors.honeyLight,
      useIndicator: true,
      selectedIconTheme: const IconThemeData(color: AssalColors.primaryLight),
      unselectedIconTheme: const IconThemeData(color: AssalColors.textMuted),
      selectedLabelTextStyle: AssalTypography.label.copyWith(
        color: AssalColors.primaryLight,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: AssalTypography.label.copyWith(
        color: AssalColors.textMuted,
      ),
      groupAlignment: -1,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: AssalColors.primaryLight,
      unselectedLabelColor: AssalColors.textMuted,
      indicatorColor: AssalColors.primary,
      dividerColor: Colors.transparent,
      overlayColor: _assalInteractionOverlay,
      labelStyle: AssalTypography.button,
      unselectedLabelStyle: AssalTypography.button,
    ),
    cardTheme: CardThemeData(
      color: AssalColors.surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AssalRadius.large),
        side: const BorderSide(color: AssalColors.border),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AssalColors.surfaceVariant,
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
        borderSide: const BorderSide(color: AssalColors.primary, width: 1.5),
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
      labelStyle: AssalTypography.body.copyWith(color: AssalColors.textSecondary),
      prefixIconColor: AssalColors.primary,
      suffixIconColor: AssalColors.primary,
    ),
    filledButtonTheme: FilledButtonThemeData(style: _assalGradientButtonStyle()),
    elevatedButtonTheme: ElevatedButtonThemeData(style: _assalGradientButtonStyle()),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AssalColors.textPrimary,
        backgroundColor: AssalColors.surfaceVariant,
        overlayColor: AssalColors.primary.withValues(alpha: .12),
        side: const BorderSide(color: AssalColors.borderStrong),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AssalRadius.medium),
        ),
        textStyle: AssalTypography.button,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AssalColors.textPrimary,
        overlayColor: AssalColors.primary.withValues(alpha: .12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AssalRadius.medium),
        ),
        textStyle: AssalTypography.button,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AssalColors.textPrimary,
        overlayColor: AssalColors.primary.withValues(alpha: .12),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AssalColors.cream;
        return AssalColors.textMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AssalColors.honeyLight;
        return AssalColors.surfaceVariant;
      }),
      overlayColor: _assalInteractionOverlay,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AssalColors.surfaceVariant,
      selectedColor: AssalColors.honeyLight,
      disabledColor: AssalColors.surface,
      labelStyle: AssalTypography.caption.copyWith(color: AssalColors.textSecondary),
      secondaryLabelStyle: AssalTypography.caption.copyWith(color: AssalColors.primaryLight),
      side: const BorderSide(color: AssalColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AssalRadius.pill)),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AssalColors.surfaceRaised,
      contentTextStyle: TextStyle(color: AssalColors.textPrimary),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: AssalColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AssalRadius.large),
        side: const BorderSide(color: AssalColors.border),
      ),
      titleTextStyle: AssalTypography.heading3.copyWith(color: AssalColors.textPrimary),
      contentTextStyle: AssalTypography.body.copyWith(color: AssalColors.textSecondary),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AssalColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: AssalColors.surfaceRaised,
      modalBarrierColor: Color(0x99000000),
      showDragHandle: true,
      dragHandleColor: AssalColors.borderStrong,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: AssalTypography.body.copyWith(color: AssalColors.textPrimary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AssalColors.surfaceVariant,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AssalRadius.medium),
          borderSide: const BorderSide(color: AssalColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AssalRadius.medium),
          borderSide: const BorderSide(color: AssalColors.primary, width: 1.5),
        ),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AssalColors.surfaceRaised,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AssalRadius.medium),
        side: const BorderSide(color: AssalColors.border),
      ),
      textStyle: AssalTypography.body.copyWith(color: AssalColors.textPrimary),
    ),
  );
}
