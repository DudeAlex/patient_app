import 'package:patient_app/core/ai/models/ai_summary_result.dart';
import 'package:patient_app/core/domain/entities/information_item.dart';

/// Port that exposes AI-powered operations to the rest of the app.
///
/// UI and use cases depend on this interface rather than concrete services so
/// Fake, Logging, and HTTP-backed implementations can be swapped freely.
abstract class AiService {
  /// Generates a compassionate, short summary for the provided [item].
  ///
  /// Implementations may throw [AiServiceException] (see
  /// `lib/core/ai/exceptions/ai_exceptions.dart`) when consent is missing or
  /// external services are unavailable.
  Future<AiSummaryResult> summarizeItem(InformationItem item);
}
