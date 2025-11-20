import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../capture_core/api/capture_artifact.dart';
import '../../capture_core/api/capture_context_extensions.dart';
import '../../capture_core/api/capture_draft.dart';
import '../../capture_core/api/capture_mode.dart';
import '../../capture_core/adapters/storage/attachments_capture_artifact_storage.dart';
import '../../capture_core/application/ports/capture_artifact_storage.dart';
import 'application/ports/document_scan_gateway.dart';
import 'analysis/document_analysis_pipeline.dart';
import 'analysis/document_clarity_analyzer.dart';
import 'analysis/document_enhancer.dart';
import 'models/document_scan_outcome.dart';

class DocumentScanService implements DocumentScanGateway {
  DocumentScanService({
    ImagePicker? picker,
    DocumentEnhancer? enhancer,
    DocumentClarityAnalyzer? clarityAnalyzer,
    DocumentAnalysisPipeline? analysisPipeline,
    Uuid? uuid,
    CaptureArtifactStorage? artifactStorage,
  })  : _picker = picker ?? ImagePicker(),
        _enhancer = enhancer ?? const DocumentEnhancer(),
        _clarityAnalyzer = clarityAnalyzer,
        _analysisPipeline = analysisPipeline,
        _uuid = uuid ?? const Uuid(),
        _storage =
            artifactStorage ?? const AttachmentsCaptureArtifactStorage();

  final ImagePicker _picker;
  final DocumentEnhancer _enhancer;
  final DocumentClarityAnalyzer? _clarityAnalyzer;
  final DocumentAnalysisPipeline? _analysisPipeline;
  final Uuid _uuid;
  final CaptureArtifactStorage _storage;

  static const int _maxPages = 10;

  @override
  bool get isAvailable {
    if (kIsWeb) return false;
    return true;
  }

  @override
  Future<DocumentScanOutcome?> captureDocument(CaptureContext context) async {
    if (!isAvailable) {
      throw const DocumentScanException(
        'Document scanning is not supported on this device.',
      );
    }

    final pages = <_PageArtifacts>[];
    while (pages.length < _maxPages) {
      final XFile? xfile;
      try {
        xfile = await _picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.rear,
        );
      } on Exception catch (e, st) {
        debugPrint('Document scan capture failed: $e\n$st');
        throw const DocumentScanException(
          'Document scan failed to start. Please try again.',
        );
      }

      if (xfile == null) {
        if (pages.isEmpty) {
          return null;
        }
        break;
      }

      // Show processing overlay IMMEDIATELY after camera closes
      // This prevents users from seeing the "Add Record" page while we process
      context.showProcessingOverlay();

      final pageArtifacts = await _processPage(
        sessionId: context.sessionId,
        file: xfile,
        pageIndex: pages.length,
      );
      var augmented = pageArtifacts;
      var userAcceptedBlurry = false;
      DocumentClarityResult? clarityResult;
      final analyzer = _clarityAnalyzer;
      if (analyzer != null) {
        // Processing overlay is already showing from above
        final originalFile = await _storage.resolveRelativePath(
          pageArtifacts.original.relativePath,
        );
        clarityResult = await analyzer.analyze(originalFile);
        // Check if we need to show quality dialog
        final needsQualityDialog = clarityResult.isSharp == false &&
            (context.promptChoice != null || context.promptRetake != null);
        
        if (needsQualityDialog) {
          // Hide processing overlay before showing dialog
          context.onProcessing?.call(false);
          
          final prompt = context.promptChoice ?? (
              context.promptRetake == null
                  ? null
                  : (String title, String message,
                          {String confirmLabel = 'Retake',
                          String cancelLabel = 'Keep'}) =>
                      context.promptRetake!(title, message));
          if (prompt != null) {
            final retry = await prompt(
              'Page looks blurry',
              clarityResult.reason ??
                  'This page might be hard to read. Retake the photo?',
              confirmLabel: 'Retake page',
              cancelLabel: 'Keep page',
            );
            if (retry) {
              await _discardArtifacts(pageArtifacts);
              continue;
            }
            userAcceptedBlurry = true;
          }
        } else {
          // No dialog needed, hide processing overlay immediately
          context.onProcessing?.call(false);
        }
        
        augmented = _applyClarityMetadata(
          pageArtifacts,
          clarityResult: clarityResult,
          userAcceptedBlurry: userAcceptedBlurry,
        );
      } else {
        // No analyzer, hide processing overlay immediately
        context.onProcessing?.call(false);
      }

      pages.add(augmented);

      if (pages.length >= _maxPages) {
        break;
      }

      final shouldContinue = await _promptForAnotherPage(context);
      if (!shouldContinue) {
        break;
      }
    }

    if (pages.isEmpty) {
      return null;
    }

    final totalPages = pages.length;
    final artifacts = <CaptureArtifact>[];
    for (final page in pages) {
      artifacts.add(page.original.copyWith(pageCount: totalPages));
      artifacts.add(page.enhanced.copyWith(pageCount: totalPages));
    }

    var draft = const CaptureDraft(
      suggestedTags: {'scan', 'document'},
    );

    Map<String, Object?> analysisMetadata = const {};
    final pipeline = _analysisPipeline;
    if (pipeline != null) {
      final onProcessing = context.onProcessing;
      onProcessing?.call(true);
      try {
        final request = DocumentAnalysisRequest(
          sessionId: context.sessionId,
          localeTag: context.locale,
          pages: List.generate(
            pages.length,
            (index) => DocumentAnalysisPage(
              index: index,
              original: pages[index].original,
              enhanced: pages[index].enhanced,
            ),
          ),
        );
        final result = await pipeline.analyze(request);
        if (result.draft != null) {
          draft = draft.merge(result.draft!);
        }
        analysisMetadata = Map.unmodifiable(result.metadata);
      } finally {
        onProcessing?.call(false);
      }
    }

    return DocumentScanOutcome(
      artifacts: artifacts,
      pageCount: totalPages,
      draft: draft,
      metadata: analysisMetadata,
    );
  }

  Future<_PageArtifacts> _processPage({
    required String sessionId,
    required XFile file,
    required int pageIndex,
  }) async {
    var success = false;
    String? originalRelative;
    String? enhancedRelative;
    try {
      originalRelative = await _storeOriginal(
        sessionId: sessionId,
        file: file,
        pageIndex: pageIndex,
      );
      final originalFile =
          await _storage.resolveRelativePath(originalRelative);
      final originalStat = await originalFile.stat();

      enhancedRelative = await _storeEnhanced(
        sessionId: sessionId,
        originalFile: originalFile,
        pageIndex: pageIndex,
      );
      final enhancedFile =
          await _storage.resolveRelativePath(enhancedRelative);
      final enhancedStat = await enhancedFile.stat();

      final baseMetadata = <String, Object?>{
        'source': 'scan.camera',
        'pageIndex': pageIndex,
      };

      final originalArtifact = CaptureArtifact(
        id: _buildArtifactId(pageIndex, 'original'),
        type: CaptureArtifactType.documentScan,
        relativePath: originalRelative,
        createdAt: originalStat.modified,
        mimeType: file.mimeType ?? 'image/jpeg',
        sizeBytes: originalStat.size,
        metadata: Map.unmodifiable({
          ...baseMetadata,
          'variant': 'original',
          'filename': file.name,
        }),
      );

      final enhancedArtifact = CaptureArtifact(
        id: _buildArtifactId(pageIndex, 'enhanced'),
        type: CaptureArtifactType.documentScan,
        relativePath: enhancedRelative,
        createdAt: enhancedStat.modified,
        mimeType: 'image/jpeg',
        sizeBytes: enhancedStat.size,
        metadata: Map.unmodifiable({
          ...baseMetadata,
          'variant': 'enhanced',
          'enhancements': ['grayscale', 'contrast'],
        }),
      );

      success = true;
      return _PageArtifacts(
        original: originalArtifact,
        enhanced: enhancedArtifact,
      );
    } on DocumentEnhancerException catch (e, st) {
      debugPrint('Document enhancement failed: $e\n$st');
      throw const DocumentScanException(
        'We could not enhance the document image. Please try again.',
      );
    } on IOException catch (e, st) {
      debugPrint('Document scan storage failed: $e\n$st');
      throw const DocumentScanException(
        'Saving the scanned page failed. Please retry.',
      );
    } finally {
      if (!success) {
        if (originalRelative != null) {
          unawaited(_storage.deleteRelativeFile(originalRelative));
        }
        if (enhancedRelative != null) {
          unawaited(_storage.deleteRelativeFile(enhancedRelative));
        }
      }
    }
  }

  Future<String> _storeOriginal({
    required String sessionId,
    required XFile file,
    required int pageIndex,
  }) async {
    final extension = _filenameExtension(file.name, file.mimeType);
    final relativePath = await _storage.allocateRelativePath(
      sessionId: sessionId,
      fileName: _buildFileName(pageIndex, 'original', extension),
    );
    final root = await _storage.rootDir();
    final target = File('${root.path}/$relativePath');
    await File(file.path).copy(target.path);
    return relativePath;
  }

  Future<String> _storeEnhanced({
    required String sessionId,
    required File originalFile,
    required int pageIndex,
  }) async {
    final bytes = await originalFile.readAsBytes();
    final enhancedBytes = await _enhancer.enhance(bytes);

    final relativePath = await _storage.allocateRelativePath(
      sessionId: sessionId,
      fileName: _buildFileName(pageIndex, 'enhanced', '.jpg'),
    );
    final root = await _storage.rootDir();
    final target = File('${root.path}/$relativePath');
    await target.writeAsBytes(enhancedBytes, flush: true);
    return relativePath;
  }

  Future<bool> _promptForAnotherPage(CaptureContext context) async {
    final prompt = context.promptChoice;
    if (prompt == null) {
      return false;
    }
    return prompt(
      'Add another page?',
      'Would you like to capture another page for this document?',
      confirmLabel: 'Add page',
      cancelLabel: 'Finish',
    );
  }

  Future<void> _discardArtifacts(_PageArtifacts artifacts) async {
    await _storage.deleteRelativeFile(artifacts.original.relativePath);
    await _storage.deleteRelativeFile(artifacts.enhanced.relativePath);
  }

  _PageArtifacts _applyClarityMetadata(
    _PageArtifacts artifacts, {
    DocumentClarityResult? clarityResult,
    required bool userAcceptedBlurry,
  }) {
    if (clarityResult == null) return artifacts;
    final updatedOriginal = _artifactWithClarity(
      artifacts.original,
      clarityResult,
      userAcceptedBlurry,
    );
    final updatedEnhanced = _artifactWithClarity(
      artifacts.enhanced,
      clarityResult,
      userAcceptedBlurry,
    );
    return _PageArtifacts(original: updatedOriginal, enhanced: updatedEnhanced);
  }

  CaptureArtifact _artifactWithClarity(
    CaptureArtifact artifact,
    DocumentClarityResult clarity,
    bool userAcceptedBlurry,
  ) {
    final metadata = Map<String, Object?>.from(artifact.metadata);
    metadata['claritySource'] = 'laplacian';
    if (clarity.score != null) {
      metadata['clarityScore'] = clarity.score;
    }
    if (clarity.isSharp != null) {
      metadata['clarityIsSharp'] = clarity.isSharp;
    }
    if (clarity.reason != null && clarity.reason!.isNotEmpty) {
      metadata['clarityReason'] = clarity.reason;
    }
    if (userAcceptedBlurry) {
      metadata['clarityUserAccepted'] = true;
    }
    return artifact.copyWith(metadata: Map.unmodifiable(metadata));
  }

  String _buildArtifactId(int pageIndex, String variant) {
    return 'scan_${pageIndex + 1}_${variant}_${_uuid.v4()}';
  }

  String _buildFileName(int pageIndex, String variant, String extension) {
    final pageLabel = (pageIndex + 1).toString().padLeft(2, '0');
    return 'scan_page${pageLabel}_$variant$extension';
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

class _PageArtifacts {
  const _PageArtifacts({
    required this.original,
    required this.enhanced,
  });

  final CaptureArtifact original;
  final CaptureArtifact enhanced;
}

class DocumentScanException implements Exception {
  const DocumentScanException(this.message);

  final String message;

  @override
  String toString() => message;
}
