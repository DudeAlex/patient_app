import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

class VoiceRecordingResult {
  const VoiceRecordingResult({
    required this.duration,
    required this.filePath,
  });

  final Duration duration;
  final String filePath;
}

class VoiceRecorderSheet extends StatefulWidget {
  const VoiceRecorderSheet({super.key, required this.targetPath});

  final String targetPath;

  @override
  State<VoiceRecorderSheet> createState() => _VoiceRecorderSheetState();
}

class _VoiceRecorderSheetState extends State<VoiceRecorderSheet> {
  bool _isRecording = false;
  bool _hasRecording = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRecording() {
    if (_isRecording) return;
    setState(() {
      _isRecording = true;
      _hasRecording = false;
      _elapsed = Duration.zero;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      setState(() {
        _elapsed += const Duration(milliseconds: 200);
      });
    });
  }

  Future<VoiceRecordingResult?> _stopRecording() async {
    if (!_isRecording) return null;
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _hasRecording = true;
    });
    final file = File(widget.targetPath);
    if (!file.existsSync()) {
      await file.writeAsBytes(const <int>[]); // placeholder audio
    }
    return VoiceRecordingResult(
      duration: _elapsed,
      filePath: widget.targetPath,
    );
  }

  Future<void> _discard() async {
    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _hasRecording = false;
      _elapsed = Duration.zero;
    });
    final file = File(widget.targetPath);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final seconds = (_elapsed.inMilliseconds / 1000).toStringAsFixed(1);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Voice recording prototype',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text('$seconds s', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              onPressed: () async {
                if (_isRecording) {
                  final navigator = Navigator.of(context);
                  final result = await _stopRecording();
                  if (!mounted) return;
                  if (result != null) {
                    navigator.pop(result);
                  }
                } else {
                  _startRecording();
                }
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 56)),
              label: Text(_isRecording ? 'Stop' : 'Start'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      await _discard();
                      if (!mounted) return;
                      navigator.pop<VoiceRecordingResult?>(null);
                    },
                    child: const Text('Discard'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _hasRecording
                        ? () {
                            Navigator.of(context).pop(
                              VoiceRecordingResult(
                                duration: _elapsed,
                                filePath: widget.targetPath,
                              ),
                            );
                          }
                        : null,
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
