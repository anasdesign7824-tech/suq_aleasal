import 'package:flutter/material.dart';

/// Shared visual contract for Souq Al Assal / عسلكم.
/// This is the new premium dark honey system. Keep feature screens dependent on
/// these tokens, not raw values.
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
