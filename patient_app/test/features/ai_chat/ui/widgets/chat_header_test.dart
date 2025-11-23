import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/features/ai_chat/ui/widgets/chat_header.dart';

void main() {
  testWidgets('renders context chip and status pill', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: ChatHeader(
            spaceName: 'Health',
            spaceIcon: Icons.favorite,
            status: ChatHeaderStatus.fake,
            onClearChat: _noop,
            onChangeContext: _noop,
          ),
        ),
      ),
    );

    expect(find.text('Health'), findsOneWidget);
    expect(find.text('Fake'), findsOneWidget);
  });

  testWidgets('invokes callbacks from overflow menu', (tester) async {
    var cleared = false;
    var changed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: ChatHeader(
            spaceName: 'Health',
            spaceIcon: Icons.favorite,
            status: ChatHeaderStatus.remote,
            onClearChat: () => cleared = true,
            onChangeContext: () => changed = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clear Chat'));
    await tester.pumpAndSettle();
    expect(cleared, isTrue);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change Context'));
    await tester.pumpAndSettle();
    expect(changed, isTrue);
  });
}

void _noop() {}
