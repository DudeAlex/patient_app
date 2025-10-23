import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KeyManager {
  static const _keyName = 'backup_key_v1';
  static const _storage = FlutterSecureStorage();

  static Future<Uint8List> getOrCreateKey() async {
    final existing = await _storage.read(key: _keyName);
    if (existing != null) {
      return Uint8List.fromList(base64Decode(existing));
    }
    final secretKey = await AesGcm.with256bits().newSecretKey();
    final bytes = await secretKey.extractBytes();
    await _storage.write(key: _keyName, value: base64Encode(bytes));
    return Uint8List.fromList(bytes);
    }
}
