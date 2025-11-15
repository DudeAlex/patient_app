/// Port (interface) for secure credential storage.
/// 
/// This interface abstracts platform-specific secure storage mechanisms
/// (iOS Keychain, Android Keystore) for storing sensitive data like
/// authentication tokens and encrypted credentials. Implementations wrap
/// secure storage libraries (flutter_secure_storage) while use cases
/// depend only on this abstraction.
abstract class SecureStorageGateway {
  /// Writes a value to secure storage.
  /// 
  /// Stores the [value] associated with the given [key] in the device's
  /// secure storage. The data is encrypted at rest using platform-specific
  /// encryption (AES-256).
  /// 
  /// If a value already exists for the [key], it is overwritten.
  /// 
  /// Common keys include:
  /// - `auth_token_{userId}`: Current session token
  /// - `biometric_credentials_{userId}`: Encrypted credentials for biometric auth
  /// - `refresh_token_{userId}`: Long-lived refresh token
  Future<void> write(String key, String value);

  /// Reads a value from secure storage.
  /// 
  /// Returns the value associated with the given [key] if it exists,
  /// null otherwise. The data is decrypted automatically by the platform.
  /// 
  /// Used for retrieving stored tokens and credentials during authentication.
  Future<String?> read(String key);

  /// Deletes a value from secure storage.
  /// 
  /// Removes the value associated with the given [key].
  /// Does nothing if the key doesn't exist.
  /// 
  /// Used when logging out or disabling authentication methods.
  Future<void> delete(String key);

  /// Deletes all values from secure storage.
  /// 
  /// Removes all stored data for this application.
  /// Used during complete logout or account deletion.
  /// 
  /// WARNING: This operation cannot be undone.
  Future<void> deleteAll();
}
