import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:starforge_student/app_state.dart';
import 'package:starforge_student/theme.dart';
import 'package:starforge_student/toolkit.dart';

void main() {
  test('toolkit catalog has 40 unique functions for each role', () {
    final allIds = ToolkitFeatureCatalog.features
        .map((feature) => feature.id)
        .toList();
    final student = ToolkitFeatureCatalog.forRole(isParent: false);
    final parent = ToolkitFeatureCatalog.forRole(isParent: true);

    expect(allIds.toSet(), hasLength(allIds.length));
    expect(student, hasLength(40));
    expect(parent, hasLength(40));
    expect(
      ToolkitActionKind.values.every(
        (kind) => student.any((feature) => feature.kind == kind),
      ),
      isTrue,
    );
  });

  Future<AppState> pumpToolkit(
    WidgetTester tester, {
    bool isParent = false,
    Size size = const Size(800, 900),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState();
    addTearDown(state.dispose);
    await tester.pumpWidget(
      AppScope(
        state: state,
        child: MaterialApp(
          theme: Sf.theme(),
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(textScale),
            ),
            child: ToolkitPage(isParent: isParent, announce: (_, {detail}) {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return state;
  }

  testWidgets('all toolkit action types create persistent visible outcomes', (
    tester,
  ) async {
    final state = await pumpToolkit(tester);

    await tester.ensureVisible(
      find.byKey(const ValueKey('toolkit-break_schedule')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('toolkit-break_schedule')));
    await tester.pump();
    expect(state.toolkitToggles['break_schedule'], isTrue);

    await tester.ensureVisible(
      find.byKey(const ValueKey('toolkit-quick_note')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('toolkit-quick_note')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('toolkit-input-quick_note')),
      'Algebra formulalarini takrorlash',
    );
    await tester.tap(find.byKey(const ValueKey('toolkit-save-quick_note')));
    await tester.pumpAndSettle();
    expect(
      state.toolkitValues['quick_note'],
      'Algebra formulalarini takrorlash',
    );
    expect(find.text('Algebra formulalarini takrorlash'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('toolkit-search')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('toolkit-search')),
      'Fokus davomiyligi',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('toolkit-focus_length')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('toolkit-option-focus_length-25 daqiqa')),
    );
    await tester.pumpAndSettle();
    expect(state.toolkitValues['focus_length'], '25 daqiqa');

    await tester.ensureVisible(find.byKey(const ValueKey('toolkit-search')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('toolkit-search')),
      'Suv hisoblagichi',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('toolkit-water')));
    await tester.pump();
    expect(state.toolkitCounters['water'], 1);
    expect(find.text('1'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('toolkit-search')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('toolkit-search')),
      'Lokal zaxira',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('toolkit-backup_snapshot')));
    await tester.pumpAndSettle();
    expect(state.toolkitValues['backup_snapshot'], contains('sozlama'));
    expect(find.text('Lokal snapshot tayyor'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    await tester.tap(find.text('Tarixni ochish'));
    await tester.pumpAndSettle();
    expect(find.text('Faollik tarixi'), findsOneWidget);
    expect(find.text('Lokal zaxira nusxa'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('action tools open persistent results instead of snackbar-only', (
    tester,
  ) async {
    final state = await pumpToolkit(tester);

    await tester.enterText(
      find.byKey(const ValueKey('toolkit-search')),
      'Svodkani nusxalash',
    );
    await tester.pump();
    final export = find.byKey(const ValueKey('toolkit-export_summary'));
    await tester.ensureVisible(export);
    await tester.pumpAndSettle();
    await tester.tap(export);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(state.toolkitValues['export_summary'], contains('band nusxalandi'));
    expect(find.text('Svodka nusxalandi'), findsOneWidget);
    expect(find.textContaining('clipboardga nusxalandi'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    await tester.tap(find.text('Yopish'));
    await tester.pumpAndSettle();
    expect(find.textContaining('band nusxalandi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('toolkit search, role tools and reset work at 320px 200%', (
    tester,
  ) async {
    final state = await pumpToolkit(
      tester,
      isParent: true,
      size: const Size(320, 720),
      textScale: 2,
    );

    await tester.enterText(
      find.byKey(const ValueKey('toolkit-search')),
      'Ota-ona haftalik',
    );
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('toolkit-parent_digest')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ota-ona haftalik svodkasi'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('toolkit-parent_digest')));
    await tester.pump();
    expect(state.toolkitToggles['parent_digest'], isTrue);

    await tester.tap(find.byKey(const ValueKey('toolkit-reset')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('toolkit-reset-confirm')));
    await tester.pumpAndSettle();

    expect(state.toolkitToggles, isEmpty);
    expect(state.toolkitActivity, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
