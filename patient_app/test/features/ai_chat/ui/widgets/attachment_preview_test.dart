import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/models/message_attachment.dart';
import 'package:patient_app/features/ai_chat/ui/widgets/attachment_preview.dart';

void main() {
  testWidgets('renders photo preview', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AttachmentPreview(
            attachment: MessageAttachment(id: 'a1', type: AttachmentType.photo, fileName: 'pic.jpg'),
          ),
        ),
      ),
    );

    expect(find.text('pic.jpg'), findsOneWidget);
    expect(find.byIcon(Icons.photo), findsOneWidget);
  });

  testWidgets('renders voice preview', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AttachmentPreview(
            attachment: MessageAttachment(id: 'a2', type: AttachmentType.voice, fileName: 'voice.m4a'),
          ),
        ),
      ),
    );

    expect(find.text('voice.m4a'), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);
  });

  testWidgets('renders file preview with size', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AttachmentPreview(
            attachment: MessageAttachment(
              id: 'a3',
              type: AttachmentType.file,
              fileName: 'doc.pdf',
              fileSizeBytes: 2048,
            ),
          ),
        ),
      ),
    );

    expect(find.text('doc.pdf'), findsOneWidget);
    expect(find.textContaining('KB'), findsOneWidget);
    expect(find.byIcon(Icons.insert_drive_file), findsOneWidget);
  });
}
