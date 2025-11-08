import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../api/capture_controller.dart';
import '../../api/capture_mode.dart';
import '../../api/capture_result.dart';

typedef CaptureDecisionPrompt = Future<bool> Function(
  String title,
  String message, {
  String confirmLabel,
  String cancelLabel,
});

class CaptureLauncherBindings {
  const CaptureLauncherBindings({
    required this.localeTag,
    required this.isAccessibilityEnabled,
    this.withUiContext,
    required this.promptRetake,
    required this.promptChoice,
  });

  final String localeTag;
  final bool isAccessibilityEnabled;
  final Future<T?> Function<T>(Future<T?> Function(BuildContext context) action)?
      withUiContext;
  final Future<bool> Function(String title, String message) promptRetake;
  final CaptureDecisionPrompt promptChoice;
}

/// Presenter that keeps capture-launcher orchestration outside Flutter widgets.
class CaptureLauncherPresenter {
  CaptureLauncherPresenter(this._controller);

  final CaptureController _controller;
  final ValueNotifier<bool> _processingNotifier = ValueNotifier<bool>(false);

  ValueListenable<bool> get processing => _processingNotifier;
  bool get isProcessing => _processingNotifier.value;

  List<CaptureMode> availableModes() {
    return _controller.modes
        .where((mode) => mode.isAvailable())
        .toList(growable: false);
  }

  Future<CaptureResult> startCapture({
    required CaptureMode mode,
    required CaptureLauncherBindings bindings,
  }) async {
    final sessionId = _controller.createSession();
    final captureContext = CaptureContext(
      sessionId: sessionId,
      locale: bindings.localeTag,
      isAccessibilityEnabled: bindings.isAccessibilityEnabled,
      promptRetake: bindings.promptRetake,
      promptChoice: bindings.promptChoice,
      onProcessing: (processing) => _processingNotifier.value = processing,
      withUiContext: bindings.withUiContext,
    );

    try {
      final result = await _controller.startMode(
        modeId: mode.id,
        context: captureContext,
      );
      return result;
    } catch (error) {
      await _controller.discardSession(sessionId);
      rethrow;
    } finally {
      if (_processingNotifier.value) {
        _processingNotifier.value = false;
      }
    }
  }

  void dispose() {
    _processingNotifier.dispose();
  }
}
