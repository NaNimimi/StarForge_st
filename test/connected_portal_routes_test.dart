import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:starforge_student/app_state.dart';
import 'package:starforge_student/portal_app.dart';
import 'package:starforge_student/portal_state.dart';
import 'package:starforge_student/starforge_api.dart';
import 'package:starforge_student/theme.dart';

void main() {
  for (final role in const ['student', 'parent']) {
    testWidgets('connected $role destinations render without exceptions', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final portal = PortalController(
        api: _routeApi(role),
        restoreSession: false,
      );
      final app = AppState();
      addTearDown(portal.dispose);
      addTearDown(app.dispose);
      expect(
        await tester.runAsync(
          () => portal.login(
            baseUrl: 'https://demo.example.uz',
            username: role,
            password: 'secret',
          ),
        ),
        isTrue,
      );
      await tester.pumpWidget(
        AppScope(
          state: app,
          child: MaterialApp(
            theme: Sf.theme(),
            home: ConnectedPortal(controller: portal),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      if (role == 'parent') {
        expect(
          find.byKey(const ValueKey('portal-nav-placement')),
          findsNothing,
          reason: 'backend does not expose guardian-scoped placement attempts',
        );
      }

      final sections = role == 'student'
          ? const [
              PortalSection.identity,
              PortalSection.assignments,
              PortalSection.schedule,
              PortalSection.attendance,
              PortalSection.academics,
              PortalSection.placement,
              PortalSection.content,
              PortalSection.ai,
              PortalSection.messages,
              PortalSection.notifications,
              PortalSection.forms,
              PortalSection.achievements,
              PortalSection.discipline,
              PortalSection.cards,
              PortalSection.account,
            ]
          : const [
              PortalSection.identity,
              PortalSection.attendance,
              PortalSection.academics,
              PortalSection.assignments,
              PortalSection.schedule,
              PortalSection.finance,
              PortalSection.content,
              PortalSection.ai,
              PortalSection.messages,
              PortalSection.notifications,
              PortalSection.forms,
              PortalSection.achievements,
              PortalSection.discipline,
              PortalSection.cards,
              PortalSection.account,
            ];

      for (final section in sections) {
        await _tapDestination(tester, section);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 450));
        expect(
          tester.takeException(),
          isNull,
          reason: '$role ${section.name} must render safely',
        );
      }
    });
  }

  testWidgets('assignment detail tap calls the detail endpoint', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var detailRequests = 0;
    final api = StarForgeApi(
      baseUrl: 'https://demo.example.uz',
      client: MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/auth/login/')) {
          return _ok({'access': 'student-token', 'role': 'student'});
        }
        if (path.endsWith('/users/me/')) {
          return _ok({
            'id': 7,
            'principal_kind': 'student',
            'full_name': 'Demo Student',
            'permission_codes': const ['assignments:read'],
          });
        }
        if (path.endsWith('/students/me/dashboard/') ||
            path.endsWith('/students/me/report/')) {
          return _ok({});
        }
        if (path.endsWith('/notifications/unread-count/')) {
          return _ok({'count': 0});
        }
        if (path.endsWith('/assignments/7/')) {
          detailRequests++;
          return _ok({
            'id': 7,
            'title': 'City presentation',
            'description': 'Full detail body from the detail endpoint.',
            'status': 'published',
            'max_score': 100,
            'due_at': '2026-08-20T12:00:00Z',
          });
        }
        if (path.endsWith('/assignments/')) {
          return _ok([
            {
              'id': 7,
              'title': 'City presentation',
              'description': 'Short list preview.',
              'status': 'published',
              'max_score': 100,
              'due_at': '2026-08-20T12:00:00Z',
            },
          ]);
        }
        if (path.endsWith('/assignments/submissions/')) return _ok([]);
        return http.Response('not found', 404);
      }),
    );
    final portal = PortalController(api: api, restoreSession: false);
    final app = AppState();
    addTearDown(portal.dispose);
    addTearDown(app.dispose);
    expect(
      await tester.runAsync(
        () => portal.login(
          baseUrl: 'https://demo.example.uz',
          username: 'student',
          password: 'secret',
        ),
      ),
      isTrue,
    );
    await tester.pumpWidget(
      AppScope(
        state: app,
        child: MaterialApp(
          theme: Sf.theme(),
          home: ConnectedPortal(controller: portal),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await _tapDestination(tester, PortalSection.assignments);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey('assignment-detail-7')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(detailRequests, 1);
    expect(
      find.byKey(const ValueKey('assignment-detail-page')),
      findsOneWidget,
    );
    expect(find.byType(BottomSheet), findsNothing);
    expect(
      find.text('Full detail body from the detail endpoint.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('grade detail opens as a full page instead of a dialog', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final portal = PortalController(
      api: _routeApi('student'),
      restoreSession: false,
    );
    final app = AppState();
    addTearDown(portal.dispose);
    addTearDown(app.dispose);
    expect(
      await tester.runAsync(
        () => portal.login(
          baseUrl: 'https://demo.example.uz',
          username: 'student',
          password: 'secret',
        ),
      ),
      isTrue,
    );
    await tester.pumpWidget(
      AppScope(
        state: app,
        child: MaterialApp(
          theme: Sf.theme(),
          home: ConnectedPortal(controller: portal),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    await _tapDestination(tester, PortalSection.academics);
    await tester.pump(const Duration(seconds: 1));
    final grade = find.byKey(const ValueKey('grade-detail-71'));
    for (var attempt = 0; attempt < 8 && grade.evaluate().isEmpty; attempt++) {
      await tester.drag(find.byType(ListView).last, const Offset(0, -360));
      await tester.pump(const Duration(milliseconds: 180));
    }
    expect(grade, findsOneWidget);
    await tester.ensureVisible(grade);
    await tester.pumpAndSettle();
    await tester.tap(grade);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(const ValueKey('record-detail-page')), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('A (92%)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('placement page renders score and opens protected detail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var detailRequests = 0;
    final api = StarForgeApi(
      baseUrl: 'https://demo.example.uz',
      client: MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/auth/login/')) {
          return _ok({'access': 'student-token', 'role': 'student'});
        }
        if (path.endsWith('/users/me/')) {
          return _ok({
            'id': 7,
            'principal_kind': 'student',
            'full_name': 'Demo Student',
            'permission_codes': const <String>[],
          });
        }
        if (path.endsWith('/students/me/dashboard/') ||
            path.endsWith('/students/me/report/')) {
          return _ok({});
        }
        if (path.endsWith('/notifications/unread-count/')) {
          return _ok({'count': 0});
        }
        if (path.endsWith('/placement/attempts/17/')) {
          detailRequests++;
          return _ok({
            'id': 17,
            'test_title': 'English placement',
            'status': 'graded',
            'score': 8,
            'max_score': 10,
            'level': 'advanced',
            'questions': const [
              {
                'id': 2,
                'prompt': 'Choose the greeting',
                'question_type': 'single_choice',
                'options': ['Hello', 'Goodbye'],
              },
            ],
            'answers': const [
              {'question': 2, 'response': 'Hello'},
            ],
          });
        }
        if (path.endsWith('/placement/attempts/')) {
          return _ok([
            {
              'id': 17,
              'student': 7,
              'test_title': 'English placement',
              'status': 'graded',
              'score': 8,
              'max_score': 10,
              'level': 'advanced',
            },
          ]);
        }
        return http.Response('not found', 404);
      }),
    );
    final portal = PortalController(api: api, restoreSession: false);
    final app = AppState();
    addTearDown(portal.dispose);
    addTearDown(app.dispose);
    expect(
      await tester.runAsync(
        () => portal.login(
          baseUrl: 'https://demo.example.uz',
          username: 'student',
          password: 'secret',
        ),
      ),
      isTrue,
    );
    await tester.pumpWidget(
      AppScope(
        state: app,
        child: MaterialApp(
          theme: Sf.theme(),
          home: ConnectedPortal(controller: portal),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await _tapDestination(tester, PortalSection.placement);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('80%'), findsWidgets);
    await tester.tap(find.text('English placement').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(detailRequests, 1);
    expect(find.textContaining('Choose the greeting'), findsOneWidget);
    expect(find.textContaining('Javob: Hello'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'student completes and submits every safe placement answer shape',
    (tester) async {
      tester.view.physicalSize = const Size(900, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Map<String, Object?>? submittedBody;
      var submitted = false;
      final api = StarForgeApi(
        baseUrl: 'https://demo.example.uz',
        client: MockClient((request) async {
          final path = request.url.path;
          if (path.endsWith('/auth/login/')) {
            return _ok({'access': 'student-token', 'role': 'student'});
          }
          if (path.endsWith('/users/me/')) {
            return _ok({
              'id': 7,
              'principal_kind': 'student',
              'full_name': 'Demo Student',
              'permission_codes': const <String>[],
            });
          }
          if (path.endsWith('/students/me/dashboard/') ||
              path.endsWith('/students/me/report/')) {
            return _ok({});
          }
          if (path.endsWith('/notifications/unread-count/')) {
            return _ok({'count': 0});
          }
          if (request.method == 'POST' &&
              path.endsWith('/placement/attempts/21/submit/')) {
            submittedBody = Map<String, Object?>.from(
              jsonDecode(request.body) as Map,
            );
            submitted = true;
            return _ok({
              'id': 21,
              'student': 7,
              'test_title': 'Secure placement',
              'status': 'graded',
              'score': 3,
              'max_score': 4,
              'level': 'advanced',
            });
          }
          if (path.endsWith('/placement/attempts/21/')) {
            return _ok({
              'id': 21,
              'student': 7,
              'test_title': 'Secure placement',
              'status': 'assigned',
              'questions': const [
                {
                  'id': 2,
                  'prompt': 'Choose the greeting',
                  'question_type': 'single_choice',
                  'options': [
                    {
                      'label': 'Hello',
                      'correct_answer': 'must-not-render',
                      'internal_score': 99,
                    },
                    'Goodbye',
                  ],
                },
                {
                  'id': 3,
                  'prompt': 'Choose two letters',
                  'question_type': 'multiple_choice',
                  'options': ['A', 'B', 'C'],
                },
                {
                  'id': 4,
                  'prompt': 'The sky can be blue',
                  'question_type': 'true_false',
                },
                {
                  'id': 5,
                  'prompt': 'Write one word',
                  'question_type': 'short_answer',
                },
              ],
              'answers': const [],
            });
          }
          if (path.endsWith('/placement/attempts/')) {
            return _ok([
              {
                'id': 21,
                'student': 7,
                'test_title': 'Secure placement',
                'status': submitted ? 'graded' : 'assigned',
                if (submitted) 'score': 3,
                if (submitted) 'max_score': 4,
                if (submitted) 'level': 'advanced',
              },
            ]);
          }
          return http.Response('not found', 404);
        }),
      );
      final portal = PortalController(api: api, restoreSession: false);
      final app = AppState();
      addTearDown(portal.dispose);
      addTearDown(app.dispose);
      expect(
        await tester.runAsync(
          () => portal.login(
            baseUrl: 'https://demo.example.uz',
            username: 'student',
            password: 'secret',
          ),
        ),
        isTrue,
      );
      await tester.pumpWidget(
        AppScope(
          state: app,
          child: MaterialApp(
            theme: Sf.theme(),
            home: ConnectedPortal(controller: portal),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await _tapDestination(tester, PortalSection.placement);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Secure placement').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('must-not-render'), findsNothing);
      expect(find.text('99'), findsNothing);
      await _tapPlacementControl(
        tester,
        const ValueKey('placement-option-2-0'),
      );
      await _tapPlacementControl(
        tester,
        const ValueKey('placement-option-3-0'),
      );
      await _tapPlacementControl(
        tester,
        const ValueKey('placement-option-3-2'),
      );
      await _tapPlacementControl(
        tester,
        const ValueKey('placement-boolean-4-true'),
      );
      final shortAnswer = find.byKey(const ValueKey('placement-text-5'));
      await tester.ensureVisible(shortAnswer);
      await tester.enterText(shortAnswer, 'Blue');
      await tester.pump();
      await _tapPlacementControl(tester, const ValueKey('placement-submit'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('placement-confirm-submit')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(submittedBody, {
        'answers': [
          {'question': 2, 'response': 'Hello'},
          {
            'question': 3,
            'response': ['A', 'C'],
          },
          {'question': 4, 'response': true},
          {'question': 5, 'response': 'Blue'},
        ],
      });
      expect(find.text('Sinov topshirildi'), findsOneWidget);
      expect(find.textContaining('75%'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('placement-result-close')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('75%'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _tapPlacementControl(WidgetTester tester, Key key) async {
  final target = find.byKey(key);
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await tester.pump();
}

Future<void> _tapDestination(WidgetTester tester, PortalSection section) async {
  final destination = find.byKey(ValueKey('portal-nav-${section.name}'));
  final navigation = find.byKey(const ValueKey('portal-navigation-list'));
  for (
    var attempt = 0;
    attempt < 8 && destination.evaluate().isEmpty;
    attempt++
  ) {
    await tester.drag(navigation, const Offset(0, -220));
    await tester.pump(const Duration(milliseconds: 180));
  }
  expect(
    destination,
    findsOneWidget,
    reason: '${section.name} is in navigation',
  );
  await tester.ensureVisible(destination);
  await tester.tap(destination);
}

StarForgeApi _routeApi(String role) => StarForgeApi(
  baseUrl: 'https://demo.example.uz',
  client: MockClient((request) async {
    final path = request.url.path;
    if (path.endsWith('/auth/login/')) {
      return _ok({'access': '$role-token', 'role': role});
    }
    if (path.endsWith('/users/me/')) {
      return _ok({
        'id': role == 'student' ? 7 : 3,
        'principal_kind': role,
        'full_name': role == 'student' ? 'Demo Student' : 'Demo Parent',
        'permission_codes': const [
          'students:read',
          'parents:read',
          'assignments:read',
          'schedule:read',
          'attendance:read',
          'academics:read',
          'content:read',
          'ai:read',
          'messaging:read',
          'messaging:write',
          'notifications:read',
          'forms:read',
          'achievements:read',
          'penalty:read',
          'finance:read_own',
          'card:read',
        ],
      });
    }
    if (path.endsWith('/students/me/dashboard/')) return _ok({});
    if (path.endsWith('/students/me/report/')) return _ok({});
    if (path.endsWith('/parents/me/children/')) {
      return _ok([
        {'id': 37, 'full_name': 'Demo Child', 'current_cohort': 12},
      ]);
    }
    if (path.endsWith('/parents/me/children/37/report/')) return _ok({});
    if (path.endsWith('/notifications/unread-count/')) {
      return _ok({'count': 0});
    }
    if (path.endsWith('/schedule/ical-url/')) return _ok({'url': ''});
    if (path.endsWith('/finance/outstanding/')) return _ok({});
    if (path.endsWith('/attendance/summary/')) return _ok({});
    if (path.endsWith('/cards/wallets/me/')) return _ok({});
    if (path.endsWith('/ai/budget/')) return _ok({});
    if (path.endsWith('/ai/usage-report/')) return _ok({});
    if (path.endsWith('/academics/grades/71/')) {
      return _ok({
        'id': 71,
        'student': role == 'parent' ? 37 : 7,
        'subject_name': 'Matematika',
        'value_display': 'A (92%)',
        'is_published': true,
        'published_at': '2026-08-12T09:00:00Z',
        'components': const [
          {'title': 'Final', 'score': 92, 'max_score': 100},
        ],
      });
    }
    if (path.endsWith('/academics/grades/')) {
      return _ok([
        {
          'id': 71,
          'student': role == 'parent' ? 37 : 7,
          'subject_name': 'Matematika',
          'value_display': 'A (92%)',
          'is_published': true,
          'published_at': '2026-08-12T09:00:00Z',
        },
      ]);
    }
    if (request.method == 'GET') return _ok(<Object?>[]);
    return http.Response('not found', 404);
  }),
);

http.Response _ok(Object? data) => http.Response(
  jsonEncode({'success': true, 'data': data}),
  200,
  headers: {'content-type': 'application/json'},
);
