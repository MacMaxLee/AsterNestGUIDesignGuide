// This is a basic Flutter widget test for the AIS Demo App.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ais_demo_app/main.dart';

void main() {
  testWidgets('AIS Demo App loads home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AisDemoApp());

    // Verify that the app title is present.
    expect(find.text('AIS v1.0 Demo'), findsOneWidget);

    // Verify menu items are present.
    expect(find.text('Semantic Tokens'), findsOneWidget);
    expect(find.text('List-Detail Shell'), findsOneWidget);
  });
}
