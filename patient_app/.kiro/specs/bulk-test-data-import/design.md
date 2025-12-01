# Design Document - Bulk Test Data Import

## Overview

The Bulk Test Data Import tool provides developers and testers with a streamlined way to populate the Patient App database with realistic test data across multiple spaces (Health, Business, Education) before running the app. This standalone tool addresses the critical need for comprehensive testing of Stage 4 AI context optimization, token budget enforcement, and multi-space functionality without requiring hours of manual data entry.

The system consists of two interfaces:
1. **CLI Tool** - Command-line script for automation and CI/CD integration
2. **Web Interface** - Single-page web app for visual data management

Both interfaces share the same core logic for importing records from JSON files, validating data integrity, and managing the database.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    CLI Interface                             │
│  - Command-line arguments parser                            │
│  - Console output formatter                                 │
│  - Exit code management                                     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ├──────────────────────────────────────┐
                     │                                      │
                     ▼                                      ▼
┌─────────────────────────────────────┐  ┌──────────────────────────────────┐
│         Web Interface                │  │    Core Import Service           │
│  - HTTP server (shelf)               │  │  - JSON validation               │
│  - Single-page HTML/JS app           │  │  - Record parsing                │
│  - REST API endpoints                │  │  - Data transformation           │
│  - File upload handling              │  │  - Error aggregation             │
└────────────────────┬────────────────┘  └────────────┬─────────────────────┘
                     │                                 │
                     └─────────────┬───────────────────┘
                                   ▼
                     ┌─────────────────────────────────────┐
                     │      Database Service               │
                     │  - Isar database connection         │
                     │  - Record CRUD operations           │
                     │  - Transaction management           │
                     │  - Space routing                    │
                     └─────────────────────────────────────┘
```

### Component Interaction Flows

**CLI Flow:**
1. User runs script with arguments (file path, dataset name, flags)
2. CLI parser validates arguments
3. Core Import Service loads and validates JSON
4. Database Service inserts records
5. Progress updates output to console
6. Summary displayed and script exits

**Web Flow:**
1. User starts web server (dart run tool/import_data.dart --web)
2. Browser opens to http://localhost:8080
3. User uploads JSON file or selects pre-packaged dataset
4. Web API receives request
5. Core Import Service processes data
6. Database Service updates records
7. Web UI refreshes to show results

## Components and Interfaces

### 1. CoreImportService

**Responsibility:** Core business logic for importing test data (shared by CLI and Web)

**Interface:**
```dart
class CoreImportService {
  final DatabaseService _dbService;
  
  /// Validates JSON structure against schema
  Future<ValidationResult> validateJson(String jsonContent);
  
  /// Parses JSON into TestDataImport model
  Future<TestDataImport> parseJson(String jsonContent);
  
  /// Imports records into database
  Future<ImportResult> importRecords(
    TestDataImport data,
    {ProgressCallback? onProgress}
  );
  
  /// Clears all test data from database
  Future<ClearResult> clearAllData();
  
  /// Loads pre-packaged dataset
  Future<String> loadPrepackagedDataset(DatasetType type);
  
  /// Gets all records grouped by space
  Future<Map<String, List<Record>>> getAllRecords();
  
  /// Updates a single record
  Future<void> updateRecord(String recordId, Record record);
  
  /// Deletes records by IDs
  Future<void> deleteRecords(List<String> recordIds);
  
  /// Exports records to JSON
  String exportRecordsToJson(List<Record> records);
}
```

### 2. DatabaseService

**Responsibility:** Direct database operations using Isar

**Interface:**
```dart
class DatabaseService {
  final String dbPath;
  late Isar _isar;
  
  /// Opens database connection
  Future<void> open();
  
  /// Closes database connection
  Future<void> close();
  
  /// Inserts records in batch
  Future<int> insertRecords(List<Record> records);
  
  /// Gets all records
  Future<List<Record>> getAllRecords();
  
  /// Gets records by space
  Future<List<Record>> getRecordsBySpace(String spaceId);
  
  /// Updates a record
  Future<void> updateRecord(Record record);
  
  /// Deletes records by IDs
  Future<void> deleteRecords(List<String> recordIds);
  
  /// Deletes all records
  Future<int> deleteAllRecords();
  
  /// Gets record count
  Future<int> getRecordCount();
}
```

### 3. CLI Interface

**Responsibility:** Command-line argument parsing and console output

**Interface:**
```dart
class CliInterface {
  /// Parses command-line arguments
  CliArgs parseArgs(List<String> args);
  
  /// Runs the CLI command
  Future<int> run(List<String> args);
  
  /// Outputs progress updates
  void outputProgress(int current, int total);
  
  /// Outputs error messages
  void outputError(String message);
  
  /// Outputs success messages
  void outputSuccess(String message);
  
  /// Displays usage instructions
  void displayUsage();
}
```

**CLI Arguments:**
```dart
class CliArgs {
  final String? filePath;
  final String? datasetName;
  final String? dbPath;
  final bool clear;
  final bool dryRun;
  final bool verbose;
}
```

### 4. Web Interface

**Responsibility:** HTTP server and REST API

**Interface:**
```dart
class WebInterface {
  final CoreImportService _importService;
  final int port;
  
  /// Starts the web server
  Future<void> start();
  
  /// Stops the web server
  Future<void> stop();
}
```

**REST API Endpoints:**
- `GET /` - Serves the single-page web app
- `GET /api/records` - Gets all records grouped by space
- `POST /api/import` - Uploads and imports JSON file
- `POST /api/import/dataset/:name` - Imports pre-packaged dataset
- `PUT /api/records/:id` - Updates a record
- `DELETE /api/records/:id` - Deletes a record
- `DELETE /api/records` - Bulk deletes records (body: `{ids: [...]}`
- `POST /api/export` - Exports records to JSON (body: `{ids: [...]}`
- `DELETE /api/clear` - Clears all data

### 5. TestDataImport Model

**Responsibility:** Represents parsed test data

```dart
class TestDataImport {
  final List<TestRecord> records;
  final Map<String, int> recordsBySpace; // Space breakdown
  
  int get totalRecords => records.length;
  List<TestRecord> get healthRecords => records.where((r) => r.spaceId == 'health').toList();
  List<TestRecord> get businessRecords => records.where((r) => r.spaceId == 'business').toList();
  List<TestRecord> get educationRecords => records.where((r) => r.spaceId == 'education').toList();
}
```

### 6. TestRecord Model

**Responsibility:** Represents a single test record

```dart
class TestRecord {
  final String title;
  final String type;
  final DateTime date;
  final String content;
  final String spaceId;
  final int viewCount;
  final List<String> tags;
  
  /// Converts to app's Record model
  Record toRecord();
  
  /// Creates from app's Record model
  factory TestRecord.fromRecord(Record record);
}
```

### 7. ValidationResult

**Responsibility:** Represents validation outcome

```dart
class ValidationResult {
  final bool isValid;
  final List<ValidationError> errors;
  
  bool get hasErrors => errors.isNotEmpty;
}

class ValidationError {
  final int? lineNumber;
  final String field;
  final String message;
}
```

### 8. ImportResult

**Responsibility:** Represents import outcome

```dart
class ImportResult {
  final int successCount;
  final int failureCount;
  final List<ImportError> errors;
  final Duration duration;
  
  bool get isFullSuccess => failureCount == 0;
  bool get isPartialSuccess => successCount > 0 && failureCount > 0;
  bool get isFullFailure => successCount == 0;
}
```

### 9. ClearResult

**Responsibility:** Represents clear operation outcome

```dart
class ClearResult {
  final int deletedCount;
  final Duration duration;
  final bool success;
  final String? error;
}
```

## Data Models

### JSON Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["records"],
  "properties": {
    "records": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["title", "spaceId"],
        "properties": {
          "title": {
            "type": "string",
            "minLength": 1,
            "maxLength": 200
          },
          "type": {
            "type": "string",
            "default": "general"
          },
          "date": {
            "type": "string",
            "format": "date-time"
          },
          "content": {
            "type": "string",
            "maxLength": 10000
          },
          "spaceId": {
            "type": "string",
            "enum": ["health", "business", "education"]
          },
          "viewCount": {
            "type": "integer",
            "minimum": 0,
            "maximum": 1000,
            "default": 0
          },
          "tags": {
            "type": "array",
            "items": {
              "type": "string"
            },
            "default": []
          }
        }
      }
    }
  }
}
```

### Database Schema Impact

No new tables required. Records are inserted into existing `records` table with:
- Standard record fields (title, content, date, spaceId, etc.)
- viewCount field (already exists)
- tags stored in existing tags table/field

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: JSON Validation Correctness
*For any* JSON string, validation should accept it if and only if it conforms to the schema (has "records" array with valid record objects).
**Validates: Requirements 1.1**

### Property 2: Parse-Import Round Trip
*For any* valid JSON file, the number of records parsed should equal the number of records imported into the database (assuming all records are valid).
**Validates: Requirements 1.2, 1.3**

### Property 3: Import Count Accuracy
*For any* import operation, the displayed success count should equal the actual number of records inserted into the database.
**Validates: Requirements 1.4**

### Property 4: Error Reporting Completeness
*For any* set of invalid records, the system should generate an error message for each invalid record.
**Validates: Requirements 1.5**

### Property 5: Space Routing Correctness
*For any* record with a valid spaceId, that record should be queryable from the specified space after import and not from other spaces.
**Validates: Requirements 2.1, 2.2, 2.3, 2.4**

### Property 6: Invalid Space Rejection
*For any* record with an invalid spaceId (not "health", "business", or "education"), the import should reject that record.
**Validates: Requirements 2.5**

### Property 7: Record Type Preservation
*For any* record with a specified type, retrieving that record after import should return the same type value.
**Validates: Requirements 3.1, 3.2, 3.3, 3.4**

### Property 8: Date Parsing Round Trip
*For any* valid ISO 8601 date string within the allowed range, parsing and storing then retrieving should produce an equivalent date.
**Validates: Requirements 4.1**

### Property 9: Date Range Enforcement
*For any* date, the system should accept it if and only if it is between 3 years ago and now.
**Validates: Requirements 4.2**

### Property 10: ViewCount Clamping
*For any* integer viewCount value, the stored value should be max(0, min(value, 1000)).
**Validates: Requirements 5.2, 5.3, 5.4**

### Property 11: ViewCount Default
*For any* record without a viewCount field, the stored viewCount should be 0.
**Validates: Requirements 5.5**

### Property 12: Clear Data Completeness
*For any* database state, after clearing all test data, querying all spaces should return zero records.
**Validates: Requirements 8.3**

### Property 13: Preview Accuracy
*For any* valid JSON file, the preview record count should match the actual number of records in the file.
**Validates: Requirements 9.2**

### Property 14: Partial Import Consistency
*For any* import with both valid and invalid records, the number of successfully imported records plus the number of failed records should equal the total number of records in the file.
**Validates: Requirements 12.4**

### Property 15: All-Fail Database Invariant
*For any* import where all records fail validation, the database record count before and after import should be identical.
**Validates: Requirements 12.5**

## Error Handling

### Validation Errors

**JSON Structure Errors:**
- Missing "records" field → "Invalid JSON: missing required 'records' array"
- Invalid JSON syntax → "JSON parse error at line X: [error message]"
- Empty records array → Warning (not error), allow import

**Record Validation Errors:**
- Missing title → "Record [index]: missing required field 'title'"
- Missing spaceId → "Record [index]: missing required field 'spaceId'"
- Invalid spaceId → "Record [index]: invalid spaceId '[value]', must be health/business/education"
- Invalid date format → "Record [index]: invalid date format, using current date"
- Future date → "Record [index]: date is in the future, rejected"
- Date too old → "Record [index]: date is more than 3 years old, rejected"
- Invalid viewCount → "Record [index]: invalid viewCount, clamping to [0, 1000]"

### Import Errors

**Database Errors:**
- Insert failure → "Failed to import record '[title]': [database error]"
- Transaction failure → "Import failed: [error], no records imported"
- Space not found → "Record '[title]': space '[spaceId]' does not exist"

**File Errors:**
- File not found → "Selected file not found or inaccessible"
- File too large → "File exceeds maximum size (10MB)"
- Permission denied → "Cannot read file: permission denied"

### Error Recovery

- **Partial failures:** Import valid records, report failures, allow retry of failed records
- **Full failures:** Rollback transaction, leave database unchanged, display comprehensive error report
- **File errors:** Allow user to select different file

## Testing Strategy

### Unit Testing

**Core Logic Tests:**
- JSON validation with valid/invalid structures
- Record parsing with various field combinations
- Date parsing and validation
- ViewCount clamping logic
- Space routing logic
- Error message generation

**Edge Cases:**
- Empty JSON file
- Single record import
- Maximum size import (1000 records)
- All records invalid
- Mixed valid/invalid records
- Missing optional fields
- Boundary values (viewCount 0, 1000, -1, 1001)

### Property-Based Testing

The system will use property-based testing to verify correctness properties across a wide range of inputs. We'll use the `test` package with custom generators for property-based testing in Dart.

**Configuration:**
- Minimum 100 iterations per property test
- Custom generators for TestRecord, JSON structures, dates, viewCounts
- Each property test tagged with: `**Feature: bulk-test-data-import, Property {number}: {property_text}**`

**Property Test Coverage:**
- Property 1: JSON validation (generate random JSON structures)
- Property 2: Parse-import round trip (generate valid JSON files)
- Property 5: Space routing (generate records with various spaceIds)
- Property 8: Date parsing round trip (generate ISO 8601 dates)
- Property 10: ViewCount clamping (generate random integers)
- Property 12: Clear data completeness (generate random database states)
- Property 15: All-fail invariant (generate all-invalid records)

### Integration Testing

**End-to-End Flows:**
- Complete import flow: file selection → validation → preview → import → verification
- Clear data flow: confirmation → deletion → verification
- Pre-packaged dataset import
- Error handling flows

### Manual Testing

**UI/UX Validation:**
- File picker interaction
- Progress indicator display
- Preview screen usability
- Error message clarity
- Developer mode access control

## Implementation Notes

### Tool Structure

**Directory Layout:**
```
tool/
  import_data.dart          # Main entry point
  lib/
    core_import_service.dart
    database_service.dart
    cli_interface.dart
    web_interface.dart
    models/
      test_record.dart
      import_result.dart
      validation_result.dart
  web/
    index.html              # Single-page web app
    app.js                  # Frontend JavaScript
    styles.css              # Styling
  test_data/
    test_data_small.json
    test_data_medium.json
    test_data_large.json
    test_data_stage4.json
```

### CLI Usage Examples

```bash
# Import from file
dart run tool/import_data.dart --file path/to/data.json

# Import pre-packaged dataset
dart run tool/import_data.dart --dataset medium

# Clear all data first, then import
dart run tool/import_data.dart --clear --file data.json

# Dry run (preview without importing)
dart run tool/import_data.dart --dry-run --file data.json

# Specify custom database path
dart run tool/import_data.dart --db-path /custom/path/db.isar --file data.json

# Start web interface
dart run tool/import_data.dart --web

# Start web interface on custom port
dart run tool/import_data.dart --web --port 3000

# Verbose output
dart run tool/import_data.dart --verbose --file data.json
```

### Web Interface Design

**Single-Page Layout:**
- Header with title and action buttons
- Sidebar with space filters (Health, Business, Education, All)
- Main area with record cards/table
- Upload zone (drag-and-drop or click)
- Modal for editing records

**Technology Stack:**
- Backend: Dart `shelf` package for HTTP server
- Frontend: Vanilla JavaScript (no framework needed for simplicity)
- Styling: Simple CSS with responsive design
- File upload: HTML5 drag-and-drop API

### Performance Considerations

**Batch Processing:**
- Import records in batches of 50
- Output progress after each batch
- Use Isar transactions for atomic operations

**Memory Management:**
- Stream large JSON files if > 10MB
- Limit web UI to display 1000 records at a time (pagination)
- Clear parsed data after import

**Database Optimization:**
- Use single transaction for all inserts
- Batch inserts for better performance
- Reuse existing Isar schemas from main app

### Pre-Packaged Datasets

**Location:** `tool/test_data/`

**Datasets:**
1. `test_data_small.json` - 20 records (7 health, 7 business, 6 education)
2. `test_data_medium.json` - 50 records (17 health, 17 business, 16 education)
3. `test_data_large.json` - 100 records (34 health, 33 business, 33 education)
4. `test_data_stage4.json` - 80 records optimized for Stage 4 testing (varied dates, viewCounts)

### JSON Parsing

**Library:** Use Dart's built-in `dart:convert` for JSON parsing

**Validation:** Manual validation against schema (no external JSON schema validator needed)

**Error Handling:** Catch `FormatException` for JSON syntax errors

### Database Path Resolution

**Default Path Logic:**
```dart
String getDefaultDbPath() {
  if (Platform.isWindows) {
    return path.join(
      Platform.environment['APPDATA']!,
      'com.example.patient_app',
      'isar.isar'
    );
  } else if (Platform.isMacOS) {
    return path.join(
      Platform.environment['HOME']!,
      'Library/Application Support/com.example.patient_app',
      'isar.isar'
    );
  } else if (Platform.isLinux) {
    return path.join(
      Platform.environment['HOME']!,
      '.local/share/com.example.patient_app',
      'isar.isar'
    );
  }
  throw UnsupportedError('Platform not supported');
}
```

## Dependencies

**New Dependencies:**
- `shelf` - HTTP server for web interface
- `shelf_static` - Serving static files (HTML/JS/CSS)
- `args` - Command-line argument parsing
- `mime` - MIME type detection for file uploads

**Existing Dependencies:**
- `isar` - Database (already in project)
- `isar_flutter_libs` - Isar platform libraries (already in project)
- `path` - Path manipulation (already in project)
- `path_provider` - For default database path (already in project)

## Security Considerations

### Tool Access

- Tool runs locally only (no remote access)
- Web interface binds to localhost only (127.0.0.1)
- No authentication needed (local development tool)
- Document that this is for development/testing only

### Data Validation

- Validate all input fields to prevent injection attacks
- Limit file size to 10MB for uploads
- Sanitize content fields before database insertion
- Validate dates to prevent invalid database states
- Reject files with non-JSON MIME types

### Privacy

- Test data should not contain real user information
- Use placeholder names, generic descriptions
- No PII in pre-packaged datasets
- Add warning in web UI that this is test data only

### Web Interface Security

- CORS disabled (localhost only)
- No session management needed
- File uploads validated before processing
- SQL injection not applicable (using Isar, not SQL)

## Future Enhancements

### Phase 2 (Optional):
- Export current data as JSON
- Generate random test data programmatically
- Test data profiles (performance, edge cases, minimal)
- Bulk edit imported records
- Import from URL
- Compressed JSON support (.json.gz)

### Phase 3 (Optional):
- Visual test data builder
- Record templates
- Automated test data generation based on schemas
- Integration with CI/CD for automated testing

---

**Document Version:** 1.0  
**Created:** November 29, 2024  
**Status:** Draft - Ready for Review
