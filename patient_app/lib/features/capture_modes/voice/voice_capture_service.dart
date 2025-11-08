import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../capture_core/api/capture_artifact.dart';
import '../../capture_core/api/capture_draft.dart';
import '../../capture_core/api/capture_mode.dart';
import '../../capture_core/adapters/storage/attachments_capture_artifact_storage.dart';
import '../../capture_core/application/ports/capture_artifact_storage.dart';
import 'analysis/voice_transcription_pipeline.dart';
import 'models/voice_capture_outcome.dart';
import 'ui/voice_recorder_sheet.dart';
import 'application/ports/voice_capture_gateway.dart';

class VoiceCaptureService implements VoiceCaptureGateway {
  VoiceCaptureService({
    VoiceTranscriptionPipeline? transcriptionPipeline,
    CaptureArtifactStorage? artifactStorage,
  })  : _transcriptionPipeline =
            transcriptionPipeline ?? const StubVoiceTranscriptionPipeline(),
        _storage =
            artifactStorage ?? const AttachmentsCaptureArtifactStorage();

  final VoiceTranscriptionPipeline _transcriptionPipeline;
  final CaptureArtifactStorage _storage;

  @override
  Future<VoiceCaptureOutcome?> captureVoice(CaptureContext context) async {
    final sessionId = context.sessionId;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final root = await _storage.rootDir();
    final allocatedRelative = await _storage.allocateRelativePath(
      sessionId: sessionId,
      fileName: 'voice_$timestamp.m4a',
    );
    final absolutePath = p.join(root.path, allocatedRelative);

    VoiceRecordingResult? recording;
    final withUi = context.withUiContext;
    if (withUi == null) {
      return null;
    }
    recording = await withUi(
      (uiContext) => showModalBottomSheet<VoiceRecordingResult?>(
        context: uiContext,
        isScrollControlled: true,
        builder: (_) => VoiceRecorderSheet(targetPath: absolutePath),
      ),
    );

    if (recording == null) {
      await _storage.deleteRelativeFile(allocatedRelative);
      return null;
    }

    final recordedFile = File(recording.filePath);
    String relativePath;
    File file;
    if (!p.isWithin(root.path, recordedFile.path)) {
      await recordedFile.copy(absolutePath);
      relativePath = allocatedRelative;
      file = File(absolutePath);
    } else {
      relativePath = p.relative(recordedFile.path, from: root.path);
      file = File(p.join(root.path, relativePath));
    }
    final stat = await file.stat();

    context.onProcessing?.call(true);
    VoiceTranscriptionResult transcriptionResult;
    try {
      transcriptionResult = await _transcriptionPipeline.transcribe(
        VoiceTranscriptionRequest(
          sessionId: context.sessionId,
          localeTag: context.locale,
          relativePath: relativePath,
          filePath: file.path,
          durationMs: recording.duration.inMilliseconds,
        ),
      );
    } finally {
      context.onProcessing?.call(false);
    }

    final metadata = <String, Object?>{
      'source': 'voice.microphone',
      'durationMs': recording.duration.inMilliseconds,
      if (transcriptionResult.metadata.isNotEmpty)
        'analysis': transcriptionResult.metadata,
    };

    final artifact = CaptureArtifact(
      id: p.basename(relativePath),
      type: CaptureArtifactType.audio,
      relativePath: relativePath,
      createdAt: stat.modified,
      mimeType: 'audio/m4a',
      sizeBytes: stat.size,
      durationMs: recording.duration.inMilliseconds,
      metadata: Map.unmodifiable(metadata),
    );

    final draft = transcriptionResult.draft ??
        const CaptureDraft(
          suggestedTags: {'voice'},
        );

    return VoiceCaptureOutcome(
      artifact: artifact,
      draft: draft,
    );
  }
}
