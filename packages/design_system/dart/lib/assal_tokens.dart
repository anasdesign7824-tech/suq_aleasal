import 'package:flutter/material.dart';

/// Shared visual contract for Souq Al Assal / عسلكم.
/// Keep feature screens dependent on these tokens, not raw values.
abstract final class AssalColors {
  static const primary = Color(0xFFF39C12);
  static const primaryDark = Color(0xFF9C5A00);
  static const primaryLight = Color(0xFFFFA94D);
  static const secondary = Color(0xFF8B5A2B);
  static const deepBrown = Color(0xFF4F2E1F);
  static const honey = Color(0xFFF39C12);
  static const honeyLight = Color(0xFFFFF0D6);
  static const cream = Color(0xFFF8F4EC);
  static const background = Color(0xFFFCFAF7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF4EEE5);
  static const textPrimary = Color(0xFF342118);
  static const textSecondary = Color(0xFF6F5B4C);
  static const textMuted = Color(0xFF9A897D);
  static const border = Color(0xFFE8DCCB);
  static const success = Color(0xFF4F7A45);
  static const warning = Color(0xFFB86B1E);
  static const error = Color(0xFFA64232);
  static const info = Color(0xFF6B675C);
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
}
