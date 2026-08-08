import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Semantic design tokens based on DESIGN_PATTERNS_AND_LAYOUT.md.
///
/// Legacy aliases remain available because the repository still contains
/// archived prototype screens, while the active application consumes the
/// colors through [ThemeData].
class Sf {
  static const bg = Color(0xFFF1EFE6);
  static const surface = Color(0xFFFAF8EF);
  static const surface2 = Color(0xFFE5E4D2);
  static const surface3 = Color(0xFFD7D5BD);
  static const ink = Color(0xFF1A1E18);
  static const ink2 = Color(0xFF2F352A);
  static const muted = Color(0xFF6F7264);
  static const muted2 = Color(0xFFA2A593);
  static const border = Color(0xFFD9D6BD);
  static const borderStrong = Color(0xFFB7B399);
  static const primary = Color(0xFF4F6A3A);
  static const primaryHover = Color(0xFF3E5A29);
  static const primarySoft = Color(0xFFDBE5C7);
  static const primaryInk = Color(0xFF324D22);
  static const accent = Color(0xFFBA8C2C);
  static const accentSoft = Color(0xFFF0E1BB);
  static const accentInk = Color(0xFF674A0D);
  static const success = Color(0xFF4F7B3B);
  static const successSoft = Color(0xFFDDE9CE);
  static const warn = Color(0xFFC68423);
  static const warnSoft = Color(0xFFF5E2BF);
  static const danger = Color(0xFFB33A2A);
  static const dangerSoft = Color(0xFFF3D8D0);
  static const ai = Color(0xFF77551B);
  static const aiBg1 = Color(0xFFF3E9D0);
  static const aiBg2 = Color(0xFFE9D6AA);
  static const aiBorder = Color(0xFFC9AD70);
  static const goldUp = accentInk;

  static const ui = 'Manrope';
  static const display = 'InstrumentSerif';
  static const mono = 'JetBrainsMono';

  static const radiusSmall = 8.0;
  static const radiusMedium = 12.0;
  static const radiusLarge = 18.0;
  static const radiusExtraLarge = 24.0;

  static const shadowMd = [
    BoxShadow(color: Color(0x12101828), blurRadius: 24, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x0A101828), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static ThemeData theme({bool highContrast = false}) =>
      _theme(Brightness.light, highContrast: highContrast);

  static ThemeData darkTheme({bool highContrast = false}) =>
      _theme(Brightness.dark, highContrast: highContrast);

  static ThemeData _theme(Brightness brightness, {required bool highContrast}) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: dark ? const Color(0xFFB7D29A) : primary,
      onPrimary: dark ? const Color(0xFF203313) : Colors.white,
      primaryContainer: dark ? const Color(0xFF344729) : primarySoft,
      onPrimaryContainer: dark ? const Color(0xFFDDEFC7) : primaryInk,
      secondary: dark ? const Color(0xFFE3BD6A) : accent,
      onSecondary: dark ? const Color(0xFF3C2B08) : const Color(0xFF332100),
      secondaryContainer: dark ? const Color(0xFF4B3B1E) : accentSoft,
      onSecondaryContainer: dark ? const Color(0xFFF5DEA8) : accentInk,
      error: dark ? const Color(0xFFFFB4A8) : danger,
      onError: dark ? const Color(0xFF680007) : Colors.white,
      errorContainer: dark ? const Color(0xFF5B2520) : dangerSoft,
      onErrorContainer: dark
          ? const Color(0xFFFFDAD4)
          : const Color(0xFF5D160D),
      surface: dark ? const Color(0xFF1D1914) : surface,
      onSurface: dark ? const Color(0xFFF0EBDD) : ink,
      surfaceContainerLowest: dark
          ? const Color(0xFF14110D)
          : const Color(0xFFF7F5EB),
      surfaceContainerLow: dark
          ? const Color(0xFF211D17)
          : const Color(0xFFF3F1E7),
      surfaceContainer: dark ? const Color(0xFF29241D) : surface2,
      surfaceContainerHigh: dark ? const Color(0xFF332D24) : surface3,
      surfaceContainerHighest: dark
          ? const Color(0xFF40382D)
          : const Color(0xFFCECBB2),
      onSurfaceVariant: dark ? const Color(0xFFC9C0AF) : ink2,
      outline: highContrast
          ? (dark ? const Color(0xFFD3CAB8) : const Color(0xFF777561))
          : (dark ? const Color(0xFF6D6252) : borderStrong),
      outlineVariant: highContrast
          ? (dark ? const Color(0xFF8B7E69) : borderStrong)
          : (dark ? const Color(0xFF443C31) : border),
      shadow: const Color(0xFF14110D),
      scrim: const Color(0x99000000),
      inverseSurface: dark ? const Color(0xFFF0EBDD) : ink,
      onInverseSurface: dark ? ink : Colors.white,
      inversePrimary: dark ? primary : const Color(0xFFB7D29A),
      surfaceTint: Colors.transparent,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: ui,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? const Color(0xFF14110D) : bg,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
    );
    final focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: BorderSide(color: scheme.primary, width: 1.8),
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusMedium),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );

    return base.copyWith(
      textTheme: base.textTheme
          .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface)
          .copyWith(
            headlineLarge: t(
              size: 34,
              weight: FontWeight.w700,
              color: scheme.onSurface,
              height: 1.08,
              family: display,
            ),
            headlineMedium: t(
              size: 27,
              weight: FontWeight.w700,
              color: scheme.onSurface,
              height: 1.12,
              family: display,
            ),
            titleLarge: t(
              size: 20,
              weight: FontWeight.w800,
              color: scheme.onSurface,
              height: 1.2,
            ),
            titleMedium: t(
              size: 16,
              weight: FontWeight.w700,
              color: scheme.onSurface,
              height: 1.25,
            ),
            bodyLarge: t(
              size: 15,
              weight: FontWeight.w500,
              color: scheme.onSurface,
              height: 1.45,
            ),
            bodyMedium: t(
              size: 13.5,
              weight: FontWeight.w500,
              color: scheme.onSurface,
              height: 1.45,
            ),
            bodySmall: t(
              size: 12,
              weight: FontWeight.w500,
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
            labelLarge: t(
              size: 13,
              weight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: t(
          size: 17,
          weight: FontWeight.w800,
          color: scheme.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => t(
            size: 11,
            weight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 0,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        selectedIconTheme: IconThemeData(color: scheme.onPrimaryContainer),
        selectedLabelTextStyle: t(
          size: 13,
          weight: FontWeight.w800,
          color: scheme.onPrimaryContainer,
        ),
        unselectedLabelTextStyle: t(
          size: 13,
          weight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusExtraLarge),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: scheme.surface,
        modalBarrierColor: scheme.scrim.withValues(alpha: 0.54),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusExtraLarge),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        labelStyle: t(
          size: 13,
          weight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
        ),
        hintStyle: t(
          size: 14,
          weight: FontWeight.w500,
          color: dark ? const Color(0xFF9E927E) : muted,
        ),
        helperStyle: t(
          size: 11,
          weight: FontWeight.w500,
          color: scheme.onSurfaceVariant,
        ),
        errorStyle: t(size: 11, weight: FontWeight.w600, color: scheme.error),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: focusBorder,
        errorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedErrorBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: scheme.error, width: 1.8),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: t(size: 13, weight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: t(size: 13, weight: FontWeight.w800),
          side: BorderSide(color: scheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          textStyle: t(size: 13, weight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        shape: const StadiumBorder(),
        labelStyle: t(
          size: 12,
          weight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark
            ? const Color(0xFFF2EADA)
            : const Color(0xFF1A1E18),
        contentTextStyle: t(
          size: 13,
          weight: FontWeight.w700,
          color: dark ? ink : const Color(0xFFF8F5EA),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      focusColor: scheme.primaryContainer,
      hoverColor: scheme.surfaceContainer,
    );
  }

  static TextStyle t({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = ink,
    double? height,
    double? letterSpacing,
    String? family,
    FontStyle? style,
  }) => TextStyle(
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
  }) => TextStyle(
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
  }) => TextStyle(
    fontFamily: mono,
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
  );

  static TextStyle eyebrow({Color color = muted}) =>
      t(size: 10.5, weight: FontWeight.w700, color: color, letterSpacing: 0.7);
}
