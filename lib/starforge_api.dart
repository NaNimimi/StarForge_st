import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

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
  const ApiResult({required this.data, this.pagination = const {}});

  final Object? data;
  final Map<String, Object?> pagination;

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

String normalizeApiBaseUrl(String raw) {
  var value = raw.trim();
  if (value.isEmpty) value = defaultApiBaseUrl;
  if (RegExp(r'\s').hasMatch(value)) {
    throw const FormatException('Markaz manzili noto‘g‘ri.');
  }
  if (!value.contains('://')) value = 'https://$value';
  value = value.replaceAll(RegExp(r'/+$'), '');
  value = value.replaceFirst(RegExp(r'/api/v1$'), '');
  final uri = Uri.tryParse(value);
  if (uri == null ||
      !uri.hasScheme ||
      !const {'http', 'https'}.contains(uri.scheme) ||
      uri.host.isEmpty) {
    throw const FormatException('Markaz manzili noto‘g‘ri.');
  }
  final localHost =
      uri.host == 'localhost' ||
      uri.host == '127.0.0.1' ||
      uri.host == '::1' ||
      uri.host.endsWith('.localhost');
  if (uri.scheme == 'http' && !localHost) {
    throw const FormatException(
      'Markaz manzili HTTPS orqali himoyalangan bo‘lishi kerak.',
    );
  }
  return uri.toString().replaceAll(RegExp(r'/+$'), '');
}

final class StarForgeApi {
  StarForgeApi({required String baseUrl, this.accessToken, http.Client? client})
    : _baseUrl = normalizeApiBaseUrl(baseUrl),
      _client = client ?? http.Client();

  final http.Client _client;
  String _baseUrl;
  String? accessToken;

  String get baseUrl => _baseUrl;

  set baseUrl(String value) => _baseUrl = normalizeApiBaseUrl(value);

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
        message: 'Fayl serverga yuklanmadi.',
        code: 'upload_failed',
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> uploadMultipartBytes(
    String uploadUrl,
    Uint8List bytes, {
    required String filename,
    required Map<String, String> fields,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(uploadUrl))
      ..fields.addAll(fields)
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );
    try {
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 60));
      await response.stream.drain<void>();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          message: 'Fayl serverga yuklanmadi.',
          code: 'upload_failed',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      throw const ApiException(
        message: 'Faylni yuklash vaqti tugadi. Qayta urinib ko‘ring.',
        code: 'upload_timeout',
      );
    } on http.ClientException catch (error) {
      throw ApiException(
        message: 'Fayl serveriga ulanib bo‘lmadi.',
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
    final headers = <String, String>{'Accept': 'application/json'};
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
      throw const ApiException(
        message:
            'Server javob bermadi. Internet va markaz manzilini tekshiring.',
        code: 'timeout',
      );
    } on http.ClientException catch (error) {
      throw ApiException(
        message: kIsWeb
            ? 'Serverga ulanib bo‘lmadi. Manzil va CORS sozlamasini tekshiring.'
            : 'Serverga ulanib bo‘lmadi. Internetni tekshiring.',
        code: 'connection_failed',
        fields: {'detail': error.message},
      );
    }

    Object? decoded;
    if (response.body.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw ApiException(
          message: 'Server noto‘g‘ri formatda javob berdi.',
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
          fallback: _statusMessage(response.statusCode),
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

String _statusMessage(int status) => switch (status) {
  400 => 'Kiritilgan ma’lumotlarni tekshiring.',
  401 => 'Sessiya tugagan. Qayta kiring.',
  403 => 'Bu amal uchun ruxsat yo‘q.',
  404 => 'Ma’lumot topilmadi.',
  429 => 'Juda ko‘p urinish. Birozdan keyin qayta urinib ko‘ring.',
  >= 500 => 'Serverda vaqtinchalik xatolik yuz berdi.',
  _ => 'So‘rov bajarilmadi.',
};
