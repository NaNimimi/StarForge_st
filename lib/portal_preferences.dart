import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Languages supported by the family portal. The value is also sent to the
/// backend in the standard `Accept-Language` request header.
enum PortalLanguage {
  uz('uz', "O‘zbekcha"),
  ru('ru', 'Русский'),
  en('en', 'English');

  const PortalLanguage(this.code, this.label);

  final String code;
  final String label;

  Locale get locale => Locale(code);

  static PortalLanguage fromCode(Object? raw) {
    final code = '${raw ?? ''}'
        .trim()
        .toLowerCase()
        .split(RegExp('[-_]'))
        .first;
    return PortalLanguage.values.firstWhere(
      (item) => item.code == code,
      orElse: () => PortalLanguage.uz,
    );
  }
}

enum PortalCurrency {
  uzs('UZS', 'so‘m', 0),
  usd('USD', r'$', 2),
  eur('EUR', '€', 2),
  rub('RUB', '₽', 2);

  const PortalCurrency(this.code, this.symbol, this.fractionDigits);

  final String code;
  final String symbol;
  final int fractionDigits;

  static PortalCurrency fromCode(Object? raw) {
    final code = '${raw ?? ''}'.trim().toUpperCase();
    return PortalCurrency.values.firstWhere(
      (item) => item.code == code,
      orElse: () => PortalCurrency.uzs,
    );
  }
}

enum PortalThemePreference { system, light, dark }

enum PortalDensity { compact, standard, comfortable }

enum PortalPattern { none, dots, grid, tile, topo }

enum PortalChatStyle {
  telegram,
  whatsapp,
  modernDark,
  glass,
  gradient,
  minimal,
  neon,
  nature,
}

enum PortalChatWallpaper {
  telegramClouds,
  whatsappPattern,
  mountains,
  aurora,
  space,
  ocean,
  sakura,
  abstract,
  gradient,
  blur,
}

extension PortalThemePreferenceX on PortalThemePreference {
  ThemeMode get materialThemeMode => switch (this) {
    PortalThemePreference.system => ThemeMode.system,
    PortalThemePreference.light => ThemeMode.light,
    PortalThemePreference.dark => ThemeMode.dark,
  };
}

/// Login-independent presentation preferences.
///
/// They intentionally live outside the authenticated session: language and
/// accessibility settings are available on the login screen and are retained
/// when a user signs out. [memory] keeps tests and previews plugin-free, while
/// [load] enables durable storage in the executable app.
final class PortalPreferences extends ChangeNotifier {
  PortalPreferences.memory({
    this.language = PortalLanguage.uz,
    this.currency = PortalCurrency.uzs,
    this.themePreference = PortalThemePreference.system,
    this.paletteIndex = 0,
    this.density = PortalDensity.standard,
    this.fontIndex = 0,
    this.pattern = PortalPattern.none,
    this.chatStyle = PortalChatStyle.telegram,
    this.chatWallpaper = PortalChatWallpaper.telegramClouds,
    this.largeText = false,
    this.highContrast = false,
    this.reduceMotion = false,
    this.hideAmounts = false,
  }) : _persistent = false;

  PortalPreferences._persistent({
    required this.language,
    required this.currency,
    required this.themePreference,
    required this.paletteIndex,
    required this.density,
    required this.fontIndex,
    required this.pattern,
    required this.chatStyle,
    required this.chatWallpaper,
    required this.largeText,
    required this.highContrast,
    required this.reduceMotion,
    required this.hideAmounts,
  }) : _persistent = true;

  static const supportedLocales = <Locale>[
    Locale('uz'),
    Locale('ru'),
    Locale('en'),
  ];

  static Future<PortalPreferences> load() async {
    final store = await SharedPreferences.getInstance();
    await Future.wait([
      store.remove('portal.profile.avatar_asset'),
      store.remove('portal.profile.avatar_custom'),
      store.remove('portal.profile.avatar_owner'),
    ]);
    return PortalPreferences._persistent(
      language: PortalLanguage.fromCode(store.getString(_languageKey)),
      currency: PortalCurrency.fromCode(store.getString(_currencyKey)),
      themePreference: _enumValue(
        PortalThemePreference.values,
        store.getString(_themeKey),
        PortalThemePreference.system,
      ),
      paletteIndex: (store.getInt(_paletteKey) ?? 0).clamp(0, 9),
      density: _enumValue(
        PortalDensity.values,
        store.getString(_densityKey),
        PortalDensity.standard,
      ),
      fontIndex: (store.getInt(_fontKey) ?? 0).clamp(0, 2),
      pattern: _enumValue(
        PortalPattern.values,
        store.getString(_patternKey),
        PortalPattern.none,
      ),
      chatStyle: _enumValue(
        PortalChatStyle.values,
        store.getString(_chatStyleKey),
        PortalChatStyle.telegram,
      ),
      chatWallpaper: _enumValue(
        PortalChatWallpaper.values,
        store.getString(_chatWallpaperKey),
        PortalChatWallpaper.telegramClouds,
      ),
      largeText: store.getBool(_largeTextKey) ?? false,
      highContrast: store.getBool(_highContrastKey) ?? false,
      reduceMotion: store.getBool(_reduceMotionKey) ?? false,
      hideAmounts: store.getBool(_hideAmountsKey) ?? false,
    );
  }

  static const _languageKey = 'portal.appearance.language';
  static const _currencyKey = 'portal.appearance.currency';
  static const _themeKey = 'portal.appearance.theme';
  static const _paletteKey = 'portal.appearance.palette';
  static const _densityKey = 'portal.appearance.density';
  static const _fontKey = 'portal.appearance.font';
  static const _patternKey = 'portal.appearance.pattern';
  static const _chatStyleKey = 'portal.chat.style';
  static const _chatWallpaperKey = 'portal.chat.wallpaper';
  static const _largeTextKey = 'portal.accessibility.large_text';
  static const _highContrastKey = 'portal.accessibility.high_contrast';
  static const _reduceMotionKey = 'portal.accessibility.reduce_motion';
  static const _hideAmountsKey = 'portal.finance.hide_amounts';
  final bool _persistent;

  PortalLanguage language;
  PortalCurrency currency;
  PortalThemePreference themePreference;
  int paletteIndex;
  PortalDensity density;
  int fontIndex;
  PortalPattern pattern;
  PortalChatStyle chatStyle;
  PortalChatWallpaper chatWallpaper;
  bool largeText;
  bool highContrast;
  bool reduceMotion;
  bool hideAmounts;

  Locale get locale => language.locale;
  ThemeMode get themeMode => themePreference.materialThemeMode;

  void setLanguage(PortalLanguage value) =>
      _set(language == value, () => language = value);

  void setCurrency(PortalCurrency value) =>
      _set(currency == value, () => currency = value);

  void setThemePreference(PortalThemePreference value) =>
      _set(themePreference == value, () => themePreference = value);

  void setDarkMode(bool value) => setThemePreference(
    value ? PortalThemePreference.dark : PortalThemePreference.light,
  );

  void setPaletteIndex(int value) {
    final next = value.clamp(0, 9);
    _set(paletteIndex == next, () => paletteIndex = next);
  }

  void setDensity(PortalDensity value) =>
      _set(density == value, () => density = value);

  void setFontIndex(int value) {
    final next = value.clamp(0, 2);
    _set(fontIndex == next, () => fontIndex = next);
  }

  void setPattern(PortalPattern value) =>
      _set(pattern == value, () => pattern = value);

  void setChatStyle(PortalChatStyle value) =>
      _set(chatStyle == value, () => chatStyle = value);

  void setChatWallpaper(PortalChatWallpaper value) =>
      _set(chatWallpaper == value, () => chatWallpaper = value);

  void setLargeText(bool value) =>
      _set(largeText == value, () => largeText = value);

  void setHighContrast(bool value) =>
      _set(highContrast == value, () => highContrast = value);

  void setReduceMotion(bool value) =>
      _set(reduceMotion == value, () => reduceMotion = value);

  void setHideAmounts(bool value) =>
      _set(hideAmounts == value, () => hideAmounts = value);

  void reset() {
    language = PortalLanguage.uz;
    currency = PortalCurrency.uzs;
    themePreference = PortalThemePreference.system;
    paletteIndex = 0;
    density = PortalDensity.standard;
    fontIndex = 0;
    pattern = PortalPattern.none;
    chatStyle = PortalChatStyle.telegram;
    chatWallpaper = PortalChatWallpaper.telegramClouds;
    largeText = false;
    highContrast = false;
    reduceMotion = false;
    hideAmounts = false;
    _commit();
  }

  /// Explicitly awaits persistence. UI setters save automatically, but this is
  /// useful for deterministic tests and lifecycle hand-off points.
  Future<void> persist() => _save();

  PortalMoneyDisplay formatMoney(
    Object? amount, {
    PortalCurrency sourceCurrency = PortalCurrency.uzs,
    double? sourceToPreferredRate,
  }) => PortalMoneyFormatter.format(
    amount,
    language: language,
    sourceCurrency: sourceCurrency,
    preferredCurrency: currency,
    sourceToPreferredRate: sourceToPreferredRate,
  );

  void _set(bool unchanged, VoidCallback mutate) {
    if (unchanged) return;
    mutate();
    _commit();
  }

  void _commit() {
    if (_persistent) unawaited(_save());
    notifyListeners();
  }

  Future<void> _save() async {
    if (!_persistent) return;
    final store = await SharedPreferences.getInstance();
    await Future.wait([
      store.setString(_languageKey, language.code),
      store.setString(_currencyKey, currency.code),
      store.setString(_themeKey, themePreference.name),
      store.setInt(_paletteKey, paletteIndex),
      store.setString(_densityKey, density.name),
      store.setInt(_fontKey, fontIndex),
      store.setString(_patternKey, pattern.name),
      store.setString(_chatStyleKey, chatStyle.name),
      store.setString(_chatWallpaperKey, chatWallpaper.name),
      store.setBool(_largeTextKey, largeText),
      store.setBool(_highContrastKey, highContrast),
      store.setBool(_reduceMotionKey, reduceMotion),
      store.setBool(_hideAmountsKey, hideAmounts),
    ]);
  }
}

T _enumValue<T extends Enum>(List<T> values, String? raw, T fallback) {
  for (final value in values) {
    if (value.name == raw) return value;
  }
  return fallback;
}

/// A formatted amount plus conversion metadata. When a requested conversion
/// has no explicit rate, [conversionUnavailable] is true and [text] safely
/// retains the source currency instead of inventing a rate.
final class PortalMoneyDisplay {
  const PortalMoneyDisplay({
    required this.text,
    required this.currency,
    required this.converted,
    required this.conversionUnavailable,
  });

  final String text;
  final PortalCurrency currency;
  final bool converted;
  final bool conversionUnavailable;
}

abstract final class PortalMoneyFormatter {
  static PortalMoneyDisplay format(
    Object? raw, {
    required PortalLanguage language,
    required PortalCurrency sourceCurrency,
    required PortalCurrency preferredCurrency,
    double? sourceToPreferredRate,
  }) {
    final parsed = raw is num ? raw.toDouble() : double.tryParse('$raw');
    if (parsed == null || !parsed.isFinite) {
      return PortalMoneyDisplay(
        text: '—',
        currency: sourceCurrency,
        converted: false,
        conversionUnavailable: false,
      );
    }

    var displayed = parsed;
    var currency = sourceCurrency;
    var converted = false;
    final conversionRequested = preferredCurrency != sourceCurrency;
    final canConvert =
        sourceToPreferredRate != null &&
        sourceToPreferredRate.isFinite &&
        sourceToPreferredRate > 0;
    if (conversionRequested && canConvert) {
      displayed *= sourceToPreferredRate;
      currency = preferredCurrency;
      converted = true;
    }

    return PortalMoneyDisplay(
      text: _formatNumber(displayed, currency, language),
      currency: currency,
      converted: converted,
      conversionUnavailable: conversionRequested && !canConvert,
    );
  }

  static String _formatNumber(
    double value,
    PortalCurrency currency,
    PortalLanguage language,
  ) {
    final negative = value < 0;
    final fixed = value.abs().toStringAsFixed(currency.fractionDigits);
    final parts = fixed.split('.');
    final digits = parts.first;
    final grouped = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        grouped.write('\u00a0');
      }
      grouped.write(digits[index]);
    }
    final decimal = language == PortalLanguage.en ? '.' : ',';
    final fraction = parts.length == 2 ? '$decimal${parts.last}' : '';
    final number = '${negative ? '−' : ''}$grouped$fraction';
    return switch (currency) {
      PortalCurrency.uzs => '$number ${currency.symbol}',
      _ => '${currency.symbol}\u00a0$number',
    };
  }
}
