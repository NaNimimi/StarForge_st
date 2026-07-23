// Smoke test for the StarForge EDU Family app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:starforge_student/main.dart';

void main() {
  testWidgets('Family shell renders parent home', (WidgetTester tester) async {
    // Desktop-sized surface so the sidebar layout is exercised.
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const StarForgeApp());
    await tester.pump();

    // Parent nav entries are present in the sidebar.
    expect(find.text('Bosh sahifa'), findsWidgets);
    expect(find.text('Farzandim'), findsOneWidget);
    expect(find.text('To‘lovlar'), findsOneWidget);
  });
}
