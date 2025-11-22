/// Types of biometric authentication supported by the device.
enum BiometricType {
  /// No biometric authentication available
  none,
  
  /// Fingerprint authentication (Touch ID, fingerprint sensor)
  fingerprint,
  
  /// Face recognition authentication (Face ID, face unlock)
  face,
  
  /// Other biometric methods (iris scan, etc.)
  other,
}

/// Port (interface) for biometric authentication operations.
/// 
/// This interface abstracts platform-specific biometric authentication
/// (fingerprint, face recognition) and secure credential storage.
/// Implementations wrap platform APIs (local_auth, flutter_secure_storage)
/// while use cases depend only on this abstraction.
abstract class BiometricGateway {
  /// Checks if biometric authentication is available on this device.
  /// 
  /// Returns true if the device has biometric hardware and the user
  /// has enrolled at least one biometric credential.
  /// Used to conditionally show biometric login options in the UI.
  Future<bool> isAvailable();

  /// Gets the type of biometric authentication supported by the device.
  /// 
  /// Returns the primary biometric type available (fingerprint, face, etc.).
  /// Returns [BiometricType.none] if no biometric auth is available.
  /// Used for displaying appropriate UI prompts and icons.
  Future<BiometricType> getSupportedType();

  /// Authenticates the user using biometric credentials.
  /// 
  /// Displays the platform's biometric prompt with the given [reason].
  /// Returns true if authentication succeeds, false otherwise.
  /// 
  /// The [reason] parameter is shown to the user explaining why
  /// biometric authentication is being requested (e.g., "Log in to Patient App").
  /// 
  /// Throws an exception if biometric auth is not available or if
  /// there's a platform error.
  Future<bool> authenticate({required String reason});

  /// Securely stores encrypted credentials for biometric authentication.
  /// 
  /// Stores the [encryptedData] in the device's secure storage (keystore)
  /// associated with the given [userId]. This data is only accessible
  /// after successful biometric authentication.
  /// 
  /// Used when enabling biometric login to store encrypted password/token.
  Future<void> storeCredentials(String userId, String encryptedData);

  /// Retrieves stored credentials after biometric authentication.
  /// 
  /// Returns the encrypted credentials for the given [userId] if they exist,
  /// null otherwise. Access to this data requires prior biometric authentication.
  /// 
  /// Used during biometric login to retrieve stored credentials.
  Future<String?> retrieveCredentials(String userId);

  /// Deletes stored credentials for a user.
  /// 
  /// Removes all biometric credentials associated with the given [userId].
  /// Used when disabling biometric authentication or during logout.
  Future<void> deleteCredentials(String userId);
}
