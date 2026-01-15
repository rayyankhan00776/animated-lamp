// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:animatedlamp/main.dart';

void main() {
  testWidgets('Lamp toggles when pulling the string', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MyApp());

    final lampStateFinder = find.byKey(const Key('lamp_state'));
    expect(lampStateFinder, findsOneWidget);

    Semantics lampState() => tester.widget<Semantics>(lampStateFinder);
    expect(lampState().properties.value, 'off');

    // Tap the pull handle.
    await tester.tap(find.byKey(const Key('pull_handle')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(lampState().properties.value, 'on');

    // Tap again to turn it off.
    await tester.tap(find.byKey(const Key('pull_handle')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(lampState().properties.value, 'off');
  });
}
