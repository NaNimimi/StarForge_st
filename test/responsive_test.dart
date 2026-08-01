import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_student/main.dart';

void main() {
  Future<void> pumpAt(
    WidgetTester tester,
    Size size, {
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const StarForgeApp());
    await tester.pumpAndSettle();
  }

  void expectFiveRichDestinations() {
    for (final id in const ['home', 'tasks', 'calendar', 'messages', 'more']) {
      expect(
        find.byKey(ValueKey('rich-nav-$id'), skipOffstage: false),
        findsOneWidget,
      );
    }
  }

  testWidgets('320px compact phone renders without overflow', (tester) async {
    await pumpAt(tester, const Size(320, 568));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).destinations,
      hasLength(5),
    );
    expect(find.text('Salom, Akmal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rotated phone keeps five-item phone navigation', (tester) async {
    await pumpAt(tester, const Size(568, 320));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).destinations,
      hasLength(5),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('medium width uses five-item rail before expanded breakpoint', (
    tester,
  ) async {
    await pumpAt(tester, const Size(839, 900));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).destinations,
      hasLength(5),
    );
    expect(find.byKey(const ValueKey('rich-nav-home')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('expanded breakpoint starts with five full destinations', (
    tester,
  ) async {
    await pumpAt(tester, const Size(840, 900));

    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expectFiveRichDestinations();
    expect(tester.takeException(), isNull);
  });

  testWidgets('840px expanded shell supports 230 percent text', (tester) async {
    await pumpAt(tester, const Size(840, 900), textScale: 2.3);

    expect(find.byKey(const ValueKey('rich-nav-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('rich-nav-tasks')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('rich-nav-more')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const ValueKey('rich-nav-more')), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Salom, Akmal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    '320px at 200% keeps Study tabs visible and opens chat from inbox',
    (tester) async {
      await pumpAt(tester, const Size(320, 720), textScale: 2);
      expect(
        find.byKey(const ValueKey('accessible-bottom-navigation')),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('O‘qish'));
      await tester.pumpAndSettle();
      for (final id in const ['tasks', 'grades', 'materials']) {
        expect(find.byKey(ValueKey('study-tab-$id')), findsOneWidget);
      }
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Xabarlar'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('message-thread-search')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('family-chat-header')), findsNothing);
      expect(find.byTooltip('Xabar yuborish'), findsNothing);

      final thread = find.byKey(
        const ValueKey('message-thread-student-thread-algebra'),
      );
      await tester.drag(
        find.byKey(const ValueKey('message-thread-list')),
        const Offset(0, -80),
      );
      await tester.pumpAndSettle();
      await tester.tap(thread);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('family-chat-header')), findsOneWidget);
      expect(find.byTooltip('Suhbatlarga qaytish'), findsOneWidget);
      expect(find.byTooltip('Xabar yuborish'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('system scaling combines with large-text accessibility setting', (
    tester,
  ) async {
    await pumpAt(tester, const Size(390, 844), textScale: 2);
    final before = MediaQuery.of(
      tester.element(find.byType(Scaffold).first),
    ).textScaler.scale(1);
    expect(before, closeTo(2, 0.01));

    await tester.tap(find.byTooltip('Xizmatlar'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -6000));
    await tester.pumpAndSettle();
    final settings = find.text('Sozlamalar').last;
    await tester.ensureVisible(settings);
    await tester.pumpAndSettle();
    await tester.tap(settings);
    await tester.pumpAndSettle();
    final largeText = find.text('Katta matn');
    await tester.ensureVisible(largeText);
    await tester.pumpAndSettle();
    await tester.tap(largeText);
    await tester.pumpAndSettle();

    final after = MediaQuery.of(
      tester.element(find.byType(Scaffold).last),
    ).textScaler.scale(1);
    expect(after, closeTo(2.3, 0.01));
    expect(tester.takeException(), isNull);
  });
}
