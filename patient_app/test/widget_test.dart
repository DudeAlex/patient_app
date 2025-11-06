// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/ui/app.dart';

void main() {
  testWidgets(
    'App renders scaffold with settings and add actions',
    (tester) async {
    await tester.pumpWidget(const PatientApp());
    await tester.pump(); // allow initial FutureBuilders to progress

    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  }, skip: true // RecordsService depends on platform channels unavailable in headless widget tests.
      );
}
