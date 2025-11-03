# Capture Mode: Document Scan

Responsibilities:
- Provide a multi-page document scanning experience that stores both the raw capture and an enhanced copy per page.
- Persist artefacts in the session directory so the review flow can surface originals or cleaned versions.
- Offer a path for future AI text extraction by attaching metadata (page index, enhancements applied, source).

Public API:
- `DocumentScanModule` registers the scan mode with `capture_core`.
- `DocumentScanService` orchestrates camera capture, basic enhancement, and attachments storage.
- `DocumentEnhancer` performs lightweight post-processing (grayscale + contrast) ahead of downstream OCR.

Dependencies:
- `image_picker` for camera access.
- `image` package for enhancement pipeline.
- `AttachmentsStorage` for session-aware persistence.

Extension Points:
- Replace `DocumentEnhancer` with a more advanced edge-detection/thresholding pipeline.
- Inject an alternative scanner implementation that provides native document detection while reusing the service wiring.
