# Capture Mode: Photo

Responsibilities:
- Launch camera capture using `image_picker`.
- Copy the resulting image into `AttachmentsStorage` under the session directory.
- Produce a `CaptureResult` populated with `CaptureArtifactType.photo` metadata and suggested tags/notes.

Public API:
- `PhotoCaptureModule` registers the mode with capture_core.
- `PhotoCaptureService` encapsulates camera invocation, local persistence, clarity/ocr analysis hooks.

Dependencies:
- `capture_core` API for mode contracts.
- `core/storage/attachments.dart` for file paths.
- `image_picker` plugin (camera UX).
- `image` package for clarity analysis.

Extension Points:
- Inject alternate `PhotoClarityAnalyzer` or `PhotoOcrExtractor` implementations.
- Replace `image_picker` usage with a custom camera implementation without touching other modules.
