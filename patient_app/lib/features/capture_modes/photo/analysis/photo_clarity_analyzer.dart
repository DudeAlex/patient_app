import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
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

/// Data class for passing parameters to isolate
class _ClarityAnalysisParams {
  const _ClarityAnalysisParams(this.bytes, this.threshold);
  
  final Uint8List bytes;
  final double threshold;
}

/// Top-level function for isolate execution
/// Must be top-level or static to work with compute()
PhotoClarityResult _analyzeClarityInIsolate(_ClarityAnalysisParams params) {
  try {
    final image = img.decodeImage(params.bytes);
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
    final isSharp = variance >= params.threshold;
    return PhotoClarityResult(
      isSharp: isSharp,
      score: variance,
      reason: isSharp
          ? null
          : 'Photo may be blurry (clarity score ${variance.toStringAsFixed(0)} < ${params.threshold.toStringAsFixed(0)}).',
    );
  } catch (_) {
    return const PhotoClarityResult(reason: 'Clarity analysis failed');
  }
}

class LaplacianVarianceClarityAnalyzer implements PhotoClarityAnalyzer {
  LaplacianVarianceClarityAnalyzer({this.threshold = 1200});

  final double threshold;

  @override
  Future<PhotoClarityResult> analyze(File file) async {
    try {
      // Read file bytes on main thread (fast I/O operation)
      final bytes = await file.readAsBytes();
      
      // Run CPU-intensive analysis in background isolate to avoid blocking UI
      final params = _ClarityAnalysisParams(bytes, threshold);
      return await compute(_analyzeClarityInIsolate, params);
    } catch (_) {
      return const PhotoClarityResult(reason: 'Clarity analysis failed');
    }
  }
}
