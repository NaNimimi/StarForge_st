import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Semantic design tokens based on DESIGN_PATTERNS_AND_LAYOUT.md.
///
/// Legacy aliases remain available because the repository still contains
/// archived prototype screens, while the active application consumes the
/// colors through [ThemeData].
class Sf {
  static const bg = Color(0xFFF6F7FC);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF0F2F9);
  static const surface3 = Color(0xFFE7EAF5);
  static const ink = Color(0xFF171A2C);
  static const ink2 = Color(0xFF3F455C);
  static const muted = Color(0xFF697089);
  static const muted2 = Color(0xFFA4A9BA);
  static const border = Color(0xFFE2E5EF);
  static const borderStrong = Color(0xFFC9CEDD);
  static const primary = Color(0xFF5B5CE2);
  static const primaryHover = Color(0xFF4849C8);
  static const primarySoft = Color(0xFFE7E7FF);
  static const primaryInk = Color(0xFF3435A4);
  static const accent = Color(0xFFFF7A59);
  static const accentSoft = Color(0xFFFFE7DF);
  static const accentInk = Color(0xFF9A351D);
  static const success = Color(0xFF009B74);
  static const successSoft = Color(0xFFDDF7EE);
  static const warn = Color(0xFFE09A24);
  static const warnSoft = Color(0xFFFFF0D2);
  static const danger = Color(0xFFD6455D);
  static const dangerSoft = Color(0xFFFFE1E6);
  static const ai = Color(0xFF7559D9);
  static const aiBg1 = Color(0xFFF1EDFF);
  static const aiBg2 = Color(0xFFE4DCFF);
  static const aiBorder = Color(0xFFB9A8F5);
  static const goldUp = accentInk;

  static const ui = 'Manrope';
  static const display = 'InstrumentSerif';
  static const mono = 'JetBrainsMono';

  static const paletteColors = <(Color, Color)>[
    (Color(0xFF5B5CE2), Color(0xFFFF7A59)),
    (Color(0xFF1F6B66), Color(0xFFC4892F)),
    (Color(0xFF2A3D8F), Color(0xFFD8A22A)),
    (Color(0xFFB85535), Color(0xFFD89A2E)),
    (Color(0xFFC2410C), Color(0xFFD6608A)),
    (Color(0xFF0E7C5A), Color(0xFFC08A2E)),
    (Color(0xFFB3122F), Color(0xFFC28A1E)),
    (Color(0xFF2563A8), Color(0xFFD98A4E)),
    (Color(0xFFB8791C), Color(0xFF3F7A6A)),
    (Color(0xFF2B2A26), Color(0xFF9A7B3F)),
  ];

  static const selectableFonts = <String>[ui, display, mono];

  static const radiusSmall = 8.0;
  static const radiusMedium = 14.0;
  static const radiusLarge = 16.0;
  static const radiusExtraLarge = 22.0;

  static const shadowMd = [
    BoxShadow(color: Color(0x12101828), blurRadius: 24, offset: Offset(0, 10)),
    BoxShadow(color: Color(0x0A101828), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static ThemeData theme({
    bool highContrast = false,
    int paletteIndex = 0,
    int fontIndex = 0,
    VisualDensity visualDensity = VisualDensity.standard,
  }) => _theme(
    Brightness.light,
    highContrast: highContrast,
    paletteIndex: paletteIndex,
    fontIndex: fontIndex,
    visualDensity: visualDensity,
  );

  static ThemeData darkTheme({
    bool highContrast = false,
    int paletteIndex = 0,
    int fontIndex = 0,
    VisualDensity visualDensity = VisualDensity.standard,
  }) => _theme(
    Brightness.dark,
    highContrast: highContrast,
    paletteIndex: paletteIndex,
    fontIndex: fontIndex,
    visualDensity: visualDensity,
  );

  static ThemeData _theme(
    Brightness brightness, {
    required bool highContrast,
    required int paletteIndex,
    required int fontIndex,
    required VisualDensity visualDensity,
  }) {
    final dark = brightness == Brightness.dark;
    final palette =
        paletteColors[paletteIndex.clamp(0, paletteColors.length - 1)];
    final selectedPrimary = palette.$1;
    final selectedAccent = palette.$2;
    final selectedFont =
        selectableFonts[fontIndex.clamp(0, selectableFonts.length - 1)];
    final darkPrimary = Color.lerp(selectedPrimary, Colors.white, .58)!;
    final darkAccent = Color.lerp(selectedAccent, Colors.white, .42)!;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: dark ? darkPrimary : selectedPrimary,
      onPrimary: dark ? const Color(0xFF20214D) : Colors.white,
      primaryContainer: dark
          ? Color.lerp(selectedPrimary, const Color(0xFF211D17), .56)!
          : Color.lerp(selectedPrimary, Colors.white, .78)!,
      onPrimaryContainer: dark ? const Color(0xFFE7E7FF) : primaryInk,
      secondary: dark ? darkAccent : selectedAccent,
      onSecondary: dark ? const Color(0xFF542014) : const Color(0xFF3F140B),
      secondaryContainer: dark
          ? Color.lerp(selectedAccent, const Color(0xFF211D17), .62)!
          : Color.lerp(selectedAccent, Colors.white, .76)!,
      onSecondaryContainer: dark ? const Color(0xFFFFE7DF) : accentInk,
      error: dark ? const Color(0xFFFFB4A8) : danger,
      onError: dark ? const Color(0xFF680007) : Colors.white,
      errorContainer: dark ? const Color(0xFF5B2520) : dangerSoft,
      onErrorContainer: dark
          ? const Color(0xFFFFDAD4)
          : const Color(0xFF5D160D),
      surface: dark ? const Color(0xFF1B1D2B) : surface,
      onSurface: dark ? const Color(0xFFF2F3FA) : ink,
      surfaceContainerLowest: dark
          ? const Color(0xFF12131D)
          : const Color(0xFFFAFBFF),
      surfaceContainerLow: dark
          ? const Color(0xFF202230)
          : const Color(0xFFF4F5FA),
      surfaceContainer: dark ? const Color(0xFF282A3A) : surface2,
      surfaceContainerHigh: dark ? const Color(0xFF303344) : surface3,
      surfaceContainerHighest: dark
          ? const Color(0xFF3A3E52)
          : const Color(0xFFDDE0EC),
      onSurfaceVariant: dark ? const Color(0xFFC7CAD8) : ink2,
      outline: highContrast
          ? (dark ? const Color(0xFFD9DCEC) : const Color(0xFF6C7289))
          : (dark ? const Color(0xFF666B81) : borderStrong),
      outlineVariant: highContrast
          ? (dark ? const Color(0xFF858A9F) : borderStrong)
          : (dark ? const Color(0xFF424658) : border),
      shadow: const Color(0xFF10121D),
      scrim: const Color(0x99000000),
      inverseSurface: dark ? const Color(0xFFF2F3FA) : ink,
      onInverseSurface: dark ? ink : Colors.white,
      inversePrimary: dark ? selectedPrimary : darkPrimary,
      surfaceTint: Colors.transparent,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: selectedFont,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? const Color(0xFF12131D) : bg,
      splashFactory: InkRipple.splashFactory,
      visualDensity: visualDensity,
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
              size: 28,
              weight: FontWeight.w800,
              color: scheme.onSurface,
              height: 1.1,
              family: selectedFont,
            ),
            headlineMedium: t(
              size: 22,
              weight: FontWeight.w800,
              color: scheme.onSurface,
              height: 1.12,
              family: selectedFont,
            ),
            titleLarge: t(
              size: 18,
              weight: FontWeight.w800,
              color: scheme.onSurface,
              height: 1.2,
            ),
            titleMedium: t(
              size: 15,
              weight: FontWeight.w700,
              color: scheme.onSurface,
              height: 1.25,
            ),
            bodyLarge: t(
              size: 14,
              weight: FontWeight.w500,
              color: scheme.onSurface,
              height: 1.45,
            ),
            bodyMedium: t(
              size: 13,
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
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: t(size: 13, weight: FontWeight.w800),
          side: BorderSide(color: scheme.outline),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          textStyle: t(size: 13, weight: FontWeight.w800),
          shape: const StadiumBorder(),
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
