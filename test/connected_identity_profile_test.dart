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
  for (final role in const ['student', 'parent']) {
    testWidgets('connected $role identity is usable at 320px and 200% text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final portal = PortalController(
        api: _identityApi(role),
        restoreSession: false,
      );
      addTearDown(portal.dispose);
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

      await tester.pumpWidget(_connectedApp(portal));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.byKey(const ValueKey('portal-bottom-identity')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(tester.takeException(), isNull);
      if (role == 'student') {
        expect(find.text('Mening profilim'), findsWidgets);
        expect(find.text('Dilshod Karimov'), findsWidgets);
        expect(find.text('Shaxsiy ma’lumotlar'), findsOneWidget);
        expect(find.textContaining('Profil tayyorligi'), findsNothing);

        expect(
          find.byKey(const ValueKey('profile-avatar-button')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('avatar-picker-page')), findsNothing);

        await tester.ensureVisible(find.text('O‘qish tarixi'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('O‘qish tarixi'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Guruhga qabul qilindi'), findsOneWidget);
      } else {
        expect(portal.selectedStudentId, 37);
        expect(portal.guardians, hasLength(1));
        expect(portal.guardians.single['custody_notes'], isNotEmpty);
        expect(find.text('Oila profili'), findsWidgets);
        expect(find.text('Madina Karimova'), findsWidgets);
        expect(find.text('Tanlangan farzand'), findsOneWidget);
        expect(
          find.textContaining('profil tayyor', findRichText: true),
          findsNothing,
        );

        expect(
          find.byKey(const ValueKey('profile-avatar-button')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('avatar-picker-page')), findsNothing);

        await tester.ensureVisible(find.text('Vakillar va olib ketish'));
        await tester.pumpAndSettle();
        expect(find.text('Bahrom Karimov'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}

Widget _connectedApp(PortalController portal) => MaterialApp(
  theme: Sf.theme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: const TextScaler.linear(2)),
    child: child!,
  ),
  home: ConnectedPortal(controller: portal),
);

StarForgeApi _identityApi(String role) => StarForgeApi(
  baseUrl: 'https://demo.example.uz',
  client: MockClient((request) async {
    final path = request.url.path;
    if (path.endsWith('/auth/login/') || path.endsWith('/auth/role-login/')) {
      return _ok({'access': '$role-token', 'role': role});
    }
    if (path.endsWith('/users/me/')) {
      return _ok({
        'id': role == 'student' ? 7 : 3,
        'principal_kind': role,
        'username': 'demo.$role',
        'full_name': role == 'student' ? 'Dilshod Karimov' : 'Madina Karimova',
        'permission_codes': const [
          'students:read',
          'parents:read',
          'attendance:read',
          'academics:read',
          'schedule:read',
          'messaging:read',
        ],
      });
    }
    if (path.endsWith('/students/me/dashboard/')) return _ok({});
    if (path.endsWith('/students/me/report/')) return _ok({});
    if (path.endsWith('/parents/me/children/')) {
      return _ok([
        {
          'id': 37,
          'full_name': 'Aziz Karimov',
          'student_id': 'ST-0037',
          'academic_level': 'Intermediate',
          'current_cohort': 12,
        },
      ]);
    }
    if (path.endsWith('/parents/me/children/37/report/')) return _ok({});
    if (path.endsWith('/notifications/unread-count/')) {
      return _ok({'count': 0});
    }
    if (path.endsWith('/finance/outstanding/')) {
      return _ok({'outstanding_uzs': '0.00'});
    }
    if (path.endsWith('/parents/3/')) return _ok(_parentProfile);
    if (path.endsWith('/parents/guardians/')) return _ok([_guardian]);
    if (path.endsWith('/parents/pickups/')) return _ok([_pickup]);
    if (path.endsWith('/students/stats/')) {
      return _ok({
        'total': 14,
        'by_status': {'active': 12, 'paused': 2},
        'by_branch': {'Chilonzor': 8, 'Yunusobod': 6},
      });
    }
    if (path.endsWith('/students/comparison/')) return _ok({});
    if (path.endsWith('/students/birthdays/')) {
      return _ok([
        {'full_name': 'Sardor Aliyev', 'birthdate': '2011-08-18'},
      ]);
    }
    if (path.endsWith('/students/enrollment-reasons/')) {
      return _ok([
        {
          'name': 'Dasturlashga qiziqish',
          'slug': 'coding-interest',
          'color': '#2F675B',
          'is_active': true,
        },
      ]);
    }
    if (path.endsWith('/students/7/') || path.endsWith('/students/37/')) {
      return _ok(_studentProfile);
    }
    if (path.endsWith('/students/7/events/') ||
        path.endsWith('/students/37/events/')) {
      return _ok([
        {
          'from_status': 'new',
          'to_status': 'active',
          'note': 'Guruhga qabul qilindi',
          'created_at': '2026-08-01T09:30:00Z',
        },
      ]);
    }
    if (path.endsWith('/students/')) {
      return _ok([
        {'id': 7, 'full_name': 'Dilshod Karimov'},
      ]);
    }
    if (request.method == 'GET') return _ok(<Object?>[]);
    return http.Response('not found', 404);
  }),
);

const _studentProfile = <String, Object?>{
  'id': 7,
  'full_name': 'Dilshod Karimov',
  'first_name': 'Dilshod',
  'last_name': 'Karimov',
  'middle_name': 'Akmal o‘g‘li',
  'username': 'demo.student',
  'student_id': 'ST-0007',
  'phone': '+998 90 123 45 67',
  'email': 'dilshod@example.uz',
  'birthdate': '2011-03-12',
  'gender': 'male',
  'location': 'Toshkent',
  'academic_level': 'Intermediate',
  'current_cohort': 12,
  'current_cohort_name': 'Flutter 12',
  'branch': 2,
  'branch_name': 'Chilonzor',
  'primary_teacher_name': 'Nodira ustoz',
  'previous_school': '145-maktab',
  'enrollment_date': '2026-01-15',
  'status': 'active',
  'is_active': true,
  'is_blocked': false,
};

const _parentProfile = <String, Object?>{
  'id': 3,
  'full_name': 'Madina Karimova',
  'phone': '+998 90 765 43 21',
  'email': 'madina@example.uz',
  'birthdate': '1987-05-20',
  'gender': 'female',
  'workplace': 'Toshkent shahar klinikasi',
  'is_active': true,
};

const _guardian = <String, Object?>{
  'id': 9,
  'parent': 3,
  'student': 37,
  'parent_name': 'Madina Karimova',
  'student_name': 'Aziz Karimov',
  'relationship': 'mother',
  'is_primary': true,
  'custody_notes': 'Asosiy qonuniy vakil',
};

const _pickup = <String, Object?>{
  'id': 11,
  'student': 37,
  'student_name': 'Aziz Karimov',
  'full_name': 'Bahrom Karimov',
  'relationship': 'father',
  'phone': '+998 91 111 22 33',
  'is_active': true,
  'created_at': '2026-08-01T09:30:00Z',
};

http.Response _ok(Object? data) => http.Response(
  jsonEncode({'success': true, 'data': data}),
  200,
  headers: {'content-type': 'application/json'},
);
