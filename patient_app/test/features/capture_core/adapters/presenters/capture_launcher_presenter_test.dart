import 'package:flutter_test/flutter_test.dart';

import 'package:patient_app/features/capture_core/adapters/presenters/capture_launcher_presenter.dart';
import 'package:patient_app/features/capture_core/api/capture_artifact.dart';
import 'package:patient_app/features/capture_core/api/capture_controller.dart';
import 'package:patient_app/features/capture_core/api/capture_draft.dart';
import 'package:patient_app/features/capture_core/api/capture_mode.dart';
import 'package:patient_app/features/capture_core/api/capture_result.dart';

void main() {
  group('CaptureLauncherPresenter', () {
    test('filters unavailable modes', () {
      final controller = _FakeController(
        modes: <CaptureMode>[
          _FakeMode(id: 'photo', available: true),
          _FakeMode(id: 'voice', available: false),
        ],
      );
      final presenter = CaptureLauncherPresenter(controller);

      final available = presenter.availableModes();

      expect(available.map((mode) => mode.id), equals(<String>['photo']));
    });

    test('returns capture result and toggles processing', () async {
      final controller = _FakeController(
        modes: <CaptureMode>[_FakeMode(id: 'voice')],
        onStartMode: (context) async {
          context.onProcessing?.call(true);
          context.onProcessing?.call(false);
          return CaptureResult(
            completed: true,
            draft: const CaptureDraft(suggestedTags: {'voice'}),
            artifacts: <CaptureArtifact>[
              CaptureArtifact(
                id: 'voice1',
                type: CaptureArtifactType.audio,
                relativePath: 'voice1.m4a',
                createdAt: DateTime(2025),
                mimeType: 'audio/m4a',
              ),
            ],
          );
        },
      );
      final presenter = CaptureLauncherPresenter(controller);

      final result = await presenter.startCapture(
        mode: controller.modes.first,
        bindings: _bindings(),
      );

      expect(result.completed, isTrue);
      expect(result.artifacts, hasLength(1));
      expect(presenter.isProcessing, isFalse);
      expect(controller.capturedContext?.locale, 'en');
    });

    test('discards session and rethrows on failure', () async {
      final controller = _FakeController(
        modes: <CaptureMode>[_FakeMode(id: 'scan')],
        onStartMode: (_) => Future<CaptureResult>.error(StateError('boom')),
      );
      final presenter = CaptureLauncherPresenter(controller);

      await expectLater(
        () => presenter.startCapture(
          mode: controller.modes.first,
          bindings: _bindings(),
        ),
        throwsA(isA<StateError>()),
      );

      expect(controller.discardedSessions, contains('session-0'));
    });
  });
}

CaptureLauncherBindings _bindings() {
  return CaptureLauncherBindings(
    localeTag: 'en',
    isAccessibilityEnabled: false,
    withUiContext: <T>(action) => Future<T?>.value(null),
    promptRetake: (title, message) => Future<bool>.value(false),
    promptChoice: (
      title,
      message, {
      String confirmLabel = 'OK',
      String cancelLabel = 'Cancel',
    }) =>
        Future<bool>.value(true),
  );
}

class _FakeMode implements CaptureMode {
  _FakeMode({
    required this.id,
    this.available = true,
  });

  @override
  final String id;

  final bool available;

  @override
  String get displayName => id;

  @override
  String get iconName => 'mic';

  @override
  bool isAvailable() => available;

  @override
  Future<CaptureResult> startCapture(CaptureContext context) {
    throw UnimplementedError();
  }
}

class _FakeController implements CaptureController {
  _FakeController({
    required this.modes,
    Future<CaptureResult> Function(CaptureContext context)? onStartMode,
  }) : _onStartMode = onStartMode ?? _defaultStartMode;

  @override
  List<CaptureMode> modes;

  int _sessionCount = 0;
  final List<String> discardedSessions = <String>[];
  final Future<CaptureResult> Function(CaptureContext context) _onStartMode;
  CaptureContext? capturedContext;

  @override
  String createSession() {
    final id = 'session-${_sessionCount++}';
    return id;
  }

  @override
  Future<void> discardSession(String sessionId) async {
    discardedSessions.add(sessionId);
  }

  @override
  Future<CaptureResult> startMode({
    required String modeId,
    required CaptureContext context,
  }) async {
    capturedContext = context;
    return _onStartMode(context);
  }

  static Future<CaptureResult> _defaultStartMode(CaptureContext context) async {
    return const CaptureResult(completed: true);
  }
}
