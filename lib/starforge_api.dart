import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

const String defaultApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://starforge.78.111.91.113.nip.io',
);

final class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.code = 'request_failed',
    this.statusCode,
    this.fields = const {},
  });

  final String message;
  final String code;
  final int? statusCode;
  final Map<String, Object?> fields;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

final class ApiResult {
  const ApiResult({
    required this.data,
    this.pagination = const {},
    this.failure,
  });

  const ApiResult.failed(ApiException error)
    : data = null,
      pagination = const {},
      failure = error;

  final Object? data;
  final Map<String, Object?> pagination;
  final ApiException? failure;

  bool get isSuccessful => failure == null;
  bool get isFailed => failure != null;

  ApiPageInfo get pageInfo => ApiPageInfo.fromResult(this);

  List<Map<String, Object?>> get rows {
    Object? value = data;
    if (value is Map) {
      final map = Map<String, Object?>.from(value);
      value = map['results'] ?? map['items'];
    }
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is Map) Map<String, Object?>.from(item),
    ];
  }

  Map<String, Object?> get object => data is Map
      ? Map<String, Object?>.from(data! as Map)
      : const <String, Object?>{};
}

/// A normalized view over both StarForge's page-number envelope and cursor
/// feeds such as notifications. Existing consumers can keep using
/// [ApiResult.rows], while screens that need "load more" no longer have to
/// inspect loosely typed response maps.
final class ApiPageInfo {
  const ApiPageInfo({
    this.total,
    this.page,
    this.pageSize,
    this.totalPages,
    this.next,
    this.previous,
  });

  factory ApiPageInfo.fromResult(ApiResult result) {
    final pagination = result.pagination;
    final data = result.data is Map
        ? Map<String, Object?>.from(result.data! as Map)
        : const <String, Object?>{};
    Object? first(Iterable<String> keys) {
      for (final key in keys) {
        if (pagination.containsKey(key)) return pagination[key];
        if (data.containsKey(key)) return data[key];
      }
      return null;
    }

    return ApiPageInfo(
      total: _apiInteger(first(const ['total', 'count'])),
      page: _apiInteger(first(const ['page', 'current_page'])),
      pageSize: _apiInteger(first(const ['page_size', 'per_page', 'limit'])),
      totalPages: _apiInteger(first(const ['pages', 'total_pages'])),
      next: _apiNullableText(first(const ['next', 'next_cursor'])),
      previous: _apiNullableText(first(const ['previous', 'prev_cursor'])),
    );
  }

  final int? total;
  final int? page;
  final int? pageSize;
  final int? totalPages;
  final String? next;
  final String? previous;

  bool get hasNext =>
      next != null ||
      (page != null && totalPages != null && page! < totalPages!);
  bool get hasPrevious => previous != null || (page != null && page! > 1);
}

String normalizeApiBaseUrl(String raw, {String language = 'uz'}) {
  final lang = _normalizeLanguage(language);
  var value = raw.trim();
  if (value.isEmpty) value = defaultApiBaseUrl;
  if (RegExp(r'\s').hasMatch(value)) {
    throw FormatException(_apiCopy(lang, 'invalidAddress'));
  }
  if (!value.contains('://')) value = 'https://$value';
  value = value.replaceAll(RegExp(r'/+$'), '');
  value = value.replaceFirst(RegExp(r'/api/v1$'), '');
  final uri = Uri.tryParse(value);
  if (uri == null ||
      !uri.hasScheme ||
      !const {'http', 'https'}.contains(uri.scheme) ||
      uri.host.isEmpty) {
    throw FormatException(_apiCopy(lang, 'invalidAddress'));
  }
  final localHost =
      uri.host == 'localhost' ||
      uri.host == '127.0.0.1' ||
      uri.host == '::1' ||
      uri.host.endsWith('.localhost');
  if (uri.scheme == 'http' && !localHost) {
    throw FormatException(_apiCopy(lang, 'requiresHttps'));
  }
  return uri.toString().replaceAll(RegExp(r'/+$'), '');
}

final class StarForgeApi {
  StarForgeApi({
    required String baseUrl,
    this.accessToken,
    String acceptLanguage = 'uz',
    http.Client? client,
  }) : _baseUrl = normalizeApiBaseUrl(baseUrl, language: acceptLanguage),
       _acceptLanguage = _normalizeLanguage(acceptLanguage),
       _client = client ?? http.Client();

  final http.Client _client;
  String _baseUrl;
  String _acceptLanguage;
  String? accessToken;

  String get baseUrl => _baseUrl;

  String get acceptLanguage => _acceptLanguage;

  set baseUrl(String value) =>
      _baseUrl = normalizeApiBaseUrl(value, language: _acceptLanguage);

  set acceptLanguage(String value) =>
      _acceptLanguage = _normalizeLanguage(value);

  Uri uri(String path, [Map<String, Object?> query = const {}]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final base = Uri.parse('$_baseUrl$normalizedPath');
    final params = <String, String>{
      for (final entry in query.entries)
        if (entry.value != null && '${entry.value}'.isNotEmpty)
          entry.key: '${entry.value}',
    };
    return params.isEmpty ? base : base.replace(queryParameters: params);
  }

  Future<ApiResult> get(String path, {Map<String, Object?> query = const {}}) =>
      _send('GET', path, query: query);

  Future<ApiResult> post(
    String path, {
    Object? body,
    Map<String, Object?> query = const {},
  }) => _send('POST', path, body: body, query: query);

  Future<ApiResult> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<ApiResult> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  Future<ApiResult> delete(String path) => _send('DELETE', path);

  Future<void> uploadBytes(
    String uploadUrl,
    Uint8List bytes, {
    required String contentType,
  }) async {
    final response = await _client
        .put(
          Uri.parse(uploadUrl),
          headers: {'Content-Type': contentType},
          body: bytes,
        )
        .timeout(const Duration(seconds: 60));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        message: _apiCopy(_acceptLanguage, 'uploadFailed'),
        code: 'upload_failed',
        statusCode: response.statusCode,
      );
    }
  }

  Future<Uint8List> downloadBytes(String downloadUrl) async {
    final response = await _client
        .get(Uri.parse(downloadUrl))
        .timeout(const Duration(seconds: 60));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        message: _apiCopy(_acceptLanguage, 'downloadFailed'),
        code: 'download_failed',
        statusCode: response.statusCode,
      );
    }
    return response.bodyBytes;
  }

  Future<void> uploadMultipartBytes(
    String uploadUrl,
    Uint8List bytes, {
    required String filename,
    required String contentType,
    required Map<String, String> fields,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(uploadUrl))
      ..fields.addAll(fields)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
          // Storage persists the MIME type of this part. The messaging API
          // verifies it exactly before consuming the one-time upload grant.
          contentType: MediaType.parse(contentType),
        ),
      );
    try {
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 60));
      await response.stream.drain<void>();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          message: _apiCopy(_acceptLanguage, 'uploadFailed'),
          code: 'upload_failed',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      throw ApiException(
        message: _apiCopy(_acceptLanguage, 'uploadTimeout'),
        code: 'upload_timeout',
      );
    } on http.ClientException catch (error) {
      throw ApiException(
        message: _apiCopy(_acceptLanguage, 'uploadConnection'),
        code: 'upload_connection_failed',
        fields: {'detail': error.message},
      );
    }
  }

  Future<ApiResult> postMultipartBytes(
    String path,
    Uint8List bytes, {
    required String filename,
    required String contentType,
    String fieldName = 'file',
  }) async {
    final request = http.MultipartRequest('POST', uri(path))
      ..headers['Accept'] = 'application/json'
      ..headers['Accept-Language'] = _acceptLanguage
      ..files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          bytes,
          filename: filename,
          contentType: MediaType.parse(contentType),
        ),
      );
    if (accessToken case final token? when token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    try {
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 60));
      return _resultFromResponse(await http.Response.fromStream(streamed));
    } on TimeoutException {
      throw ApiException(
        message: _apiCopy(_acceptLanguage, 'uploadTimeout'),
        code: 'upload_timeout',
      );
    } on http.ClientException catch (error) {
      throw ApiException(
        message: _apiCopy(_acceptLanguage, 'uploadConnection'),
        code: 'upload_connection_failed',
        fields: {'detail': error.message},
      );
    }
  }

  Future<ApiResult> _send(
    String method,
    String path, {
    Object? body,
    Map<String, Object?> query = const {},
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Accept-Language': _acceptLanguage,
    };
    if (body != null) headers['Content-Type'] = 'application/json';
    if (accessToken case final token? when token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    http.Response response;
    try {
      final target = uri(path, query);
      final request = switch (method) {
        'GET' => _client.get(target, headers: headers),
        'POST' => _client.post(
          target,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        ),
        'PATCH' => _client.patch(
          target,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        ),
        'PUT' => _client.put(
          target,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        ),
        'DELETE' => _client.delete(target, headers: headers),
        _ => throw ArgumentError.value(method, 'method'),
      };
      response = await request.timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw ApiException(
        message: _apiCopy(_acceptLanguage, 'timeout'),
        code: 'timeout',
      );
    } on http.ClientException catch (error) {
      throw ApiException(
        message: kIsWeb
            ? _apiCopy(_acceptLanguage, 'connectionWeb')
            : _apiCopy(_acceptLanguage, 'connection'),
        code: 'connection_failed',
        fields: {'detail': error.message},
      );
    }

    return _resultFromResponse(response);
  }

  ApiResult _resultFromResponse(http.Response response) {
    Object? decoded;
    if (response.body.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw ApiException(
          message: _apiCopy(_acceptLanguage, 'invalidResponse'),
          code: 'invalid_response',
          statusCode: response.statusCode,
        );
      }
    }

    final map = decoded is Map
        ? Map<String, Object?>.from(decoded)
        : const <String, Object?>{};
    final successful =
        response.statusCode >= 200 &&
        response.statusCode < 300 &&
        map['success'] != false;
    if (!successful) {
      final fieldValue = map['errors'];
      throw ApiException(
        message: _text(
          map['message'],
          fallback: _statusMessage(response.statusCode, _acceptLanguage),
        ),
        code: _text(map['code'], fallback: 'request_failed'),
        statusCode: response.statusCode,
        fields: fieldValue is Map
            ? Map<String, Object?>.from(fieldValue)
            : const {},
      );
    }

    // The notification cursor feed intentionally has no {success,data} envelope.
    final data = map.containsKey('success') ? map['data'] : decoded;
    final paginationValue = map['pagination'];
    return ApiResult(
      data: data,
      pagination: paginationValue is Map
          ? Map<String, Object?>.from(paginationValue)
          : const {},
    );
  }

  void close() => _client.close();
}

final class SessionRecord {
  const SessionRecord({
    required this.baseUrl,
    required this.accessToken,
    required this.role,
    required this.deviceId,
  });

  final String baseUrl;
  final String accessToken;
  final String role;
  final String deviceId;
}

final class SecureSessionStore {
  const SecureSessionStore();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static final Map<String, String> _fallback = {};

  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key) ?? _fallback[key];
    } on Object {
      return _fallback[key];
    }
  }

  Future<void> _write(String key, String? value) async {
    if (value == null) {
      _fallback.remove(key);
    } else {
      _fallback[key] = value;
    }
    try {
      if (value == null) {
        await _storage.delete(key: key);
      } else {
        await _storage.write(key: key, value: value);
      }
    } on Object {
      // Linux preview environments can lack libsecret; the authenticated session
      // remains available in memory without ever falling back to plain-text files.
    }
  }

  Future<SessionRecord?> read() async {
    final values = await Future.wait([
      _read('sf_base_url'),
      _read('sf_access_token'),
      _read('sf_role'),
      _read('sf_device_id'),
    ]);
    if (values[0] == null || values[1] == null || values[2] == null) {
      return null;
    }
    return SessionRecord(
      baseUrl: values[0]!,
      accessToken: values[1]!,
      role: values[2]!,
      deviceId: values[3] ?? '',
    );
  }

  Future<void> save(SessionRecord record) async {
    await Future.wait([
      _write('sf_base_url', record.baseUrl),
      _write('sf_access_token', record.accessToken),
      _write('sf_role', record.role),
      _write('sf_device_id', record.deviceId),
    ]);
  }

  Future<void> clear() async {
    await Future.wait([
      _write('sf_access_token', null),
      _write('sf_role', null),
      _write('sf_device_id', null),
    ]);
  }
}

String _text(Object? value, {required String fallback}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty || text == 'null' ? fallback : text;
}

int? _apiInteger(Object? value) => switch (value) {
  int number => number,
  num number => number.toInt(),
  String text => int.tryParse(text),
  _ => null,
};

String? _apiNullableText(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty || text == 'null' ? null : text;
}

String _normalizeLanguage(String value) {
  final normalized = value.trim().toLowerCase().split(RegExp('[-_]')).first;
  return const {'uz', 'ru', 'en'}.contains(normalized) ? normalized : 'uz';
}

String _statusMessage(int status, String language) => switch (status) {
  400 => _apiCopy(language, 'status400'),
  401 => _apiCopy(language, 'status401'),
  403 => _apiCopy(language, 'status403'),
  404 => _apiCopy(language, 'status404'),
  429 => _apiCopy(language, 'status429'),
  >= 500 => _apiCopy(language, 'status500'),
  _ => _apiCopy(language, 'statusDefault'),
};

String _apiCopy(String language, String key) {
  final values = _apiCopies[key];
  if (values == null) return key;
  return values[_normalizeLanguage(language)] ?? values['uz'] ?? key;
}

const Map<String, Map<String, String>> _apiCopies = {
  'invalidAddress': {
    'uz': 'Markaz manzili noto‘g‘ri.',
    'ru': 'Неверный адрес сервера центра.',
    'en': 'The center server address is invalid.',
  },
  'requiresHttps': {
    'uz': 'Markaz manzili HTTPS orqali himoyalangan bo‘lishi kerak.',
    'ru': 'Адрес сервера центра должен быть защищён с помощью HTTPS.',
    'en': 'The center server address must be protected with HTTPS.',
  },
  'uploadFailed': {
    'uz': 'Fayl serverga yuklanmadi.',
    'ru': 'Не удалось загрузить файл на сервер.',
    'en': 'The file could not be uploaded to the server.',
  },
  'downloadFailed': {
    'uz': 'Faylni serverdan olib bo‘lmadi.',
    'ru': 'Не удалось получить файл с сервера.',
    'en': 'The file could not be downloaded from the server.',
  },
  'uploadTimeout': {
    'uz': 'Faylni yuklash vaqti tugadi. Qayta urinib ko‘ring.',
    'ru': 'Время загрузки файла истекло. Попробуйте ещё раз.',
    'en': 'The file upload timed out. Please try again.',
  },
  'uploadConnection': {
    'uz': 'Fayl serveriga ulanib bo‘lmadi.',
    'ru': 'Не удалось подключиться к файловому серверу.',
    'en': 'Could not connect to the file server.',
  },
  'timeout': {
    'uz': 'Server javob bermadi. Internet va markaz manzilini tekshiring.',
    'ru': 'Сервер не отвечает. Проверьте интернет и адрес сервера центра.',
    'en':
        'The server did not respond. Check your connection and server address.',
  },
  'connectionWeb': {
    'uz': 'Serverga ulanib bo‘lmadi. Manzil va CORS sozlamasini tekshiring.',
    'ru':
        'Не удалось подключиться к серверу. Проверьте адрес и настройки CORS.',
    'en':
        'Could not connect to the server. Check the address and CORS settings.',
  },
  'connection': {
    'uz': 'Serverga ulanib bo‘lmadi. Internetni tekshiring.',
    'ru': 'Не удалось подключиться к серверу. Проверьте интернет.',
    'en': 'Could not connect to the server. Check your internet connection.',
  },
  'invalidResponse': {
    'uz': 'Server noto‘g‘ri formatda javob berdi.',
    'ru': 'Сервер вернул ответ в неверном формате.',
    'en': 'The server returned an invalid response format.',
  },
  'status400': {
    'uz': 'Kiritilgan ma’lumotlarni tekshiring.',
    'ru': 'Проверьте введённые данные.',
    'en': 'Check the entered information.',
  },
  'status401': {
    'uz': 'Sessiya tugagan. Qayta kiring.',
    'ru': 'Сессия завершена. Войдите снова.',
    'en': 'Your session has expired. Sign in again.',
  },
  'status403': {
    'uz': 'Bu amal uchun ruxsat yo‘q.',
    'ru': 'Недостаточно прав для этого действия.',
    'en': 'You do not have permission for this action.',
  },
  'status404': {
    'uz': 'Ma’lumot topilmadi.',
    'ru': 'Данные не найдены.',
    'en': 'The requested information was not found.',
  },
  'status429': {
    'uz': 'Juda ko‘p urinish. Birozdan keyin qayta urinib ko‘ring.',
    'ru': 'Слишком много попыток. Повторите немного позже.',
    'en': 'Too many attempts. Please try again later.',
  },
  'status500': {
    'uz': 'Serverda vaqtinchalik xatolik yuz berdi.',
    'ru': 'На сервере произошла временная ошибка.',
    'en': 'A temporary server error occurred.',
  },
  'statusDefault': {
    'uz': 'So‘rov bajarilmadi.',
    'ru': 'Не удалось выполнить запрос.',
    'en': 'The request could not be completed.',
  },
};
