import 'dart:async';
import 'dart:math' as math;

import 'package:patient_app/core/ai/ai_service.dart';
import 'package:patient_app/core/ai/exceptions/ai_exceptions.dart';
import 'package:patient_app/core/ai/models/ai_error.dart';
import 'package:patient_app/core/ai/models/ai_summary_result.dart';
import 'package:patient_app/core/domain/entities/information_item.dart';

/// Deterministic AI implementation for development and widget tests.
///
/// Generates simple summaries from the item's title/body fields so UI and
/// orchestration code can be exercised without calling external providers.
class FakeAiService implements AiService {
  FakeAiService({
    Duration latency = const Duration(milliseconds: 500),
    bool simulateFailure = false,
    AiError? failureError,
  })  : _latency = latency,
        _simulateFailure = simulateFailure,
        _failureError =
            failureError ?? const AiError(message: 'Simulated AI failure', isRetryable: true);

  Duration _latency;
  bool _simulateFailure;
  AiError _failureError;

  /// Updates latency used to simulate provider round-trip.
  set latency(Duration value) => _latency = value;

  /// Enables/disables deterministic failure mode for testing.
  void configureFailure({
    required bool enabled,
    AiError? error,
  }) {
    _simulateFailure = enabled;
    if (error != null) {
      _failureError = error;
    }
  }

  @override
  Future<AiSummaryResult> summarizeItem(InformationItem item) async {
    await Future<void>.delayed(_latency);

    if (_simulateFailure) {
      throw AiServiceException(
        'Fake AI service configured to fail',
        error: _failureError,
      );
    }

    final summary = _buildSummaryText(item);
    final hints = _buildActionHints(item);

    return AiSummaryResult.success(
      summaryText: summary,
      actionHints: hints,
      tokensUsed: summary.split(' ').length + hints.fold<int>(0, (sum, hint) => sum + hint.length),
      latencyMs: _latency.inMilliseconds,
      provider: 'fake',
      confidence: 0.42,
    );
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
      final excerptLength = math.min(notes.length, 80);
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
