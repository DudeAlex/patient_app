# TODO / Milestones

M1: Core App + Settings (done)
- Scaffold Flutter app and base UI shell
- Add Settings screen with Google sign-in + Drive backup/restore buttons
- Wire Isar schemas and open helper

M2: Records CRUD UI (next)
- Home list of recent records
- Add/Edit Record (type, date, title, text, tags)
- Record detail screen
- Repository wiring + basic state management

M3: Auto Sync
- Track local dirty state (changes increment counter)
- On app resume/exit: export/encrypt/upload if dirty
- Conflict: last-write-wins with banner

M4: Attachments + OCR (stub)
- Pick image/PDF (mobile)
- Store in attachments folder
- Extract basic text stub for future OCR pipeline

M5: Security & Backup UX
- Passcode/biometric lock
- Backup/restore progress + error handling improvements

Optional: Web JSON Backup
- Export/import Isar collections (records/tags/insights) as JSON (no attachments)
- Use distinct filename in Drive appData

