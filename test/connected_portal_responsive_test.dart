import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:starforge_student/portal_app.dart';
import 'package:starforge_student/portal_state.dart';
import 'package:starforge_student/starforge_api.dart';
import 'package:starforge_student/theme.dart';

void main() {
  testWidgets('connected login stays compact on a wide desktop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final portal = PortalController(restoreSession: false);
    addTearDown(portal.dispose);
    await tester.pumpWidget(_connectedApp(portal));
    await tester.pumpAndSettle();

    expect(find.text('Kabinetga kirish'), findsOneWidget);
    expect(find.byKey(const ValueKey('portal-login-username')), findsOneWidget);
    expect(find.text('Ta’lim jarayoni\nendi aniq ko‘rinadi.'), findsNothing);
    final fieldSize = tester.getSize(
      find.byKey(const ValueKey('portal-login-username')),
    );
    expect(fieldSize.width, lessThanOrEqualTo(430));
    expect(tester.takeException(), isNull);
  });

  testWidgets('connected student portal survives 320px and 200% text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final portal = PortalController(
      api: _familyApi(role: 'student'),
      restoreSession: false,
    );
    addTearDown(portal.dispose);
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

    await tester.pumpWidget(_connectedApp(portal, textScale: 2));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Bugungi marshrut'), findsOneWidget);
    expect(find.text('Tezkor o‘tish'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('portal-bottom-navigation')),
      findsOneWidget,
    );
    expect(find.text('Barchasi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('connected parent portal renders child context on desktop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final portal = PortalController(
      api: _familyApi(role: 'parent'),
      restoreSession: false,
    );
    addTearDown(portal.dispose);
    expect(
      await tester.runAsync(
        () => portal.login(
          baseUrl: 'https://demo.example.uz',
          username: 'parent',
          password: 'secret',
        ),
      ),
      isTrue,
    );

    await tester.pumpWidget(_connectedApp(portal));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Oila nazorat markazi'), findsOneWidget);
    expect(find.text('Demo Child'), findsWidgets);
    expect(find.text('Davomatni kuzatish kerak'), findsOneWidget);
    expect(find.text('Oila uchun tezkor amallar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('connected AI page renders server request history', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final portal = PortalController(
      api: _familyApi(role: 'student'),
      restoreSession: false,
    );
    addTearDown(portal.dispose);
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

    await tester.pumpWidget(_connectedApp(portal));
    await tester.pump();
    await tester.tap(find.text('AI yordamchi'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('AI o‘qish yordamchisi'), findsOneWidget);
    expect(find.text('Essay feedback'), findsOneWidget);
    expect(find.text('SERVER AI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _connectedApp(PortalController portal, {double textScale = 1}) =>
    MaterialApp(
      theme: Sf.theme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: ConnectedPortal(controller: portal),
    );

StarForgeApi _familyApi({required String role}) => StarForgeApi(
  baseUrl: 'https://demo.example.uz',
  client: MockClient((request) async {
    final path = request.url.path;
    if (path.endsWith('/auth/role-login/')) {
      return _ok({
        'access': '$role-session',
        'role': role,
        'must_change_password': false,
      });
    }
    if (path.endsWith('/users/me/')) {
      return _ok({
        'id': role == 'parent' ? 3 : 7,
        'principal_kind': role,
        'username': 'demo.$role',
        'full_name': role == 'parent' ? 'Demo Parent' : 'Demo Student',
        'permission_codes': role == 'parent'
            ? [
                'parents:read',
                'students:read',
                'finance:read_own',
                'attendance:read',
                'academics:read',
                'schedule:read',
                'messaging:read',
              ]
            : [
                'students:read',
                'assignments:read',
                'attendance:read',
                'academics:read',
                'schedule:read',
                'messaging:read',
                'ai:read',
              ],
      });
    }
    if (path.endsWith('/students/me/dashboard/')) {
      return _ok({
        'group': 'Frontend Pro',
        'open_homework_count': 2,
        'open_homework': <Object?>[],
        'next_lessons': <Object?>[],
        'recent_grades': <Object?>[],
      });
    }
    if (path.endsWith('/students/me/report/')) {
      return _ok({
        'attendance': {'rate': 0.9, 'present': 9, 'of': 10},
        'payment': {'outstanding_uzs': '0.00'},
      });
    }
    if (path.endsWith('/parents/me/children/')) {
      return _ok([
        {
          'id': 37,
          'full_name': 'Demo Child',
          'student_id': 'S-37',
          'academic_level': 'Intermediate',
          'current_cohort': 12,
        },
      ]);
    }
    if (path.endsWith('/parents/me/children/37/report/')) {
      return _ok({
        'attendance': {
          'rate': 0.75,
          'present': 3,
          'of': 4,
          'sheet': <Object?>[],
        },
        'payment': {'outstanding_uzs': '0.00'},
        'rank': <String, Object?>{},
      });
    }
    if (path.endsWith('/finance/outstanding/')) {
      return _ok({'student': 37, 'outstanding_uzs': '0.00'});
    }
    if (path.endsWith('/notifications/unread-count/')) {
      return _ok({'count': 0});
    }
    if (path.endsWith('/ai/requests/')) {
      return _ok([
        {
          'id': 1,
          'title': 'Essay feedback',
          'status': 'completed',
          'model': 'education-model',
          'created_at': '2026-08-08T10:00:00Z',
        },
      ]);
    }
    if (path.endsWith('/ai/budget/')) {
      return _ok({'remaining': 42, 'spent': 8});
    }
    if (path.endsWith('/ai/usage-report/')) {
      return _ok({'total_requests': 1, 'total_tokens': 1200});
    }
    return http.Response('not found', 404);
  }),
);

http.Response _ok(Object? data) => http.Response(
  jsonEncode({'success': true, 'data': data}),
  200,
  headers: {'content-type': 'application/json'},
);
