import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:patient_app/core/ai/ai_service.dart';
import 'package:patient_app/core/ai/exceptions/ai_exceptions.dart';
import 'package:patient_app/core/ai/models/ai_error.dart';
import 'package:patient_app/core/ai/models/ai_summary_result.dart';
import 'package:patient_app/core/domain/entities/information_item.dart';

/// HTTP-backed implementation that delegates summarization to a backend proxy.
class HttpAiService implements AiService {
  HttpAiService({
    required this.client,
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
  });

  final http.Client client;
  final String baseUrl;
  final Duration timeout;
  final int maxRetries;

  @override
  Future<AiSummaryResult> summarizeItem(InformationItem item) async {
    final payload = _requestPayload(item);
    final uri = Uri.parse('$baseUrl/ai/summarize');

    int attempt = 0;
    while (true) {
      attempt++;
      try {
        final response = await client
            .post(
              uri,
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(timeout);
        if (response.statusCode == 200) {
          final map = jsonDecode(response.body) as Map<String, dynamic>;
          return _resultFromResponse(map);
        }
        if (_isRetryableStatus(response.statusCode) && attempt < maxRetries) {
          await Future<void>.delayed(Duration(seconds: attempt));
          continue;
        }
        throw AiProviderUnavailableException(
          error: AiError(
            message: 'Provider returned ${response.statusCode}',
            isRetryable: _isRetryableStatus(response.statusCode),
            code: '${response.statusCode}',
          ),
        );
      } on AiServiceException {
        rethrow;
      } catch (e) {
        if (attempt >= maxRetries) {
          throw AiProviderUnavailableException(
            error: const AiError(
              message: 'Network failure contacting AI provider',
              isRetryable: true,
            ),
            cause: e,
          );
        }
        await Future<void>.delayed(Duration(seconds: attempt));
      }
    }
  }

  Map<String, dynamic> _requestPayload(InformationItem item) {
    return {
      'space': item.spaceId,
      'domain': item.domainId,
      'title': item.data['title'],
      'category': item.data['type'] ?? item.data['category'],
      'tags': item.data['tags'] ?? [],
      'body': item.data['text'] ?? item.data['notes'],
      'attachments': (item.data['attachments'] as List?)
              ?.map((att) => {
                    'type': att['type'],
                    'name': att['name'],
                  })
              .toList() ??
          [],
    };
  }

  AiSummaryResult _resultFromResponse(Map<String, dynamic> map) {
    if (map.containsKey('error')) {
      final err = map['error'] as Map<String, dynamic>;
      throw AiProviderUnavailableException(
        error: AiError(
          message: err['message'] as String? ?? 'AI error',
          isRetryable: err['retryable'] as bool? ?? false,
          code: err['code'] as String?,
        ),
      );
    }
    return AiSummaryResult(
      summaryText: map['summary'] as String? ?? '',
      actionHints: (map['actionHints'] as List?)?.cast<String>() ?? const [],
      tokensUsed: map['tokensUsed'] as int? ?? 0,
      latencyMs: map['latencyMs'] as int? ?? 0,
      provider: map['provider'] as String? ?? 'remote',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  bool _isRetryableStatus(int status) {
    return status == 408 || status >= 500;
  }
}
