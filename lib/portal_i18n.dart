import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'portal_preferences.dart';

/// Localized system copy for the connected family portal. Server/user content
/// (names, teacher messages and assignment text) is intentionally not altered.
final class PortalLocalizations {
  const PortalLocalizations(this.language);

  final PortalLanguage language;

  static PortalLocalizations of(BuildContext context) =>
      Localizations.of<PortalLocalizations>(context, PortalLocalizations) ??
      const PortalLocalizations(PortalLanguage.uz);

  String text(String key, {String? fallback}) =>
      portalText(language, key, fallback: fallback);
}

final class PortalLocalizationsDelegate
    extends LocalizationsDelegate<PortalLocalizations> {
  const PortalLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => PortalLanguage.values.any(
    (language) => language.code == locale.languageCode,
  );

  @override
  Future<PortalLocalizations> load(Locale locale) => SynchronousFuture(
    PortalLocalizations(PortalLanguage.fromCode(locale.languageCode)),
  );

  @override
  bool shouldReload(PortalLocalizationsDelegate old) => false;
}

extension PortalLocalizationContext on BuildContext {
  String tr(String key, {String? fallback}) =>
      PortalLocalizations.of(this).text(key, fallback: fallback);
}

String portalText(PortalLanguage language, String key, {String? fallback}) {
  final row = _catalog[key];
  if (row == null) return fallback ?? key;
  return row[language] ?? row[PortalLanguage.uz] ?? fallback ?? key;
}

const Map<String, Map<PortalLanguage, String>> _catalog = {
  'brand.familyPortal': {
    PortalLanguage.uz: 'O‘quvchi va ota-ona portali',
    PortalLanguage.ru: 'Портал ученика и родителя',
    PortalLanguage.en: 'Student and parent portal',
  },
  'brand.sessionVerified': {
    PortalLanguage.uz: 'Rol va ruxsatlar markaz serverida tekshiriladi',
    PortalLanguage.ru: 'Роль и права проверяются сервером центра',
    PortalLanguage.en: 'Role and permissions are verified by the center server',
  },
  'login.title': {
    PortalLanguage.uz: 'Kabinetga kirish',
    PortalLanguage.ru: 'Вход в кабинет',
    PortalLanguage.en: 'Sign in',
  },
  'login.subtitle': {
    PortalLanguage.uz:
        'Rol va ruxsatlar serverdagi hisobingizdan avtomatik olinadi.',
    PortalLanguage.ru:
        'Роль и права будут автоматически получены из вашей учётной записи.',
    PortalLanguage.en:
        'Your role and permissions are loaded automatically from your account.',
  },
  'login.username': {
    PortalLanguage.uz: 'Login',
    PortalLanguage.ru: 'Логин',
    PortalLanguage.en: 'Login',
  },
  'login.password': {
    PortalLanguage.uz: 'Parol',
    PortalLanguage.ru: 'Пароль',
    PortalLanguage.en: 'Password',
  },
  'login.usernameRequired': {
    PortalLanguage.uz: 'Loginni kiriting',
    PortalLanguage.ru: 'Введите логин',
    PortalLanguage.en: 'Enter your login',
  },
  'login.passwordRequired': {
    PortalLanguage.uz: 'Parolni kiriting',
    PortalLanguage.ru: 'Введите пароль',
    PortalLanguage.en: 'Enter your password',
  },
  'login.showPassword': {
    PortalLanguage.uz: 'Parolni ko‘rsatish',
    PortalLanguage.ru: 'Показать пароль',
    PortalLanguage.en: 'Show password',
  },
  'login.hidePassword': {
    PortalLanguage.uz: 'Parolni yashirish',
    PortalLanguage.ru: 'Скрыть пароль',
    PortalLanguage.en: 'Hide password',
  },
  'login.submit': {
    PortalLanguage.uz: 'Kirish',
    PortalLanguage.ru: 'Войти',
    PortalLanguage.en: 'Sign in',
  },
  'login.submitting': {
    PortalLanguage.uz: 'Kirilmoqda…',
    PortalLanguage.ru: 'Выполняется вход…',
    PortalLanguage.en: 'Signing in…',
  },
  'login.forgotPassword': {
    PortalLanguage.uz: 'Parolni unutdingizmi?',
    PortalLanguage.ru: 'Забыли пароль?',
    PortalLanguage.en: 'Forgot password?',
  },
  'login.centerServer': {
    PortalLanguage.uz: 'Markaz serveri',
    PortalLanguage.ru: 'Сервер центра',
    PortalLanguage.en: 'Center server',
  },
  'login.hideServer': {
    PortalLanguage.uz: 'Server sozlamasini yopish',
    PortalLanguage.ru: 'Скрыть настройки сервера',
    PortalLanguage.en: 'Hide server settings',
  },
  'login.serverAddress': {
    PortalLanguage.uz: 'Server manzili',
    PortalLanguage.ru: 'Адрес сервера',
    PortalLanguage.en: 'Server address',
  },
  'language.choose': {
    PortalLanguage.uz: 'Tilni tanlang',
    PortalLanguage.ru: 'Выберите язык',
    PortalLanguage.en: 'Choose language',
  },
  'role.student': {
    PortalLanguage.uz: 'O‘quvchi',
    PortalLanguage.ru: 'Ученик',
    PortalLanguage.en: 'Student',
  },
  'role.parent': {
    PortalLanguage.uz: 'Ota-ona',
    PortalLanguage.ru: 'Родитель',
    PortalLanguage.en: 'Parent',
  },
  'passwordReset.title': {
    PortalLanguage.uz: 'Parolni tiklash',
    PortalLanguage.ru: 'Восстановление пароля',
    PortalLanguage.en: 'Reset password',
  },
  'passwordReset.identifier': {
    PortalLanguage.uz: 'Login, telefon yoki email',
    PortalLanguage.ru: 'Логин, телефон или email',
    PortalLanguage.en: 'Login, phone or email',
  },
  'passwordReset.code': {
    PortalLanguage.uz: 'Tasdiqlash kodi',
    PortalLanguage.ru: 'Код подтверждения',
    PortalLanguage.en: 'Verification code',
  },
  'passwordReset.newPassword': {
    PortalLanguage.uz: 'Yangi parol',
    PortalLanguage.ru: 'Новый пароль',
    PortalLanguage.en: 'New password',
  },
  'passwordReset.minimum': {
    PortalLanguage.uz: 'Kamida 8 belgi',
    PortalLanguage.ru: 'Минимум 8 символов',
    PortalLanguage.en: 'At least 8 characters',
  },
  'passwordReset.codeSent': {
    PortalLanguage.uz: 'Agar akkaunt mavjud bo‘lsa, tasdiqlash kodi yuborildi.',
    PortalLanguage.ru:
        'Если аккаунт существует, код подтверждения уже отправлен.',
    PortalLanguage.en:
        'If the account exists, a verification code has been sent.',
  },
  'passwordReset.updated': {
    PortalLanguage.uz: 'Parol yangilandi. Endi tizimga kiring.',
    PortalLanguage.ru: 'Пароль обновлён. Теперь войдите в систему.',
    PortalLanguage.en: 'Password updated. You can now sign in.',
  },
  'passwordReset.wait': {
    PortalLanguage.uz: 'Kuting…',
    PortalLanguage.ru: 'Подождите…',
    PortalLanguage.en: 'Please wait…',
  },
  'passwordReset.sendCode': {
    PortalLanguage.uz: 'Kod yuborish',
    PortalLanguage.ru: 'Отправить код',
    PortalLanguage.en: 'Send code',
  },
  'passwordReset.update': {
    PortalLanguage.uz: 'Parolni yangilash',
    PortalLanguage.ru: 'Обновить пароль',
    PortalLanguage.en: 'Update password',
  },
  'passwordChange.title': {
    PortalLanguage.uz: 'Yangi parol',
    PortalLanguage.ru: 'Новый пароль',
    PortalLanguage.en: 'New password',
  },
  'passwordChange.prompt': {
    PortalLanguage.uz: 'Vaqtinchalik parolni almashtiring',
    PortalLanguage.ru: 'Замените временный пароль',
    PortalLanguage.en: 'Replace your temporary password',
  },
  'passwordChange.current': {
    PortalLanguage.uz: 'Hozirgi parol',
    PortalLanguage.ru: 'Текущий пароль',
    PortalLanguage.en: 'Current password',
  },
  'passwordChange.repeat': {
    PortalLanguage.uz: 'Yangi parolni takrorlang',
    PortalLanguage.ru: 'Повторите новый пароль',
    PortalLanguage.en: 'Repeat new password',
  },
  'passwordChange.invalid': {
    PortalLanguage.uz:
        'Yangi parol kamida 8 belgi bo‘lsin va ikkala maydon mos kelsin.',
    PortalLanguage.ru:
        'Новый пароль должен содержать минимум 8 символов, а поля — совпадать.',
    PortalLanguage.en:
        'The new password must be at least 8 characters and both fields must match.',
  },
  'passwordChange.save': {
    PortalLanguage.uz: 'Parolni saqlash',
    PortalLanguage.ru: 'Сохранить пароль',
    PortalLanguage.en: 'Save password',
  },
  'passwordChange.saving': {
    PortalLanguage.uz: 'Saqlanmoqda…',
    PortalLanguage.ru: 'Сохранение…',
    PortalLanguage.en: 'Saving…',
  },
  'action.logout': {
    PortalLanguage.uz: 'Chiqish',
    PortalLanguage.ru: 'Выйти',
    PortalLanguage.en: 'Log out',
  },
  'error.unexpectedLogin': {
    PortalLanguage.uz: 'Kirish vaqtida kutilmagan xatolik yuz berdi.',
    PortalLanguage.ru: 'При входе произошла непредвиденная ошибка.',
    PortalLanguage.en: 'An unexpected error occurred while signing in.',
  },
  'error.invalidLoginResponse': {
    PortalLanguage.uz: 'Server sessiya kalitini qaytarmadi.',
    PortalLanguage.ru: 'Сервер не вернул ключ сессии.',
    PortalLanguage.en: 'The server did not return a session key.',
  },
};
