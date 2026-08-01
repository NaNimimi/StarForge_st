import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_student/app_state.dart';
import 'package:starforge_student/theme.dart';
import 'package:starforge_student/widgets.dart';

class _QueuedAiTransport implements AiTutorTransport {
  final List<Completer<Object?>> requests = [];

  @override
  String get connectionLabel => 'Test backend';

  @override
  bool get isLocalDemo => false;

  @override
  Future<Object?> send(String prompt) {
    final request = Completer<Object?>();
    requests.add(request);
    return request.future;
  }
}

void main() {
  group('AppState', () {
    test('notification read state is consistent', () {
      final state = AppState();

      expect(state.unreadNoticeCount, 3);
      state.markNoticeRead('n1');
      expect(state.unreadNoticeCount, 2);
      state.markAllNoticesRead();
      expect(state.unreadNoticeCount, 0);
    });

    test('notification payload aliases normalize, scope and deduplicate', () {
      final state = AppState();
      addTearDown(state.dispose);
      final received = state.receiveNoticePayload({
        'notification_id': 'server-1',
        'subject': 'Yangi vazifa',
        'message': 'Algebra 12-misol',
        'sent_at': SfClock.now().toIso8601String(),
        'recipient_role': 'student',
        'category': 'homework',
        'destination': 'tasks',
        'is_read': false,
        'data': {'entity_id': 'task-12'},
      });

      expect(received, isTrue);
      expect(state.notices.first.destination, NoticeDestination.study);
      expect(state.notices.first.audience, NoticeAudience.student);
      expect(state.notices.first.entityId, 'task-12');
      expect(state.noticesForRole('student').first.id, 'server-1');
      expect(
        state.noticesForRole('parent').map((notice) => notice.id),
        isNot(contains('server-1')),
      );

      state.receiveNoticePayload({
        'id': 'server-1',
        'title': 'Vazifa yangilandi',
        'body': 'Muddat ertaga',
        'route': 'homework',
      });
      expect(
        state.notices.where((notice) => notice.id == 'server-1'),
        hasLength(1),
      );
      expect(state.notices.first.title, 'Vazifa yangilandi');
      expect(state.receiveNoticePayload({'id': 'broken'}), isFalse);
    });

    test('AI payload supports nested aliases and optional sources', () {
      final response = AiTutorResponse.fromPayload({
        'data': {
          'response': 'Server javobi',
          'request_id': 'req-42',
          'citations': [
            {'name': 'Algebra darsligi', 'section': '42-bet'},
            '',
          ],
        },
      });

      expect(response.answer, 'Server javobi');
      expect(response.requestId, 'req-42');
      expect(response.sources.single.title, 'Algebra darsligi');
    });

    test(
      'AI cancellation token prevents an old response entering a new chat',
      () async {
        final transport = _QueuedAiTransport();
        final state = AppState(aiTransport: transport);
        addTearDown(state.dispose);

        final first = state.askAi('Birinchi savol');
        expect(state.aiGenerating, isTrue);
        state.cancelAiRequest();
        final second = state.askAi('Ikkinchi savol');

        transport.requests.first.complete({'answer': 'Eski javob'});
        await first;
        expect(
          state.aiMessages.map((message) => message.text),
          isNot(contains('Eski javob')),
        );

        transport.requests.last.complete({
          'data': {'answer': 'Yangi javob', 'request_id': 'new-response'},
        });
        expect(await second, isTrue);
        expect(state.aiMessages.last.text, 'Yangi javob');
        expect(state.aiGenerating, isFalse);
      },
    );

    test('AI failure can retry without duplicating the question', () async {
      final transport = _QueuedAiTransport();
      final state = AppState(aiTransport: transport);
      addTearDown(state.dispose);

      final first = state.askAi('Retry qilinadigan savol');
      transport.requests.first.completeError(Exception('offline'));
      expect(await first, isFalse);
      expect(state.aiMessages, hasLength(1));
      expect(state.aiError, isNotNull);

      final retry = state.retryLastAiPrompt();
      transport.requests.last.complete({'answer': 'Tiklangan javob'});
      expect(await retry, isTrue);
      expect(state.aiMessages, hasLength(2));
      expect(state.aiMessages.last.text, 'Tiklangan javob');
      expect(state.aiError, isNull);
    });

    test('task and material toggles are reversible', () {
      final state = AppState();

      state.toggleTask('algebra-equations');
      expect(state.completedTasks, contains('algebra-equations'));
      state.toggleTask('algebra-equations');
      expect(state.completedTasks, isNot(contains('algebra-equations')));

      state.toggleFavoriteMaterial('material-601');
      expect(state.favoriteMaterials, isNot(contains('material-601')));
      state.toggleFavoriteMaterial('material-601');
      expect(state.favoriteMaterials, contains('material-601'));
    });

    test('demo payment is idempotent', () {
      final state = AppState();
      final initialNotices = state.notices.length;

      state.completePayment('Click');
      final firstReceipt = state.receiptNumber;
      state.completePayment('Payme');

      expect(state.paymentCompleted, isTrue);
      expect(state.receiptNumber, firstReceipt);
      expect(state.paymentMethod, 'Click');
      expect(state.notices.length, initialNotices + 1);
      expect(state.notices.first.route, 'payments');
    });

    test('profile names are trimmed and validated', () {
      final state = AppState();

      state.setProfileName('student', '  Akmaljon Akbarov  ');
      expect(state.profileNames['student'], 'Akmaljon Akbarov');
      state.setProfileName('student', 'A');
      expect(state.profileNames['student'], 'Akmaljon Akbarov');
    });

    test('calendar, announcements and support state stay consistent', () {
      final state = AppState();
      final event = PersonalCalendarEvent(
        id: 'event-test',
        title: 'Test voqea',
        category: 'Shaxsiy',
        date: DateTime(2026, 7, 25),
        time: '17:00',
        notes: 'Izoh',
      );
      final ticket = SupportTicket(
        id: 'SF-TEST',
        topic: 'Taklif',
        message: 'Yangi imkoniyat uchun taklif',
        priority: 'Oddiy',
        createdAt: DateTime(2026, 7, 25),
      );

      state.addPersonalEvent(event);
      state.toggleCalendarReminder(event.id);
      state.markAnnouncementRead('announcement-olympiad');
      state.togglePinnedAnnouncement('announcement-olympiad');
      state.createSupportTicket(ticket);

      expect(state.personalEvents.single.id, event.id);
      expect(state.calendarReminders, contains(event.id));
      expect(state.readAnnouncements, contains('announcement-olympiad'));
      expect(state.pinnedAnnouncements, contains('announcement-olympiad'));
      expect(state.supportTickets.single.id, ticket.id);

      state.removePersonalEvent(event.id);
      expect(state.personalEvents, isEmpty);
      expect(state.calendarReminders, isNot(contains(event.id)));
    });

    test('toolkit actions persist values, counters, toggles and history', () {
      final state = AppState();

      state.setToolkitToggle('break_schedule', 'Tanaffus', true);
      state.setToolkitValue('quick_note', 'Tezkor qayd', 'Algebra 18:00');
      state.incrementToolkitCounter('water', 'Suv');
      state.incrementToolkitCounter('water', 'Suv');
      state.recordToolkitAction('backup_snapshot', 'Snapshot', '3 sozlama');

      expect(state.toolkitToggles['break_schedule'], isTrue);
      expect(state.toolkitValues['quick_note'], 'Algebra 18:00');
      expect(state.toolkitCounters['water'], 2);
      expect(state.toolkitActivity, hasLength(5));
      expect(state.toolkitActivity.first.title, 'Snapshot');

      state.clearToolkitWorkspace();
      expect(state.toolkitToggles, isEmpty);
      expect(state.toolkitValues, isEmpty);
      expect(state.toolkitCounters, isEmpty);
      expect(state.toolkitActivity, isEmpty);
    });

    test('parent reminder and attendance reason are session-persistent', () {
      final state = AppState();

      expect(state.markParentReminderSent('algebra-equations'), isTrue);
      expect(state.markParentReminderSent('algebra-equations'), isFalse);
      state.addAttendanceExplanation('Shifokor ko‘rigida edi');

      expect(state.sentParentReminders, contains('algebra-equations'));
      expect(state.attendanceExplanations, ['Shifokor ko‘rigida edi']);
    });

    test('full demo reset restores the original snapshot', () {
      final state = AppState();
      state.setProfileName('student', 'O‘zgargan ism');
      state.setNotificationPreference('push', false);
      state.setLargeText(true);
      state.setHideAmounts(true);
      state.setDarkMode(true);
      state.setHighContrast(true);
      state.markAllNoticesRead();
      state.completePayment('Payme');
      state.addGoal(
        const StudyGoal(
          id: 'custom-goal',
          title: 'Test maqsad',
          subject: 'Test',
          current: 1,
          target: 2,
        ),
      );
      state.createSupportTicket(
        SupportTicket(
          id: 'SF-RESET',
          topic: 'Test',
          message: 'Reset bilan o‘chiriladi',
          priority: 'Oddiy',
          createdAt: DateTime(2026, 7, 25),
        ),
      );
      state.setToolkitToggle('break_schedule', 'Tanaffus', true);
      state.addAttendanceExplanation('Reset bilan o‘chiriladi');
      state.markParentReminderSent('algebra-equations');

      state.resetDemoSession();

      expect(state.resetSignal.value, 1);
      expect(state.profileNames['student'], 'Akbarov Akmal');
      expect(state.notificationPreferences['push'], isTrue);
      expect(state.largeText, isFalse);
      expect(state.hideAmounts, isFalse);
      expect(state.darkMode, isFalse);
      expect(state.highContrast, isFalse);
      expect(state.paymentCompleted, isFalse);
      expect(state.paymentMethod, isNull);
      expect(state.receiptNumber, isNull);
      expect(state.notices.length, 3);
      expect(state.unreadNoticeCount, 3);
      expect(state.goals.map((goal) => goal.id), [
        'goal-algebra',
        'goal-reading',
      ]);
      expect(state.supportTickets, isEmpty);
      expect(state.toolkitActivity, isEmpty);
      expect(state.attendanceExplanations, isEmpty);
      expect(state.sentParentReminders, isEmpty);
    });
  });

  test('money uses readable Uzbek grouping', () {
    expect(money(600000), '600 000 so‘m');
    expect(money(12500000), '12 500 000 so‘m');
  });

  test('high contrast changes outlines in light and dark themes', () {
    expect(
      Sf.theme().colorScheme.outline,
      isNot(Sf.theme(highContrast: true).colorScheme.outline),
    );
    expect(
      Sf.darkTheme().colorScheme.outline,
      isNot(Sf.darkTheme(highContrast: true).colorScheme.outline),
    );
  });
}
