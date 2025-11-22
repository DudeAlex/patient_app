import 'package:patient_app/core/ai/ai_service.dart';
import 'package:patient_app/core/ai/models/ai_call_log_entry.dart';
import 'package:patient_app/core/ai/models/ai_summary_result.dart';
import 'package:patient_app/core/ai/repositories/ai_call_log_repository.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';
import 'package:patient_app/core/domain/entities/information_item.dart';

/// Decorator that logs AI calls for diagnostics without exposing sensitive text.
class LoggingAiService implements AiService {
  LoggingAiService(this._delegate, {AiCallLogRepository? callLogRepository})
      : _callLogRepository = callLogRepository;

  final AiService _delegate;
  final AiCallLogRepository? _callLogRepository;

  @override
  Future<AiSummaryResult> summarizeItem(InformationItem item) async {
    final operationId = AppLogger.startOperation('ai_summarize_item');
    final baseContext = _contextFor(item);

    await AppLogger.info(
      'AI summarize request started',
      context: baseContext,
      correlationId: operationId,
    );

    try {
      final result = await _delegate.summarizeItem(item);

      await AppLogger.info(
        'AI summarize request completed',
        context: {
          ...baseContext,
          'tokensUsed': result.tokensUsed,
          'latencyMs': result.latencyMs,
          'provider': result.provider,
          'confidence': result.confidence,
          'success': result.isSuccess,
        },
        correlationId: operationId,
      );
      _callLogRepository?.add(
        AiCallLogEntry(
          timestamp: DateTime.now(),
          spaceId: item.spaceId,
          domainId: item.domainId,
          provider: result.provider,
          latencyMs: result.latencyMs,
          tokensUsed: result.tokensUsed,
          confidence: result.confidence,
          success: result.isSuccess,
        ),
      );

      return result;
    } catch (error, stackTrace) {
      await AppLogger.error(
        'AI summarize request failed',
        error: error,
        stackTrace: stackTrace,
        context: baseContext,
        correlationId: operationId,
      );
      _callLogRepository?.add(
        AiCallLogEntry(
          timestamp: DateTime.now(),
          spaceId: item.spaceId,
          domainId: item.domainId,
          provider: 'unknown',
          latencyMs: 0,
          tokensUsed: 0,
          confidence: 0,
          success: false,
          errorMessage: error.toString(),
        ),
      );
      rethrow;
    } finally {
      await AppLogger.endOperation(operationId);
    }
  }

  Map<String, dynamic> _contextFor(InformationItem item) {
    return {
      'itemId': item.id,
      'spaceId': item.spaceId,
      'domainId': item.domainId,
      'category': _stringField(item, 'category'),
      'attachmentCount': _attachmentCount(item),
    };
  }

  String? _stringField(InformationItem item, String key) {
    final value = item.data[key];
    return value is String ? value : null;
  }

  int _attachmentCount(InformationItem item) {
    final attachments = item.data['attachments'];
    if (attachments is List) {
      return attachments.length;
    }
    return 0;
  }
}
