import 'package:flutter/material.dart';

/// Shared visual contract for Souq Al Assal / عسلكم.
/// The design system ships two skins:
/// - [AssalBeigeColors] (default): warm beige / near-white cream canvas.
/// - [AssalColors] (dark night): premium dark honey canvas.
/// Keep feature screens dependent on these tokens, not raw values.

/// Default light skin: بيج دافئ قريب من الأبيض.
abstract final class AssalBeigeColors {
  // Brand accent
  static const primary = Color(0xFFB86A10);
  static const primaryDark = Color(0xFF8A4D00);
  static const primaryLight = Color(0xFFD79A2B);
  static const secondary = Color(0xFF8A5C3B);
  static const deepBrown = Color(0xFF4F2E1F);
  static const darkGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF6B3F22), Color(0xFFC77D1A)],
  );
  static const honey = Color(0xFFD79A2B);
  static const honeyLight = Color(0xFFFFF0D6);

  // Warm beige canvas
  static const background = Color(0xFFFBF8F2);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF5EEE3);
  static const surfaceRaised = Color(0xFFFFFFFF);
  static const cream = Color(0xFFFBF8F2);
  static const textPrimary = Color(0xFF342118);
  static const textSecondary = Color(0xFF806B5A);
  static const textMuted = Color(0xFF9A8A79);
  static const border = Color(0xFFE5DACB);
  static const borderStrong = Color(0xFFCDBA9E);

  // States
  static const success = Color(0xFF3E7E4F);
  static const warning = Color(0xFFB5651D);
  static const error = Color(0xFFC64235);
  static const info = Color(0xFF7A6A55);

  // Semantic overlays
  static const accentOverlay = Color(0x1FB86A10);
  static const dangerOverlay = Color(0x1FC64235);
  static const glassDark = Color(0xCCFFFFFF);
}

/// Dark night skin: premium dark honey.
abstract final class AssalColors {
  // Brand accent
  static const primary = Color(0xFFF5A623);
  static const primaryDark = Color(0xFFE08A00);
  static const primaryLight = Color(0xFFFFC45E);
  static const secondary = Color(0xFFB8833B);
  static const deepBrown = Color(0xFF2B1A12);
  static const darkGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF3A2414), Color(0xFFB86A10)],
  );
  static const honey = Color(0xFFF5A623);
  static const honeyLight = Color(0xFF332416);

  // Dark canvas
  static const background = Color(0xFF0D0906);
  static const surface = Color(0xFF1A120C);
  static const surfaceVariant = Color(0xFF24180F);
  static const surfaceRaised = Color(0xFF2B1D12);
  static const cream = Color(0xFFF8EDE1);
  static const textPrimary = Color(0xFFF7EDE2);
  static const textSecondary = Color(0xFFC9B6A3);
  static const textMuted = Color(0xFF8F7A66);
  static const border = Color(0xFF38291D);
  static const borderStrong = Color(0xFF4A3523);

  // States
  static const success = Color(0xFF66A85E);
  static const warning = Color(0xFFE07B34);
  static const error = Color(0xFFE0614F);
  static const info = Color(0xFFA99A8A);

  // Semantic overlays
  static const accentOverlay = Color(0x1AF5A623);
  static const dangerOverlay = Color(0x22E0614F);
  static const glassDark = Color(0xB30D0906);
}

/// Colors resolved by the active theme skin. Screens should read via
/// [AssalPaletteContext] instead of hard-coding a skin.
class AssalPalette extends ThemeExtension<AssalPalette> {
  const AssalPalette({
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

  @override
  AssalPalette copyWith({
    Color? primary,
    Color? primaryDark,
    Color? primaryLight,
    Color? secondary,
    Color? deepBrown,
    LinearGradient? gradient,
    Color? honey,
    Color? honeyLight,
    Color? background,
    Color? surface,
    Color? surfaceVariant,
    Color? surfaceRaised,
    Color? cream,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? borderStrong,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? accentOverlay,
    bool? isDark,
  }) =>
      AssalPalette(
        primary: primary ?? this.primary,
        primaryDark: primaryDark ?? this.primaryDark,
        primaryLight: primaryLight ?? this.primaryLight,
        secondary: secondary ?? this.secondary,
        deepBrown: deepBrown ?? this.deepBrown,
        gradient: gradient ?? this.gradient,
        honey: honey ?? this.honey,
        honeyLight: honeyLight ?? this.honeyLight,
        background: background ?? this.background,
        surface: surface ?? this.surface,
        surfaceVariant: surfaceVariant ?? this.surfaceVariant,
        surfaceRaised: surfaceRaised ?? this.surfaceRaised,
        cream: cream ?? this.cream,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textMuted: textMuted ?? this.textMuted,
        border: border ?? this.border,
        borderStrong: borderStrong ?? this.borderStrong,
        success: success ?? this.success,
        warning: warning ?? this.warning,
        error: error ?? this.error,
        info: info ?? this.info,
        accentOverlay: accentOverlay ?? this.accentOverlay,
        isDark: isDark ?? this.isDark,
      );

  @override
  AssalPalette lerp(covariant AssalPalette? other, double t) {
    if (other == null) return this;
    return AssalPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      deepBrown: Color.lerp(deepBrown, other.deepBrown, t)!,
      gradient: gradient,
      honey: Color.lerp(honey, other.honey, t)!,
      honeyLight: Color.lerp(honeyLight, other.honeyLight, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      cream: Color.lerp(cream, other.cream, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      accentOverlay: Color.lerp(accentOverlay, other.accentOverlay, t)!,
      isDark: isDark,
    );
  }
}

/// Convenience accessors for the active skin palette.
extension AssalPaletteContext on BuildContext {
  AssalPalette get assalPalette =>
      Theme.of(this).extension<AssalPalette>() ??
      const AssalPalette(
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
      );

  Color get assalPrimary => assalPalette.primary;
  Color get assalPrimaryDark => assalPalette.primaryDark;
  Color get assalPrimaryLight => assalPalette.primaryLight;
  Color get assalSecondary => assalPalette.secondary;
  Color get assalDeepBrown => assalPalette.deepBrown;
  LinearGradient get assalGradient => assalPalette.gradient;
  Color get assalHoney => assalPalette.honey;
  Color get assalHoneyLight => assalPalette.honeyLight;
  Color get assalBackground => assalPalette.background;
  Color get assalSurface => assalPalette.surface;
  Color get assalSurfaceVariant => assalPalette.surfaceVariant;
  Color get assalSurfaceRaised => assalPalette.surfaceRaised;
  Color get assalCream => assalPalette.cream;
  Color get assalTextPrimary => assalPalette.textPrimary;
  Color get assalTextSecondary => assalPalette.textSecondary;
  Color get assalTextMuted => assalPalette.textMuted;
  Color get assalBorder => assalPalette.border;
  Color get assalBorderStrong => assalPalette.borderStrong;
  Color get assalSuccess => assalPalette.success;
  Color get assalWarning => assalPalette.warning;
  Color get assalError => assalPalette.error;
  Color get assalInfo => assalPalette.info;
  Color get assalAccentOverlay => assalPalette.accentOverlay;
  bool get assalIsDark => assalPalette.isDark;
}

/// Runtime theme selection for عسلكم.
enum AssalThemeMode {
  /// Default warm beige / near-white skin.
  beige,

  /// Optional premium dark night skin.
  dark,
}

/// Local presentation-only theme state. No backend, no auth, no persistence
/// contract is touched. Preference lives for this app session.
class AssalThemeController extends ValueNotifier<AssalThemeMode> {
  AssalThemeController([super.value = AssalThemeMode.beige]);

  void setMode(AssalThemeMode mode) {
    if (value != mode) value = mode;
  }

  void toggleNight() =>
      value = value == AssalThemeMode.dark ? AssalThemeMode.beige : AssalThemeMode.dark;

  bool get isDark => value == AssalThemeMode.dark;
}

/// Gives any descendant access to the active theme skin without threading
/// callbacks through every screen constructor.
class AssalThemeScope extends InheritedNotifier<AssalThemeController> {
  const AssalThemeScope({
    required AssalThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static AssalThemeController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AssalThemeScope>();
    assert(scope != null, 'AssalThemeScope is not present in this tree.');
    return scope!.notifier!;
  }
}

abstract final class AssalSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const x2l = 32.0;
  static const x3l = 40.0;
  static const x4l = 48.0;
  static const x5l = 64.0;
}

abstract final class AssalRadius {
  static const small = 8.0;
  static const medium = 12.0;
  static const large = 18.0;
  static const extraLarge = 28.0;
  static const pill = 999.0;
}

abstract final class AssalTypography {
  static const family = 'IBM Plex Sans Arabic';
  static const display = TextStyle(fontFamily: family, fontSize: 36, height: 48 / 36, fontWeight: FontWeight.w700);
  static const heading1 = TextStyle(fontFamily: family, fontSize: 30, height: 40 / 30, fontWeight: FontWeight.w700);
  static const heading2 = TextStyle(fontFamily: family, fontSize: 24, height: 34 / 24, fontWeight: FontWeight.w600);
  static const heading3 = TextStyle(fontFamily: family, fontSize: 20, height: 30 / 20, fontWeight: FontWeight.w600);
  static const title = TextStyle(fontFamily: family, fontSize: 18, height: 28 / 18, fontWeight: FontWeight.w600);
  static const subtitle = TextStyle(fontFamily: family, fontSize: 16, height: 26 / 16, fontWeight: FontWeight.w500);
  static const bodyLarge = TextStyle(fontFamily: family, fontSize: 16, height: 28 / 16, fontWeight: FontWeight.w400);
  static const body = TextStyle(fontFamily: family, fontSize: 14, height: 24 / 14, fontWeight: FontWeight.w400);
  static const bodySmall = TextStyle(fontFamily: family, fontSize: 12, height: 20 / 12, fontWeight: FontWeight.w400);
  static const caption = TextStyle(fontFamily: family, fontSize: 11, height: 18 / 11, fontWeight: FontWeight.w500);
  static const button = TextStyle(fontFamily: family, fontSize: 14, height: 22 / 14, fontWeight: FontWeight.w600);
  static const label = TextStyle(fontFamily: family, fontSize: 12, height: 18 / 12, fontWeight: FontWeight.w500);
  static const navigation = TextStyle(fontFamily: family, fontSize: 13, height: 20 / 13, fontWeight: FontWeight.w600);
  static const metadata = TextStyle(fontFamily: family, fontSize: 10, height: 16 / 10, fontWeight: FontWeight.w500);
}
