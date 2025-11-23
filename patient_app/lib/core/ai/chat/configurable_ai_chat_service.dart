import 'package:http/http.dart' as http;

import 'package:patient_app/core/ai/ai_config.dart';
import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/http_ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/models/ai_summary_result.dart';
import 'package:patient_app/core/ai/repositories/ai_config_repository.dart';
import 'package:patient_app/core/domain/entities/information_item.dart';

/// Routes AI chat requests to Fake or HTTP implementations depending on config.
class ConfigurableAiChatService implements AiChatService {
  ConfigurableAiChatService({
    required this.configRepository,
    required AiChatService fakeService,
    required HttpAiChatService httpService,
  })  : _fakeService = fakeService,
        _httpService = httpService;

  final AiConfigRepository configRepository;
  final AiChatService _fakeService;
  final HttpAiChatService _httpService;

  @override
  Future<ChatResponse> sendMessage(ChatRequest request) async {
    final config = configRepository.current;
    if (!config.enabled || config.mode == AiMode.fake) {
      return _fakeService.sendMessage(request);
    }
    final remote = HttpAiChatService(
      client: _httpService.client,
      baseUrl: config.remoteUrl,
      timeout: _httpService.timeout,
      maxRetries: _httpService.maxRetries,
    );
    return remote.sendMessage(request);
  }

  @override
  Stream<ChatResponseChunk> sendMessageStream(ChatRequest request) {
    final config = configRepository.current;
    if (!config.enabled || config.mode == AiMode.fake) {
      return _fakeService.sendMessageStream(request);
    }
    final remote = HttpAiChatService(
      client: _httpService.client,
      baseUrl: config.remoteUrl,
      timeout: _httpService.timeout,
      maxRetries: _httpService.maxRetries,
    );
    return remote.sendMessageStream(request);
  }

  @override
  Future<AiSummaryResult> summarizeItem(InformationItem item) {
    // Not used for chat; delegate to keep interface parity.
    return _fakeService.summarizeItem(item);
  }
}
