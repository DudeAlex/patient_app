import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/storage/attachments.dart';
import '../../capture_core/api/capture_artifact.dart';
import '../../capture_core/api/capture_draft.dart';
import '../../capture_core/api/capture_mode.dart';
import 'analysis/photo_clarity_analyzer.dart';
import 'analysis/photo_ocr_extractor.dart';
import 'models/photo_capture_outcome.dart';

class PhotoCaptureService {
  PhotoCaptureService({
    ImagePicker? picker,
    PhotoClarityAnalyzer? clarityAnalyzer,
    PhotoOcrExtractor? ocrExtractor,
  }) : _picker = picker ?? ImagePicker(),
       _clarityAnalyzer = clarityAnalyzer,
       _ocrExtractor = ocrExtractor ?? const StubPhotoOcrExtractor();

  final ImagePicker _picker;
  final PhotoClarityAnalyzer? _clarityAnalyzer;
  final PhotoOcrExtractor _ocrExtractor;

  Future<PhotoCaptureOutcome?> capturePhoto(CaptureContext context) async {
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (xfile == null) {
        return null;
      }

      final relativePath = await _storeOnDevice(
        sessionId: context.sessionId,
        sourcePath: xfile.path,
        fileNameHint: _buildFileName(xfile),
      );
      final savedFile = await AttachmentsStorage.resolveRelativePath(
        relativePath,
      );
      final stat = await savedFile.stat();

      PhotoClarityResult? clarityResult;
      final analyzer = _clarityAnalyzer;
      if (analyzer != null) {
        clarityResult = await analyzer.analyze(savedFile);
      }

      final ocrText = await _ocrExtractor.extract(savedFile);

      final clarityScore = clarityResult?.score;
      final clarityIsSharp = clarityResult?.isSharp;
      final clarityReason = clarityResult?.reason;

      final metadata = <String, Object?>{
        'source': 'photo.camera',
        if (clarityScore != null) 'clarityScore': clarityScore,
        if (clarityIsSharp != null) 'clarityIsSharp': clarityIsSharp,
        if (clarityReason != null) 'clarityReason': clarityReason,
        if (ocrText != null && ocrText.isNotEmpty) 'ocrText': ocrText,
      };

      final artifact = CaptureArtifact(
        id: xfile.name,
        type: CaptureArtifactType.photo,
        relativePath: relativePath,
        createdAt: stat.modified,
        mimeType: xfile.mimeType ?? 'image/jpeg',
        sizeBytes: stat.size,
        metadata: Map.unmodifiable(metadata),
      );

      CaptureDraft? draft;
      if (ocrText != null && ocrText.isNotEmpty) {
        draft = CaptureDraft(
          suggestedDetails: ocrText,
          suggestedTags: {'photo', 'ocr'},
        );
      } else {
        draft = const CaptureDraft(suggestedTags: {'photo'});
      }

      return PhotoCaptureOutcome(
        artifact: artifact,
        draft: draft,
        clarity: clarityResult,
      );
    } on Exception catch (e, st) {
      debugPrint('Photo capture failed: $e\n$st');
      throw PhotoCaptureException('Camera capture failed. Please try again.');
    }
  }

  Future<void> discardArtifacts(List<CaptureArtifact> artifacts) async {
    for (final artifact in artifacts) {
      await AttachmentsStorage.deleteRelativeFile(artifact.relativePath);
    }
  }

  Future<String> _storeOnDevice({
    required String sessionId,
    required String sourcePath,
    required String fileNameHint,
  }) async {
    final relativePath = await AttachmentsStorage.allocateRelativePath(
      sessionId: sessionId,
      fileName: fileNameHint,
    );
    final root = await AttachmentsStorage.rootDir();
    final target = File('${root.path}/$relativePath');
    final sourceFile = File(sourcePath);
    await sourceFile.copy(target.path);
    return relativePath;
  }

  String _buildFileName(XFile xfile) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = _filenameExtension(xfile.name, xfile.mimeType);
    return 'photo_$timestamp$extension';
  }

  String _filenameExtension(String originalName, String? mimeType) {
    final dotIndex = originalName.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < originalName.length - 1) {
      return originalName.substring(dotIndex);
    }
    switch (mimeType) {
      case 'image/png':
        return '.png';
      case 'image/gif':
        return '.gif';
      default:
        return '.jpg';
    }
  }
}

class PhotoCaptureException implements Exception {
  PhotoCaptureException(this.message);

  final String message;

  @override
  String toString() => message;
}
