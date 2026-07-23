import 'package:flutter/material.dart';

/// StarForge EDU design tokens — default "saroy" palette (warm terracotta/saffron).
class Sf {
  // surfaces
  static const bg = Color(0xFFFBF6EC);
  static const surface = Color(0xFFFFFCF5);
  static const surface2 = Color(0xFFF4EBD8);
  static const surface3 = Color(0xFFEADFC4);
  // ink / text
  static const ink = Color(0xFF1F1B16);
  static const ink2 = Color(0xFF3A332A);
  static const muted = Color(0xFF847663);
  static const muted2 = Color(0xFFB0A38B);
  // borders
  static const border = Color(0xFFE5D9BE);
  static const borderStrong = Color(0xFFCFC0A0);
  // primary — terracotta
  static const primary = Color(0xFFB85535);
  static const primaryHover = Color(0xFFA04524);
  static const primarySoft = Color(0xFFF3D9CC);
  static const primaryInk = Color(0xFF5A2412);
  // accent — saffron
  static const accent = Color(0xFFD89A2E);
  static const accentSoft = Color(0xFFF6E4B8);
  static const accentInk = Color(0xFF6B4810);
  // semantic
  static const success = Color(0xFF4F7B3B);
  static const successSoft = Color(0xFFDDEACA);
  static const warn = Color(0xFFC68423);
  static const warnSoft = Color(0xFFF6E4B8);
  static const danger = Color(0xFFB33A2A);
  static const dangerSoft = Color(0xFFF3D2CC);
  // ai
  static const ai = Color(0xFF8B5A0F);
  static const aiBg1 = Color(0xFFF9EAC4);
  static const aiBg2 = Color(0xFFF6DCB0);
  static const aiBorder = Color(0xFFE2BC72);
  static const goldUp = Color(0xFF7A4F0E);

  // fonts
  static const ui = 'Manrope';
  static const display = 'InstrumentSerif';
  static const mono = 'JetBrainsMono';

  static const shadowMd = [
    BoxShadow(color: Color(0x14361E0E), blurRadius: 18, offset: Offset(0, 6)),
    BoxShadow(color: Color(0x0A361E0E), blurRadius: 4, offset: Offset(0, 2)),
  ];

  static ThemeData theme() {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      fontFamily: ui,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: surface,
        brightness: Brightness.light,
      ),
      splashFactory: InkRipple.splashFactory,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
        fontFamily: ui,
      ),
    );
  }

  // text helpers
  static TextStyle t({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = ink,
    double? height,
    double? letterSpacing,
    String? family,
    FontStyle? style,
  }) =>
      TextStyle(
        fontFamily: family ?? ui,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        fontStyle: style,
      );

  static TextStyle serif({
    double size = 16,
    Color color = ink,
    double? height,
    bool italic = true,
    FontWeight weight = FontWeight.w400,
  }) =>
      TextStyle(
        fontFamily: display,
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      );

  static TextStyle monoStyle({
    double size = 14,
    FontWeight weight = FontWeight.w600,
    Color color = ink,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: mono,
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );

  static TextStyle eyebrow({Color color = muted}) => t(
        size: 11,
        weight: FontWeight.w700,
        color: color,
        letterSpacing: 1.1,
      );
}
