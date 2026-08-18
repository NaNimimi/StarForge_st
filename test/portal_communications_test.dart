import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:starforge_student/notification_service.dart';
import 'package:starforge_student/platform_file_bytes.dart';
import 'package:starforge_student/portal_app.dart';
import 'package:starforge_student/portal_state.dart';
import 'package:starforge_student/starforge_api.dart';
import 'package:starforge_student/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Android AAC MP42 recording is normalized to M4A audio', () async {
    final bytes = Uint8List.fromList([
      0,
      0,
      0,
      24,
      ...'ftyp'.codeUnits,
      ...'mp42'.codeUnits,
      0,
      0,
      0,
      0,
      ...'mp42'.codeUnits,
    ]);
    final file = File(
      '${Directory.systemTemp.path}/starforge_voice_brand_${DateTime.now().microsecondsSinceEpoch}.m4a',
    );
    addTearDown(() async {
      if (await file.exists()) await file.delete();
    });
    await file.writeAsBytes(bytes, flush: true);

    expect(await normalizeRecordedM4aBrand(file.path), isTrue);
    final normalized = await file.readAsBytes();
    expect(String.fromCharCodes(normalized.sublist(8, 12)), 'M4A ');

    final format = recordedVoiceUploadFormat(normalized, 'm4a');

    expect(format.extension, 'm4a');
    expect(format.contentType, 'audio/mp4');
  });

  testWidgets(
    'notification feed exposes filters, groups and server event data',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final portal = PortalController(
        api: _communicationsApi(withContacts: true),
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

      await tester.pumpWidget(_app(portal));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('Bildirishnomalar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.byKey(const ValueKey('notification-filter-panel')),
        findsOneWidget,
      );
      expect(find.text('Bugun'), findsWidgets);
      expect(find.text('Yangi algebra vazifasi'), findsOneWidget);
      expect(find.textContaining('Yangi vazifa'), findsWidgets);
      expect(find.text('Yetkazish kanallari'), findsNothing);
      expect(portal.unreadNotificationCount, 0);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('chat explains an empty school contact directory', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final portal = PortalController(
      api: _communicationsApi(withContacts: false),
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

    await tester.pumpWidget(_app(portal));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Chat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('chat-directory-notice')), findsOneWidget);
    expect(find.text('Maktab kontaktlari hali mavjud emas'), findsOneWidget);
    expect(find.text('Hozircha suhbat yo‘q'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('message notification opens its exact teacher thread', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final portal = PortalController(
      api: _communicationsApi(withContacts: true, withThread: true),
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
    await tester.pumpWidget(_app(portal));
    await tester.pump(const Duration(milliseconds: 200));

    DeviceNotificationService.instance.ingestRemoteTap({
      'route': 'messages',
      'thread_id': 44,
      'message_id': 501,
    });
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.byKey(const ValueKey('family-chat-header')), findsOneWidget);
    expect(find.text('Algebra Teacher'), findsWidgets);
    expect(find.text('Ertangi dars uchun material tayyor.'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('message-actions-502')));
    await tester.pumpAndSettle();
    expect(find.text('Xabar amallari'), findsOneWidget);
    expect(find.text('Boshqa suhbatga yuborish'), findsOneWidget);
    expect(find.text('Tahrirlash'), findsOneWidget);
    expect(find.text('O‘chirish'), findsOneWidget);
    expect(find.text('👍'), findsOneWidget);
    await tester.tap(find.text('👍'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final headerTitle = find.descendant(
      of: find.byKey(const ValueKey('family-chat-header')),
      matching: find.text('Algebra Teacher'),
    );
    await tester.tap(headerTitle);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('chat-contact-profile-page')),
      findsOneWidget,
    );
    expect(find.text('Teacher'), findsOneWidget);
    expect(find.text('+998 90 111 22 33'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -650));
    await tester.pumpAndSettle();
    expect(find.text('Mathematics'), findsOneWidget);
    expect(find.text('Chilonzor'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

Widget _app(PortalController portal) => MaterialApp(
  theme: Sf.theme(),
  home: ConnectedPortal(controller: portal),
);

StarForgeApi _communicationsApi({
  required bool withContacts,
  bool withThread = false,
}) => StarForgeApi(
  baseUrl: 'https://demo.example.uz',
  client: MockClient((request) async {
    final path = request.url.path;
    if (path.endsWith('/auth/login/') || path.endsWith('/auth/role-login/')) {
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
        'username': 'demo.student',
        'full_name': 'Demo Student',
        'permission_codes': [
          'students:read',
          'messaging:read',
          'messaging:write',
          'notifications:read',
        ],
      });
    }
    if (path.endsWith('/students/me/dashboard/')) {
      return _ok({
        'group': 'Frontend Pro',
        'open_homework': <Object?>[],
        'next_lessons': <Object?>[],
        'recent_grades': <Object?>[],
      });
    }
    if (path.endsWith('/students/me/report/')) {
      return _ok({
        'attendance': {'rate': 1, 'present': 1, 'of': 1},
        'payment': {'outstanding_uzs': '0'},
      });
    }
    if (path.endsWith('/notifications/unread-count/')) {
      return _ok({'count': 1});
    }
    if (path.endsWith('/notifications/preferences/')) return _ok(<Object?>[]);
    if (path.endsWith('/notifications/read-all/')) {
      return _ok({'status': 'ok'});
    }
    if (path.endsWith('/notifications/')) {
      return http.Response(
        jsonEncode({
          'results': [
            {
              'id': 91,
              'event_type': 'assignments.created',
              'title': 'Yangi algebra vazifasi',
              'body': 'Topshiriq juma kunigacha.',
              'data': {'assignment_id': 8},
              'read_at': null,
              'created_at': DateTime.now().toUtc().toIso8601String(),
            },
          ],
          'next': null,
          'previous': null,
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    if (path.endsWith('/teachers/8/')) {
      return _ok({
        'id': 12,
        'user_id': 12,
        'profile_id': 8,
        'principal_kind': 'teacher',
        'display_name': 'Algebra Teacher',
        'full_name': 'Algebra Teacher',
        'role_label': 'Teacher',
        'username': 'algebra.teacher',
        'phone': '+998 90 111 22 33',
        'email': 'teacher@example.uz',
        'branch_name': 'Chilonzor',
        'department_name': 'Mathematics',
        'subjects': ['Algebra', 'Geometry'],
        'gender': 'f',
        'birthdate': '1990-02-03',
        'is_online': true,
      });
    }
    if (path.endsWith('/messaging/contacts/')) {
      return _page(
        withContacts
            ? [
                {
                  'id': 12,
                  'user_id': 12,
                  'profile_id': 8,
                  'principal_kind': 'teacher',
                  'display_name': 'Algebra Teacher',
                  'role_label': 'Teacher',
                  'is_online': true,
                },
              ]
            : <Object?>[],
        extra: {'self_user_id': 7},
      );
    }
    final thread = {
      'id': 44,
      'subject': 'Algebra savollari',
      'last_message_at': DateTime.now().toUtc().toIso8601String(),
      'participants': [
        {'user': 7, 'last_read_at': null},
        {'user': 12, 'last_read_at': null},
      ],
      'unread_count': 1,
      'notifications_muted': false,
    };
    if (path.endsWith('/messaging/threads/44/messages/')) {
      if (request.method == 'POST') return _ok(<String, Object?>{});
      return _page([
        {
          'id': 501,
          'thread': 44,
          'sender': 12,
          'body': 'Ertangi dars uchun material tayyor.',
          'attachments': <Object?>[],
          'created_at': DateTime.now().toUtc().toIso8601String(),
        },
        {
          'id': 502,
          'thread': 44,
          'sender': 7,
          'body': 'Rahmat, ustoz.',
          'attachments': <Object?>[],
          'created_at': DateTime.now()
              .toUtc()
              .add(const Duration(seconds: 1))
              .toIso8601String(),
        },
      ]);
    }
    if (path.endsWith('/messaging/threads/44/read/')) {
      return _ok({'status': 'ok'});
    }
    if (path.endsWith('/messaging/messages/502/reactions/')) {
      return _ok({'emoji': '👍', 'count': 1});
    }
    if (path.endsWith('/messaging/threads/44/')) return _ok(thread);
    if (path.endsWith('/messaging/threads/')) {
      return _page(withThread ? [thread] : <Object?>[]);
    }
    return http.Response(
      jsonEncode({'success': false, 'message': 'not found'}),
      404,
      headers: {'content-type': 'application/json'},
    );
  }),
);

http.Response _ok(Object? data) => http.Response(
  jsonEncode({'success': true, 'data': data}),
  200,
  headers: {'content-type': 'application/json'},
);

http.Response _page(Object? data, {Map<String, Object?> extra = const {}}) =>
    http.Response(
      jsonEncode({
        'success': true,
        'data': data,
        'pagination': {
          'total': data is List ? data.length : 0,
          'page': 1,
          'page_size': 100,
          'pages': 1,
          'has_next': false,
          'has_prev': false,
          ...extra,
        },
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
