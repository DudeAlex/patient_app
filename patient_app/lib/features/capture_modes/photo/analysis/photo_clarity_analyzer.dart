import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

class PhotoClarityResult {
  const PhotoClarityResult({this.isSharp, this.score, this.reason});

  final bool? isSharp;
  final double? score;
  final String? reason;

  static const PhotoClarityResult unknown = PhotoClarityResult();
}

abstract class PhotoClarityAnalyzer {
  Future<PhotoClarityResult> analyze(File file);
}

class LaplacianVarianceClarityAnalyzer implements PhotoClarityAnalyzer {
  LaplacianVarianceClarityAnalyzer({this.threshold = 1200});

  final double threshold;

  @override
  Future<PhotoClarityResult> analyze(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        return const PhotoClarityResult(reason: 'Unable to decode image');
      }
      final grayscale = img.grayscale(image);
      if (grayscale.width < 3 || grayscale.height < 3) {
        return const PhotoClarityResult(reason: 'Image resolution too low');
      }
      double sum = 0;
      double sumSq = 0;
      int count = 0;
      for (var y = 1; y < grayscale.height - 1; y++) {
        for (var x = 1; x < grayscale.width - 1; x++) {
          final center = grayscale.getPixel(x, y).luminance;
          final top = grayscale.getPixel(x, y - 1).luminance;
          final bottom = grayscale.getPixel(x, y + 1).luminance;
          final left = grayscale.getPixel(x - 1, y).luminance;
          final right = grayscale.getPixel(x + 1, y).luminance;
          final laplacian = -4 * center + top + bottom + left + right;
          sum += laplacian;
          sumSq += laplacian * laplacian;
          count++;
        }
      }
      if (count == 0) {
        return const PhotoClarityResult(reason: 'Image too small');
      }
      final mean = sum / count;
      final variance = max<double>(0, (sumSq / count) - (mean * mean));
      final isSharp = variance >= threshold;
      return PhotoClarityResult(
        isSharp: isSharp,
        score: variance,
        reason: isSharp
            ? null
            : 'Photo may be blurry (clarity score ${variance.toStringAsFixed(0)} < ${threshold.toStringAsFixed(0)}).',
      );
    } catch (_) {
      return const PhotoClarityResult(reason: 'Clarity analysis failed');
    }
  }
}
