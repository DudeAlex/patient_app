import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Applies lightweight enhancements to scanned document images so text remains
/// legible before an AI pipeline runs full OCR.
class DocumentEnhancer {
  const DocumentEnhancer();

  /// Returns JPEG-encoded bytes with grayscale + contrast tweaks applied.
  Future<Uint8List> enhance(Uint8List sourceBytes) async {
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
}

class DocumentEnhancerException implements Exception {
  const DocumentEnhancerException(this.message);

  final String message;

  @override
  String toString() => message;
}
