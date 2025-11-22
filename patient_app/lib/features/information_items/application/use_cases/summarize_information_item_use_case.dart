import 'package:patient_app/core/ai/ai_service.dart';
import 'package:patient_app/core/ai/exceptions/ai_exceptions.dart';
import 'package:patient_app/core/ai/models/ai_summary_result.dart';
import 'package:patient_app/core/ai/repositories/ai_consent_repository.dart';
import 'package:patient_app/core/domain/entities/information_item.dart';

/// Use case that orchestrates AI summarization for a single Information Item.
///
/// The caller is expected to provide the already loaded [InformationItem]; this
/// use case ensures consent has been granted before delegating to [AiService].
class SummarizeInformationItemUseCase {
  SummarizeInformationItemUseCase({
    required AiService aiService,
    required AiConsentRepository consentRepository,
  })  : _aiService = aiService,
        _consentRepository = consentRepository;

  final AiService _aiService;
  final AiConsentRepository _consentRepository;

  Future<AiSummaryResult> execute(InformationItem item) async {
    if (item.deletedAt != null) {
      throw ArgumentError('Cannot summarize a deleted Information Item');
    }

    final hasConsent = await _consentRepository.hasConsent();
    if (!hasConsent) {
      throw AiConsentRequiredException();
    }

    return _aiService.summarizeItem(item);
  }
}
