import 'package:flutter/material.dart';

import '../adapters/presenters/capture_launcher_presenter.dart';
import '../api/capture_controller.dart';
import '../api/capture_mode.dart';
import '../api/capture_result.dart';

typedef CaptureResultCallback =
    Future<void> Function(
      BuildContext context,
      CaptureMode mode,
      CaptureResult result,
    );

typedef CaptureFallbackCallback = Future<void> Function(BuildContext context);

class CaptureLauncherScreen extends StatefulWidget {
  const CaptureLauncherScreen({
    super.key,
    required this.controller,
    required this.locale,
    required this.onResult,
    required this.onKeyboardEntry,
    this.isAccessibilityEnabled = false,
    this.emptyStateBuilder,
  });

  final CaptureController controller;
  final Locale locale;
  final bool isAccessibilityEnabled;
  final CaptureResultCallback onResult;
  final CaptureFallbackCallback onKeyboardEntry;
  final WidgetBuilder? emptyStateBuilder;

  @override
  State<CaptureLauncherScreen> createState() => _CaptureLauncherScreenState();
}

class _CaptureLauncherScreenState extends State<CaptureLauncherScreen> {
  late final CaptureLauncherPresenter _presenter;

  Future<T?> _withUiContext<T>(
    Future<T?> Function(BuildContext context) action,
  ) async {
    if (!mounted) return null;
    return action(context);
  }

  @override
  void initState() {
    super.initState();
    _presenter = CaptureLauncherPresenter(widget.controller);
  }

  @override
  void dispose() {
    _presenter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modes = _presenter.availableModes();
    return ValueListenableBuilder<bool>(
      valueListenable: _presenter.processing,
      builder: (context, isProcessing, child) {
        return Stack(
          children: [
            child!,
            if (isProcessing) const _ProcessingOverlay(),
          ],
        );
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Add Record')),
        body: SafeArea(
          child: modes.isEmpty
              ? (widget.emptyStateBuilder?.call(context) ??
                    _DefaultEmptyState(onKeyboardEntry: widget.onKeyboardEntry))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: modes.length + 1,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index < modes.length) {
                      final mode = modes[index];
                      return _CaptureModeTile(
                        mode: mode,
                        onPressed: () => _startMode(context, mode),
                      );
                    }
                    return _CaptureFallbackTile(
                      onPressed: () => widget.onKeyboardEntry(context),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _startMode(BuildContext context, CaptureMode mode) async {
    try {
      final result = await _presenter.startCapture(
        mode: mode,
        bindings: CaptureLauncherBindings(
          localeTag: widget.locale.toLanguageTag(),
          isAccessibilityEnabled: widget.isAccessibilityEnabled,
          withUiContext: _withUiContext,
          promptRetake: (title, message) => _showDecisionDialog(
            context,
            title: title,
            message: message,
            confirmLabel: 'Retake',
            cancelLabel: 'Keep',
          ),
          promptChoice: (title, message,
                  {String confirmLabel = 'OK', String cancelLabel = 'Cancel'}) =>
              _showDecisionDialog(
            context,
            title: title,
            message: message,
            confirmLabel: confirmLabel,
            cancelLabel: cancelLabel,
          ),
        ),
      );
      if (!mounted || !context.mounted) return;
      await widget.onResult(context, mode, result);
    } catch (e) {
      if (!mounted || !context.mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text('Unable to start ${mode.displayName}: $e')),
      );
    }
  }

  Future<bool> _showDecisionDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _CaptureModeTile extends StatelessWidget {
  const _CaptureModeTile({required this.mode, required this.onPressed});

  final CaptureMode mode;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      ),
      icon: Icon(_resolveIcon(mode.iconName)),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          mode.displayName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }

  IconData _resolveIcon(String iconName) {
    final iconData = _materialIconMap[iconName];
    return iconData ?? Icons.extension;
  }
}

const Map<String, IconData> _materialIconMap = {
  'camera_alt': Icons.camera_alt,
  'document_scanner': Icons.document_scanner,
  'keyboard': Icons.keyboard,
  'mic': Icons.mic,
  'upload_file': Icons.upload_file,
  'email': Icons.email,
};

class _CaptureFallbackTile extends StatelessWidget {
  const _CaptureFallbackTile({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          alignment: Alignment.centerLeft,
        ),
        icon: const Icon(Icons.keyboard),
        label: Text(
          'Use keyboard entry instead',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay();

  @override
  Widget build(BuildContext context) {
    // Get the theme background color for a clean, opaque overlay
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    
    return Positioned.fill(
      child: AbsorbPointer(
        child: DecoratedBox(
          // Use solid background color instead of semi-transparent
          // This completely hides the "Add Record" page underneath
          // so users only see the processing indicator
          decoration: BoxDecoration(color: backgroundColor),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Checking clarity…',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DefaultEmptyState extends StatelessWidget {
  const _DefaultEmptyState({required this.onKeyboardEntry});

  final CaptureFallbackCallback onKeyboardEntry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.extension_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Capture modes are not available yet. You can still use keyboard entry.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _CaptureFallbackTile(onPressed: () => onKeyboardEntry(context)),
          ],
        ),
      ),
    );
  }
}
