import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';

import '../../capture_core/api/capture_artifact.dart';
import '../../capture_core/api/capture_context_extensions.dart';
import '../../capture_core/api/capture_draft.dart';
import '../../capture_core/api/capture_mode.dart';
import '../../capture_core/adapters/storage/attachments_capture_artifact_storage.dart';
import '../../capture_core/application/ports/capture_artifact_storage.dart';
import 'application/ports/photo_capture_gateway.dart';
import 'analysis/photo_clarity_analyzer.dart';
import 'analysis/photo_ocr_extractor.dart';
import 'models/photo_capture_outcome.dart';

class PhotoCaptureService implements PhotoCaptureGateway {
  PhotoCaptureService({
    ImagePicker? picker,
    PhotoClarityAnalyzer? clarityAnalyzer,
    PhotoOcrExtractor? ocrExtractor,
    CaptureArtifactStorage? artifactStorage,
  })  : _picker = picker ?? ImagePicker(),
       _clarityAnalyzer = clarityAnalyzer,
       _ocrExtractor = ocrExtractor ?? const StubPhotoOcrExtractor(),
       _storage =
           artifactStorage ?? const AttachmentsCaptureArtifactStorage();

  final ImagePicker _picker;
  final PhotoClarityAnalyzer? _clarityAnalyzer;
  final PhotoOcrExtractor _ocrExtractor;
  final CaptureArtifactStorage _storage;

  @override
  Future<PhotoCaptureOutcome?> capturePhoto(CaptureContext context) async {
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (xfile == null) {
        return null;
      }

      // Step 1: Show processing overlay IMMEDIATELY after camera closes
      // This is the first thing we do after getting the photo, before any
      // file operations. This gives the UI the maximum time to update and
      // show the overlay while we're doing file storage work.
      context.showProcessingOverlay();

      // Step 2: Store the captured photo to device storage
      // These file operations take ~50-200ms, which gives the overlay time
      // to render on screen while we're working.
      final relativePath = await _storeOnDevice(
        sessionId: context.sessionId,
        sourcePath: xfile.path,
        fileNameHint: _buildFileName(xfile),
      );
      final savedFile = await _storage.resolveRelativePath(relativePath);
      final stat = await savedFile.stat();

      // Step 3: Analyze photo clarity (check if blurry)
      // This can take 500ms-2s depending on image size
      PhotoClarityResult? clarityResult;
      final analyzer = _clarityAnalyzer;
      if (analyzer != null) {
        clarityResult = await analyzer.analyze(savedFile);
      }

      // Step 4: Extract text from photo using OCR
      // This can take 500ms-3s depending on text complexity
      final ocrText = await _ocrExtractor.extract(savedFile);

      // Step 5: Build metadata with analysis results
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

      // Step 6: Create artifact with all metadata
      final artifact = CaptureArtifact(
        id: xfile.name,
        type: CaptureArtifactType.photo,
        relativePath: relativePath,
        createdAt: stat.modified,
        mimeType: xfile.mimeType ?? 'image/jpeg',
        sizeBytes: stat.size,
        metadata: Map.unmodifiable(metadata),
      );

      // Step 7: Create draft with OCR text if available
      CaptureDraft? draft;
      if (ocrText != null && ocrText.isNotEmpty) {
        draft = CaptureDraft(
          suggestedDetails: ocrText,
          suggestedTags: {'photo', 'ocr'},
        );
      } else {
        draft = const CaptureDraft(suggestedTags: {'photo'});
      }

      // Step 8: Return outcome WITHOUT hiding processing overlay
      // The CapturePhotoUseCase will handle hiding the overlay after deciding
      // whether to show a quality dialog or proceed to review
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

  @override
  Future<void> discardArtifacts(List<CaptureArtifact> artifacts) async {
    for (final artifact in artifacts) {
      await _storage.deleteRelativeFile(artifact.relativePath);
    }
  }

  Future<String> _storeOnDevice({
    required String sessionId,
    required String sourcePath,
    required String fileNameHint,
  }) async {
    final relativePath = await _storage.allocateRelativePath(
      sessionId: sessionId,
      fileName: fileNameHint,
    );
    final root = await _storage.rootDir();
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
