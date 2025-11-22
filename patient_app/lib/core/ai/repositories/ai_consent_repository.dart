/// Persists the user's consent choice for AI-assisted features.
abstract class AiConsentRepository {
  /// Returns true when the person has opted into AI processing.
  Future<bool> hasConsent();

  /// Stores a positive consent decision.
  Future<void> grantConsent();

  /// Clears a previous consent decision.
  Future<void> revokeConsent();
}
