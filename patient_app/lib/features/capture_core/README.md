# capture_core Module

Responsibilities:
- Provides the multi-modal capture launcher UI and navigation shell.
- Manages capture session state, review panel orchestration, and communication with downstream modules (records, attachments).
- Registers available `CaptureMode` plugins (photo, scan, voice, file, email) and exposes flows to the app shell.

Public API (planned):
- `CaptureModule.register(container)` – registers services/routes.
- `CaptureController` – coordinates lifecycle of a capture session.
- `CaptureMode` – abstract base describing requirements, permission handling, and payload format.
- `CaptureReviewScreen` – shared UI for reviewing artefacts before saving.

Dependencies:
- `core/storage/attachments.dart` for physical artefact persistence.
- `features/records` service interfaces for saving records/attachments.
- Optional mode-specific dependencies injected via `CaptureMode`.

Events / Notifications:
- Emits `CaptureSessionState` updates (loading, success, failure).
- Notifies dirty tracking via records module hooks upon commit.

Testing:
- Unit tests for `CaptureController` (mock modes).
- Widget tests for launcher and review screens (ensuring accessibility labels/copy).

Docs:
- See `M5_MULTI_MODAL_PLAN.md` for feature roadmap and manual test scenarios.
