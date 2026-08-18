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
    expect(
      find.byKey(const ValueKey('portal-bottom-assignments')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('portal-bottom-schedule')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('portal-bottom-messages')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('portal-bottom-identity')),
      findsOneWidget,
    );
    expect(find.text('Profil'), findsOneWidget);
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

  testWidgets('schedule uses two compact columns on a phone', (tester) async {
    await _openSchedule(tester, const Size(390, 844));
    await _revealScheduleCards(tester);

    final first = tester.getRect(_lessonCard(1));
    final second = tester.getRect(_lessonCard(2));
    final third = tester.getRect(_lessonCard(3));
    expect((first.top - second.top).abs(), lessThan(1));
    expect(third.top, greaterThan(first.top + 1));
    expect(first.width, lessThan(190));
    expect(tester.takeException(), isNull);
  });

  testWidgets('schedule uses three compact columns on a tablet', (
    tester,
  ) async {
    await _openSchedule(tester, const Size(820, 1000));
    await _revealScheduleCards(tester);

    final first = tester.getRect(_lessonCard(1));
    final second = tester.getRect(_lessonCard(2));
    final third = tester.getRect(_lessonCard(3));
    final fourth = tester.getRect(_lessonCard(4));
    expect((first.top - second.top).abs(), lessThan(1));
    expect((first.top - third.top).abs(), lessThan(1));
    expect(fourth.top, greaterThan(first.top + 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('schedule uses four compact columns on desktop', (tester) async {
    await _openSchedule(tester, const Size(1280, 900));
    await _revealScheduleCards(tester);

    final first = tester.getRect(_lessonCard(1));
    final second = tester.getRect(_lessonCard(2));
    final third = tester.getRect(_lessonCard(3));
    final fourth = tester.getRect(_lessonCard(4));
    final fifth = tester.getRect(_lessonCard(5));
    expect((first.top - second.top).abs(), lessThan(1));
    expect((first.top - third.top).abs(), lessThan(1));
    expect((first.top - fourth.top).abs(), lessThan(1));
    expect(fifth.top, greaterThan(first.top + 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('schedule falls back to one column at 200 percent text', (
    tester,
  ) async {
    await _openSchedule(tester, const Size(320, 760), textScale: 2);
    await _revealScheduleCards(tester);

    final first = tester.getRect(_lessonCard(1));
    final second = tester.getRect(_lessonCard(2));
    expect(second.top, greaterThan(first.top + 1));
    expect((first.left - second.left).abs(), lessThan(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('schedule lesson opens a full details page', (tester) async {
    await _openSchedule(tester, const Size(390, 844));
    await _revealScheduleCards(tester);

    await tester.tap(_lessonCard(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Dars tafsilotlari'), findsOneWidget);
    expect(find.text('Frontend Pro'), findsWidgets);
    expect(find.text('Ustoz 1'), findsWidgets);
    expect(find.text('101-xona'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('system back returns to dashboard before offering app exit', (
    tester,
  ) async {
    await _openSchedule(tester, const Size(390, 844));

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Bugungi marshrut'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(
      find.text('Ilovadan chiqish uchun yana bir marta bosing.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile side panel closes and opens its selected section', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
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
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.byTooltip('Barcha bo‘limlar'));
    await tester.pumpAndSettle();
    final destination = find.byKey(const ValueKey('portal-nav-academics'));
    await tester.scrollUntilVisible(
      destination,
      180,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('portal-navigation-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(destination);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold).first);
    expect(scaffold.isDrawerOpen, isFalse);
    expect(find.text('Natijalarim'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('connected AI page renders family assistant conversation', (
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
    expect(find.text('Bugun nimadan boshlay?'), findsOneWidget);
    expect(find.byKey(const ValueKey('family-ai-input')), findsOneWidget);
    expect(find.text('SERVER AI'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('family-ai-history')));
    await tester.pumpAndSettle();
    expect(find.text('AI suhbat tarixi'), findsOneWidget);
    expect(find.text('Bugungi rejangiz tayyor.'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('family-ai-input')),
      'Baholarim qanday?',
    );
    await tester.tap(find.byKey(const ValueKey('family-ai-send')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text('Natijangiz 92%. Mashqni davom ettiring.'),
      findsOneWidget,
    );
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
    if (path.endsWith('/academics/grades/')) return _ok(<Object?>[]);
    if (path.endsWith('/schedule/lessons/')) {
      return _ok([
        for (var index = 1; index <= 5; index++)
          {
            'id': index,
            'title': index == 2
                ? 'Ingliz tili va suhbat amaliyoti'
                : 'Dars $index',
            'teacher_name': 'Ustoz $index',
            'room_name': '${100 + index}-xona',
            'status': index == 5 ? 'cancelled' : 'scheduled',
            'starts_at':
                '2026-08-${11 + index}T${(7 + index).toString().padLeft(2, '0')}:00:00Z',
            'ends_at':
                '2026-08-${11 + index}T${(8 + index).toString().padLeft(2, '0')}:00:00Z',
          },
      ]);
    }
    final lessonMatch = RegExp(r'/schedule/lessons/(\d+)/$').firstMatch(path);
    if (lessonMatch != null) {
      final id = int.parse(lessonMatch.group(1)!);
      return _ok({
        'id': id,
        'title': 'Dars $id',
        'term_name': '2026 yozgi davr',
        'cohort_name': 'Frontend Pro',
        'teacher_name': 'Ustoz $id',
        'room_name': '${100 + id}-xona',
        'lesson_type_name': 'Amaliy dars',
        'status': 'scheduled',
        'starts_at': '2026-08-12T08:00:00Z',
        'ends_at': '2026-08-12T09:00:00Z',
        'detached_from_rule': false,
        'cancel_reason': '',
      });
    }
    if (path.endsWith('/schedule/terms/') ||
        path.endsWith('/schedule/timeslots/') ||
        path.endsWith('/schedule/lesson-types/') ||
        path.endsWith('/schedule/rules/')) {
      return _ok(<Object?>[]);
    }
    if (path.endsWith('/schedule/ical-url/')) return _ok({'url': ''});
    if (path.endsWith('/ai/family-assistant/')) {
      if (request.method == 'POST') {
        return _ok({
          'conversation_id': 1,
          'message': {'id': 2, 'role': 'user', 'content': 'Baholarim qanday?'},
          'assistant_message_id': 3,
          'answer': 'Natijangiz 92%. Mashqni davom ettiring.',
          'sources': [
            {'type': 'grade', 'label': 'English: 92'},
          ],
          'suggestions': ['Keyingi vazifam nima?'],
          'fallback_used': false,
        });
      }
      return _ok({
        'history': [
          {
            'id': 1,
            'role': 'assistant',
            'content': 'Bugungi rejangiz tayyor.',
            'created_at': '2026-08-08T10:00:00Z',
          },
        ],
        'sources': [
          {'type': 'assignments', 'label': 'Vazifalar'},
        ],
        'suggestions': ['Bugun nimadan boshlay?', 'Baholarimni tahlil qil'],
        'fallback_used': false,
      });
    }
    return http.Response('not found', 404);
  }),
);

Finder _lessonCard(int id) => find.byKey(ValueKey('schedule-lesson-card-$id'));

Future<void> _openSchedule(
  WidgetTester tester,
  Size size, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
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
  await tester.pumpWidget(_connectedApp(portal, textScale: textScale));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));

  final destination = size.width >= 840
      ? find.byKey(const ValueKey('portal-nav-schedule'))
      : find.byKey(const ValueKey('portal-bottom-schedule'));
  expect(destination, findsOneWidget);
  await tester.ensureVisible(destination);
  await tester.tap(destination);
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

Future<void> _revealScheduleCards(WidgetTester tester) async {
  final page = find.byType(ListView).last;
  for (
    var attempt = 0;
    attempt < 8 && _lessonCard(1).evaluate().isEmpty;
    attempt++
  ) {
    await tester.drag(page, const Offset(0, -350));
    await tester.pump(const Duration(milliseconds: 120));
  }
  expect(_lessonCard(1), findsOneWidget);
}

http.Response _ok(Object? data) => http.Response(
  jsonEncode({'success': true, 'data': data}),
  200,
  headers: {'content-type': 'application/json'},
);
