import 'package:local_auth/local_auth.dart' hide BiometricType;
import '../../application/ports/biometric_gateway.dart';
import '../../application/ports/secure_storage_gateway.dart';

/// Implementation of BiometricGateway using local_auth package.
/// Provides biometric authentication (fingerprint, face recognition) capabilities.
class LocalAuthBiometricGateway implements BiometricGateway {
  final LocalAuthentication _localAuth;
  final SecureStorageGateway _secureStorage;

  LocalAuthBiometricGateway({
    LocalAuthentication? localAuth,
    required SecureStorageGateway secureStorage,
  })  : _localAuth = localAuth ?? LocalAuthentication(),
        _secureStorage = secureStorage;

  @override
  Future<bool> isAvailable() async {
    try {
      // Check if device supports biometric authentication
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<BiometricType> getSupportedType() async {
    try {
      final isAvail = await isAvailable();
      if (!isAvail) {
        return BiometricType.none;
      }

      // Get list of available biometric types from local_auth
      // Note: local_auth returns platform-specific BiometricType enum values
      // We check if any biometrics are available and return a generic type
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      if (availableBiometrics.isEmpty) {
        return BiometricType.none;
      }

      // Check the string representation to determine type
      // This is a workaround for the BiometricType name collision
      final biometricStrings =
          availableBiometrics.map((b) => b.toString()).toList();

      if (biometricStrings.any((s) => s.contains('face'))) {
        return BiometricType.face;
      } else if (biometricStrings.any((s) => s.contains('fingerprint'))) {
        return BiometricType.fingerprint;
      } else {
        // Some other biometric type is available
        return BiometricType.other;
      }
    } catch (e) {
      return BiometricType.none;
    }
  }

  @override
  Future<bool> authenticate({required String reason}) async {
    try {
      final isAvail = await isAvailable();
      if (!isAvail) {
        return false;
      }

      // Perform biometric authentication
      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true, // Keep auth dialog visible until success/cancel
          biometricOnly: true, // Only use biometric, not device PIN
        ),
      );

      return authenticated;
    } catch (e) {
      // Authentication failed or was cancelled
      return false;
    }
  }

  @override
  Future<void> storeCredentials(String userId, String encryptedData) async {
    try {
      final key = _getCredentialKey(userId);
      await _secureStorage.write(key, encryptedData);
    } catch (e) {
      throw BiometricException('Failed to store credentials: $e');
    }
  }

  @override
  Future<String?> retrieveCredentials(String userId) async {
    try {
      final key = _getCredentialKey(userId);
      return await _secureStorage.read(key);
    } catch (e) {
      throw BiometricException('Failed to retrieve credentials: $e');
    }
  }

  @override
  Future<void> deleteCredentials(String userId) async {
    try {
      final key = _getCredentialKey(userId);
      await _secureStorage.delete(key);
    } catch (e) {
      throw BiometricException('Failed to delete credentials: $e');
    }
  }

  /// Generate secure storage key for biometric credentials
  String _getCredentialKey(String userId) {
    return 'biometric_credentials_$userId';
  }
}

/// Exception thrown when biometric operations fail.
class BiometricException implements Exception {
  final String message;
  BiometricException(this.message);

  @override
  String toString() => 'BiometricException: $message';
}
