import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:patient_app/core/ai/ai_service.dart';
import 'package:patient_app/core/ai/models/ai_call_log_entry.dart';
import 'package:patient_app/core/ai/repositories/ai_call_log_repository.dart';
import 'package:patient_app/core/ai/repositories/ai_consent_repository.dart';
import 'package:patient_app/core/di/app_container.dart';

/// Riverpod provider for resolving the current AiService implementation.
final aiServiceProvider = Provider<AiService>((ref) {
  return AppContainer.instance.resolve<AiService>();
});

/// Riverpod provider exposing the consent repository to UI/view models.
final aiConsentRepositoryProvider = Provider<AiConsentRepository>((ref) {
  return AppContainer.instance.resolve<AiConsentRepository>();
});

final aiCallLogRepositoryProvider = Provider<AiCallLogRepository>((ref) {
  return AppContainer.instance.resolve<AiCallLogRepository>();
});

final aiCallLogStreamProvider =
    StreamProvider<List<AiCallLogEntry>>((ref) async* {
  final repo = ref.watch(aiCallLogRepositoryProvider);
  yield repo.entries;
  yield* repo.stream;
});
