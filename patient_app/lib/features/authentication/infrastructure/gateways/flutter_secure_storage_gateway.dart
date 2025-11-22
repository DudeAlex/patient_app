import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../application/ports/secure_storage_gateway.dart';

/// Implementation of SecureStorageGateway using flutter_secure_storage package.
/// Provides secure storage for sensitive authentication data like tokens and credentials.
class FlutterSecureStorageGateway implements SecureStorageGateway {
  final FlutterSecureStorage _storage;

  FlutterSecureStorageGateway({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      throw SecureStorageException('Failed to write to secure storage: $e');
    }
  }

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw SecureStorageException('Failed to read from secure storage: $e');
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw SecureStorageException('Failed to delete from secure storage: $e');
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw SecureStorageException(
          'Failed to delete all from secure storage: $e');
    }
  }
}

/// Exception thrown when secure storage operations fail.
class SecureStorageException implements Exception {
  final String message;
  SecureStorageException(this.message);

  @override
  String toString() => 'SecureStorageException: $message';
}
