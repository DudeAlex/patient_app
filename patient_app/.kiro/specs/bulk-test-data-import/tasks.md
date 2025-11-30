# Implementation Plan - Bulk Test Data Import

- [ ] 1. Set up project structure and dependencies
  - Create `tool/` directory with subdirectories (lib, web, test_data)
  - Add new dependencies to pubspec.yaml (shelf, shelf_static, args, mime)
  - Create main entry point at `tool/import_data.dart`
  - _Requirements: All_

- [ ] 2. Implement core data models
  - [ ] 2.1 Create TestRecord model with JSON serialization
    - Write TestRecord class with all fields (title, type, date, content, spaceId, viewCount, tags)
    - Implement `toJson()` and `fromJson()` methods
    - Implement `toRecord()` to convert to app's Record model
    - Implement `fromRecord()` factory constructor
    - _Requirements: 1.2, 3.4_

  - [ ] 2.2 Create result models (ValidationResult, ImportResult, ClearResult)
    - Write ValidationResult with errors list
    - Write ImportResult with success/failure counts and duration
    - Write ClearResult with deleted count and duration
    - _Requirements: 1.4, 1.5, 8.3_

  - [ ] 2.3 Create TestDataImport model
    - Write TestDataImport class with records list
    - Implement space breakdown getters (healthRecords, businessRecords, educationRecords)
    - _Requirements: 2.4_

- [ ] 3. Implement DatabaseService
  - [ ] 3.1 Create DatabaseService class with Isar integration
    - Implement database path resolution logic (Windows, macOS, Linux)
    - Implement `open()` and `close()` methods
    - Handle database initialization and schema setup
    - _Requirements: 10.1, 10.2, 10.3_

  - [ ] 3.2 Implement CRUD operations
    - Write `insertRecords()` for batch inserts
    - Write `getAllRecords()` to fetch all records
    - Write `getRecordsBySpace()` for space filtering
    - Write `updateRecord()` for single record updates
    - Write `deleteRecords()` for batch deletes
    - Write `deleteAllRecords()` for clearing data
    - Write `getRecordCount()` for statistics
    - _Requirements: 1.3, 2.1-2.4, 8.3, 13.2, 13.4, 13.5_

- [ ] 4. Implement CoreImportService
  - [ ] 4.1 Create JSON validation logic
    - Implement `validateJson()` to check schema compliance
    - Validate required fields (records array, title, spaceId)
    - Validate field types and constraints
    - Generate detailed ValidationError objects
    - _Requirements: 1.1, 12.1, 12.2_

  - [ ] 4.2 Implement JSON parsing
    - Write `parseJson()` to convert JSON to TestDataImport
    - Handle date parsing (ISO 8601 format)
    - Apply viewCount clamping (0-1000)
    - Apply date range validation (3 years ago to now)
    - Set defaults for missing optional fields
    - _Requirements: 1.2, 4.1, 4.2, 4.3, 4.4, 4.5, 5.1-5.5_

  - [ ] 4.3 Implement record import logic
    - Write `importRecords()` with batch processing
    - Process records in batches of 50
    - Call progress callback after each batch
    - Handle partial failures (import valid, report invalid)
    - Generate ImportResult with statistics
    - _Requirements: 1.3, 1.4, 12.4_

  - [ ] 4.4 Implement data management operations
    - Write `clearAllData()` to delete all records
    - Write `getAllRecords()` to fetch records grouped by space
    - Write `updateRecord()` for single record updates
    - Write `deleteRecords()` for batch deletes
    - Write `exportRecordsToJson()` to convert records to JSON
    - _Requirements: 8.3, 13.2, 13.4, 15.4_

  - [ ] 4.5 Implement pre-packaged dataset loading
    - Write `loadPrepackagedDataset()` to read from tool/test_data/
    - Support dataset types: small, medium, large, stage4
    - Handle file not found errors
    - _Requirements: 6.1-6.5_

- [ ] 5. Create pre-packaged test datasets
  - [ ] 5.1 Create test_data_small.json
    - Generate 20 records (7 health, 7 business, 6 education)
    - Include variety of types and dates
    - Include varied viewCounts
    - _Requirements: 6.1_

  - [ ] 5.2 Create test_data_medium.json
    - Generate 50 records (17 health, 17 business, 16 education)
    - Include variety of types and dates
    - Include varied viewCounts
    - _Requirements: 6.2_

  - [ ] 5.3 Create test_data_large.json
    - Generate 100 records (34 health, 33 business, 33 education)
    - Include variety of types and dates
    - Include varied viewCounts
    - _Requirements: 6.3_

  - [ ] 5.4 Create test_data_stage4.json
    - Generate 80 records optimized for Stage 4 testing
    - Include wide date range distribution
    - Include high viewCount records for relevance testing
    - Include low viewCount records for filtering testing
    - _Requirements: 6.4_

- [ ] 6. Implement CLI interface
  - [ ] 6.1 Create argument parser
    - Use `args` package to define options
    - Support --file, --dataset, --db-path, --clear, --dry-run, --verbose flags
    - Implement `parseArgs()` to create CliArgs object
    - Validate argument combinations
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 8.1, 9.1, 10.2_

  - [ ] 6.2 Implement CLI command execution
    - Write `run()` method to execute based on arguments
    - Handle file import flow
    - Handle dataset import flow
    - Handle clear operation
    - Handle dry-run mode
    - _Requirements: 7.1, 7.2, 8.1, 8.4, 9.1-9.5_

  - [ ] 6.3 Implement console output formatting
    - Write `outputProgress()` for progress updates
    - Write `outputError()` for error messages
    - Write `outputSuccess()` for success messages
    - Write `displayUsage()` for help text
    - Support verbose mode for detailed logging
    - _Requirements: 7.3, 11.1-11.5, 12.1-12.5_

  - [ ] 6.4 Implement exit code management
    - Return 0 for success
    - Return 1 for validation errors
    - Return 2 for database errors
    - Return 3 for file errors
    - _Requirements: 7.5, 12.5_

- [ ] 7. Implement web interface backend
  - [ ] 7.1 Create HTTP server with shelf
    - Set up shelf server on configurable port (default 8080)
    - Bind to localhost only (127.0.0.1)
    - Implement graceful shutdown
    - _Requirements: 13.1_

  - [ ] 7.2 Implement REST API endpoints
    - `GET /` - Serve index.html
    - `GET /api/records` - Get all records grouped by space
    - `POST /api/import` - Handle file upload and import
    - `POST /api/import/dataset/:name` - Import pre-packaged dataset
    - `PUT /api/records/:id` - Update a record
    - `DELETE /api/records/:id` - Delete a record
    - `DELETE /api/records` - Bulk delete records
    - `POST /api/export` - Export records to JSON
    - `DELETE /api/clear` - Clear all data
    - _Requirements: 13.2-13.5, 14.4, 15.2-15.5_

  - [ ] 7.3 Implement file upload handling
    - Parse multipart/form-data
    - Validate file MIME type (application/json)
    - Limit file size to 10MB
    - Pass file content to CoreImportService
    - _Requirements: 14.1-14.4_

  - [ ] 7.4 Implement error handling and responses
    - Return appropriate HTTP status codes
    - Format error messages as JSON
    - Handle CORS (disabled for localhost)
    - _Requirements: 12.1-12.5_

- [ ] 8. Implement web interface frontend
  - [ ] 8.1 Create HTML structure (index.html)
    - Header with title and action buttons
    - Sidebar with space filters
    - Main area for record display
    - Upload zone (drag-and-drop)
    - Modal for editing records
    - _Requirements: 13.1, 13.2, 14.1_

  - [ ] 8.2 Implement JavaScript functionality (app.js)
    - Fetch and display records on load
    - Implement space filtering
    - Handle file drag-and-drop
    - Handle file picker click
    - Implement record editing modal
    - Implement record deletion with confirmation
    - Implement bulk selection
    - Implement bulk operations (delete, export)
    - Implement clear all data with confirmation
    - _Requirements: 13.2-13.5, 14.2-14.5, 15.1-15.5_

  - [ ] 8.3 Create CSS styling (styles.css)
    - Responsive layout
    - Card-based record display
    - Drag-and-drop visual feedback
    - Modal styling
    - Button and form styling
    - _Requirements: 13.1_

- [ ] 9. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 10. Create documentation
  - [ ] 10.1 Write README for tool
    - Document CLI usage with examples
    - Document web interface usage
    - Document JSON schema
    - Document pre-packaged datasets
    - _Requirements: All_

  - [ ] 10.2 Add inline code documentation
    - Document all public methods
    - Add usage examples in doc comments
    - Document error conditions
    - _Requirements: All_

- [ ] 11. Final testing and validation
  - [ ] 11.1 Test CLI with various scenarios
    - Test file import
    - Test dataset import
    - Test clear operation
    - Test dry-run mode
    - Test error handling
    - _Requirements: 1-12_

  - [ ] 11.2 Test web interface
    - Test file upload
    - Test record editing
    - Test record deletion
    - Test bulk operations
    - Test clear all data
    - _Requirements: 13-15_

  - [ ] 11.3 Test database operations
    - Verify records are inserted correctly
    - Verify space routing works
    - Verify viewCount clamping
    - Verify date validation
    - _Requirements: 2, 4, 5_

- [ ] 12. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
