import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_student/app_state.dart';
import 'package:starforge_student/main.dart';

void main() {
  setUpAll(() async {
    SfClock.now = () => DateTime(2026, 7, 26, 9);
    await (FontLoader(
      'Manrope',
    )..addFont(rootBundle.load('assets/fonts/Manrope.ttf'))).load();
    await (FontLoader('JetBrainsMono')
          ..addFont(rootBundle.load('assets/fonts/JetBrainsMono-Regular.ttf')))
        .load();
    await (FontLoader(
          'InstrumentSerif',
        )..addFont(rootBundle.load('assets/fonts/InstrumentSerif-Regular.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  tearDownAll(() {
    SfClock.now = DateTime.now;
  });

  Future<void> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const StarForgeApp());
    await tester.pumpAndSettle();
  }

  testWidgets('compact home visual regression', (tester) async {
    await pumpAt(tester, const Size(390, 844));
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/home_compact.png'),
    );
  });

  testWidgets('expanded home visual regression', (tester) async {
    await pumpAt(tester, const Size(1280, 900));
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/home_expanded.png'),
    );
  });

  testWidgets('compact services page stays focused on role services', (
    tester,
  ) async {
    await pumpAt(tester, const Size(390, 844));
    await tester.tap(find.text('Xizmatlar').last);
    await tester.pumpAndSettle();

    expect(find.text('Aqlli asboblar'), findsOneWidget);
    expect(find.text('AI repetitor'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Sozlamalar'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Sozlamalar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
