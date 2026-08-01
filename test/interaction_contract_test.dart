import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('active UI has no empty, placeholder or notification-only callbacks', () {
    final source = File('lib/redesign_app.dart').readAsStringSync();

    final callbacks = RegExp(
      r'on(?:Pressed|Tap|Changed|Selected|Submitted|DestinationSelected|SelectionChanged)\s*:',
    ).allMatches(source);
    final emptyCallbacks = RegExp(
      r'on(?:Pressed|Tap|Changed|Selected|Submitted)\s*:\s*\([^)]*\)\s*\{\s*\}',
      multiLine: true,
    ).allMatches(source);
    final notificationOnlyCallbacks = RegExp(
      r'on(?:Pressed|Tap)\s*:\s*\([^)]*\)\s*\{\s*(?:widget\.)?announce\([^;]*;\s*\}',
      multiLine: true,
      dotAll: true,
    ).allMatches(source);
    final notificationOnlyExpressions = RegExp(
      r'on(?:Pressed|Tap)\s*:\s*\([^)]*\)\s*=>\s*(?:widget\.)?announce\(',
      multiLine: true,
    ).allMatches(source);

    expect(callbacks.length, greaterThanOrEqualTo(85));
    expect(emptyCallbacks, isEmpty);
    expect(notificationOnlyCallbacks, isEmpty);
    expect(notificationOnlyExpressions, isEmpty);
    expect(source, isNot(contains('UnimplementedError')));
    expect(source, isNot(contains('UnsupportedError')));
    expect(source, isNot(contains('TODO')));
    expect(source, isNot(contains('FIXME')));
    expect(source, contains('FeatureRoute.toolkit'));
    expect(source, isNot(contains('Biriktirma qo‘shish')));
    expect(source, isNot(contains('Offline saqlash')));
  });
}
