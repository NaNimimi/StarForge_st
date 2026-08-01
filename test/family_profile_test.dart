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

  Future<void> openTopProfile(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('open-family-profile-topbar')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('family-profile-screen')), findsOneWidget);
  }

  Future<void> switchToParent(WidgetTester tester) async {
    await tester.tap(
      find.byKey(const ValueKey('switch-family-cabinet-sidebar')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Akbarova Dilnoza').last);
    await tester.pumpAndSettle();
  }

  testWidgets('student profile is real, data-backed and editable', (
    tester,
  ) async {
    await pumpDesktop(tester);
    await openTopProfile(tester);

    expect(find.byKey(const ValueKey('family-profile-hero')), findsOneWidget);
    expect(find.text('O‘quvchi · 9-B'), findsOneWidget);
    expect(find.text('Namuna ma’lumotlari'), findsOneWidget);
    expect(find.text('100%'), findsWidgets);
    expect(find.text('88%'), findsWidgets);
    expect(find.byKey(const ValueKey('home-quick-profile-ai')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-quick-profile-payments')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('family-profile-edit')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Karimov Kamol');
    await tester.tap(find.text('Saqlash'));
    await tester.pumpAndSettle();

    expect(find.text('Karimov Kamol'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile quick actions open results and a prepared chat', (
    tester,
  ) async {
    await pumpDesktop(tester);
    await openTopProfile(tester);

    await tester.tap(find.byKey(const ValueKey('home-quick-profile-results')));
    await tester.pumpAndSettle();
    expect(find.text('Baholangan ishlar'), findsOneWidget);

    await openTopProfile(tester);
    await tester.tap(find.byKey(const ValueKey('home-quick-profile-message')));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Xabar yuborish'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller?.text,
      contains('savolim bor'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('parent sees linked child and parent-only payment action', (
    tester,
  ) async {
    await pumpDesktop(tester);
    await switchToParent(tester);
    await openTopProfile(tester);

    expect(
      find.byKey(const ValueKey('family-profile-student-summary')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('home-quick-profile-payments')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('home-quick-profile-ai')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('home-quick-profile-payments')));
    await tester.pumpAndSettle();
    expect(find.text('To‘lovlar'), findsOneWidget);
    expect(find.text('Demo to‘lov'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('More profile card opens profile instead of role picker', (
    tester,
  ) async {
    await pumpDesktop(tester);
    await tester.tap(find.byKey(const ValueKey('rich-nav-more')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('open-family-profile-more')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('family-profile-screen')), findsOneWidget);
    expect(find.text('Profilni almashtirish'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
