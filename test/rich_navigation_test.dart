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

  void expectFullNavigation({required bool parent}) {
    for (final id in const [
      'home',
      'tasks',
      'grades',
      'materials',
      'calendar',
      'messages',
      'attendance',
      'achievements',
      'announcements',
      'toolkit',
      'more',
      'profile',
      'settings',
      'support',
    ]) {
      expect(
        find.byKey(ValueKey('rich-nav-$id'), skipOffstage: false),
        findsOneWidget,
        reason: '$id must be directly reachable from the full navigation',
      );
    }
    expect(
      find.byKey(const ValueKey('rich-nav-payments'), skipOffstage: false),
      parent ? findsOneWidget : findsNothing,
    );
    expect(
      find.byKey(const ValueKey('rich-nav-ai'), skipOffstage: false),
      parent ? findsNothing : findsOneWidget,
    );
  }

  testWidgets('phone keeps five bottom tabs and exposes a full drawer', (
    tester,
  ) async {
    await pumpAt(tester, const Size(390, 844));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      tester.widgetList<NavigationDestination>(
        find.byType(NavigationDestination),
      ),
      hasLength(5),
    );

    await tester.tap(find.byKey(const ValueKey('open-rich-navigation')));
    await tester.pumpAndSettle();
    expectFullNavigation(parent: false);

    await tester.tap(find.byKey(const ValueKey('rich-nav-grades')));
    await tester.pumpAndSettle();
    expect(find.text('Baholangan ishlar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('medium rail drawer opens services and toolkit', (tester) async {
    await pumpAt(tester, const Size(700, 900));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.byTooltip('Barcha bo‘limlar'));
    await tester.pumpAndSettle();
    expectFullNavigation(parent: false);

    final toolkit = find.byKey(const ValueKey('rich-nav-toolkit'));
    await tester.scrollUntilVisible(
      toolkit,
      240,
      scrollable: find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(toolkit);
    await tester.pumpAndSettle();
    expect(find.text('Aqlli asboblar'), findsOneWidget);
    expect(find.byKey(const ValueKey('toolkit-search')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('expanded direct study destinations stay synchronized', (
    tester,
  ) async {
    await pumpAt(tester, const Size(1280, 900));
    expectFullNavigation(parent: false);

    await tester.tap(find.byKey(const ValueKey('rich-nav-materials')));
    await tester.pumpAndSettle();
    expect(find.text('O‘quv materiallari'), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(const ValueKey('study-tab-materials')))
          .selected,
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('rich-nav-tasks')));
    await tester.pumpAndSettle();
    expect(find.text('Faol vazifalar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile opening and cabinet switching are separate actions', (
    tester,
  ) async {
    await pumpAt(tester, const Size(1280, 900));

    await tester.tap(find.byKey(const ValueKey('open-family-profile-topbar')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('family-profile-screen')), findsOneWidget);
    expect(find.text('Profilni almashtirish'), findsNothing);

    await tester.tap(find.byTooltip('Orqaga'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('switch-family-cabinet-sidebar')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Profilni almashtirish'), findsOneWidget);
    await tester.tap(find.text('Akbarova Dilnoza').last);
    await tester.pumpAndSettle();

    expect(find.text('Oila nazorati'), findsOneWidget);
    expectFullNavigation(parent: true);
    expect(tester.takeException(), isNull);
  });

  testWidgets('full drawer remains usable at 320px and 200 percent text', (
    tester,
  ) async {
    await pumpAt(tester, const Size(320, 720), textScale: 2);

    await tester.tap(find.byKey(const ValueKey('open-rich-navigation')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('rich-nav-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('rich-nav-tasks')), findsOneWidget);

    final profile = find.byKey(const ValueKey('rich-nav-profile'));
    await tester.scrollUntilVisible(
      profile,
      260,
      scrollable: find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(profile);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('family-profile-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
