import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// Service for generating and encrypting secure authentication tokens.
/// 
/// Generates cryptographically secure random tokens and provides AES-256
/// encryption for secure token storage. Tokens have a 24-hour expiration.
class TokenGenerator {
  /// AES-256-GCM cipher for token encryption
  final AesGcm _cipher = AesGcm.with256bits();
  
  /// Random number generator for secure token generation
  final Random _random = Random.secure();
  
  /// Default session duration (24 hours)
  static const Duration sessionDuration = Duration(hours: 24);

  /// Generates a cryptographically secure random token.
  /// 
  /// [length] The length of the token in bytes (default: 32)
  /// Returns a base64-encoded random token string
  /// 
  /// Example:
  /// ```dart
  /// final generator = TokenGenerator();
  /// final token = generator.generateToken();
  /// ```
  String generateToken({int length = 32}) {
    // Generate random bytes using secure random number generator
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = _random.nextInt(256);
    }
    
    // Encode as base64 for safe string representation
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Encrypts a token using AES-256-GCM encryption.
  /// 
  /// [token] The token to encrypt
  /// [secretKey] The encryption key (must be 32 bytes for AES-256)
  /// Returns the encrypted token as a base64-encoded string
  /// 
  /// The encrypted result includes the nonce (IV) prepended to the ciphertext,
  /// separated by a colon for easy parsing during decryption.
  /// 
  /// Example:
  /// ```dart
  /// final generator = TokenGenerator();
  /// final encrypted = await generator.encryptToken(token, secretKey);
  /// ```
  Future<String> encryptToken(String token, List<int> secretKey) async {
    // Validate key length for AES-256
    if (secretKey.length != 32) {
      throw ArgumentError('Secret key must be 32 bytes for AES-256');
    }
    
    // Create secret key object
    final key = SecretKey(secretKey);
    
    // Encrypt the token
    final secretBox = await _cipher.encrypt(
      utf8.encode(token),
      secretKey: key,
    );
    
    // Combine nonce and ciphertext for storage
    // Format: base64(nonce):base64(ciphertext+mac)
    final nonce = base64Url.encode(secretBox.nonce);
    final ciphertext = base64Url.encode(secretBox.cipherText);
    final mac = base64Url.encode(secretBox.mac.bytes);
    
    return '$nonce:$ciphertext:$mac';
  }

  /// Decrypts an encrypted token using AES-256-GCM.
  /// 
  /// [encryptedToken] The encrypted token string (format: nonce:ciphertext:mac)
  /// [secretKey] The encryption key (must be 32 bytes for AES-256)
  /// Returns the decrypted token string
  /// 
  /// Example:
  /// ```dart
  /// final generator = TokenGenerator();
  /// final decrypted = await generator.decryptToken(encrypted, secretKey);
  /// ```
  Future<String> decryptToken(String encryptedToken, List<int> secretKey) async {
    // Validate key length for AES-256
    if (secretKey.length != 32) {
      throw ArgumentError('Secret key must be 32 bytes for AES-256');
    }
    
    // Parse the encrypted token format
    final parts = encryptedToken.split(':');
    if (parts.length != 3) {
      throw ArgumentError('Invalid encrypted token format');
    }
    
    final nonce = base64Url.decode(parts[0]);
    final ciphertext = base64Url.decode(parts[1]);
    final mac = base64Url.decode(parts[2]);
    
    // Create secret key object
    final key = SecretKey(secretKey);
    
    // Create SecretBox for decryption
    final secretBox = SecretBox(
      ciphertext,
      nonce: nonce,
      mac: Mac(mac),
    );
    
    // Decrypt the token
    final decrypted = await _cipher.decrypt(
      secretBox,
      secretKey: key,
    );
    
    return utf8.decode(decrypted);
  }

  /// Calculates the expiration timestamp for a new session.
  /// 
  /// Returns a DateTime representing when the session should expire
  /// (24 hours from now by default)
  /// 
  /// Example:
  /// ```dart
  /// final generator = TokenGenerator();
  /// final expiresAt = generator.calculateExpiration();
  /// ```
  DateTime calculateExpiration() {
    return DateTime.now().add(sessionDuration);
  }

  /// Checks if a token has expired based on its expiration timestamp.
  /// 
  /// [expiresAt] The expiration timestamp to check
  /// Returns true if the token has expired, false otherwise
  /// 
  /// Example:
  /// ```dart
  /// final generator = TokenGenerator();
  /// final isExpired = generator.isExpired(session.expiresAt);
  /// ```
  bool isExpired(DateTime expiresAt) {
    return DateTime.now().isAfter(expiresAt);
  }

  /// Generates a secure encryption key for token encryption.
  /// 
  /// Returns a 32-byte key suitable for AES-256 encryption
  /// 
  /// Note: This key should be securely stored and reused for the application.
  /// Generate once during app initialization and store in secure storage.
  /// 
  /// Example:
  /// ```dart
  /// final generator = TokenGenerator();
  /// final key = generator.generateEncryptionKey();
  /// // Store key securely using flutter_secure_storage
  /// ```
  List<int> generateEncryptionKey() {
    final bytes = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return bytes;
  }
}
