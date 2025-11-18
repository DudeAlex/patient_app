import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Top-level function for isolate execution
/// Must be top-level or static to work with compute()
Uint8List _enhanceImageInIsolate(Uint8List sourceBytes) {
  final decoded = img.decodeImage(sourceBytes);
  if (decoded == null) {
    throw const DocumentEnhancerException('Unable to decode image data.');
  }

  final grayscale = img.grayscale(decoded);
  final contrasted = img.adjustColor(
    grayscale,
    contrast: 1.2,
    brightness: 0,
  );
  final encoded = img.encodeJpg(contrasted, quality: 90);
  return Uint8List.fromList(encoded);
}

/// Applies lightweight enhancements to scanned document images so text remains
/// legible before an AI pipeline runs full OCR.
class DocumentEnhancer {
  const DocumentEnhancer();

  /// Returns JPEG-encoded bytes with grayscale + contrast tweaks applied.
  /// Runs image processing in background isolate to avoid blocking UI.
  Future<Uint8List> enhance(Uint8List sourceBytes) async {
    try {
      // Run CPU-intensive enhancement in background isolate
      return await compute(_enhanceImageInIsolate, sourceBytes);
    } catch (e) {
      if (e is DocumentEnhancerException) {
        rethrow;
      }
      throw const DocumentEnhancerException('Image enhancement failed.');
    }
  }
}

class DocumentEnhancerException implements Exception {
  const DocumentEnhancerException(this.message);

  final String message;

  @override
  String toString() => message;
}
