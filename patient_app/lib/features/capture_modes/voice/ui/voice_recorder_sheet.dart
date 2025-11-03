import 'dart:async';

import 'package:flutter/material.dart';
import 'package:record/record.dart';

class VoiceRecordingResult {
  const VoiceRecordingResult({
    required this.duration,
  });

  final Duration duration;
}

class VoiceRecorderSheet extends StatefulWidget {
  const VoiceRecorderSheet({
    super.key,
    required this.targetPath,
  });

  final String targetPath;

  @override
  State<VoiceRecorderSheet> createState() => _VoiceRecorderSheetState();
}

class _VoiceRecorderSheetState extends State<VoiceRecorderSheet> {
  final Record _recorder = Record();
  bool _isRecording = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  bool _hasRecording = false;

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission required.')),
      );
      return;
    }
    await _recorder.start(
      path: widget.targetPath,
      encoder: AudioEncoder.aacLc,
      bitRate: 128000,
      samplingRate: 44100,
    );
    setState(() {
      _isRecording = true;
      _elapsed = Duration.zero;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed += const Duration(seconds: 1);
      });
    });
  }

  Future<VoiceRecordingResult?> _stopRecording() async {
    if (!_isRecording) return null;
    await _recorder.stop();
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _hasRecording = true;
    });
    return VoiceRecordingResult(duration: _elapsed);
  }

  Future<void> _handleRecordToggle() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeLabel = _elapsed.toString().split('.').first.padLeft(8, '0');
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hold to record voice note',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(timeLabel, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              onPressed: _handleRecordToggle,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 56),
              ),
              label: Text(_isRecording ? 'Stop recording' : 'Start recording'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      if (_isRecording) {
                        await _recorder.stop();
                      }
                      if (!mounted) return;
                      Navigator.of(context).pop<VoiceRecordingResult?>(null);
                    },
                    child: const Text('Discard'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: !_hasRecording && !_isRecording
                        ? null
                        : () async {
                            VoiceRecordingResult? result;
                            if (_isRecording) {
                              result = await _stopRecording();
                            } else {
                              result = VoiceRecordingResult(
                                duration: _elapsed,
                              );
                            }
                            if (!mounted) return;
                            Navigator.of(context).pop(result);
                          },
                    child: const Text('Use recording'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
