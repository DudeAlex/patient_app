# Database Structure

## Overview

The app uses **Isar** - a high-performance NoSQL database for Flutter/Dart. Data is stored locally on the device with optional encrypted backup to Google Drive.

## Database Technology

- **Database**: Isar 3.1.0+
- **Type**: NoSQL (document-based)
- **Storage**: On-device (mobile: app documents directory, web: IndexedDB)
- **Encryption**: Backup files are AES-GCM encrypted; on-device DB is not encrypted

## Collections (Tables)

### 1. Record Collection
**File**: `lib/features/records/adapters/storage/record_isar_model.dart`

The main collection storing all user records across all spaces.

```dart
@collection
class Record {
  Id id;                    // Auto-increment primary key
  String spaceId;           // Space identifier (e.g., 'health', 'education')
  String type;              // Category/type (e.g., 'Checkup', 'Assignment')
  DateTime date;            // Record date
  String title;             // Record title
  String? text;             // Optional notes/description
  List<String> tags;        // Tags for organization
  DateTime createdAt;       // Creation timestamp
  DateTime updatedAt;       // Last update timestamp
  DateTime? deletedAt;      // Soft delete timestamp (null = not deleted)
}
```

**Indexes**:
- `@Index()` on `spaceId` - Fast space filtering
- `@Index()` on `type` - Fast category filtering
- `@Index()` on `date` - Fast date sorting
- `@Index(caseSensitive: false)` on `title` - Case-insensitive title search
- `@Index(type: IndexType.value, caseSensitive: false)` on `text` - Full-text search
- **Composite Index**: `spaceId + type + date` - Optimized for space-based queries

**Key Features**:
- Soft deletes (deletedAt field)
- Space-scoped records
- Full-text search capability
- Efficient composite indexing

### 2. User Collection
**File**: `lib/features/authentication/infrastructure/models/user_isar_model.dart`

Stores user account information.

```dart
@collection
class User {
  Id id;
  String email;
  String? displayName;
  String? photoUrl;
  DateTime createdAt;
  DateTime? lastLoginAt;
}
```

### 3. Session Collection
**File**: `lib/features/authentication/infrastructure/models/session_isar_model.dart`

Tracks user sessions.

```dart
@collection
class Session {
  Id id;
  String userId;
  String token;
  DateTime createdAt;
  DateTime expiresAt;
}
```

### 4. MFA Pending Collection
**File**: `lib/features/authentication/infrastructure/models/mfa_pending_isar_model.dart`

Stores pending multi-factor authentication requests.

```dart
@collection
class MfaPending {
  Id id;
  String userId;
  String code;
  DateTime createdAt;
  DateTime expiresAt;
}
```

### 5. Login Attempt Collection
**File**: `lib/features/authentication/infrastructure/models/login_attempt_isar_model.dart`

Tracks login attempts for security.

```dart
@collection
class LoginAttempt {
  Id id;
  String email;
  bool success;
  DateTime attemptedAt;
  String? failureReason;
}
```

## Non-Database Storage

### SharedPreferences (Key-Value Store)
**File**: `lib/core/infrastructure/storage/space_preferences.dart`

Used for lightweight configuration and space management:

```dart
// Keys
'spaces.active'              // List<String> - Active space IDs
'spaces.current'             // String - Current space ID
'spaces.custom'              // JSON - Custom space definitions
'spaces.onboarding_complete' // bool - Onboarding completion flag
```

**Why SharedPreferences for Spaces?**
- Spaces are configuration, not user data
- Need to be loaded before database initialization
- Lightweight and fast access
- No need for complex queries

## Database Initialization

**File**: `lib/features/records/data/records_service.dart`

```dart
final isar = await Isar.open(
  [
    RecordSchema,
    UserSchema,
    SessionSchema,
    MfaPendingSchema,
    LoginAttemptSchema,
  ],
  directory: directory.path,
  inspector: true, // Enable Isar Inspector in debug mode
);
```

## Data Flow

### Writing Data
```
User Action
  ↓
UI Widget
  ↓
Provider/State Management
  ↓
Use Case (Application Layer)
  ↓
Repository Interface (Port)
  ↓
Isar Repository (Adapter)
  ↓
Isar Database
```

### Reading Data
```
UI Widget
  ↓
Provider/State Management
  ↓
Use Case (Application Layer)
  ↓
Repository Interface (Port)
  ↓
Isar Repository (Adapter)
  ↓
Isar Database (with indexes)
  ↓
Filtered/Sorted Results
```

## Query Examples

### Get Records for Current Space
```dart
final records = await isar.records
    .filter()
    .spaceIdEqualTo('health')
    .sortByDateDesc()
    .findAll();
```

### Search Records by Title
```dart
final results = await isar.records
    .filter()
    .spaceIdEqualTo(currentSpaceId)
    .titleContains(searchQuery, caseSensitive: false)
    .findAll();
```

### Get Records by Category in Space
```dart
final checkups = await isar.records
    .filter()
    .spaceIdEqualTo('health')
    .typeEqualTo('Checkup')
    .sortByDateDesc()
    .findAll();
```

### Count Records in Space
```dart
final count = await isar.records
    .filter()
    .spaceIdEqualTo('health')
    .count();
```

## Migration System

**File**: `lib/core/infrastructure/storage/migration_service.dart`

Handles database schema migrations:

### Migration Version 1: Spaces System
- Added `spaceId` field to all records
- Set default `spaceId = 'health'` for existing records
- Added composite index for space-based queries
- Set up default space configuration for existing users

**Migration Process**:
1. Check current migration version
2. If version < target, run migrations sequentially
3. Update records in batches (100 at a time)
4. Verify migration success
5. Mark migration complete

## Performance Optimizations

### Indexes
- **Single-field indexes**: Fast filtering on common fields
- **Composite indexes**: Optimized for multi-field queries
- **Case-insensitive indexes**: Better search UX

### Query Optimization
- Use composite index for space + type + date queries
- Batch operations for bulk updates
- Lazy loading with pagination
- Watch queries for reactive UI updates

### Caching
- SpaceProvider caches active spaces in memory
- Migration version cached after first check
- Frequently accessed data kept in provider state

## Backup & Sync

### Backup Format
```
patient-backup-v1.enc (encrypted ZIP file)
  ├── default.isar (database file)
  ├── default.isar.lock
  └── attachments/ (files)
```

### Backup Process
1. Export entire app documents directory
2. Create ZIP archive
3. Encrypt with AES-GCM
4. Upload to Google Drive App Data
5. Store encryption key in secure storage

### Restore Process
1. Download encrypted backup from Drive
2. Decrypt with stored key
3. Extract to app documents directory
4. Reopen database
5. Verify data integrity

## Database Location

### Android
```
/data/data/com.example.patient_app/files/default.isar
```

### iOS
```
/var/mobile/Containers/Data/Application/<UUID>/Documents/default.isar
```

### Windows
```
C:\Users\<username>\AppData\Roaming\com.example\patient_app\default.isar
```

### Web
```
IndexedDB: isar_default
```

## Isar Inspector

Access the Isar Inspector during development:
```
https://inspect.isar.dev/3.1.0+1/#/<port>/<token>
```

The URL is printed in the console when the app starts in debug mode.

## Schema Generation

After modifying Isar models, regenerate schemas:
```bash
dart run build_runner build --delete-conflicting-outputs
```

This generates `*.g.dart` files with schema definitions.

## Future Considerations

### Planned Collections
- `Attachment` - File metadata and references
- `Insight` - AI-generated insights
- `SyncState` - Sync status tracking
- `SupportContact` - Emergency contacts
- `WellnessCheckIn` - Wellness tracking

### Planned Optimizations
- Implement attachment collection for better file management
- Add full-text search indexes
- Implement incremental sync
- Add data compression for large text fields

---

**Last Updated**: November 15, 2025
**Database Version**: 1
**Isar Version**: 3.1.0+1
