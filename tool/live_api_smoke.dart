import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final environment = Platform.environment;
  final baseUrl = _required(
    environment,
    'STARFORGE_API_BASE_URL',
  ).replaceAll(RegExp(r'/+$'), '').replaceFirst(RegExp(r'/api/v1$'), '');
  final uri = Uri.tryParse(baseUrl);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
    throw const FormatException('STARFORGE_API_BASE_URL is invalid.');
  }

  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    await _smokeRole(
      client: client,
      baseUrl: baseUrl,
      role: 'student',
      username: _required(environment, 'STARFORGE_STUDENT_USERNAME'),
      password: _required(environment, 'STARFORGE_STUDENT_PASSWORD'),
    );
    await _smokeRole(
      client: client,
      baseUrl: baseUrl,
      role: 'parent',
      username: _required(environment, 'STARFORGE_PARENT_USERNAME'),
      password: _required(environment, 'STARFORGE_PARENT_PASSWORD'),
    );
    stdout.writeln('Live student and parent API smoke checks passed.');
  } finally {
    client.close(force: true);
  }
}

Future<void> _smokeRole({
  required HttpClient client,
  required String baseUrl,
  required String role,
  required String username,
  required String password,
}) async {
  final anonymous = _ApiProbe(client: client, baseUrl: baseUrl);
  final loginBody = <String, Object?>{
    'username': username,
    'password': password,
  };
  Object? loginData;
  try {
    loginData = await anonymous.request(
      'POST',
      '/api/v1/auth/login/',
      body: loginBody,
    );
  } on _ProbeException catch (error) {
    if (error.statusCode != 404 && error.statusCode != 405) rethrow;
    loginData = await anonymous.request(
      'POST',
      '/api/v1/auth/role-login/',
      body: loginBody,
    );
  }
  final login = _map(loginData, '$role login');
  final token = _sessionAccess(login);
  final loginRole = '${login['role'] ?? ''}'.trim().toLowerCase();
  if (token.isEmpty || (loginRole.isNotEmpty && loginRole != role)) {
    throw StateError('$role login returned an invalid role or empty session.');
  }

  final api = _ApiProbe(client: client, baseUrl: baseUrl, token: token);
  try {
    final profile = _map(
      await api.request('GET', '/api/v1/users/me/'),
      '$role profile',
    );
    if ('${profile['principal_kind'] ?? ''}'.toLowerCase() != role) {
      throw StateError('$role /users/me/ returned another principal kind.');
    }
    final permissions = _strings(profile['permission_codes']);
    final studentId = role == 'student'
        ? _integer(profile['id'])
        : await _probeParentHome(api);

    if (role == 'student') {
      await api.request('GET', '/api/v1/students/me/dashboard/');
      await api.request('GET', '/api/v1/students/me/report/');
    }

    if (_can(permissions, 'students:read')) {
      await api.request('GET', '/api/v1/students/', query: {'page_size': 1});
      if (studentId != null) {
        await api.request('GET', '/api/v1/students/$studentId/');
        await api.request('GET', '/api/v1/students/$studentId/events/');
      }
    }
    if (role == 'parent' && _can(permissions, 'parents:read')) {
      await api.request('GET', '/api/v1/parents/', query: {'page_size': 1});
      await api.request(
        'GET',
        '/api/v1/parents/guardians/',
        query: {'page_size': 1},
      );
      await api.request(
        'GET',
        '/api/v1/parents/pickups/',
        query: {'page_size': 1},
      );
    }
    await _probeSharedDomains(api, permissions, studentId);
    await api.request('GET', '/api/v1/users/devices/', query: {'page_size': 1});
    stdout.writeln('$role API surface passed.');
  } finally {
    try {
      await api.request('POST', '/api/v1/auth/logout/', body: const {});
    } on Object {
      stderr.writeln('WARNING: $role logout failed after smoke checks.');
    }
  }
}

Future<int?> _probeParentHome(_ApiProbe api) async {
  final children = _rows(
    await api.request('GET', '/api/v1/parents/me/children/'),
  );
  if (children.isEmpty) {
    throw StateError('Parent smoke account has no linked children.');
  }
  final studentId = _integer(children.first['id']);
  if (studentId == null) {
    throw StateError('Parent child payload has no numeric id.');
  }
  await api.request('GET', '/api/v1/parents/me/children/$studentId/report/');
  return studentId;
}

Future<void> _probeSharedDomains(
  _ApiProbe api,
  Set<String> permissions,
  int? studentId,
) async {
  if (_can(permissions, 'assignments:read')) {
    await api.request('GET', '/api/v1/assignments/', query: {'page_size': 1});
    await api.request(
      'GET',
      '/api/v1/assignments/submissions/',
      query: {'page_size': 1},
    );
  }
  List<Map<String, Object?>> terms = const [];
  if (_can(permissions, 'schedule:read')) {
    await api.request(
      'GET',
      '/api/v1/schedule/lessons/',
      query: {'page_size': 1},
    );
    terms = _rows(
      await api.request(
        'GET',
        '/api/v1/schedule/terms/',
        query: {'page_size': 1},
      ),
    );
    await api.request('GET', '/api/v1/schedule/ical-url/');
  }
  if (_can(permissions, 'attendance:read')) {
    await api.request(
      'GET',
      '/api/v1/attendance/records/',
      query: {'page_size': 1, 'student': ?studentId},
    );
    final termId = _integer(terms.firstOrNull?['id']);
    if (studentId != null && termId != null) {
      await api.request(
        'GET',
        '/api/v1/attendance/summary/',
        query: {'student': studentId, 'term': termId},
      );
    }
  }
  if (_can(permissions, 'academics:read')) {
    for (final path in [
      '/api/v1/academics/subjects/',
      '/api/v1/academics/exam-types/',
      '/api/v1/academics/exams/',
      '/api/v1/academics/grades/',
      '/api/v1/academics/transcripts/',
    ]) {
      await api.request('GET', path, query: {'page_size': 1});
    }
  }
  if (_can(permissions, 'content:read')) {
    for (final path in [
      '/api/v1/content/libraries/',
      '/api/v1/content/courses/',
      '/api/v1/content/modules/',
      '/api/v1/content/lessons/',
      '/api/v1/content/folders/',
      '/api/v1/content/files/',
      '/api/v1/content/materials/',
    ]) {
      await api.request('GET', path, query: {'page_size': 1});
    }
  }
  if (_can(permissions, 'messaging:read')) {
    await api.request(
      'GET',
      '/api/v1/messaging/contacts/',
      query: {'page_size': 1},
    );
    await api.request(
      'GET',
      '/api/v1/messaging/threads/',
      query: {'page_size': 1},
    );
  }
  if (_can(permissions, 'notifications:read')) {
    await api.request('GET', '/api/v1/notifications/', query: {'page_size': 1});
    await api.request('GET', '/api/v1/notifications/unread-count/');
  }
  if (_can(permissions, 'forms:read')) {
    await api.request('GET', '/api/v1/forms/', query: {'page_size': 1});
  }
  if (_can(permissions, 'achievements:read')) {
    await api.request(
      'GET',
      '/api/v1/achievements/mine/',
      query: {'page_size': 1},
    );
  }
  if (_can(permissions, 'compliance:read')) {
    await api.request('GET', '/api/v1/rulebook/rules/mine/');
    await api.request('GET', '/api/v1/rulebook/rules/pending/');
  }
  if (_can(permissions, 'penalty:read')) {
    await api.request(
      'GET',
      '/api/v1/rulebook/penalties/',
      query: {'page_size': 1, 'student': ?studentId},
    );
  }
  if (_can(permissions, 'finance:read_own') && studentId != null) {
    await api.request(
      'GET',
      '/api/v1/finance/outstanding/',
      query: {'student': studentId},
    );
  }
  if (_can(permissions, 'card:read')) {
    await api.request('GET', '/api/v1/cards/', query: {'page_size': 1});
    await api.request('GET', '/api/v1/cards/types/', query: {'page_size': 1});
    await api.request('GET', '/api/v1/cards/wallets/me/');
  }
}

final class _ApiProbe {
  const _ApiProbe({required this.client, required this.baseUrl, this.token});

  final HttpClient client;
  final String baseUrl;
  final String? token;

  Future<Object?> request(
    String method,
    String path, {
    Map<String, Object?> query = const {},
    Object? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: query.isEmpty
          ? null
          : {for (final entry in query.entries) entry.key: '${entry.value}'},
    );
    for (var attempt = 1; attempt <= 3; attempt++) {
      final request = await client.openUrl(method, uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (token case final value? when value.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $value');
      }
      if (body != null) {
        final encodedBody = utf8.encode(jsonEncode(body));
        request.headers.contentType = ContentType.json;
        request.contentLength = encodedBody.length;
        request.add(encodedBody);
      }
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      final raw = await utf8.decoder.bind(response).join();
      Object? decoded;
      if (raw.trim().isNotEmpty) decoded = jsonDecode(raw);
      final envelope = decoded is Map
          ? Map<String, Object?>.from(decoded)
          : const <String, Object?>{};
      if (response.statusCode == 429 && attempt < 3) {
        final retryAfter = int.tryParse(
          response.headers.value(HttpHeaders.retryAfterHeader) ?? '',
        );
        await Future<void>.delayed(
          Duration(seconds: (retryAfter ?? 2).clamp(1, 60)),
        );
        continue;
      }
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          envelope['success'] == false) {
        final message = '${envelope['message'] ?? 'request failed'}';
        throw _ProbeException(
          statusCode: response.statusCode,
          message: '$method $path: ${response.statusCode} $message',
        );
      }
      return envelope.containsKey('success') ? envelope['data'] : decoded;
    }
    throw StateError('Unreachable retry state for $method $path.');
  }
}

final class _ProbeException implements Exception {
  const _ProbeException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

String _required(Map<String, String> environment, String key) {
  final value = environment[key]?.trim() ?? '';
  if (value.isEmpty) {
    throw StateError('Missing required environment variable $key.');
  }
  return value;
}

Map<String, Object?> _map(Object? value, String label) {
  if (value is! Map) throw FormatException('$label must be an object.');
  return Map<String, Object?>.from(value);
}

List<Map<String, Object?>> _rows(Object? value) {
  Object? rows = value;
  if (rows is Map) rows = rows['results'] ?? rows['items'];
  if (rows is! List) return const [];
  return [
    for (final row in rows)
      if (row is Map) Map<String, Object?>.from(row),
  ];
}

Set<String> _strings(Object? value) =>
    value is List ? value.map((item) => '$item').toSet() : const <String>{};

bool _can(Set<String> permissions, String permission) {
  final separator = permission.indexOf(':');
  final wildcard = separator < 0
      ? '$permission:*'
      : '${permission.substring(0, separator)}:*';
  return permissions.contains('*:*') ||
      permissions.contains(permission) ||
      permissions.contains(wildcard);
}

int? _integer(Object? value) => switch (value) {
  int number => number,
  num number => number.toInt(),
  String text => int.tryParse(text),
  _ => null,
};

String _sessionAccess(Object? value) {
  if (value is! Map) return '';
  for (final key in const [
    'access',
    'access_token',
    'token',
    'session_key',
    'key',
  ]) {
    final text = value[key]?.toString().trim() ?? '';
    if (text.isNotEmpty && text != 'null') return text;
  }
  for (final key in const ['session', 'data', 'credentials']) {
    final nested = _sessionAccess(value[key]);
    if (nested.isNotEmpty) return nested;
  }
  return '';
}
