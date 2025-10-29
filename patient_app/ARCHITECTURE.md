# Architecture

Overview
- Local-first app with Isar for structured data and file storage for attachments (mobile)
- Optional encrypted backup to Google Drive App Data (mobile)
- Web build runs with IndexedDB-backed Isar; backup disabled by default
- Dual operating modes: Local Only (default) and AI-Assisted (opt-in via Together AI) for analysis and encouragement.

Key Modules
- `lib/ui/` app shell and screens
  - `ui/app.dart` Material app + Settings entry
  - `ui/settings/settings_screen.dart` wires UI to the reusable backup manager
  - Planned: `ui/records/add_record/` multi-modal capture flow + accessibility-first review panel
- `lib/core/`
  - `core/db/isar.dart` open Isar with schemas
  - `core/storage/attachments.dart` manage attachments directory
  - Planned: `core/ai/ai_processing_service.dart` encapsulates Together AI calls, consent checks, retries, schema validation
  - Planned: `core/support/support_network.dart` manages trusted contacts, emergency actions, and sharing audit trail
- `packages/google_drive_backup/`
  - `auth/` Google Sign-In wrapper + injected HTTP client (v7 API)
  - `crypto/` AES-GCM helpers + secure key management
  - `backup/` zip/encrypt/export + decrypt/unzip/import (with web stubs)
  - `drive/` Drive API upload/download in appData
  - `backup_manager.dart` orchestrates auth, encryption, and Drive sync for consumers
- `lib/features/records/`
  - `model/record.dart`, `attachment.dart`, `insight.dart`, `sync_state.dart`
  - `repo/records_repo.dart`
  - Planned: `model/support_contact.dart`, `model/wellness_check_in.dart` to persist support networks and wellness check-ins

Data Model (Isar)
- Record: id, type, date, title, text?, tags[], createdAt, updatedAt, deletedAt?
- Attachment: id, recordId, path, kind, ocrText?, createdAt
- Insight: id, recordId?, kind, text, createdAt
- SyncState (singleton): lastSyncedAt?, lastRemoteModified?, localChangeCounter, deviceId
- Planned: SupportContact, WellnessCheckIn collections (see SPEC.md for fields)

Security
- Backup encryption: AES-GCM with random nonce; key stored in platform secure storage
- No data leaves device unencrypted for backups
- AI-assisted mode: outbound requests gated by consent, API key stored securely, responses include confidence + disclaimers, logs redact PHI

Platform Behavior
- Android/iOS: full backup/restore via Drive appData (`patient-backup-v1.enc`)
- Web: no backup (stub), app runs with UI and IndexedDB-backed Isar
- AI-assisted features target Android/iOS first; web companion requires dedicated consent UX and may ship later.

Future Work
- Implement multi-modal Add Record flow with contextual prompts and accessible design.
- Build `AiProcessingService` + background queue for Together AI enrichment.
- Add support network/emergency modules and integrate with home/emergency UI.
- Ship compassionate notifications, wellness check-ins, and localisation via Flutter `gen-l10n`.
- See `TODO.md` for the detailed milestone breakdown.
