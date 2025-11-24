import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/ai_chat/ui/widgets/action_hints_row.dart';

void main() {
  testWidgets('renders chips for hints', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ActionHintsRow(
            hints: ['Do A', 'Do B'],
          ),
        ),
      ),
    );

    expect(find.byType(ActionChip), findsNWidgets(2));
    expect(find.text('Do A'), findsOneWidget);
    expect(find.text('Do B'), findsOneWidget);
  });

  testWidgets('invokes callback on tap', (tester) async {
    var tapped = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActionHintsRow(
            hints: const ['Take action'],
            onHintTapped: (hint) => tapped = hint,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ActionChip));
    await tester.pumpAndSettle();

    expect(tapped, 'Take action');
  });

  testWidgets('renders nothing for empty hints', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ActionHintsRow(hints: []),
        ),
      ),
    );

    expect(find.byType(ActionChip), findsNothing);
  });
}
