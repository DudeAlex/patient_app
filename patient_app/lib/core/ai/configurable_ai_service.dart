import 'package:http/http.dart' as http;

import 'package:patient_app/core/ai/ai_service.dart';
import 'package:patient_app/core/ai/ai_config.dart';
import 'package:patient_app/core/ai/http/http_ai_service.dart';
import 'package:patient_app/core/ai/models/ai_summary_result.dart';
import 'package:patient_app/core/ai/repositories/ai_config_repository.dart';
import 'package:patient_app/core/domain/entities/information_item.dart';

/// Routes AI requests to Fake or HTTP implementations depending on config.
class ConfigurableAiService implements AiService {
  ConfigurableAiService({
    required this.configRepository,
    required AiService fakeService,
    required http.Client client,
  })  : _fakeService = fakeService,
        _client = client;

  final AiConfigRepository configRepository;
  final AiService _fakeService;
  final http.Client _client;

  @override
  Future<AiSummaryResult> summarizeItem(InformationItem item) async {
    final config = configRepository.current;
    if (!config.enabled || config.mode == AiMode.fake) {
      return _fakeService.summarizeItem(item);
    }
    final remote = HttpAiService(
      client: _client,
      baseUrl: config.remoteUrl,
    );
    return remote.summarizeItem(item);
  }
}
