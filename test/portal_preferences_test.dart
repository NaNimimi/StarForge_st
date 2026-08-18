import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:starforge_student/portal_i18n.dart';
import 'package:starforge_student/portal_preferences.dart';
import 'package:starforge_student/portal_state.dart';
import 'package:starforge_student/starforge_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('obsolete profile photos are removed from device storage', () async {
    SharedPreferences.setMockInitialValues({
      'portal.profile.avatar_asset': 'assets/avatars/student_1.png',
      'portal.profile.avatar_custom': 'old-image-data',
      'portal.profile.avatar_owner': 'student:7',
    });

    await PortalPreferences.load();
    final store = await SharedPreferences.getInstance();

    expect(store.containsKey('portal.profile.avatar_asset'), isFalse);
    expect(store.containsKey('portal.profile.avatar_custom'), isFalse);
    expect(store.containsKey('portal.profile.avatar_owner'), isFalse);
  });

  test(
    'language, currency and presentation preferences survive reload',
    () async {
      final preferences = await PortalPreferences.load();
      preferences
        ..setLanguage(PortalLanguage.ru)
        ..setCurrency(PortalCurrency.rub)
        ..setThemePreference(PortalThemePreference.dark)
        ..setDensity(PortalDensity.compact)
        ..setPaletteIndex(7)
        ..setFontIndex(2)
        ..setPattern(PortalPattern.grid)
        ..setChatStyle(PortalChatStyle.glass)
        ..setChatWallpaper(PortalChatWallpaper.aurora)
        ..setLargeText(true);
      await preferences.persist();

      final restored = await PortalPreferences.load();
      expect(restored.language, PortalLanguage.ru);
      expect(restored.locale.languageCode, 'ru');
      expect(restored.currency, PortalCurrency.rub);
      expect(restored.themePreference, PortalThemePreference.dark);
      expect(restored.density, PortalDensity.compact);
      expect(restored.paletteIndex, 7);
      expect(restored.fontIndex, 2);
      expect(restored.pattern, PortalPattern.grid);
      expect(restored.chatStyle, PortalChatStyle.glass);
      expect(restored.chatWallpaper, PortalChatWallpaper.aurora);
      expect(restored.largeText, isTrue);
    },
  );

  test('money formatter never invents a foreign-exchange rate', () {
    final unavailable = PortalMoneyFormatter.format(
      1250000,
      language: PortalLanguage.ru,
      sourceCurrency: PortalCurrency.uzs,
      preferredCurrency: PortalCurrency.usd,
    );
    expect(unavailable.text, '1\u00a0250\u00a0000 so‘m');
    expect(unavailable.currency, PortalCurrency.uzs);
    expect(unavailable.converted, isFalse);
    expect(unavailable.conversionUnavailable, isTrue);

    final converted = PortalMoneyFormatter.format(
      1250000,
      language: PortalLanguage.en,
      sourceCurrency: PortalCurrency.uzs,
      preferredCurrency: PortalCurrency.usd,
      sourceToPreferredRate: 0.00008,
    );
    expect(converted.text, r'$ 100.00');
    expect(converted.currency, PortalCurrency.usd);
    expect(converted.converted, isTrue);
    expect(converted.conversionUnavailable, isFalse);
  });

  test('Russian and English login system copy is available', () {
    expect(portalText(PortalLanguage.ru, 'login.title'), 'Вход в кабинет');
    expect(portalText(PortalLanguage.en, 'login.submit'), 'Sign in');
    expect(portalText(PortalLanguage.uz, 'missing.key'), 'missing.key');
  });

  test(
    'controller updates Accept-Language before authenticated login',
    () async {
      late String sentLanguage;
      final api = StarForgeApi(
        baseUrl: 'https://demo.example.uz',
        client: MockClient((request) async {
          sentLanguage = request.headers['accept-language'] ?? '';
          return http.Response('{"success":true,"data":[]}', 200);
        }),
      );
      final preferences = PortalPreferences.memory(language: PortalLanguage.uz);
      final portal = PortalController(
        api: api,
        preferences: preferences,
        restoreSession: false,
      );
      addTearDown(portal.dispose);

      preferences.setLanguage(PortalLanguage.ru);
      await portal.getApi('/api/v1/public-test/');

      expect(sentLanguage, 'ru');
    },
  );

  test('client-side API fallback errors follow the selected language', () {
    final api = StarForgeApi(
      baseUrl: 'https://demo.example.uz',
      acceptLanguage: 'ru',
      client: MockClient((_) async => http.Response('{"success":false}', 404)),
    );
    addTearDown(api.close);

    expect(
      () => api.get('/api/v1/missing/'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'Данные не найдены.',
        ),
      ),
    );
  });
}
