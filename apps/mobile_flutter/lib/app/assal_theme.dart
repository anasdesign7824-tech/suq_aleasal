import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:assalkom_design/assal_tokens.dart';

/// Selects the correct skin for the runtime theme mode.
class _AssalSkin {
  const _AssalSkin({
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.secondary,
    required this.deepBrown,
    required this.gradient,
    required this.honey,
    required this.honeyLight,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.surfaceRaised,
    required this.cream,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.borderStrong,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.accentOverlay,
    required this.isDark,
  });

  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color secondary;
  final Color deepBrown;
  final LinearGradient gradient;
  final Color honey;
  final Color honeyLight;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color surfaceRaised;
  final Color cream;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color borderStrong;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color accentOverlay;
  final bool isDark;
}

AssalPalette _paletteFor(_AssalSkin skin) => AssalPalette(
      primary: skin.primary,
      primaryDark: skin.primaryDark,
      primaryLight: skin.primaryLight,
      secondary: skin.secondary,
      deepBrown: skin.deepBrown,
      gradient: skin.gradient,
      honey: skin.honey,
      honeyLight: skin.honeyLight,
      background: skin.background,
      surface: skin.surface,
      surfaceVariant: skin.surfaceVariant,
      surfaceRaised: skin.surfaceRaised,
      cream: skin.cream,
      textPrimary: skin.textPrimary,
      textSecondary: skin.textSecondary,
      textMuted: skin.textMuted,
      border: skin.border,
      borderStrong: skin.borderStrong,
      success: skin.success,
      warning: skin.warning,
      error: skin.error,
      info: skin.info,
      accentOverlay: skin.accentOverlay,
      isDark: skin.isDark,
    );

_AssalSkin _skinFor(AssalThemeMode mode) => switch (mode) {
      AssalThemeMode.dark => _AssalSkin(
          primary: AssalColors.primary,
          primaryDark: AssalColors.primaryDark,
          primaryLight: AssalColors.primaryLight,
          secondary: AssalColors.secondary,
          deepBrown: AssalColors.deepBrown,
          gradient: AssalColors.darkGradient,
          honey: AssalColors.honey,
          honeyLight: AssalColors.honeyLight,
          background: AssalColors.background,
          surface: AssalColors.surface,
          surfaceVariant: AssalColors.surfaceVariant,
          surfaceRaised: AssalColors.surfaceRaised,
          cream: AssalColors.cream,
          textPrimary: AssalColors.textPrimary,
          textSecondary: AssalColors.textSecondary,
          textMuted: AssalColors.textMuted,
          border: AssalColors.border,
          borderStrong: AssalColors.borderStrong,
          success: AssalColors.success,
          warning: AssalColors.warning,
          error: AssalColors.error,
          info: AssalColors.info,
          accentOverlay: AssalColors.accentOverlay,
          isDark: true,
        ),
      AssalThemeMode.beige => _AssalSkin(
          primary: AssalBeigeColors.primary,
          primaryDark: AssalBeigeColors.primaryDark,
          primaryLight: AssalBeigeColors.primaryLight,
          secondary: AssalBeigeColors.secondary,
          deepBrown: AssalBeigeColors.deepBrown,
          gradient: AssalBeigeColors.darkGradient,
          honey: AssalBeigeColors.honey,
          honeyLight: AssalBeigeColors.honeyLight,
          background: AssalBeigeColors.background,
          surface: AssalBeigeColors.surface,
          surfaceVariant: AssalBeigeColors.surfaceVariant,
          surfaceRaised: AssalBeigeColors.surfaceRaised,
          cream: AssalBeigeColors.cream,
          textPrimary: AssalBeigeColors.textPrimary,
          textSecondary: AssalBeigeColors.textSecondary,
          textMuted: AssalBeigeColors.textMuted,
          border: AssalBeigeColors.border,
          borderStrong: AssalBeigeColors.borderStrong,
          success: AssalBeigeColors.success,
          warning: AssalBeigeColors.warning,
          error: AssalBeigeColors.error,
          info: AssalBeigeColors.info,
          accentOverlay: AssalBeigeColors.accentOverlay,
          isDark: false,
        ),
    };

Widget _assalGradientButtonBackground(
  BuildContext context,
  Set<WidgetState> states,
  Widget? child,
  Color disabledA,
  Color disabledB,
  LinearGradient gradient,
  BorderRadius radius,
) {
  final disabled = states.contains(WidgetState.disabled);
  return ClipRRect(
    borderRadius: radius,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient:
            disabled ? LinearGradient(colors: [disabledA, disabledB]) : gradient,
      ),
      child: child,
    ),
  );
}

ButtonStyle _assalGradientButtonStyle(_AssalSkin skin) => ButtonStyle(
      backgroundColor: const WidgetStatePropertyAll<Color?>(Colors.transparent),
      foregroundColor: WidgetStatePropertyAll<Color?>(skin.cream),
      overlayColor: WidgetStatePropertyAll<Color?>(skin.accentOverlay),
      elevation: const WidgetStatePropertyAll<double>(0),
      backgroundBuilder: (context, states, child) =>
          _assalGradientButtonBackground(
        context,
        states,
        child,
        skin.surfaceVariant,
        skin.border,
        skin.gradient,
        BorderRadius.circular(AssalRadius.medium),
      ),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AssalRadius.medium)),
        ),
      ),
      textStyle: const WidgetStatePropertyAll<TextStyle?>(AssalTypography.button),
    );

ThemeData buildAssalTheme({AssalThemeMode mode = AssalThemeMode.beige}) {
  final skin = _skinFor(mode);
  final brightness =
      skin.isDark ? Brightness.dark : Brightness.light;

  final scheme = ColorScheme.fromSeed(
    seedColor: skin.primary,
    brightness: brightness,
    primary: skin.primaryDark,
    onPrimary: skin.cream,
    secondary: skin.secondary,
    onSecondary: skin.cream,
    surface: skin.surface,
    onSurface: skin.textPrimary,
    error: skin.error,
    surfaceTint: Colors.transparent,
  );

  final bodyForeground = AssalTypography.body.copyWith(color: skin.textSecondary);
  final captionForeground = AssalTypography.caption.copyWith(color: skin.textMuted);
  final navigationLabel = AssalTypography.caption.copyWith(
    color: skin.textSecondary,
    fontWeight: FontWeight.w700,
  );
  final icon = IconThemeData(color: skin.textPrimary);

  final overlayColor = skin.primary.withValues(alpha: skin.isDark ? .12 : .10);
  final interactionOverlay = WidgetStatePropertyAll<Color?>(skin.accentOverlay);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    extensions: [_paletteFor(skin)],
    scaffoldBackgroundColor: skin.background,
    canvasColor: skin.surface,
    fontFamily: AssalTypography.family,
    splashFactory: InkSparkle.splashFactory,
    hoverColor: skin.primary.withValues(alpha: skin.isDark ? .12 : .08),
    focusColor: skin.primary.withValues(alpha: skin.isDark ? .12 : .08),
    highlightColor: skin.primary.withValues(alpha: skin.isDark ? .08 : .06),
    disabledColor: skin.textMuted,
    overlayColor: overlayColor,
    dividerColor: skin.border,
    textTheme: TextTheme(
      displayLarge: AssalTypography.display.copyWith(color: skin.textPrimary),
      headlineLarge: AssalTypography.heading1.copyWith(color: skin.textPrimary),
      headlineMedium: AssalTypography.heading2.copyWith(color: skin.textPrimary),
      headlineSmall: AssalTypography.heading3.copyWith(color: skin.textPrimary),
      titleLarge: AssalTypography.heading3.copyWith(color: skin.textPrimary),
      titleMedium: AssalTypography.title.copyWith(color: skin.textPrimary),
      titleSmall: AssalTypography.subtitle.copyWith(color: skin.textSecondary),
      bodyLarge: AssalTypography.bodyLarge.copyWith(color: skin.textSecondary),
      bodyMedium: bodyForeground,
      bodySmall: AssalTypography.bodySmall.copyWith(color: skin.textMuted),
      labelLarge: AssalTypography.button.copyWith(color: skin.cream),
      labelMedium: AssalTypography.label.copyWith(color: skin.textSecondary),
      labelSmall: captionForeground,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: skin.surface,
      foregroundColor: skin.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: AssalTypography.heading3.copyWith(color: skin.textPrimary),
      iconTheme: icon,
      actionsIconTheme: icon,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            skin.isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            skin.isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: skin.background,
        systemNavigationBarIconBrightness:
            skin.isDark ? Brightness.light : Brightness.dark,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarContrastEnforced: false,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: skin.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: skin.honeyLight,
      elevation: 0,
      shadowColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return navigationLabel.copyWith(
          color: selected ? skin.primaryLight : skin.textMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? skin.primaryLight : skin.textMuted,
        );
      }),
      overlayColor: interactionOverlay,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: skin.surface,
      indicatorColor: skin.honeyLight,
      useIndicator: true,
      selectedIconTheme: IconThemeData(color: skin.primaryLight),
      unselectedIconTheme: IconThemeData(color: skin.textMuted),
      selectedLabelTextStyle: AssalTypography.label.copyWith(
        color: skin.primaryLight,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: AssalTypography.label.copyWith(
        color: skin.textMuted,
      ),
      groupAlignment: -1,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: skin.primaryLight,
      unselectedLabelColor: skin.textMuted,
      indicatorColor: skin.primary,
      dividerColor: Colors.transparent,
      overlayColor: interactionOverlay,
      labelStyle: AssalTypography.button,
      unselectedLabelStyle: AssalTypography.button,
    ),
    cardTheme: CardThemeData(
      color: skin.surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AssalRadius.large),
        side: BorderSide(color: skin.border),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: skin.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AssalSpacing.lg,
        vertical: AssalSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AssalRadius.medium),
        borderSide: BorderSide(color: skin.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AssalRadius.medium),
        borderSide: BorderSide(color: skin.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AssalRadius.medium),
        borderSide: BorderSide(color: skin.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AssalRadius.medium),
        borderSide: BorderSide(color: skin.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AssalRadius.medium),
        borderSide: BorderSide(color: skin.error, width: 1.5),
      ),
      hintStyle: AssalTypography.body.copyWith(color: skin.textMuted),
      labelStyle: AssalTypography.body.copyWith(color: skin.textSecondary),
      prefixIconColor: skin.primary,
      suffixIconColor: skin.primary,
    ),
    filledButtonTheme:
        FilledButtonThemeData(style: _assalGradientButtonStyle(skin)),
    elevatedButtonTheme:
        ElevatedButtonThemeData(style: _assalGradientButtonStyle(skin)),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: skin.textPrimary,
        backgroundColor: skin.surfaceVariant,
        overlayColor: skin.primary.withValues(alpha: skin.isDark ? .12 : .10),
        side: BorderSide(color: skin.borderStrong),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AssalRadius.medium),
        ),
        textStyle: AssalTypography.button,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: skin.textPrimary,
        overlayColor: skin.primary.withValues(alpha: skin.isDark ? .12 : .10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AssalRadius.medium),
        ),
        textStyle: AssalTypography.button,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: skin.textPrimary,
        overlayColor: skin.primary.withValues(alpha: skin.isDark ? .12 : .10),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return skin.cream;
        return skin.textMuted;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return skin.honeyLight;
        return skin.surfaceVariant;
      }),
      overlayColor: interactionOverlay,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: skin.surfaceVariant,
      selectedColor: skin.honeyLight,
      disabledColor: skin.surface,
      labelStyle: AssalTypography.caption.copyWith(color: skin.textSecondary),
      secondaryLabelStyle:
          AssalTypography.caption.copyWith(color: skin.primaryLight),
      side: BorderSide(color: skin.border),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AssalRadius.pill)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: skin.surfaceRaised,
      contentTextStyle: TextStyle(color: skin.textPrimary),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: skin.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AssalRadius.large),
        side: BorderSide(color: skin.border),
      ),
      titleTextStyle: AssalTypography.heading3.copyWith(color: skin.textPrimary),
      contentTextStyle: AssalTypography.body.copyWith(color: skin.textSecondary),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: skin.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: skin.surfaceRaised,
      modalBarrierColor: skin.isDark
          ? const Color(0x99000000)
          : const Color(0x66000000),
      showDragHandle: true,
      dragHandleColor: skin.borderStrong,
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: AssalTypography.body.copyWith(color: skin.textPrimary),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: skin.surfaceVariant,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AssalRadius.medium),
          borderSide: BorderSide(color: skin.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AssalRadius.medium),
          borderSide: BorderSide(color: skin.primary, width: 1.5),
        ),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: skin.surfaceRaised,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AssalRadius.medium),
        side: BorderSide(color: skin.border),
      ),
      textStyle: AssalTypography.body.copyWith(color: skin.textPrimary),
    ),
  );
}
