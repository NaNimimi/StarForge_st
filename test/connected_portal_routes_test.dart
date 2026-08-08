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

      final sections = role == 'student'
          ? const [
              PortalSection.identity,
              PortalSection.assignments,
              PortalSection.schedule,
              PortalSection.attendance,
              PortalSection.academics,
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
    if (request.method == 'GET') return _ok(<Object?>[]);
    return http.Response('not found', 404);
  }),
);

http.Response _ok(Object? data) => http.Response(
  jsonEncode({'success': true, 'data': data}),
  200,
  headers: {'content-type': 'application/json'},
);
