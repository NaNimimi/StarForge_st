import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:starforge_student/portal_state.dart';
import 'package:starforge_student/starforge_api.dart';

void main() {
  test('normalizes a center URL without duplicating the API prefix', () {
    expect(
      normalizeApiBaseUrl('https://demo.example.uz/api/v1/'),
      'https://demo.example.uz',
    );
    expect(
      () => normalizeApiBaseUrl('not a url'),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => normalizeApiBaseUrl('http://center.example.uz'),
      throwsA(isA<FormatException>()),
    );
    expect(
      normalizeApiBaseUrl('http://demo.localhost:8000'),
      'http://demo.localhost:8000',
    );
  });

  test('API client accepts envelope and cursor contracts', () async {
    final api = StarForgeApi(
      baseUrl: 'https://demo.example.uz',
      accessToken: 'opaque',
      client: MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer opaque');
        if (request.url.path.endsWith('/notifications/')) {
          return http.Response(
            jsonEncode({
              'results': [
                {'id': 1, 'title': 'Hello'},
              ],
              'next': null,
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {'id': 2},
            ],
            'pagination': {'total': 1},
          }),
          200,
        );
      }),
    );

    expect((await api.get('/api/v1/items/')).rows.single['id'], 2);
    expect((await api.get('/api/v1/notifications/')).rows.single['id'], 1);
  });

  test('student role login hydrates profile and server dashboard', () async {
    final api = StarForgeApi(
      baseUrl: 'https://demo.example.uz',
      client: MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/auth/role-login/')) {
          return _ok({
            'access': 'session-key',
            'role': 'student',
            'must_change_password': false,
          });
        }
        if (path.endsWith('/users/me/')) {
          expect(request.headers['authorization'], 'Bearer session-key');
          return _ok({
            'id': 7,
            'principal_kind': 'student',
            'username': 'demo.student',
            'full_name': 'Demo Student',
            'permission_codes': [
              'students:read',
              'assignments:read',
              'schedule:read',
            ],
          });
        }
        if (path.endsWith('/students/me/dashboard/')) {
          return _ok({'group': 'A1', 'open_homework_count': 2});
        }
        if (path.endsWith('/students/me/report/')) {
          return _ok({
            'attendance': {'rate': 0.9},
            'payment': {'outstanding_uzs': '0.00'},
          });
        }
        return http.Response('not found', 404);
      }),
    );
    final portal = PortalController(api: api, restoreSession: false);
    addTearDown(portal.dispose);

    final loggedIn = await portal.login(
      baseUrl: 'https://demo.example.uz',
      username: 'demo.student',
      password: 'secret',
    );

    expect(loggedIn, isTrue);
    expect(portal.phase, AuthPhase.signedIn);
    expect(portal.role, 'student');
    expect(portal.selectedStudentId, 7);
    expect(portal.dashboard['group'], 'A1');
    expect(portal.can('assignments:read'), isTrue);
  });

  test(
    'parent identity loads family links, pickup and selected child',
    () async {
      final api = StarForgeApi(
        baseUrl: 'https://demo.example.uz',
        client: MockClient((request) async {
          final path = request.url.path;
          if (path.endsWith('/auth/role-login/')) {
            return _ok({
              'access': 'parent-session',
              'role': 'parent',
              'must_change_password': false,
            });
          }
          if (path.endsWith('/users/me/')) {
            return _ok({
              'id': 3,
              'principal_kind': 'parent',
              'full_name': 'Demo Parent',
              'permission_codes': [
                'parents:read',
                'students:read',
                'finance:read_own',
                'notifications:read',
              ],
            });
          }
          if (path.endsWith('/parents/me/children/')) {
            return _ok([
              {'id': 37, 'full_name': 'Demo Child'},
            ]);
          }
          if (path.endsWith('/parents/me/children/37/report/')) {
            return _ok({
              'attendance': {'rate': 0.92},
            });
          }
          if (path.endsWith('/finance/outstanding/')) {
            return _ok({'student': 37, 'outstanding_uzs': '100.00'});
          }
          if (path.endsWith('/parents/')) {
            return _ok([
              {'id': 3, 'full_name': 'Demo Parent', 'workplace': 'Office'},
            ]);
          }
          if (path.endsWith('/parents/guardians/')) {
            return _ok([
              {
                'id': 1,
                'parent': 3,
                'student': 37,
                'relationship': 'father',
                'is_primary': true,
              },
            ]);
          }
          if (path.endsWith('/parents/pickups/')) {
            return _ok([
              {'id': 2, 'student': 37, 'full_name': 'Trusted Person'},
            ]);
          }
          if (path.endsWith('/students/37/')) {
            return _ok({
              'id': 37,
              'full_name': 'Demo Child',
              'student_id': 'S-37',
            });
          }
          if (path.endsWith('/students/37/events/')) {
            return _ok([
              {'id': 4, 'to_status': 'active'},
            ]);
          }
          return http.Response('not found', 404);
        }),
      );
      final portal = PortalController(api: api, restoreSession: false);
      addTearDown(portal.dispose);

      expect(
        await portal.login(
          baseUrl: 'https://demo.example.uz',
          username: 'demo.parent',
          password: 'secret',
        ),
        isTrue,
      );
      await portal.loadSection(PortalSection.identity);

      expect(portal.selectedStudentId, 37);
      expect(portal.parentProfile['workplace'], 'Office');
      expect(portal.studentProfile['student_id'], 'S-37');
      expect(portal.guardians.single['relationship'], 'father');
      expect(portal.pickups.single['full_name'], 'Trusted Person');
      expect(portal.studentEvents, hasLength(1));
    },
  );

  test(
    'messaging sends backend attachment keys and refreshes the thread',
    () async {
      Map<String, dynamic>? sentBody;
      final api = StarForgeApi(
        baseUrl: 'https://demo.example.uz',
        client: MockClient((request) async {
          final path = request.url.path;
          if (path.endsWith('/auth/role-login/')) {
            return _ok({
              'access': 'student-session',
              'role': 'student',
              'must_change_password': false,
            });
          }
          if (path.endsWith('/users/me/')) {
            return _ok({
              'id': 7,
              'principal_kind': 'student',
              'full_name': 'Demo Student',
              'permission_codes': ['messaging:read', 'messaging:write'],
            });
          }
          if (path.endsWith('/students/me/dashboard/')) return _ok({});
          if (path.endsWith('/students/me/report/')) return _ok({});
          if (path.endsWith('/threads/11/messages/')) {
            if (request.method == 'POST') {
              sentBody = jsonDecode(request.body) as Map<String, dynamic>;
              return _ok({'id': 99});
            }
            return _ok([
              {'id': 99, 'thread': 11, 'body': 'File'},
            ]);
          }
          if (path.endsWith('/threads/11/read/')) {
            return _ok({'status': 'ok'});
          }
          return http.Response('not found', 404);
        }),
      );
      final portal = PortalController(api: api, restoreSession: false);
      addTearDown(portal.dispose);
      await portal.login(
        baseUrl: 'https://demo.example.uz',
        username: 'demo.student',
        password: 'secret',
      );

      await portal.sendMessage(
        11,
        'File',
        attachments: const ['tenant/messages/report.pdf'],
      );

      expect(sentBody?['body'], 'File');
      expect(sentBody?['attachments'], ['tenant/messages/report.pdf']);
      expect(portal.messages[11], hasLength(1));
    },
  );

  test('child switch commits report and identity atomically', () async {
    final api = StarForgeApi(
      baseUrl: 'https://demo.example.uz',
      client: MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/auth/role-login/')) {
          return _ok({
            'access': 'parent-session',
            'role': 'parent',
            'must_change_password': false,
          });
        }
        if (path.endsWith('/users/me/')) {
          return _ok({
            'id': 3,
            'principal_kind': 'parent',
            'full_name': 'Demo Parent',
            'permission_codes': ['parents:read', 'finance:read_own'],
          });
        }
        if (path.endsWith('/parents/me/children/')) {
          return _ok([
            {'id': 37, 'full_name': 'First Child'},
            {'id': 38, 'full_name': 'Second Child'},
          ]);
        }
        if (path.endsWith('/parents/me/children/37/report/')) {
          return _ok({
            'student': 37,
            'attendance': {'rate': 0.9},
          });
        }
        if (path.endsWith('/parents/me/children/38/report/')) {
          await Future<void>.delayed(const Duration(milliseconds: 40));
          return _ok({
            'student': 38,
            'attendance': {'rate': 0.7},
          });
        }
        if (path.endsWith('/finance/outstanding/')) {
          final student = request.url.queryParameters['student'];
          if (student == '38') {
            await Future<void>.delayed(const Duration(milliseconds: 40));
          }
          return _ok({
            'student': int.parse(student!),
            'outstanding_uzs': student == '38' ? '250.00' : '0.00',
          });
        }
        return http.Response('not found', 404);
      }),
    );
    final portal = PortalController(api: api, restoreSession: false);
    addTearDown(portal.dispose);
    await portal.login(
      baseUrl: 'https://demo.example.uz',
      username: 'demo.parent',
      password: 'secret',
    );

    final switching = portal.selectChild(38);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(portal.selectedStudentId, 37);
    expect(portal.report['student'], 37);
    expect(portal.selectingStudentId, 38);

    await switching;
    expect(portal.selectedStudentId, 38);
    expect(portal.report['student'], 38);
    expect(portal.outstanding['student'], 38);
    expect(portal.selectingStudentId, isNull);
  });

  test('message transcript survives a failed read marker', () async {
    final api = StarForgeApi(
      baseUrl: 'https://demo.example.uz',
      accessToken: 'session',
      client: MockClient((request) async {
        if (request.url.path.endsWith('/threads/11/messages/')) {
          return _ok([
            {'id': 1, 'thread': 11, 'body': 'Visible message'},
          ]);
        }
        if (request.url.path.endsWith('/threads/11/read/')) {
          return http.Response('failed', 500);
        }
        return http.Response('not found', 404);
      }),
    );
    final portal = PortalController(api: api, restoreSession: false);
    addTearDown(portal.dispose);

    await portal.loadMessages(11);

    expect(portal.messages[11]?.single['body'], 'Visible message');
    expect(portal.loadingMessageThreads, isNot(contains(11)));
    expect(portal.messageErrors[11], isNull);
  });

  test('messaging attachment upload uses presigned multipart fields', () async {
    String? method;
    String? contentType;
    String? multipartBody;
    final api = StarForgeApi(
      baseUrl: 'https://demo.example.uz',
      client: MockClient((request) async {
        method = request.method;
        contentType = request.headers['content-type'];
        multipartBody = request.body;
        return http.Response('', 204);
      }),
    );

    await api.uploadMultipartBytes(
      'https://storage.example.uz/upload',
      Uint8List.fromList(const [1, 2, 3, 4]),
      filename: 'voice.wav',
      fields: const {
        'key': 'demo/messaging/voice.wav',
        'Content-Type': 'audio/wav',
        'policy': 'signed-policy',
      },
    );

    expect(method, 'POST');
    expect(contentType, startsWith('multipart/form-data; boundary='));
    expect(multipartBody, contains('demo/messaging/voice.wav'));
    expect(multipartBody, contains('signed-policy'));
    expect(multipartBody, contains('filename="voice.wav"'));
  });

  test('backend errors keep stable message and code', () async {
    final api = StarForgeApi(
      baseUrl: 'https://demo.example.uz',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'success': false,
            'code': 'invalid_credentials',
            'message': 'Invalid username or password.',
          }),
          401,
        ),
      ),
    );

    await expectLater(
      api.post('/api/v1/auth/role-login/', body: const {}),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'invalid_credentials')
            .having((error) => error.isUnauthorized, 'unauthorized', isTrue),
      ),
    );
  });
}

http.Response _ok(Object? data) => http.Response(
  jsonEncode({'success': true, 'data': data}),
  200,
  headers: {'content-type': 'application/json'},
);
