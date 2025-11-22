import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:patient_app/core/ai/ai_config.dart';
import 'package:patient_app/core/ai/configurable_ai_service.dart';
import 'package:patient_app/core/ai/fake_ai_service.dart';
import 'package:patient_app/core/ai/repositories/ai_config_repository.dart';
import 'package:patient_app/core/domain/entities/information_item.dart';

class _FakeConfigRepo implements AiConfigRepository {
  @override
  AiConfig current;
  _FakeConfigRepo(this.current);
  @override
  Stream<AiConfig> get stream => const Stream.empty();
  @override
  Future<AiConfig> loadConfig() async => current;
  @override
  Future<void> setEnabled(bool enabled) async {}
  @override
  Future<void> setMode(AiMode mode) async {}
  Future<void> setRemoteUrl(String url) async {}
}

class _FakeHttpClient extends http.BaseClient {
  final http.Response response;
  _FakeHttpClient(this.response);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(Stream.value(response.bodyBytes), response.statusCode);
  }
}

void main() {
  final now = DateTime.now();
  final item = InformationItem(spaceId: 'health', domainId: 'visit', data: {}, createdAt: now, updatedAt: now);

  test('routes to fake service when disabled', () async {
    final repo = _FakeConfigRepo(const AiConfig(enabled: false));
    final service = ConfigurableAiService(
      configRepository: repo,
      fakeService: FakeAiService(latency: Duration.zero),
      client: http.Client(),
    );
    final result = await service.summarizeItem(item);
    expect(result.provider, 'fake');
  });
}
