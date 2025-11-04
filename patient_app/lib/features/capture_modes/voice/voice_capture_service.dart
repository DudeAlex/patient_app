import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../../core/storage/attachments.dart';
import '../../capture_core/api/capture_artifact.dart';
import '../../capture_core/api/capture_draft.dart';
import '../../capture_core/api/capture_mode.dart';
import 'analysis/voice_transcription_pipeline.dart';
import 'models/voice_capture_outcome.dart';
import 'ui/voice_recorder_sheet.dart';

class VoiceCaptureService {
  VoiceCaptureService({VoiceTranscriptionPipeline? transcriptionPipeline})
    : _transcriptionPipeline =
          transcriptionPipeline ?? const StubVoiceTranscriptionPipeline();

  final VoiceTranscriptionPipeline _transcriptionPipeline;

  Future<VoiceCaptureOutcome?> captureVoice(CaptureContext context) async {
    final sessionId = context.sessionId;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final root = await AttachmentsStorage.rootDir();
    final allocatedRelative = await AttachmentsStorage.allocateRelativePath(
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
      await AttachmentsStorage.deleteRelativeFile(allocatedRelative);
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
