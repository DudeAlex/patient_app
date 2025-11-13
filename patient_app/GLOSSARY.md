# Glossary

Canonical terms for the Patient App project. Use these consistently across all documentation and code.

Last Updated: 2025-11-12

---

## Core Concepts

### Patient
The person using the app to manage their health records.
- ✅ Use: "patient", "the patient"
- ❌ Avoid: "user", "customer", "client", "end-user"
- **Why:** Emphasizes healthcare context and compassionate approach

### Record
A single health-related entry (lab result, visit note, medication, etc.)
- ✅ Use: "record", "health record"
- ❌ Avoid: "entry", "document", "item", "note" (unless specifically referring to note-type records)
- **Code:** `Record` (Isar model), `RecordEntity` (domain)

### Attachment
A file associated with a record (photo, scan, audio, PDF, etc.)
- ✅ Use: "attachment", "artifact" (in capture context)
- ❌ Avoid: "file", "asset", "media" (too generic)
- **Code:** `Attachment` (Isar model)

---

## Features & Modes

### Backup
The process of encrypting and uploading data to Google Drive App Data
- ✅ Use: "backup", "Drive backup", "encrypted backup"
- ❌ Avoid: "sync" (unless referring to auto-sync feature), "export", "upload"
- **Why:** "Sync" implies bidirectional; our backup is unidirectional (device → cloud)
- **File:** `patient-backup-v1.enc`

### Auto Sync
The automatic backup feature that runs in the background
- ✅ Use: "auto sync", "automatic backup", "background backup"
- ❌ Avoid: "auto backup" (less clear), "sync" alone
- **Why:** Distinguishes the feature from manual backup action
- **Code:** `AutoSyncStatus`, `AutoSyncRunner`

### Restore
The process of downloading and decrypting a backup from Google Drive
- ✅ Use: "restore", "restore from backup"
- ❌ Avoid: "import", "download", "sync down"

### Capture
The multi-modal process of adding data to a record (photo, scan, voice, etc.)
- ✅ Use: "capture", "capture mode", "capture flow"
- ❌ Avoid: "add", "create", "input" (too generic)
- **Why:** Emphasizes the active, multi-modal nature
- **Code:** `CaptureController`, `CaptureMode`

### AI Companion
The optional AI-powered assistant using Together AI
- ✅ Use: "AI companion", "AI assistant", "wellness companion"
- ❌ Avoid: "AI", "bot", "chatbot", "advisor" (unless referring to specific advisor personas)
- **Why:** "Companion" emphasizes supportive, non-clinical relationship
- **Code:** `AiProcessingService`, `AiProcessingMode`

---

## Operating Modes

### Local-Only Mode
Default mode where all data stays on device, no AI processing
- ✅ Use: "local-only mode", "local-only"
- ❌ Avoid: "offline mode" (app works offline in both modes)
- **Code:** `AiProcessingMode.localOnly`

### AI-Assisted Mode
Opt-in mode where AI helps with data extraction and organization
- ✅ Use: "AI-assisted mode", "AI-assisted"
- ❌ Avoid: "AI mode", "smart mode", "enhanced mode"
- **Code:** `AiProcessingMode.aiAssisted`

---

## Data & Storage

### Isar
The local database used for structured data
- ✅ Use: "Isar", "Isar database", "local database"
- ❌ Avoid: "DB", "database" (without qualifier)
- **Code:** `IsarDatabase`, `Isar` instance

### Attachments Directory
The folder storing files associated with records
- ✅ Use: "attachments directory", "attachments folder"
- ❌ Avoid: "files folder", "media directory"
- **Path:** `app_flutter/attachments/`

### Sync State
Metadata tracking backup status and dirty changes
- ✅ Use: "sync state", "SyncState"
- ❌ Avoid: "backup state", "sync metadata"
- **Code:** `SyncState` (Isar singleton, id=1)

### Dirty Changes
Local modifications not yet backed up
- ✅ Use: "dirty changes", "pending changes", "dirty counters"
- ❌ Avoid: "unsaved changes", "uncommitted changes"
- **Code:** `criticalDirtyCount`, `routineDirtyCount`

---

## Record Types

### Visit
Doctor appointment, hospital visit, consultation
- ✅ Use: "visit", "visit record"
- **Code:** `RecordType.visit`

### Lab
Laboratory test results, blood work, imaging
- ✅ Use: "lab", "lab result", "lab record"
- **Code:** `RecordType.lab`

### Med (Medication)
Prescriptions, medications, supplements
- ✅ Use: "med", "medication", "medication record"
- ❌ Avoid: "drug", "prescription" (unless specifically referring to Rx)
- **Code:** `RecordType.med`

### Note
General health notes, symptoms, observations
- ✅ Use: "note", "health note"
- **Code:** `RecordType.note`

---

## Capture Modes

### Photo Capture
Taking a photo with the device camera
- ✅ Use: "photo capture", "take photo"
- ❌ Avoid: "camera", "picture"
- **Code:** `PhotoCaptureMode`

### Document Scan
Multi-page document scanning with enhancement
- ✅ Use: "document scan", "scan document"
- ❌ Avoid: "scanner", "PDF scan"
- **Code:** `DocumentScanMode`

### Voice Dictation
Recording and transcribing audio notes
- ✅ Use: "voice dictation", "voice note", "voice capture"
- ❌ Avoid: "audio recording", "speech-to-text"
- **Code:** `VoiceCaptureMode`

### Keyboard Entry
Manual text input via form
- ✅ Use: "keyboard entry", "manual entry", "type note"
- ❌ Avoid: "text input", "form entry"

### File Upload
Selecting existing files from device storage
- ✅ Use: "file upload", "upload file"
- ❌ Avoid: "import file", "attach file"

### Email Import
Importing health records from Gmail
- ✅ Use: "email import", "Gmail import"
- ❌ Avoid: "email sync", "mail import"

---

## Architecture Terms

### Domain Layer
Business logic and entities, framework-independent
- ✅ Use: "domain layer", "domain entity", "business logic"
- **Path:** `lib/features/<feature>/domain/`

### Application Layer
Use cases and ports (interfaces)
- ✅ Use: "application layer", "use case", "port"
- ❌ Avoid: "service layer", "business layer"
- **Path:** `lib/features/<feature>/application/`

### Adapter Layer
Implementations of ports (repositories, gateways, presenters)
- ✅ Use: "adapter layer", "adapter", "repository adapter"
- ❌ Avoid: "implementation layer", "infrastructure"
- **Path:** `lib/features/<feature>/adapters/`

### UI Layer (Framework Layer)
Flutter widgets and screens
- ✅ Use: "UI layer", "framework layer", "presentation layer"
- ❌ Avoid: "view layer", "frontend"
- **Path:** `lib/features/<feature>/ui/`

### Port
Interface defining a boundary (repository, gateway, presenter)
- ✅ Use: "port", "repository port", "gateway port"
- ❌ Avoid: "interface", "contract" (too generic)
- **Path:** `lib/features/<feature>/application/ports/`

### Use Case
Single application scenario (save record, fetch records, etc.)
- ✅ Use: "use case", "interactor"
- ❌ Avoid: "service", "handler", "action"
- **Path:** `lib/features/<feature>/application/use_cases/`

---

## Testing Terms

### Manual Test
Human-executed test scenario logged in TESTING.md
- ✅ Use: "manual test", "manual scenario"
- ❌ Avoid: "QA test", "user test"

### Unit Test
Automated test of a single component with mocks
- ✅ Use: "unit test"
- **Path:** `test/features/<feature>/`

### Integration Test
Automated test of multiple components together
- ✅ Use: "integration test", "adapter test"

### Widget Test
Flutter-specific UI component test
- ✅ Use: "widget test"

---

## Milestones

### M1-M11
Numbered milestones in the project roadmap
- ✅ Use: "M2", "M3", "milestone 4"
- ❌ Avoid: "phase 2", "sprint 3", "iteration 4"
- **Files:** `M2_RECORDS_CRUD_PLAN.md`, etc.

---

## Status Terms

### Implemented / Done / Completed
Feature is coded, tested, and merged
- ✅ Use: "implemented", "done", "completed"
- **Checkbox:** `[x]`

### Planned / TODO
Feature is designed but not yet implemented
- ✅ Use: "planned", "TODO", "upcoming"
- **Checkbox:** `[ ]`

### In Progress
Feature is currently being implemented
- ✅ Use: "in progress", "WIP"
- **Checkbox:** `[~]` (if using extended syntax)

### Deferred
Feature is postponed to a later milestone
- ✅ Use: "deferred", "postponed", "future"
- **Checkbox:** `[-]` (if using extended syntax)

### Blocked
Feature cannot proceed due to dependency
- ✅ Use: "blocked", "waiting for"
- **Checkbox:** `[!]` (if using extended syntax)

---

## Common Abbreviations

- **PHI:** Protected Health Information
- **OCR:** Optical Character Recognition
- **STT:** Speech-to-Text
- **TTS:** Text-to-Speech
- **CRUD:** Create, Read, Update, Delete
- **DTO:** Data Transfer Object
- **MVP:** Minimum Viable Product
- **AVD:** Android Virtual Device
- **SHA:** Secure Hash Algorithm
- **AES-GCM:** Advanced Encryption Standard - Galois/Counter Mode
- **API:** Application Programming Interface
- **UI/UX:** User Interface / User Experience
- **WCAG:** Web Content Accessibility Guidelines

---

## For AI Agents

When writing code or documentation:
1. Use the ✅ terms consistently
2. Avoid the ❌ terms
3. Check this glossary when unsure
4. Suggest additions if you find ambiguous terms
5. Update code comments to match canonical terms

When you see inconsistent terminology in existing code/docs, flag it for cleanup but don't block on it.
