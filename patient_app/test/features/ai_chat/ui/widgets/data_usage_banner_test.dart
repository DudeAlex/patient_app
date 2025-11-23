import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/ai_chat/ui/widgets/data_usage_banner.dart';

void main() {
  testWidgets('renders space message and default context info', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DataUsageBanner(spaceName: 'Health'),
        ),
      ),
    );

    expect(find.textContaining('Health'), findsOneWidget);
    expect(find.textContaining('Context stays within this space'), findsOneWidget);
  });

  testWidgets('shows record title when provided', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DataUsageBanner(
            spaceName: 'Education',
            recordTitle: 'Physics Notes',
          ),
        ),
      ),
    );

    expect(find.textContaining('Physics Notes'), findsOneWidget);
  });

  testWidgets('invokes onDismissed when close tapped', (tester) async {
    var dismissed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DataUsageBanner(
            spaceName: 'Finance',
            onDismissed: () => dismissed = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(dismissed, isTrue);
  });
}
