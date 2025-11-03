# Capture Mode: Document Scan

Responsibilities:
- Provide a multi-page document scanning experience that stores both the raw capture and an enhanced copy per page.
- Persist artefacts in the session directory so the review flow can surface originals or cleaned versions.
- Perform baseline clarity analysis with retake prompts and attach metadata for future AI extraction (page index, enhancements applied, clarity score/source).
- Expose an optional analysis pipeline hook that can run OCR/LLM extraction and return structured draft suggestions.

Public API:
- `DocumentScanModule` registers the scan mode with `capture_core`.
- `DocumentScanService` orchestrates camera capture, basic enhancement, and attachments storage.
- `DocumentEnhancer` performs lightweight post-processing (grayscale + contrast) ahead of downstream OCR.
- `DocumentClarityAnalyzer` scores pages for blur and surfaces retry prompts.
- `DocumentAnalysisPipeline` consumes the captured artefacts and returns draft/metadata suggestions (stubbed by default).

Dependencies:
- `image_picker` for camera access.
- `image` package for enhancement pipeline.
- `AttachmentsStorage` for session-aware persistence.
- Optional clarity analyzers injected via constructor (defaults to Laplacian variance).
- Optional document analysis pipeline injected via constructor (defaults to a stub implementation).

Extension Points:
- Replace `DocumentEnhancer` with a more advanced edge-detection/thresholding pipeline.
- Swap in a different `DocumentClarityAnalyzer` (e.g., ML-based) without touching the rest of the module.
- Swap in a production `DocumentAnalysisPipeline` that performs OCR/LLM extraction.
- Inject an alternative scanner implementation that provides native document detection while reusing the service wiring.
