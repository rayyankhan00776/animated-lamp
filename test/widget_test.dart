import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:animated_lamp/main.dart';

void main() {
  testWidgets('Animated lamp app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpAndSettle();
    await tester.pumpWidget(const AnimatedLampApp());

    // Verify that the app starts with lamp off state
    expect(find.text('Lamp is OFF'), findsOneWidget);
    expect(find.text('Lamp is ON'), findsNothing);
    
    // Verify instruction text is present
    expect(find.text('Pull the string to toggle'), findsOneWidget);
  });

  testWidgets('Lamp screen contains key UI elements', (WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pumpWidget(const MaterialApp(home: LampScreen()));

    // Verify the LampScreen widget is present
    expect(find.byType(LampScreen), findsOneWidget);
    
    // Verify status text is present
    expect(find.textContaining('Lamp is'), findsOneWidget);
  });
}
