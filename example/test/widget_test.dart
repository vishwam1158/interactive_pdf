// Widget test for the example app

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ExampleApp());

    // Verify that the app title is displayed
    expect(find.text('Advance PDF Generator'), findsOneWidget);

    // Verify that the generate PDF button exists
    expect(find.text('Generate PDF'), findsOneWidget);

    // Verify the PDF icon is present
    expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
  });
}
