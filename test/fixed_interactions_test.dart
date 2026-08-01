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

  Future<void> pumpMobile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
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

  Future<void> openQuickService(WidgetTester tester, String id) async {
    await tapRich(tester, 'more');
    final item = find.byKey(ValueKey('home-quick-$id'));
    await tester.ensureVisible(item);
    await tester.pumpAndSettle();
    await tester.tap(item);
    await tester.pumpAndSettle();
  }

  testWidgets('global search opens grades instead of the default task tab', (
    tester,
  ) async {
    await pumpDesktop(tester);

    await tester.tap(find.byKey(const ValueKey('global-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Baholar');
    await tester.pump();
    await tester.tap(find.text('Baholar').last);
    await tester.pumpAndSettle();

    expect(find.text('Baholangan ishlar'), findsOneWidget);
    expect(find.textContaining('o‘rtachasi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notification routes open messages and protected payments', (
    tester,
  ) async {
    await pumpDesktop(tester);

    await tester.tap(find.byTooltip('Bildirishnomalar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('notice-n3')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Xabar yuborish'), findsOneWidget);

    await tapRich(tester, 'home');
    await switchProfile(tester, 'Akbarova Dilnoza');
    await tester.tap(find.byTooltip('Bildirishnomalar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('notice-n2')));
    await tester.pumpAndSettle();

    expect(find.text('To‘lovlar'), findsOneWidget);
    expect(find.text('Demo to‘lov'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notification center scopes roles and exposes unread history', (
    tester,
  ) async {
    await pumpDesktop(tester);

    await tester.tap(find.byTooltip('Bildirishnomalar'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notice-n1')), findsOneWidget);
    expect(find.byKey(const ValueKey('notice-n2')), findsNothing);
    expect(find.byKey(const ValueKey('notice-n3')), findsOneWidget);
    expect(find.text('Yangi'), findsWidgets);
    expect(find.text('Tarix'), findsOneWidget);

    await tester.tap(find.text('Barchasini o‘qish'));
    await tester.pumpAndSettle();
    expect(find.text('Barcha yangi xabarlar o‘qildi'), findsOneWidget);
    await tester.tap(find.text('Tarixni ochish'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notice-n1')), findsOneWidget);
    expect(find.byKey(const ValueKey('notice-n3')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('teacher chats isolate transcripts, drafts and mute state', (
    tester,
  ) async {
    await pumpDesktop(tester);
    await tapRich(tester, 'messages');

    expect(
      find.text('Akmal, 8-misol yechimini tekshirib chiqdim.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Bobur Aliyev').first);
    await tester.pumpAndSettle();
    expect(
      find.text('Ertaga uchburchaklar mavzusini davom ettiramiz.'),
      findsWidgets,
    );
    expect(
      find.text('Akmal, 8-misol yechimini tekshirib chiqdim.'),
      findsNothing,
    );

    await tester.enterText(find.byType(TextField).last, 'Bobur uchun draft');
    await tester.tap(find.text('Nigora Karimova').first);
    await tester.pump();
    await tester.tap(find.text('Bobur Aliyev').first);
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller?.text,
      'Bobur uchun draft',
    );

    await tester.tap(find.byTooltip('Bildirishnomalarni o‘chirish'));
    await tester.pump();
    await tapRich(tester, 'home');
    await tapRich(tester, 'messages');
    expect(find.byTooltip('Bildirishnomalarni yoqish'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'mobile messages open inbox first and support thread search mute and back',
    (tester) async {
      await pumpMobile(tester);

      await tester.tap(find.byTooltip('Xabarlar'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('message-thread-search')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('family-chat-header')), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('message-thread-student-thread-geometry')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('family-chat-header')), findsOneWidget);
      expect(
        find.text('Ertaga uchburchaklar mavzusini davom ettiramiz.'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Suhbat ichida qidirish'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('family-chat-search-header')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('family-chat-message-search')),
        'uchburchaklar',
      );
      await tester.pump();
      expect(
        find.text('Ertaga uchburchaklar mavzusini davom ettiramiz.'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Qidiruvni yopish'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Bildirishnomalarni o‘chirish'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Bildirishnomalarni yoqish'), findsOneWidget);

      await tester.tap(find.byTooltip('Suhbatlarga qaytish'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('message-thread-search')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('family-chat-header')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('attendance question becomes a role-scoped message draft', (
    tester,
  ) async {
    await pumpDesktop(tester);
    await switchProfile(tester, 'Akbarova Dilnoza');
    await openQuickService(tester, 'attendance');
    await tester.tap(find.text('Davomat haqida ustozga yozish'));
    await tester.pumpAndSettle();
    final draft = tester
        .widget<TextField>(find.byType(TextField).last)
        .controller
        ?.text;
    expect(draft, contains('davomat yozuvi'));

    await tapRich(tester, 'home');
    await tapRich(tester, 'messages');
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller?.text,
      draft,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('More exposes working tools and privacy hides payment history', (
    tester,
  ) async {
    await pumpDesktop(tester);
    expect(find.byKey(const ValueKey('rich-nav-toolkit')), findsOneWidget);

    await switchProfile(tester, 'Akbarova Dilnoza');
    await tapRich(tester, 'more');
    await tapRich(tester, 'settings');
    final hideAmounts = find.text('Summalarni yashirish');
    await tester.ensureVisible(hideAmounts);
    await tester.pumpAndSettle();
    await tester.tap(hideAmounts);
    await tester.pump();
    await tester.tap(find.byTooltip('Orqaga'));
    await tester.pumpAndSettle();
    final payments = find.byKey(const ValueKey('home-quick-payments'));
    await tester.ensureVisible(payments);
    await tester.pumpAndSettle();
    await tester.tap(payments);
    await tester.pumpAndSettle();

    expect(find.textContaining('600 000'), findsNothing);
    expect(find.textContaining('••• •••'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
