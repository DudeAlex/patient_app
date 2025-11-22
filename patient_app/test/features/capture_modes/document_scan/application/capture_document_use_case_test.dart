import 'package:flutter_test/flutter_test.dart';

import 'package:patient_app/features/capture_core/api/capture_artifact.dart';
import 'package:patient_app/features/capture_core/api/capture_mode.dart';
import 'package:patient_app/features/capture_modes/document_scan/application/ports/document_scan_gateway.dart';
import 'package:patient_app/features/capture_modes/document_scan/application/use_cases/capture_document_use_case.dart';
import 'package:patient_app/features/capture_modes/document_scan/models/document_scan_outcome.dart';

void main() {
  group('CaptureDocumentUseCase', () {
    test('returns cancelled result when gateway yields null', () async {
      final gateway = _RecordingGateway(null);
      final useCase = CaptureDocumentUseCase(gateway);

      final result = await useCase.execute(_context());

      expect(result.completed, isFalse);
      expect(gateway.captureCalls, 1);
    });

    test('wraps artifacts/draft when gateway returns outcome', () async {
      final outcome = DocumentScanOutcome(
        artifacts: [
          CaptureArtifact(
            id: 'id',
            type: CaptureArtifactType.documentScan,
            relativePath: 'scan.jpg',
            createdAt: DateTime(2025),
          ),
        ],
        pageCount: 1,
      );
      final gateway = _RecordingGateway(outcome);
      final useCase = CaptureDocumentUseCase(gateway);

      final result = await useCase.execute(_context());

      expect(result.completed, isTrue);
      expect(result.artifacts, hasLength(1));
    });
  });
}

CaptureContext _context() => const CaptureContext(sessionId: 'session', locale: 'en');

class _RecordingGateway implements DocumentScanGateway {
  _RecordingGateway(this._outcome);

  final DocumentScanOutcome? _outcome;
  int captureCalls = 0;

  @override
  bool get isAvailable => true;

  @override
  Future<DocumentScanOutcome?> captureDocument(CaptureContext context) async {
    captureCalls += 1;
    return _outcome;
  }
}
