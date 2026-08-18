import 'dart:convert';

import 'package:flutter/foundation.dart';
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

    final numbered = await api.get('/api/v1/items/');
    final cursor = await api.get('/api/v1/notifications/');
    expect(numbered.rows.single['id'], 2);
    expect(numbered.pageInfo.total, 1);
    expect(cursor.rows.single['id'], 1);
    expect(cursor.pageInfo.hasNext, isFalse);
  });

  test('effective permissions win over fallback and honor revocations', () {
    final portal = PortalController(restoreSession: false);
    addTearDown(portal.dispose);
    portal.profile = {
      'effective_permissions': {
        'granted': ['*:*'],
        'revoked': ['ai:read', 'finance:*'],
      },
      'permission_codes': ['ai:read'],
    };

    expect(portal.can('students:read'), isTrue);
    expect(portal.can('ai:read'), isFalse);
    expect(portal.can('finance:read_own'), isFalse);

    portal.profile = {
      'permission_codes': ['assignments:*'],
      'revoked_permission_codes': ['assignments:write'],
    };
    expect(portal.can('assignments:read'), isTrue);
    expect(portal.can('assignments:write'), isFalse);
  });

  test('live flat effective-permission lists are grants, not revocations', () {
    final portal = PortalController(restoreSession: false);
    addTearDown(portal.dispose);
    portal.profile = const {
      'effective_permissions': [
        'assignments:read',
        'messaging:read',
        'schedule:read',
      ],
    };

    expect(portal.permissions, contains('messaging:read'));
    expect(portal.revokedPermissions, isEmpty);
    expect(portal.can('assignments:read'), isTrue);
    expect(portal.can('messaging:read'), isTrue);
    expect(portal.can('schedule:read'), isTrue);
  });

  test(
    'optional endpoint failures remain observable without hiding the page',
    () async {
      final api = StarForgeApi(
        baseUrl: 'https://demo.example.uz',
        client: MockClient((request) async {
          final path = request.url.path;
          if (path.endsWith('/auth/login/')) {
            return _ok({'access': 'session', 'role': 'student'});
          }
          if (path.endsWith('/users/me/')) {
            return _ok({
              'id': 7,
              'principal_kind': 'student',
              'permission_codes': _studentPermissions,
            });
          }
          if (path.endsWith('/students/me/dashboard/') ||
              path.endsWith('/students/me/report/')) {
            return _ok({});
          }
          if (path.endsWith('/schedule/lessons/')) {
            return _ok([
              {'id': 1, 'subject_name': 'Math'},
            ]);
          }
          if (path.endsWith('/schedule/terms/')) {
            return http.Response(
              jsonEncode({
                'success': false,
                'code': 'temporary_failure',
                'message': 'Terms unavailable.',
              }),
              503,
            );
          }
          if (path.endsWith('/schedule/ical-url/')) return _ok({'url': ''});
          if (path.contains('/schedule/')) return _ok([]);
          return http.Response('not found', 404);
        }),
      );
      final portal = PortalController(api: api, restoreSession: false);
      addTearDown(portal.dispose);
      await portal.login(
        baseUrl: 'https://demo.example.uz',
        username: 'student',
        password: 'secret',
      );

      await portal.loadSection(PortalSection.schedule);

      expect(portal.lessons.single['subject_name'], 'Math');
      expect(portal.isLoaded(PortalSection.schedule), isTrue);
      expect(portal.sectionError(PortalSection.schedule), isNull);
      expect(
        portal.optionalApiFailure('/api/v1/schedule/terms/'),
        isA<ApiException>()
            .having((error) => error.statusCode, 'status', 503)
            .having((error) => error.code, 'code', 'temporary_failure'),
      );
    },
  );

  test(
    'detail loaders cache reads and the public bridge stays read-only',
    () async {
      var detailRequests = 0;
      final api = StarForgeApi(
        baseUrl: 'https://demo.example.uz',
        accessToken: 'session',
        client: MockClient((request) async {
          if (request.url.path.endsWith('/achievements/9/')) {
            detailRequests++;
            return _ok({'id': 9, 'name': 'Science star'});
          }
          if (request.url.path.endsWith('/achievements/')) {
            return _ok([
              {'id': 9, 'name': 'Science star'},
            ]);
          }
          return http.Response('not found', 404);
        }),
      );
      final portal = PortalController(api: api, restoreSession: false);
      addTearDown(portal.dispose);

      expect((await portal.loadAchievementDetail(9))['name'], 'Science star');
      expect((await portal.loadAchievementDetail(9))['name'], 'Science star');
      expect(detailRequests, 1);
      expect(
        (await portal.getApi('/api/v1/achievements/')).rows.single['id'],
        9,
      );
      expect(
        () => portal.getApi('https://untrusted.example/api/v1/achievements/'),
        throwsArgumentError,
      );
    },
  );

  test('numbered family lists drain every server-declared page', () async {
    final assignmentPages = <int>[];
    final api = StarForgeApi(
      baseUrl: 'https://demo.example.uz',
      accessToken: 'session',
      client: MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/assignments/')) {
          final page =
              int.tryParse(request.url.queryParameters['page'] ?? '') ?? 1;
          assignmentPages.add(page);
          final start = page == 1 ? 1 : 101;
          final end = page == 1 ? 100 : 101;
          return _okPaged(
            [
              for (var id = start; id <= end; id++)
                {'id': id, 'title': 'Assignment $id'},
            ],
            total: 101,
            page: page,
            pages: 2,
          );
        }
        if (path.endsWith('/assignments/submissions/')) {
          return _okPaged(const [], total: 0, page: 1, pages: 1);
        }
        return http.Response('not found', 404);
      }),
    );
    final portal = PortalController(api: api, restoreSession: false)
      ..phase = AuthPhase.signedIn
      ..role = 'student'
      ..profile = const {
        'principal_kind': 'student',
        'permission_codes': ['assignments:read'],
      };
    addTearDown(portal.dispose);

    await portal.loadSection(PortalSection.assignments);

    expect(portal.assignments, hasLength(101));
    expect(portal.assignments.last['id'], 101);
    expect(assignmentPages, [1, 2]);
  });

  test(
    'placement attempts are loaded as a self-scoped family surface',
    () async {
      final requestedPaths = <String>[];
      var detailRequests = 0;
      final api = StarForgeApi(
        baseUrl: 'https://demo.example.uz',
        accessToken: 'session',
        client: MockClient((request) async {
          requestedPaths.add(request.url.path);
          if (request.url.path.endsWith('/placement/attempts/17/')) {
            detailRequests++;
            return _ok({
              'id': 17,
              'test_title': 'English placement',
              'status': 'graded',
              'score': 8,
              'max_score': 10,
              'questions': const [],
              'answers': const [],
            });
          }
          if (request.url.path.endsWith('/placement/attempts/')) {
            return _ok([
              {
                'id': 17,
                'student': 7,
                'test_title': 'English placement',
                'status': 'graded',
                'score': 8,
                'max_score': 10,
              },
            ]);
          }
          return http.Response('not found', 404);
        }),
      );
      final portal = PortalController(api: api, restoreSession: false)
        ..phase = AuthPhase.signedIn
        ..role = 'student'
        ..selectedStudentId = 7
        ..profile = const {
          'id': 7,
          'principal_kind': 'student',
          'permission_codes': <String>[],
        };
      addTearDown(portal.dispose);

      await portal.loadSection(PortalSection.placement);
      final detail = await portal.loadPlacementAttemptDetail(17);
      await portal.loadPlacementAttemptDetail(17);

      expect(portal.placementAttempts.single['id'], 17);
      expect(detail['score'], 8);
      expect(detailRequests, 1, reason: 'placement detail is cached');
      expect(
        requestedPaths,
        isNot(contains('/api/v1/placement/tests/')),
        reason: 'family clients must not probe staff test definitions',
      );
    },
  );

  test('student submits placement answers and refreshes the attempt', () async {
    Map<String, Object?>? submittedBody;
    var listRequests = 0;
    final api = StarForgeApi(
      baseUrl: 'https://demo.example.uz',
      accessToken: 'session',
      client: MockClient((request) async {
        final path = request.url.path;
        if (request.method == 'POST' &&
            path.endsWith('/placement/attempts/17/submit/')) {
          submittedBody = Map<String, Object?>.from(
            jsonDecode(request.body) as Map,
          );
          return _ok({
            'id': 17,
            'student': 7,
            'test_title': 'English placement',
            'status': 'graded',
            'score': 3,
            'max_score': 4,
            'level': 'advanced',
          });
        }
        if (request.method == 'GET' && path.endsWith('/placement/attempts/')) {
          listRequests++;
          return _ok([
            {
              'id': 17,
              'student': 7,
              'test_title': 'English placement',
              'status': 'graded',
              'score': 3,
              'max_score': 4,
              'level': 'advanced',
            },
          ]);
        }
        return http.Response('not found', 404);
      }),
    );
    final portal = PortalController(api: api, restoreSession: false)
      ..phase = AuthPhase.signedIn
      ..role = 'student'
      ..selectedStudentId = 7
      ..profile = const {
        'id': 7,
        'principal_kind': 'student',
        'permission_codes': <String>[],
      }
      ..placementAttempts = const [
        {
          'id': 17,
          'student': 7,
          'test_title': 'English placement',
          'status': 'assigned',
        },
      ];
    addTearDown(portal.dispose);

    final result = await portal.submitPlacementAttempt(17, const [
      {'question': 2, 'response': 'Hello'},
      {'question': 3, 'response': true},
      {
        'question': 4,
        'response': ['A', 'C'],
      },
    ]);

    expect(submittedBody, {
      'answers': [
        {'question': 2, 'response': 'Hello'},
        {'question': 3, 'response': true},
        {
          'question': 4,
          'response': ['A', 'C'],
        },
      ],
    });
    expect(listRequests, 1, reason: 'successful submit refreshes placement');
    expect(result['status'], 'graded');
    expect(portal.placementAttempts.single['score'], 3);
    expect(portal.placementAttemptDetails[17]?['level'], 'advanced');
  });

  test('parent placement loading is guarded without an API probe', () async {
    var requests = 0;
    final portal =
        PortalController(
            api: StarForgeApi(
              baseUrl: 'https://demo.example.uz',
              accessToken: 'session',
              client: MockClient((_) async {
                requests++;
                return http.Response('unexpected request', 500);
              }),
            ),
            restoreSession: false,
          )
          ..phase = AuthPhase.signedIn
          ..role = 'parent'
          ..profile = const {
            'id': 3,
            'principal_kind': 'parent',
            'permission_codes': <String>[],
          };
    addTearDown(portal.dispose);

    await portal.loadSection(PortalSection.placement);
    await expectLater(
      portal.submitPlacementAttempt(17, const []),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'status', 403)
            .having((error) => error.code, 'code', 'forbidden'),
      ),
    );

    expect(portal.placementAttempts, isEmpty);
    expect(portal.isLoaded(PortalSection.placement), isTrue);
    expect(requests, 0);
  });

  test('placement suggestions require the explicit staff capability', () async {
    var requests = 0;
    final portal =
        PortalController(
            api: StarForgeApi(
              baseUrl: 'https://demo.example.uz',
              accessToken: 'session',
              client: MockClient((_) async {
                requests++;
                return _ok(const []);
              }),
            ),
            restoreSession: false,
          )
          ..phase = AuthPhase.signedIn
          ..role = 'student'
          ..profile = const {'permission_codes': <String>[]};
    addTearDown(portal.dispose);

    await expectLater(
      portal.loadPlacementSuggestions(17),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'status', 403)
            .having((error) => error.code, 'code', 'forbidden'),
      ),
    );
    expect(requests, 0, reason: 'forbidden capability never reaches the API');
  });

  test(
    'logout revokes every push device before global server logout',
    () async {
      final requested = <String>[];
      final portal =
          PortalController(
              api: StarForgeApi(
                baseUrl: 'https://demo.example.uz',
                accessToken: 'session',
                client: MockClient((request) async {
                  requested.add('${request.method} ${request.url.path}');
                  if (request.method == 'DELETE' &&
                      (request.url.path.endsWith('/users/devices/12/') ||
                          request.url.path.endsWith('/users/devices/13/'))) {
                    return http.Response('', 204);
                  }
                  if (request.method == 'POST' &&
                      request.url.path.endsWith('/auth/logout/')) {
                    return http.Response('', 204);
                  }
                  return http.Response('not found', 404);
                }),
              ),
              restoreSession: false,
            )
            ..phase = AuthPhase.signedIn
            ..role = 'student'
            ..deviceId = 'this-phone'
            ..devices = const [
              {'id': 12, 'device_id': 'this-phone'},
              {'id': 13, 'device_id': 'another-phone'},
            ];
      addTearDown(portal.dispose);

      await portal.logout();

      expect(requested, contains('DELETE /api/v1/users/devices/12/'));
      expect(requested, contains('DELETE /api/v1/users/devices/13/'));
      expect(requested, contains('POST /api/v1/auth/logout/'));
      expect(
        requested.indexOf('DELETE /api/v1/users/devices/13/'),
        lessThan(requested.indexOf('POST /api/v1/auth/logout/')),
      );
      expect(portal.phase, AuthPhase.signedOut);
    },
  );

  test('missing family AI route exposes a clear disconnected state', () async {
    final api = StarForgeApi(
      baseUrl: 'https://demo.example.uz',
      accessToken: 'session',
      client: MockClient((request) async {
        if (request.url.path.endsWith('/ai/family-assistant/')) {
          return http.Response(
            jsonEncode({
              'success': false,
              'code': 'not_found',
              'message': 'Not found.',
            }),
            404,
          );
        }
        return http.Response('not found', 404);
      }),
    );
    final portal = PortalController(api: api, restoreSession: false)
      ..phase = AuthPhase.signedIn
      ..role = 'student'
      ..profile = const {
        'principal_kind': 'student',
        'permission_codes': ['ai:read'],
      };
    addTearDown(portal.dispose);

    await portal.loadSection(PortalSection.ai);

    expect(portal.aiServiceAvailable, isFalse);
    expect(portal.aiFallbackMode, isFalse);
    expect(portal.aiConversation, isEmpty);
    expect(portal.aiReplyError, contains('ulanmagan'));
    expect(portal.optionalApiFailure('/api/v1/ai/family-assistant/'), isNull);
  });

  for (final role in const ['student', 'parent']) {
    test('profile patch refreshes the visible $role identity model', () async {
      final api = StarForgeApi(
        baseUrl: 'https://demo.example.uz',
        accessToken: 'session',
        client: MockClient((request) async {
          expect(request.method, 'PATCH');
          expect(request.url.path, '/api/v1/users/me/');
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'principal_kind': role,
                'first_name': 'Yangi',
                'phone': '+998900000000',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final portal = PortalController(api: api, restoreSession: false)
        ..phase = AuthPhase.signedIn
        ..role = role
        ..profile = {'principal_kind': role, 'first_name': 'Eski'};
      if (role == 'student') {
        portal.studentProfile = const {
          'id': 7,
          'first_name': 'Eski',
          'academic_level': 'advanced',
        };
      } else {
        portal.parentProfile = const {
          'id': 3,
          'first_name': 'Eski',
          'workplace': 'StarForge',
        };
      }
      addTearDown(portal.dispose);

      await portal.updateProfile(const {'first_name': 'Yangi'});

      final visible = role == 'student'
          ? portal.studentProfile
          : portal.parentProfile;
      expect(visible['first_name'], 'Yangi');
      expect(
        visible[role == 'student' ? 'academic_level' : 'workplace'],
        isNotNull,
      );
    });
  }

  test(
    'temporarily unavailable family AI does not invent local answers',
    () async {
      final api = StarForgeApi(
        baseUrl: 'https://demo.example.uz',
        accessToken: 'session',
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'success': false,
              'code': 'service_unavailable',
              'message': 'AI is warming up.',
            }),
            503,
          ),
        ),
      );
      final portal = PortalController(api: api, restoreSession: false)
        ..phase = AuthPhase.signedIn
        ..role = 'student'
        ..profile = const {
          'principal_kind': 'student',
          'permission_codes': ['ai:read'],
        };
      addTearDown(portal.dispose);

      await portal.loadSection(PortalSection.ai);
      expect(portal.aiServiceAvailable, isFalse);
      expect(portal.aiFallbackMode, isFalse);
      expect(portal.aiConversation, isEmpty);
      expect(portal.aiReplyError, contains('ulanmagan'));
      expect(portal.optionalApiFailure('/api/v1/ai/family-assistant/'), isNull);

      await portal.askFamilyAssistant('Bugun nimadan boshlay?');
      expect(portal.aiReplyError, contains('ulanmagan'));
      expect(portal.aiConversation, isEmpty);
    },
  );

  test(
    'login uses canonical auth endpoint before compatibility fallback',
    () async {
      final requestedPaths = <String>[];
      final api = StarForgeApi(
        baseUrl: 'https://demo.example.uz',
        client: MockClient((request) async {
          requestedPaths.add(request.url.path);
          final path = request.url.path;
          if (path.endsWith('/auth/login/')) {
            return _ok({'access_token': 'canonical-session'});
          }
          if (path.endsWith('/users/me/')) {
            expect(
              request.headers['authorization'],
              'Bearer canonical-session',
            );
            return _ok({
              'id': 7,
              'principal_kind': 'student',
              'permission_codes': _studentPermissions,
            });
          }
          if (path.endsWith('/students/me/dashboard/')) return _ok({});
          if (path.endsWith('/students/me/report/')) return _ok({});
          if (path.endsWith('/notifications/unread-count/')) {
            return _ok({'count': 0});
          }
          return http.Response('not found', 404);
        }),
      );
      final portal = PortalController(api: api, restoreSession: false);
      addTearDown(portal.dispose);

      expect(
        await portal.login(
          baseUrl: 'https://demo.example.uz',
          username: 'student',
          password: 'secret',
        ),
        isTrue,
      );
      expect(requestedPaths.first, '/api/v1/auth/login/');
      expect(requestedPaths, isNot(contains('/api/v1/auth/role-login/')));
    },
  );

  test('invalid canonical login never falls back to role-login', () async {
    final requestedPaths = <String>[];
    final api = StarForgeApi(
      baseUrl: 'https://demo.example.uz',
      client: MockClient((request) async {
        requestedPaths.add(request.url.path);
        return http.Response(
          jsonEncode({
            'success': false,
            'code': 'invalid_credentials',
            'message': 'Invalid username or password.',
          }),
          401,
        );
      }),
    );
    final portal = PortalController(api: api, restoreSession: false);
    addTearDown(portal.dispose);

    expect(
      await portal.login(
        baseUrl: 'https://demo.example.uz',
        username: 'student',
        password: 'wrong',
      ),
      isFalse,
    );
    expect(requestedPaths, ['/api/v1/auth/login/']);
    expect(portal.authenticationError, 'Invalid username or password.');
  });

  test('native login binds the backend session to the push device', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    Map<String, dynamic>? loginBody;
    final api = StarForgeApi(
      baseUrl: 'https://demo.example.uz',
      client: MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/auth/login/')) {
          loginBody = jsonDecode(request.body) as Map<String, dynamic>;
          return _ok({'access': 'native-session', 'role': 'student'});
        }
        if (path.endsWith('/users/me/')) {
          return _ok({
            'id': 7,
            'principal_kind': 'student',
            'permission_codes': _studentPermissions,
          });
        }
        if (path.endsWith('/students/me/dashboard/')) return _ok({});
        if (path.endsWith('/students/me/report/')) return _ok({});
        if (path.endsWith('/notifications/unread-count/')) {
          return _ok({'count': 0});
        }
        return http.Response('not found', 404);
      }),
    );
    final portal = PortalController(api: api, restoreSession: false);
    addTearDown(portal.dispose);

    expect(
      await portal.login(
        baseUrl: 'https://demo.example.uz',
        username: 'student',
        password: 'secret',
      ),
      isTrue,
    );
    expect(loginBody?['platform'], 'android');
    expect('${loginBody?['device_id']}', startsWith('family-'));
    expect(loginBody?['username'], 'student');
    expect(loginBody?['password'], 'secret');
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
            'permission_codes': _studentPermissions,
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
        if (path.endsWith('/students/')) {
          return _ok([
            {'id': 7, 'student_id': 'ST-007', 'full_name': 'Demo Student'},
          ]);
        }
        if (path.endsWith('/students/7/')) {
          return _ok({
            'id': 7,
            'student_id': 'ST-007',
            'full_name': 'Demo Student',
          });
        }
        if (path.endsWith('/students/comparison/')) {
          expect(request.url.queryParameters['metric'], 'joined');
          expect(request.url.queryParameters['unit'], 'month');
          return _ok({'current': 5, 'previous': 4, 'change_percent': 25});
        }
        if (path.endsWith('/students/stats/')) {
          return _ok({'total': 1, 'active': 1});
        }
        if (path.endsWith('/students/7/events/')) return _ok([]);
        if (path.endsWith('/students/birthdays/')) return _ok([]);
        if (path.endsWith('/students/enrollment-reasons/')) return _ok([]);
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
    await portal.loadSection(PortalSection.identity);
    expect(portal.studentProfile['student_id'], 'ST-007');
    expect(portal.studentComparison['change_percent'], 25);
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
              'permission_codes': _parentPermissions,
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
          if (path.endsWith('/parents/3/')) {
            return _ok({
              'id': 3,
              'username': 'demo.parent',
              'full_name': 'Demo Parent',
              'workplace': 'Office',
            });
          }
          if (path.endsWith('/parents/guardians/')) {
            expect(request.url.queryParameters['parent'], '3');
            expect(request.url.queryParameters['student'], '37');
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
            expect(request.url.queryParameters['student'], '37');
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
    'parent domain requests and rows stay scoped to the selected child',
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
              'permission_codes': _parentPermissions,
            });
          }
          if (path.endsWith('/parents/me/children/')) {
            return _ok([
              {'id': 37, 'full_name': 'Selected Child', 'current_cohort': 9},
              {'id': 38, 'full_name': 'Other Child', 'current_cohort': 10},
            ]);
          }
          if (path.endsWith('/parents/me/children/37/report/')) return _ok({});
          if (path.endsWith('/notifications/unread-count/')) {
            return _ok({'count': 0});
          }
          if (path.endsWith('/attendance/records/')) {
            expect(request.url.queryParameters['student'], '37');
            return _ok([
              {'id': 21, 'student': 37},
            ]);
          }
          if (path.endsWith('/schedule/terms/')) {
            return _ok([
              {'id': 4, 'is_current': true},
            ]);
          }
          if (path.endsWith('/attendance/summary/')) {
            expect(request.url.queryParameters['student'], '37');
            expect(request.url.queryParameters['term'], '4');
            return _ok({'student': 37});
          }
          if (path.endsWith('/academics/subjects/')) return _ok([]);
          if (path.endsWith('/academics/exam-types/')) return _ok([]);
          if (path.endsWith('/academics/exams/')) {
            expect(request.url.queryParameters['cohort'], '9');
            return _ok([]);
          }
          if (path.endsWith('/academics/grades/')) {
            expect(request.url.queryParameters['student'], '37');
            return _ok([
              {'id': 31, 'student': 37},
              {'id': 32, 'student': 38},
            ]);
          }
          if (path.endsWith('/academics/transcripts/')) {
            return _ok([
              {'id': 41, 'student': 37},
              {'id': 42, 'student': 38},
            ]);
          }
          if (path.endsWith('/achievements/mine/')) {
            return _ok([
              {'id': 51, 'student': 37},
              {'id': 52, 'student': 38},
            ]);
          }
          if (path.endsWith('/achievements/')) {
            return _ok([
              {'id': 50, 'name': 'Attendance star', 'status': 'active'},
            ]);
          }
          if (path.endsWith('/rulebook/rules/mine/')) return _ok([]);
          if (path.endsWith('/rulebook/rules/pending/')) return _ok([]);
          if (path.endsWith('/rulebook/penalties/')) {
            expect(request.url.queryParameters['student'], '37');
            return _ok([
              {'id': 61, 'student': 37},
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

      await portal.loadSection(PortalSection.attendance);
      await portal.loadSection(PortalSection.academics);
      await portal.loadSection(PortalSection.achievements);
      await portal.loadSection(PortalSection.discipline);

      expect(portal.can('assignments:read'), isFalse);
      expect(portal.attendanceSummary['student'], 37);
      expect(portal.grades.map((row) => row['student']), [37]);
      expect(portal.transcripts.map((row) => row['student']), [37]);
      expect(portal.achievementGrants.map((row) => row['student']), [37]);
      expect(portal.achievementCatalog.single['name'], 'Attendance star');
      expect(portal.penalties.map((row) => row['student']), [37]);
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
              'permission_codes': _studentPermissions,
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
            'permission_codes': _parentPermissions,
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
      contentType: 'audio/wav',
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
    expect(multipartBody, contains('content-type: audio/wav'));
  });

  test(
    'authenticated multipart transport preserves the declared MIME',
    () async {
      String? authorization;
      String? contentType;
      String? body;
      final api = StarForgeApi(
        baseUrl: 'https://demo.example.uz',
        accessToken: 'avatar-token',
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/example-upload/');
          authorization = request.headers['authorization'];
          contentType = request.headers['content-type'];
          body = latin1.decode(request.bodyBytes);
          return _ok({'file_url': '/media/files/image.png'});
        }),
      );

      final result = await api.postMultipartBytes(
        '/api/v1/example-upload/',
        Uint8List.fromList(const [137, 80, 78, 71]),
        filename: 'avatar.png',
        contentType: 'image/png',
      );

      expect(result.object['file_url'], '/media/files/image.png');
      expect(authorization, 'Bearer avatar-token');
      expect(contentType, startsWith('multipart/form-data; boundary='));
      expect(body, contains('content-type: image/png'));
      expect(body, contains('filename="avatar.png"'));
    },
  );

  test('successful message POST is not failed by a refresh outage', () async {
    var sends = 0;
    final api = StarForgeApi(
      baseUrl: 'https://demo.example.uz',
      client: MockClient((request) async {
        if (request.url.path.endsWith('/threads/9/messages/') &&
            request.method == 'POST') {
          sends++;
          return _ok({'id': 101});
        }
        return http.Response(
          jsonEncode({
            'success': false,
            'code': 'temporarily_unavailable',
            'message': 'refresh failed',
          }),
          503,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final portal = PortalController(api: api, restoreSession: false);
    addTearDown(portal.dispose);

    await portal.sendMessage(9, '', attachments: const ['tenant/voice.m4a']);

    expect(sends, 1);
  });

  test(
    'forwarding re-uploads private attachments into the target chat',
    () async {
      Map<String, Object?>? forwardedBody;
      String? requestedContentType;
      final api = StarForgeApi(
        baseUrl: 'https://demo.example.uz',
        client: MockClient((request) async {
          final path = request.url.path;
          if (path.endsWith('/threads/11/attachments/download/')) {
            return _ok({'url': 'https://storage.example.uz/private/photo'});
          }
          if (request.url.host == 'storage.example.uz' &&
              request.method == 'GET') {
            return http.Response.bytes(const [1, 2, 3, 4], 200);
          }
          if (path.endsWith('/attachments/upload-url/')) {
            final body = Map<String, Object?>.from(
              jsonDecode(request.body) as Map,
            );
            requestedContentType = '${body['content_type']}';
            expect(body['filename'], 'photo.jpg');
            return _ok({
              'url': 'https://storage.example.uz/upload',
              'key': 'tenant/messaging/7/forwarded-photo.jpg',
              'fields': {
                'key': 'tenant/messaging/7/forwarded-photo.jpg',
                'Content-Type': 'image/jpeg',
                'policy': 'signed-policy',
              },
            });
          }
          if (request.url.host == 'storage.example.uz' &&
              request.method == 'POST') {
            return http.Response('', 204);
          }
          if (path.endsWith('/threads/22/messages/') &&
              request.method == 'POST') {
            forwardedBody = Map<String, Object?>.from(
              jsonDecode(request.body) as Map,
            );
            return _ok({'id': 99});
          }
          if (request.method == 'GET') return _ok(<Object?>[]);
          return http.Response('not found', 404);
        }),
      );
      final portal = PortalController(api: api, restoreSession: false);
      addTearDown(portal.dispose);

      await portal.forwardMessage(
        sourceThreadId: 11,
        targetThreadId: 22,
        message: const {
          'id': 5,
          'body': 'Dars rasmi',
          'attachments': ['tenant/messaging/12/12345678-photo.jpg'],
        },
      );

      expect(requestedContentType, 'image/jpeg');
      expect(forwardedBody, {
        'body': '↪ Forwarded message\nDars rasmi',
        'attachments': ['tenant/messaging/7/forwarded-photo.jpg'],
      });
    },
  );

  test('assignment attachment follows the presigned POST grant', () async {
    final methods = <String>[];
    String? multipartBody;
    final api = StarForgeApi(
      baseUrl: 'https://demo.example.uz',
      client: MockClient((request) async {
        methods.add('${request.method} ${request.url}');
        if (request.url.path.endsWith('/assignments/upload-url/')) {
          expect(
            jsonDecode(request.body),
            containsPair('content_type', 'application/pdf'),
          );
          return _ok({
            'url': 'https://storage.example.uz/upload',
            'key': 'demo/assignments/answer.pdf',
            'method': 'POST',
            'fields': {
              'key': 'demo/assignments/answer.pdf',
              'Content-Type': 'application/pdf',
              'policy': 'signed-policy',
            },
          });
        }
        if (request.url.host == 'storage.example.uz') {
          multipartBody = request.body;
          expect(
            request.headers['content-type'],
            startsWith('multipart/form-data; boundary='),
          );
          return http.Response('', 204);
        }
        return http.Response('not found', 404);
      }),
    );
    final portal = PortalController(api: api, restoreSession: false);
    addTearDown(portal.dispose);

    final key = await portal.uploadAssignmentFile(
      filename: 'answer.pdf',
      contentType: 'application/pdf',
      bytes: Uint8List.fromList(const [1, 2, 3, 4]),
    );

    expect(key, 'demo/assignments/answer.pdf');
    expect(methods.first, contains('POST https://demo.example.uz'));
    expect(methods.last, 'POST https://storage.example.uz/upload');
    expect(multipartBody, contains('signed-policy'));
    expect(multipartBody, contains('filename="answer.pdf"'));
  });

  test('latest assignment attempt drives the resubmission limit', () {
    final rows = <Map<String, Object?>>[
      {
        'id': 30,
        'assignment': 8,
        'attempt_number': 3,
        'submitted_at': '2026-08-08T10:00:00Z',
        'status': 'submitted',
      },
      {
        'id': 10,
        'assignment': 8,
        'attempt_number': 1,
        'submitted_at': '2026-08-06T10:00:00Z',
        'status': 'returned',
      },
      {
        'id': 20,
        'assignment': 8,
        'attempt_number': 2,
        'submitted_at': '2026-08-07T10:00:00Z',
        'status': 'returned',
      },
    ];

    final latest = latestAssignmentSubmissions(rows)[8];

    expect(latest?['id'], 30);
    expect(
      assignmentAcceptsAnotherSubmission({
        'status': 'published',
        'max_resubmits': 3,
      }, latest),
      isTrue,
    );
    expect(
      assignmentAcceptsAnotherSubmission({
        'status': 'published',
        'max_resubmits': 2,
      }, latest),
      isFalse,
    );
    expect(
      assignmentAcceptsAnotherSubmission({
        'status': 'closed',
        'max_resubmits': 10,
      }, latest),
      isFalse,
    );
  });

  test(
    'message edit, delete and reaction actions use the agreed API',
    () async {
      final requests = <String>[];
      Map<String, Object?>? editedBody;
      Map<String, Object?>? reactionBody;
      final api = StarForgeApi(
        baseUrl: 'https://demo.example.uz',
        client: MockClient((request) async {
          requests.add('${request.method} ${request.url.path}');
          if (request.method == 'PATCH' &&
              request.url.path.endsWith('/messaging/messages/42/')) {
            editedBody = Map<String, Object?>.from(
              jsonDecode(request.body) as Map,
            );
            return _ok({'id': 42, 'body': 'Yangilangan xabar'});
          }
          if (request.method == 'DELETE' &&
              request.url.path.endsWith('/messaging/messages/42/')) {
            return http.Response('', 204);
          }
          if (request.method == 'POST' &&
              request.url.path.endsWith('/messaging/messages/42/reactions/')) {
            reactionBody = Map<String, Object?>.from(
              jsonDecode(request.body) as Map,
            );
            return _ok({'emoji': '👍', 'count': 1});
          }
          if (request.method == 'DELETE' &&
              request.url.pathSegments.contains('reactions')) {
            return http.Response('', 204);
          }
          if (request.method == 'GET' &&
              request.url.path.endsWith('/threads/11/messages/')) {
            return _ok(<Object?>[]);
          }
          if (request.url.path.endsWith('/threads/11/read/')) return _ok({});
          return _ok(<Object?>[]);
        }),
      );
      final portal = PortalController(api: api, restoreSession: false);
      addTearDown(portal.dispose);

      await portal.editMessage(
        threadId: 11,
        messageId: 42,
        body: ' Yangilangan xabar ',
      );
      await portal.setMessageReaction(
        threadId: 11,
        messageId: 42,
        emoji: '👍',
        remove: false,
      );
      await portal.setMessageReaction(
        threadId: 11,
        messageId: 42,
        emoji: '👍',
        remove: true,
      );
      await portal.deleteMessage(threadId: 11, messageId: 42);

      expect(editedBody, {'body': 'Yangilangan xabar'});
      expect(reactionBody, {'emoji': '👍'});
      expect(
        requests,
        contains('POST /api/v1/messaging/messages/42/reactions/'),
      );
      expect(
        requests.any(
          (value) =>
              value.startsWith('DELETE ') && value.contains('/reactions/'),
        ),
        isTrue,
      );
      expect(requests, contains('DELETE /api/v1/messaging/messages/42/'));
    },
  );

  test(
    'chat contact profile merges role detail without losing user id',
    () async {
      final api = StarForgeApi(
        baseUrl: 'https://demo.example.uz',
        client: MockClient((request) async {
          if (request.url.path == '/api/v1/students/14/') {
            return _ok({
              'id': 14,
              'full_name': 'Ali Valiyev',
              'academic_level': 'B2',
            });
          }
          expect(request.url.path, '/api/v1/students/14/leadership-profile/');
          return _ok({
            'identity': {
              'public_student_id': 'SF-0014',
              'branch': {'id': 2, 'name': 'Chilonzor'},
              'current_group': {
                'id': 9,
                'name': 'Flutter 12',
                'department': {'id': 3, 'name': 'Mobile'},
              },
              'photo': {
                'available': true,
                'download_url': '/media/users/ali.jpg',
              },
            },
            'learning': {
              'subjects': [
                {'id': 5, 'name': 'Dart'},
              ],
            },
            'record_metadata': {'created_at': '2026-08-01T10:00:00Z'},
          });
        }),
      );
      final portal = PortalController(api: api, restoreSession: false);
      addTearDown(portal.dispose);
      portal.contacts = const [
        {
          'id': 71,
          'user_id': 71,
          'profile_id': 14,
          'principal_kind': 'student',
          'display_name': 'Ali',
        },
      ];

      final contact = await portal.loadMessagingContactProfile(
        portal.contacts.single,
      );

      expect(contact['user_id'], 71);
      expect(contact['id'], 71);
      expect(contact['full_name'], 'Ali Valiyev');
      expect(contact['avatar_url'], '/media/users/ali.jpg');
      expect(contact['current_cohort_name'], 'Flutter 12');
      expect(contact['student_id'], 'SF-0014');
      expect(contact['branch_name'], 'Chilonzor');
      expect(contact['department_name'], 'Mobile');
      expect(contact['subjects'], isNotEmpty);
    },
  );

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

const _studentPermissions = <String>[
  'students:read',
  'schedule:read',
  'attendance:read',
  'academics:read',
  'assignments:read',
  'assignments:submit',
  'content:read',
  'forms:read',
  'messaging:read',
  'messaging:write',
  'achievements:read',
  'penalty:read',
  'card:read',
];

const _parentPermissions = <String>[
  'students:read',
  'parents:read',
  'students:read_own_children',
  'attendance:read',
  'academics:read',
  'content:read',
  'finance:read_own',
  'schedule:read',
  'notifications:read',
  'forms:read',
  'messaging:read',
  'messaging:write',
  'achievements:read',
  'penalty:read',
];

http.Response _ok(Object? data) => http.Response(
  jsonEncode({'success': true, 'data': data}),
  200,
  headers: {'content-type': 'application/json'},
);

http.Response _okPaged(
  Object? data, {
  required int total,
  required int page,
  required int pages,
}) => http.Response(
  jsonEncode({
    'success': true,
    'data': data,
    'pagination': {
      'total': total,
      'page': page,
      'page_size': 100,
      'pages': pages,
    },
  }),
  200,
  headers: {'content-type': 'application/json'},
);
