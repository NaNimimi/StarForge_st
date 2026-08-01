import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_student/main.dart';

void main() {
  Future<void> pumpDesktop(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const StarForgeApp());
    await tester.pumpAndSettle();
  }

  Future<void> tapRich(WidgetTester tester, String id) async {
    final item = find.byKey(ValueKey('rich-nav-$id'));
    final navigation = find.byType(Scrollable).first;
    await tester.drag(navigation, const Offset(0, 10000));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(item, 240, scrollable: navigation);
    await tester.pumpAndSettle();
    await tester.tap(item);
    await tester.pumpAndSettle();
  }

  Future<void> switchProfile(WidgetTester tester, String profileName) async {
    await tester.tap(
      find.byKey(const ValueKey('switch-family-cabinet-sidebar')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(profileName).last);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'mobile-first shell has five real destinations and search works',
    (tester) async {
      await pumpDesktop(tester);

      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byKey(const ValueKey('rich-nav-home')), findsOneWidget);
      expect(find.byKey(const ValueKey('rich-nav-tasks')), findsOneWidget);
      expect(find.byKey(const ValueKey('rich-nav-calendar')), findsOneWidget);
      expect(find.byKey(const ValueKey('rich-nav-messages')), findsOneWidget);
      expect(find.text('Salom, Akmal'), findsOneWidget);
      for (final label in const [
        'Bosh sahifa',
        'Vazifalar',
        'Jadval',
        'Xabarlar',
        'Barcha xizmatlar',
      ]) {
        expect(find.text(label), findsWidgets);
      }

      await tester.tap(find.byKey(const ValueKey('global-search')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'jadval');
      await tester.pump();
      await tester.tap(find.text('Jadval').last);
      await tester.pumpAndSettle();

      expect(find.text('Reja va voqealar'.toUpperCase()), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'task completion and personal task creation have visible result',
    (tester) async {
      await pumpDesktop(tester);
      await tapRich(tester, 'tasks');

      // Teacher assignments reflect submission state and are intentionally
      // not locally toggleable.
      expect(find.byType(Checkbox), findsNothing);

      await tester.tap(find.text('Shaxsiy vazifa'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField),
        'Fizika formulasini takrorlash',
      );
      await tester.tap(find.text('Vazifa qo‘shish'));
      await tester.pumpAndSettle();

      expect(find.text('Fizika formulasini takrorlash'), findsWidgets);
      final personalCheckbox = find.byType(Checkbox);
      expect(personalCheckbox, findsOneWidget);
      await tester.tap(personalCheckbox);
      await tester.pump();
      expect(tester.widget<Checkbox>(personalCheckbox).value, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('message composer and new conversation really work', (
    tester,
  ) async {
    await pumpDesktop(tester);
    await tapRich(tester, 'messages');

    await tester.enterText(find.byType(TextField).last, 'Yangi test xabari');
    await tester.tap(find.byTooltip('Xabar yuborish'));
    await tester.pump();
    expect(find.text('Yangi test xabari'), findsOneWidget);

    await tester.tap(find.byTooltip('Suhbatni tanlash').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bobur Aliyev').last);
    await tester.pumpAndSettle();

    expect(find.text('Bobur Aliyev'), findsWidgets);
    expect(find.text('Assalomu alaykum, '), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('calendar form adds an event and returns to selected date', (
    tester,
  ) async {
    await pumpDesktop(tester);
    await tapRich(tester, 'calendar');
    await tester.tap(find.byTooltip('Shaxsiy reja qo‘shish'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'Biologiya takrorlash',
    );
    await tester.tap(find.text('Voqeani saqlash'));
    await tester.pumpAndSettle();

    expect(find.text('Biologiya takrorlash'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('calendar blocks a personal event over a school lesson', (
    tester,
  ) async {
    await pumpDesktop(tester);
    await tapRich(tester, 'calendar');
    await tester.tap(find.byTooltip('Shaxsiy reja qo‘shish'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'Algebra vaqtida uchrashuv',
    );
    await tester.tap(find.text('17:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('09:00').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voqeani saqlash'));
    await tester.pumpAndSettle();

    expect(find.text('Vaqt band'), findsOneWidget);
    expect(find.textContaining('boshqa dars'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('parent role exposes payment and payment completes once', (
    tester,
  ) async {
    await pumpDesktop(tester);

    await switchProfile(tester, 'Akbarova Dilnoza');
    expect(find.text('Oila nazorati'), findsOneWidget);

    await tapRich(tester, 'payments');
    await tester.tap(find.text('Demo to‘lov'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('To‘lovni tasdiqlash'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('Kvitansiyani ochish'), findsOneWidget);
    expect(find.text('To‘langan'), findsWidgets);

    await tester.tap(find.text('Iyul · 600 000 so‘m'));
    await tester.pumpAndSettle();
    expect(find.text('Iyul 2026 kvitansiyasi'), findsOneWidget);
    expect(find.textContaining('SF-240701'), findsWidgets);
    await tester.tap(find.text('Yopish'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('announcement actions and local support draft persist visibly', (
    tester,
  ) async {
    await pumpDesktop(tester);
    await tapRich(tester, 'announcements');
    await tester.tap(find.byTooltip('Mahkamlash').first);
    await tester.pump();
    expect(find.byTooltip('Mahkamlashni bekor qilish'), findsOneWidget);
    await tester.tap(find.byTooltip('Orqaga'));
    await tester.pumpAndSettle();

    await tapRich(tester, 'support');
    await tester.tap(find.text('Lokal murojaat yaratish'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField),
      'Taqvim bo‘limi uchun yangi taklifim bor',
    );
    await tester.tap(find.text('Draftni saqlash'));
    await tester.pumpAndSettle();

    expect(find.text('Lokal murojaatlar'), findsOneWidget);
    expect(find.text('Lokal draft'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark mode setting changes the active theme', (tester) async {
    await pumpDesktop(tester);
    await tapRich(tester, 'settings');

    await tester.tap(find.text('Qorong‘i rejim'));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Scaffold).last);
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(tester.takeException(), isNull);
  });

  testWidgets('grade question opens a real prepared teacher conversation', (
    tester,
  ) async {
    await pumpDesktop(tester);
    await tapRich(tester, 'grades');
    await tester.scrollUntilVisible(
      find.text('Algebra testi'),
      260,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Algebra testi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ustozga savol berish'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Algebra testi (94%)'), findsOneWidget);
    expect(find.byTooltip('Xabar yuborish'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('material preview and favorites expose visible state', (
    tester,
  ) async {
    await pumpDesktop(tester);
    await tapRich(tester, 'materials');

    await tester.tap(find.byTooltip('Tanlanganlarga qo‘shish').last);
    await tester.pump();
    expect(find.byTooltip('Tanlanganlardan olib tashlash'), findsWidgets);

    await tester.tap(find.text('Kvadrat tenglamalar'));
    await tester.pumpAndSettle();
    expect(find.text('Material ma’lumoti'), findsOneWidget);
    expect(find.textContaining('Family server'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('attendance question and AI answer produce persistent outcomes', (
    tester,
  ) async {
    await pumpDesktop(tester);
    await switchProfile(tester, 'Akbarova Dilnoza');
    await tapRich(tester, 'attendance');
    await tester.tap(find.text('Davomat haqida ustozga yozish'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller?.text,
      contains('davomat yozuvi'),
    );

    await switchProfile(tester, 'Akbarov Akmal');
    await tapRich(tester, 'ai');
    await tester.enterText(
      find.byType(TextField).last,
      'Diskriminantni tushuntir',
    );
    final send = find.byKey(const ValueKey('ai-send'));
    await tester.ensureVisible(send);
    await tester.pumpAndSettle();
    await tester.tap(send);
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pumpAndSettle();

    expect(find.textContaining('Kvadrat tenglama ax²'), findsOneWidget);
    expect(find.text('Lokal demo'), findsOneWidget);
    await tester.tap(find.byTooltip('Orqaga'));
    await tester.pumpAndSettle();
    await tapRich(tester, 'ai');
    expect(find.textContaining('Kvadrat tenglama ax²'), findsOneWidget);
    await tester.tap(find.byTooltip('Tarixni tozalash'));
    await tester.pumpAndSettle();
    expect(find.text('Suhbatni tozalash?'), findsOneWidget);
    await tester.tap(find.text('Bekor qilish'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Kvadrat tenglama ax²'), findsOneWidget);
    await tester.tap(find.byTooltip('Tarixni tozalash'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ai-clear-confirm')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Kvadrat tenglama ax²'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
