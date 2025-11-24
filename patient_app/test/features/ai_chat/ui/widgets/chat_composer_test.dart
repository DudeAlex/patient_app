import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/models/message_attachment.dart';
import 'package:patient_app/features/ai_chat/ui/widgets/chat_composer.dart';

void main() {
  testWidgets('send enabled with text and calls onSend', (tester) async {
    var sentText = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatComposer(
            onSend: (text) => sentText = text,
          ),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('chat_composer_input')), 'Hello');
    await tester.pump();
    
    // Check send button enablement
    final sendButton = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send));
    expect(sendButton.onPressed, isNotNull);
    
    // Manually invoke
    sendButton.onPressed?.call();
    expect(sentText, 'Hello');
  });

  testWidgets('send enabled with attachments only', (tester) async {
    var sent = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatComposer(
            attachments: [
              MessageAttachment(id: 'a1', type: AttachmentType.file, fileName: 'doc.pdf'),
            ],
            onSend: (_) => sent = true,
          ),
        ),
      ),
    );

    // Check send button enablement
    final sendButton = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send));
    expect(sendButton.onPressed, isNotNull);
    
    // Manually invoke
    sendButton.onPressed?.call();
    expect(sent, isTrue);
  });

  testWidgets('shows attachment chips and remove callback fires', (tester) async {
    var removedId = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatComposer(
            attachments: [
              MessageAttachment(id: 'a1', type: AttachmentType.photo, fileName: 'pic.jpg'),
            ],
            onSend: (_) {},
            onRemoveAttachment: (att) => removedId = att.id,
          ),
        ),
      ),
    );

    expect(find.text('pic.jpg'), findsOneWidget);
    
    // Verify the chip is configured with the callback
    final chipFinder = find.byType(InputChip);
    expect(chipFinder, findsOneWidget);
    final chip = tester.widget<InputChip>(chipFinder);
    expect(chip.onDeleted, isNotNull);
    
    // Manually invoke the callback
    chip.onDeleted?.call();
    expect(removedId, 'a1');
  });

  testWidgets('offline disables inputs and shows hint', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatComposer(
            isOffline: true,
            onSend: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Offline - cannot send'), findsOneWidget);
    
    // Check send button
    final sendButton = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send));
    expect(sendButton.onPressed, isNull);
    
    // Check photo button
    final photoButton = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.photo_camera));
    expect(photoButton.onPressed, isNull);
  });

  testWidgets('attachment buttons trigger callbacks', (tester) async {
    var photoTapped = false;
    var voiceTapped = false;
    var fileTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatComposer(
            onSend: (_) {},
            onPhotoTap: () => photoTapped = true,
            onVoiceTap: () => voiceTapped = true,
            onFileTap: () => fileTapped = true,
          ),
        ),
      ),
    );

    // Check photo button
    final photoButton = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.photo_camera));
    expect(photoButton.onPressed, isNotNull);
    photoButton.onPressed?.call();
    
    // Check voice button
    final voiceButton = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.mic));
    expect(voiceButton.onPressed, isNotNull);
    voiceButton.onPressed?.call();
    
    // Check file button
    final fileButton = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.attach_file));
    expect(fileButton.onPressed, isNotNull);
    fileButton.onPressed?.call();

    expect(photoTapped, isTrue);
    expect(voiceTapped, isTrue);
    expect(fileTapped, isTrue);
  });
}
