import 'dart:async';

import 'package:patient_app/core/ai/ai_service.dart';
import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/core/ai/models/ai_summary_result.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';
import 'package:patient_app/core/domain/entities/information_item.dart';

/// Simulated AI chat service with deterministic, persona-aware responses.
class FakeAiChatService implements AiChatService {
  FakeAiChatService({
    this.simulatedLatency = const Duration(milliseconds: 1000),
    this.streamChunkDelay = const Duration(milliseconds: 50),
  });

  /// Fixed delay used to mimic provider round-trip time.
  final Duration simulatedLatency;

  /// Delay between streamed word chunks for typing effect.
  final Duration streamChunkDelay;

  @override
  Future<ChatResponse> sendMessage(ChatRequest request) async {
    final opId = AppLogger.startOperation('fake_ai_chat_send');
    try {
      await Future.delayed(simulatedLatency);
      final response = _buildResponse(request);

      await AppLogger.info(
        'Fake AI chat response generated',
        context: {
          'threadId': request.threadId,
          'spaceId': request.spaceContext.spaceId,
          'persona': request.spaceContext.persona.name,
          'attachmentTypes': request.attachments.map((a) => a.type.name).toList(),
          'tokensUsed': response.metadata.tokensUsed,
          'latencyMs': response.metadata.latencyMs,
        },
      );

      return response;
    } catch (e, stackTrace) {
      await AppLogger.error(
        'Fake AI chat failed',
        error: e,
        stackTrace: stackTrace,
        context: {
          'threadId': request.threadId,
          'spaceId': request.spaceContext.spaceId,
        },
      );
      rethrow;
    } finally {
      await AppLogger.endOperation(opId);
    }
  }

  @override
  Stream<ChatResponseChunk> sendMessageStream(ChatRequest request) async* {
    final opId = AppLogger.startOperation('fake_ai_chat_stream');
    try {
      await Future.delayed(simulatedLatency);
      final response = _buildResponse(request);

      final words = response.messageContent.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      for (var i = 0; i < words.length; i++) {
        final chunk = words.sublist(0, i + 1).join(' ');
        yield ChatResponseChunk(
          content: chunk,
          isComplete: i == words.length - 1,
        );
        if (i < words.length - 1) {
          await Future.delayed(streamChunkDelay);
        }
      }

      await AppLogger.info(
        'Fake AI chat streamed response generated',
        context: {
          'threadId': request.threadId,
          'spaceId': request.spaceContext.spaceId,
          'persona': request.spaceContext.persona.name,
          'tokensUsed': response.metadata.tokensUsed,
          'latencyMs': response.metadata.latencyMs,
        },
      );
    } catch (e, stackTrace) {
      await AppLogger.error(
        'Fake AI chat stream failed',
        error: e,
        stackTrace: stackTrace,
        context: {
          'threadId': request.threadId,
          'spaceId': request.spaceContext.spaceId,
        },
      );
      rethrow;
    } finally {
      await AppLogger.endOperation(opId);
    }
  }

  @override
  Future<AiSummaryResult> summarizeItem(InformationItem item) async {
    final opId = AppLogger.startOperation('fake_ai_chat_summarize');
    try {
      await Future.delayed(simulatedLatency);
      final summary = _buildSummaryText(item);
      final hints = _buildActionHints(item);

      final result = AiSummaryResult.success(
        summaryText: summary,
        actionHints: hints,
        tokensUsed: summary.split(' ').length + hints.fold<int>(0, (sum, hint) => sum + hint.length),
        latencyMs: simulatedLatency.inMilliseconds,
        provider: 'fake',
        confidence: 0.45,
      );

      await AppLogger.info(
        'Fake AI summary generated',
        context: {
          'spaceId': item.spaceId,
          'domainId': item.domainId,
          'tokensUsed': result.tokensUsed,
          'latencyMs': result.latencyMs,
        },
      );

      return result;
    } catch (e, stackTrace) {
      await AppLogger.error(
        'Fake AI summary failed',
        error: e,
        stackTrace: stackTrace,
        context: {'spaceId': item.spaceId, 'domainId': item.domainId},
      );
      rethrow;
    } finally {
      await AppLogger.endOperation(opId);
    }
  }

  ChatResponse _buildResponse(ChatRequest request) {
    final persona = request.spaceContext.persona;
    final message = request.messageContent.toLowerCase();
    final actionHints = _actionHintsForPersona(persona);
    final text = _personaResponse(persona, message, request.spaceContext.spaceName);

    final estimatedTokens = _estimateTokens(message, request.messageHistory.length, request.attachments.length);

    return ChatResponse.success(
      messageContent: text,
      actionHints: actionHints,
      metadata: AiMessageMetadata(
        tokensUsed: estimatedTokens,
        latencyMs: simulatedLatency.inMilliseconds,
        provider: 'fake',
        confidence: 0.9,
      ),
    );
  }

  List<String> _actionHintsForPersona(SpacePersona persona) {
    switch (persona) {
      case SpacePersona.health:
        return [
          'View recent health records',
          'Track symptoms over time',
          'Schedule a check-up reminder',
        ];
      case SpacePersona.education:
        return [
          'Create a study schedule',
          'Review recent notes',
          'Set assignment deadlines',
        ];
      case SpacePersona.finance:
        return [
          'View spending summary',
          'Set budget goals',
          'Track recurring expenses',
        ];
      case SpacePersona.travel:
        return [
          'Create trip itinerary',
          'Add travel documents',
          'Check packing list',
        ];
      case SpacePersona.general:
      default:
        return [
          'View recent records',
          'Add new information',
          'Search your data',
        ];
    }
  }

  String _personaResponse(
    SpacePersona persona,
    String normalizedMessage,
    String spaceName,
  ) {
    switch (persona) {
      case SpacePersona.health:
        if (normalizedMessage.contains('pain') || normalizedMessage.contains('symptom')) {
          return "I’m here to help you track what you’re feeling. I can summarize your recent $spaceName records, but please reach out to a clinician for medical advice. Do you want to log this and set a reminder?";
        }
        return "I’ll keep guidance gentle and safety-first. I can organize your $spaceName notes and highlight patterns. This isn’t medical advice—would you like help summarizing recent visits?";
      case SpacePersona.education:
        if (normalizedMessage.contains('exam') || normalizedMessage.contains('study')) {
          return "Let’s set up a short study plan. We can break topics into manageable blocks and track progress for your $spaceName work. Which subject should we prioritize?";
        }
        return "I’m here to support your learning. I can organize notes, suggest review cadences, and keep the $spaceName materials tidy. Where should we start?";
      case SpacePersona.finance:
        if (normalizedMessage.contains('budget') || normalizedMessage.contains('expense')) {
          return "Let’s review spending and set a simple budget for your $spaceName items. I can group expenses and surface recurring costs. Want a quick summary?";
        }
        return "I’ll stay practical and budget-conscious. I can organize your $spaceName records, spot recurring items, and suggest tidy categories. What should we look at first?";
      case SpacePersona.travel:
        if (normalizedMessage.contains('trip') || normalizedMessage.contains('destination')) {
          return "Sounds exciting! I can help outline an itinerary, track bookings, and keep your $spaceName documents handy. Where are you headed?";
        }
        return "Let’s plan together. I can build a lightweight itinerary, packing list, and reminders for your $spaceName plans. What’s the next step you need?";
      case SpacePersona.general:
      default:
        return "I’m here to help organize your information and suggest next steps. Tell me what you’re focusing on, and I’ll keep it concise and actionable.";
    }
  }

  int _estimateTokens(String message, int historyCount, int attachmentCount) {
    final base = (message.length / 4).ceil();
    return base + historyCount * 8 + attachmentCount * 4 + 50;
  }

  String _buildSummaryText(InformationItem item) {
    final title = _extractStringField(item, const ['title', 'name', 'subject']);
    final notes = _extractStringField(item, const ['notes', 'note', 'body', 'description']) ?? '';
    final firstSentence = _firstSentence(notes);

    final buffer = StringBuffer();
    buffer.write(title ?? 'Information item');
    buffer.write(' in the ');
    buffer.write(item.spaceId);
    buffer.write(' space focuses on ');
    buffer.write(item.domainId.replaceAll('_', ' '));

    if (firstSentence != null && firstSentence.isNotEmpty) {
      buffer.write('. ');
      buffer.write(firstSentence);
    } else if (notes.isNotEmpty) {
      buffer.write('. ');
      final excerptLength = notes.length > 80 ? 80 : notes.length;
      buffer.write(notes.substring(0, excerptLength));
    }

    return buffer.toString();
  }

  List<String> _buildActionHints(InformationItem item) {
    final tags = _extractListField(item, const ['tags', 'labels']);
    final category = _extractStringField(item, const ['category', 'type']) ?? item.domainId;

    final hints = <String>[
      'Review "$category" details soon',
      'Update notes if anything changed',
    ];

    if (tags.isNotEmpty) {
      hints.add('Tag reminder: ${tags.first}');
    }

    return hints.take(3).toList();
  }

  String? _extractStringField(InformationItem item, List<String> candidateKeys) {
    for (final key in candidateKeys) {
      final value = item.data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  List<String> _extractListField(InformationItem item, List<String> candidateKeys) {
    for (final key in candidateKeys) {
      final value = item.data[key];
      if (value is List) {
        return value.whereType<String>().toList();
      }
    }
    return const [];
  }

  String? _firstSentence(String text) {
    if (text.isEmpty) return null;
    final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
    return sentences.isNotEmpty ? sentences.first.trim() : text.trim();
  }
}
