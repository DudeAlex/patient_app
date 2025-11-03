import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/attachments.dart';
import '../../capture_core/api/capture_artifact.dart';
import '../../capture_core/api/capture_draft.dart';
import '../../capture_core/api/capture_mode.dart';
import 'analysis/document_enhancer.dart';
import 'models/document_scan_outcome.dart';

class DocumentScanService {
  DocumentScanService({
    ImagePicker? picker,
    DocumentEnhancer? enhancer,
    Uuid? uuid,
  })  : _picker = picker ?? ImagePicker(),
        _enhancer = enhancer ?? const DocumentEnhancer(),
        _uuid = uuid ?? const Uuid();

  final ImagePicker _picker;
  final DocumentEnhancer _enhancer;
  final Uuid _uuid;

  static const int _maxPages = 10;

  bool get isAvailable {
    if (kIsWeb) return false;
    return true;
  }

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

      final artifacts = await _processPage(
        sessionId: context.sessionId,
        file: xfile,
        pageIndex: pages.length,
      );
      pages.add(artifacts);

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

    final draft = CaptureDraft(
      suggestedTags: {'scan', 'document'},
    );

    return DocumentScanOutcome(
      artifacts: artifacts,
      pageCount: totalPages,
      draft: draft,
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
      final originalFile = await AttachmentsStorage.resolveRelativePath(
        originalRelative,
      );
      final originalStat = await originalFile.stat();

      enhancedRelative = await _storeEnhanced(
        sessionId: sessionId,
        originalFile: originalFile,
        pageIndex: pageIndex,
      );
      final enhancedFile = await AttachmentsStorage.resolveRelativePath(
        enhancedRelative,
      );
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
          unawaited(AttachmentsStorage.deleteRelativeFile(originalRelative));
        }
        if (enhancedRelative != null) {
          unawaited(AttachmentsStorage.deleteRelativeFile(enhancedRelative));
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
    final relativePath = await AttachmentsStorage.allocateRelativePath(
      sessionId: sessionId,
      fileName: _buildFileName(pageIndex, 'original', extension),
    );
    final root = await AttachmentsStorage.rootDir();
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

    final relativePath = await AttachmentsStorage.allocateRelativePath(
      sessionId: sessionId,
      fileName: _buildFileName(pageIndex, 'enhanced', '.jpg'),
    );
    final root = await AttachmentsStorage.rootDir();
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
