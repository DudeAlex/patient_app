import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/message_attachment.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/core/ai/chat/models/record_summary.dart';

/// Property 5: On-device data protection
/// Feature: llm-stage-7e-privacy-security, Property 5: On-device data protection
/// Validates: Requirements 5.1, 5.2
///
/// Backend payloads should not contain on-device identifiers or keys such as
/// Information Item IDs, encryption keys, or local file paths.
void main() {
  test('Property 5: ChatRequest JSON omits device-only identifiers', () {
    final attachment = MessageAttachment(
      id: 'att-1',
      type: AttachmentType.file,
      localPath: '/tmp/local.doc',
      fileName: 'local.doc',
      transcription: 'notes',
    );
    final request = ChatRequest(
      threadId: 'thread-1',
      messageContent: 'hello',
      spaceContext: SpaceContext(
        spaceId: 'health',
        spaceName: 'Health',
        persona: SpacePersona.health,
        description: 'desc',
        recentRecords: [
          RecordSummary(
            title: 'Lab',
            type: 'lab',
            date: DateTime(2024, 1, 1),
            summary: 'Bloodwork',
          ),
        ],
      ),
      attachments: [attachment],
    );

    final json = request.toJson();
    final attachments = json['attachments'] as List<dynamic>;
    final attachmentMap = attachments.first as Map<String, dynamic>;

    // Ensure no device-only fields present.
    expect(json.containsKey('encryptionKey'), isFalse);
    expect(json.containsKey('informationItemId'), isFalse);
    expect(attachmentMap.containsKey('localPath'), isFalse);
  });
}
