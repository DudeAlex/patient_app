import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class CryptoHelper {
  static final _algo = AesGcm.with256bits();

  static Future<Uint8List> deriveKey(String passphrase, {String salt = 'patient_salt', int length = 32}) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: length * 8,
    );
    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(passphrase)),
      nonce: utf8.encode(salt),
    );
    final bytes = await secretKey.extractBytes();
    return Uint8List.fromList(bytes);
  }

  static Future<Uint8List> encrypt(Uint8List data, Uint8List keyBytes) async {
    final secretKey = SecretKey(keyBytes);
    final nonce = await _randomBytes(12);
    final secretBox = await _algo.encrypt(data, secretKey: secretKey, nonce: nonce);
    // prefix nonce to ciphertext for storage
    return Uint8List.fromList(nonce + secretBox.cipherText + secretBox.mac.bytes);
  }

  static Future<Uint8List> decrypt(Uint8List payload, Uint8List keyBytes) async {
    final nonce = payload.sublist(0, 12);
    final mac = Mac(payload.sublist(payload.length - 16));
    final cipherText = payload.sublist(12, payload.length - 16);
    final secretKey = SecretKey(keyBytes);
    final clear = await _algo.decrypt(SecretBox(cipherText, nonce: nonce, mac: mac), secretKey: secretKey);
    return Uint8List.fromList(clear);
  }

  static Future<List<int>> _randomBytes(int length) async {
    try {
      final r = Random.secure();
      return List<int>.generate(length, (_) => r.nextInt(256));
    } catch (_) {
      // Fallback: derive randomness from a new secret key if Random.secure
      // is not available on the current platform.
      final out = <int>[];
      while (out.length < length) {
        final sk = await AesGcm.with256bits().newSecretKey();
        out.addAll(await sk.extractBytes());
      }
      return out.sublist(0, length);
    }
  }
}
