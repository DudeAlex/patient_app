# Implementation Plan - Bulk Test Data Import

## Task Completion Guidelines

When completing each task:
1. Implement the code for the task
2. Write and run all tests for that task
3. Ensure all tests pass
4. Mark the task as complete with `[x]`
5. Commit the changes with a descriptive message: `git commit -m "feat: [task description]"`

---

- [ ] 1. Set up project structure and dependencies
  - Create `tool/` directory with subdirectories (lib, web, test_data)
  - Add new dependencies to pubspec.yaml (shelf, shelf_static, args, mime)
  - Create main entry point at `tool/import_data.dart`
  - _Requirements: All_
  
  - [ ] 1.1 Verify project structure
    - Test that all directories exist
    - Test that pubspec.yaml contains new dependencies
    - Test that tool/import_data.dart exists and is executable

- [ ] 2. Implement core data models
  - [ ] 2.1 Create TestRecord model with JSON serialization
    - Write TestRecord class with all fields (title, type, date, content, spaceId, viewCount, tags)
    - Implement `toJson()` and `fromJson()` methods
    - Implement `toRecord()` to convert to app's Record model
    - Implement `fromRecord()` factory constructor
    - _Requirements: 1.2, 3.4_
    
    - [ ] 2.1.1 Write unit tests for TestRecord
      - Test JSON serialization round-trip (toJson → fromJson)
      - Test conversion to/from app Record model
      - Test with all fields present
      - Test with optional fields missing
      - Test date parsing from ISO 8601 strings

  - [ ] 2.2 Create result models (ValidationResult, ImportResult, ClearResult)
    - Write ValidationResult with errors list
    - Write ImportResult with success/failure counts and duration
    - Write ClearResult with deleted count and duration
    - _Requirements: 1.4, 1.5, 8.3_
    
    - [ ] 2.2.1 Write unit tests for result models
      - Test ValidationResult with various error combinations
      - Test ImportResult success/partial/failure states
      - Test ClearResult with different outcomes

  - [ ] 2.3 Create TestDataImport model
    - Write TestDataImport class with records list
    - Implement space breakdown getters (healthRecords, businessRecords, educationRecords)
    - _Requirements: 2.4_
    
    - [ ] 2.3.1 Write unit tests for TestDataImport
      - Test space breakdown getters with mixed records
      - Test totalRecords calculation
      - Test with empty records list
      - Test with records from single space

- [ ] 3. Implement DatabaseService
  - [ ] 3.1 Create DatabaseService class with Isar integration
    - Implement database path resolution logic (Windows, macOS, Linux)
    - Implement `open()` and `close()` methods
    - Handle database initialization and schema setup
    - _Requirements: 10.1, 10.2, 10.3_
    
    - [ ] 3.1.1 Write unit tests for DatabaseService initialization
      - Test database path resolution on current platform
      - Test open() creates database if not exists
      - Test close() properly closes connection
      - Test custom database path handling

  - [ ] 3.2 Implement CRUD operations
    - Write `insertRecords()` for batch inserts
    - Write `getAllRecords()` to fetch all records
    - Write `getRecordsBySpace()` for space filtering
    - Write `updateRecord()` for single record updates
    - Write `deleteRecords()` for batch deletes
    - Write `deleteAllRecords()` for clearing data
    - Write `getRecordCount()` for statistics
    - _Requirements: 1.3, 2.1-2.4, 8.3, 13.2, 13.4, 13.5_
    
    - [ ] 3.2.1 Write unit tests for CRUD operations
      - Test insertRecords() with batch of records
      - Test getAllRecords() returns all inserted records
      - Test getRecordsBySpace() filters correctly
      - Test updateRecord() modifies existing record
      - Test deleteRecords() removes specified records
      - Test deleteAllRecords() clears entire database
      - Test getRecordCount() returns accurate count

- [ ] 4. Implement CoreImportService
  - [ ] 4.1 Create JSON validation logic
    - Implement `validateJson()` to check schema compliance
    - Validate required fields (records array, title, spaceId)
    - Validate field types and constraints
    - Generate detailed ValidationError objects
    - _Requirements: 1.1, 12.1, 12.2_
    
    - [ ] 4.1.1 Write unit tests for JSON validation
      - Test valid JSON passes validation
      - Test missing "records" field fails
      - Test missing required fields (title, spaceId) fails
      - Test invalid spaceId values fail
      - Test invalid field types fail
      - Test validation error messages are descriptive

  - [ ] 4.2 Implement JSON parsing
    - Write `parseJson()` to convert JSON to TestDataImport
    - Handle date parsing (ISO 8601 format)
    - Apply viewCount clamping (0-1000)
    - Apply date range validation (3 years ago to now)
    - Set defaults for missing optional fields
    - _Requirements: 1.2, 4.1, 4.2, 4.3, 4.4, 4.5, 5.1-5.5_
    
    - [ ] 4.2.1 Write property tests for JSON parsing
      - **Property 8: Date Parsing Round Trip** - For any valid ISO 8601 date, parsing and storing then retrieving should produce equivalent date
      - **Validates: Requirements 4.1**
    
    - [ ] 4.2.2 Write property tests for viewCount clamping
      - **Property 10: ViewCount Clamping** - For any integer viewCount, stored value should be max(0, min(value, 1000))
      - **Validates: Requirements 5.2, 5.3, 5.4**
    
    - [ ] 4.2.3 Write property tests for date range enforcement
      - **Property 9: Date Range Enforcement** - For any date, system should accept it if and only if between 3 years ago and now
      - **Validates: Requirements 4.2**
    
    - [ ] 4.2.4 Write unit tests for parsing edge cases
      - Test parsing with all optional fields missing
      - Test parsing with invalid date format (uses current date)
      - Test parsing with future date (rejected)
      - Test parsing with date > 3 years old (rejected)
      - Test negative viewCount (clamped to 0)
      - Test viewCount > 1000 (clamped to 1000)

  - [ ] 4.3 Implement record import logic
    - Write `importRecords()` with batch processing
    - Process records in batches of 50
    - Call progress callback after each batch
    - Handle partial failures (import valid, report invalid)
    - Generate ImportResult with statistics
    - _Requirements: 1.3, 1.4, 12.4_
    
    - [ ] 4.3.1 Write property tests for import operations
      - **Property 2: Parse-Import Round Trip** - For any valid JSON file, number of records parsed should equal number imported
      - **Validates: Requirements 1.2, 1.3**
      
      - **Property 3: Import Count Accuracy** - For any import operation, displayed success count should equal actual records in database
      - **Validates: Requirements 1.4**
      
      - **Property 14: Partial Import Consistency** - For any import with valid and invalid records, success count + failure count should equal total records
      - **Validates: Requirements 12.4**
    
    - [ ] 4.3.2 Write unit tests for import logic
      - Test batch processing with 100+ records
      - Test progress callback is called correctly
      - Test partial failure handling
      - Test ImportResult statistics are accurate

  - [ ] 4.4 Implement data management operations
    - Write `clearAllData()` to delete all records
    - Write `getAllRecords()` to fetch records grouped by space
    - Write `updateRecord()` for single record updates
    - Write `deleteRecords()` for batch deletes
    - Write `exportRecordsToJson()` to convert records to JSON
    - _Requirements: 8.3, 13.2, 13.4, 15.4_
    
    - [ ] 4.4.1 Write property tests for data operations
      - **Property 12: Clear Data Completeness** - For any database state, after clearing all data, querying all spaces should return zero records
      - **Validates: Requirements 8.3**
      
      - **Property 15: All-Fail Database Invariant** - For any import where all records fail validation, database record count before and after should be identical
      - **Validates: Requirements 12.5**
    
    - [ ] 4.4.2 Write unit tests for data management
      - Test clearAllData() removes all records
      - Test getAllRecords() groups by space correctly
      - Test updateRecord() modifies correct record
      - Test deleteRecords() removes only specified records
      - Test exportRecordsToJson() produces valid JSON

  - [ ] 4.5 Implement pre-packaged dataset loading
    - Write `loadPrepackagedDataset()` to read from tool/test_data/
    - Support dataset types: small, medium, large, stage4
    - Handle file not found errors
    - _Requirements: 6.1-6.5_
    
    - [ ] 4.5.1 Write unit tests for dataset loading
      - Test loading each pre-packaged dataset
      - Test file not found error handling
      - Test invalid dataset name error handling

- [ ] 5. Create pre-packaged test datasets
  - [ ] 5.1 Create test_data_small.json
    - Generate 20 records (7 health, 7 business, 6 education)
    - Include variety of types and dates
    - Include varied viewCounts
    - _Requirements: 6.1_
    
    - [ ] 5.1.1 Validate test_data_small.json
      - Test JSON is valid and parseable
      - Test contains exactly 20 records
      - Test space distribution (7 health, 7 business, 6 education)
      - Test all records have required fields

  - [ ] 5.2 Create test_data_medium.json
    - Generate 50 records (17 health, 17 business, 16 education)
    - Include variety of types and dates
    - Include varied viewCounts
    - _Requirements: 6.2_
    
    - [ ] 5.2.1 Validate test_data_medium.json
      - Test JSON is valid and parseable
      - Test contains exactly 50 records
      - Test space distribution (17 health, 17 business, 16 education)
      - Test all records have required fields

  - [ ] 5.3 Create test_data_large.json
    - Generate 100 records (34 health, 33 business, 33 education)
    - Include variety of types and dates
    - Include varied viewCounts
    - _Requirements: 6.3_
    
    - [ ] 5.3.1 Validate test_data_large.json
      - Test JSON is valid and parseable
      - Test contains exactly 100 records
      - Test space distribution (34 health, 33 business, 33 education)
      - Test all records have required fields

  - [ ] 5.4 Create test_data_stage4.json
    - Generate 80 records optimized for Stage 4 testing
    - Include wide date range distribution
    - Include high viewCount records for relevance testing
    - Include low viewCount records for filtering testing
    - _Requirements: 6.4_
    
    - [ ] 5.4.1 Validate test_data_stage4.json
      - Test JSON is valid and parseable
      - Test contains exactly 80 records
      - Test includes records with high viewCounts (>50)
      - Test includes records with low viewCounts (<5)
      - Test includes wide date range (3 years)

- [ ] 6. Implement CLI interface
  - [ ] 6.1 Create argument parser
    - Use `args` package to define options
    - Support --file, --dataset, --db-path, --clear, --dry-run, --verbose flags
    - Implement `parseArgs()` to create CliArgs object
    - Validate argument combinations
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 8.1, 9.1, 10.2_
    
    - [ ] 6.1.1 Write unit tests for argument parser
      - Test parsing --file argument
      - Test parsing --dataset argument
      - Test parsing --db-path argument
      - Test parsing boolean flags (--clear, --dry-run, --verbose)
      - Test invalid argument combinations
      - Test missing required arguments

  - [ ] 6.2 Implement CLI command execution
    - Write `run()` method to execute based on arguments
    - Handle file import flow
    - Handle dataset import flow
    - Handle clear operation
    - Handle dry-run mode
    - _Requirements: 7.1, 7.2, 8.1, 8.4, 9.1-9.5_
    
    - [ ] 6.2.1 Write integration tests for CLI execution
      - Test file import end-to-end
      - Test dataset import end-to-end
      - Test clear operation
      - Test dry-run mode (no database changes)
      - Test --clear flag with import

  - [ ] 6.3 Implement console output formatting
    - Write `outputProgress()` for progress updates
    - Write `outputError()` for error messages
    - Write `outputSuccess()` for success messages
    - Write `displayUsage()` for help text
    - Support verbose mode for detailed logging
    - _Requirements: 7.3, 11.1-11.5, 12.1-12.5_
    
    - [ ] 6.3.1 Write unit tests for console output
      - Test progress output formatting
      - Test error message formatting
      - Test success message formatting
      - Test usage text is complete
      - Test verbose mode outputs additional details

  - [ ] 6.4 Implement exit code management
    - Return 0 for success
    - Return 1 for validation errors
    - Return 2 for database errors
    - Return 3 for file errors
    - _Requirements: 7.5, 12.5_
    
    - [ ] 6.4.1 Write unit tests for exit codes
      - Test successful operation returns 0
      - Test validation error returns 1
      - Test database error returns 2
      - Test file error returns 3

- [ ] 7. Implement web interface backend
  - [ ] 7.1 Create HTTP server with shelf
    - Set up shelf server on configurable port (default 8080)
    - Bind to localhost only (127.0.0.1)
    - Implement graceful shutdown
    - _Requirements: 13.1_
    
    - [ ] 7.1.1 Write unit tests for HTTP server
      - Test server starts on specified port
      - Test server binds to localhost only
      - Test graceful shutdown closes connections
      - Test custom port configuration

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
    
    - [ ] 7.2.1 Write property tests for API endpoints
      - **Property 5: Space Routing Correctness** - For any record with valid spaceId, that record should be queryable from specified space and not from other spaces
      - **Validates: Requirements 2.1, 2.2, 2.3, 2.4**
      
      - **Property 7: Record Type Preservation** - For any record with specified type, retrieving after import should return same type value
      - **Validates: Requirements 3.1, 3.2, 3.3, 3.4**
    
    - [ ] 7.2.2 Write integration tests for API endpoints
      - Test GET / returns HTML page
      - Test GET /api/records returns records grouped by space
      - Test POST /api/import imports file successfully
      - Test POST /api/import/dataset/:name imports dataset
      - Test PUT /api/records/:id updates record
      - Test DELETE /api/records/:id deletes record
      - Test DELETE /api/records bulk deletes
      - Test POST /api/export returns JSON
      - Test DELETE /api/clear removes all records

  - [ ] 7.3 Implement file upload handling
    - Parse multipart/form-data
    - Validate file MIME type (application/json)
    - Limit file size to 10MB
    - Pass file content to CoreImportService
    - _Requirements: 14.1-14.4_
    
    - [ ] 7.3.1 Write unit tests for file upload
      - Test multipart/form-data parsing
      - Test MIME type validation rejects non-JSON
      - Test file size limit rejects files > 10MB
      - Test valid JSON file is processed
      - Test upload error handling

  - [ ] 7.4 Implement error handling and responses
    - Return appropriate HTTP status codes
    - Format error messages as JSON
    - Handle CORS (disabled for localhost)
    - _Requirements: 12.1-12.5_
    
    - [ ] 7.4.1 Write property tests for error handling
      - **Property 4: Error Reporting Completeness** - For any set of invalid records, system should generate error message for each invalid record
      - **Validates: Requirements 1.5**
      
      - **Property 6: Invalid Space Rejection** - For any record with invalid spaceId, import should reject that record
      - **Validates: Requirements 2.5**
    
    - [ ] 7.4.2 Write unit tests for error responses
      - Test 400 for validation errors
      - Test 404 for not found
      - Test 500 for server errors
      - Test error messages are JSON formatted
      - Test error messages are descriptive

- [ ] 8. Implement web interface frontend
  - [ ] 8.1 Create HTML structure (index.html)
    - Header with title and action buttons
    - Sidebar with space filters
    - Main area for record display
    - Upload zone (drag-and-drop)
    - Modal for editing records
    - _Requirements: 13.1, 13.2, 14.1_
    
    - [ ] 8.1.1 Validate HTML structure
      - Test HTML is valid and well-formed
      - Test all required elements are present
      - Test accessibility attributes are included
      - Test responsive meta tags are present

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
    
    - [ ] 8.2.1 Write property tests for frontend operations
      - **Property 13: Preview Accuracy** - For any valid JSON file, preview record count should match actual number of records in file
      - **Validates: Requirements 9.2**
    
    - [ ] 8.2.2 Write manual test checklist for web UI
      - Test records load and display on page load
      - Test space filter buttons work correctly
      - Test drag-and-drop file upload works
      - Test file picker upload works
      - Test edit modal opens and saves changes
      - Test delete confirmation dialog appears
      - Test bulk selection checkboxes work
      - Test bulk delete with confirmation
      - Test bulk export downloads JSON
      - Test clear all data with confirmation

  - [ ] 8.3 Create CSS styling (styles.css)
    - Responsive layout
    - Card-based record display
    - Drag-and-drop visual feedback
    - Modal styling
    - Button and form styling
    - _Requirements: 13.1_
    
    - [ ] 8.3.1 Validate CSS and responsiveness
      - Test layout works on desktop (1920x1080)
      - Test layout works on tablet (768x1024)
      - Test layout works on mobile (375x667)
      - Test drag-and-drop visual feedback is visible
      - Test modal is centered and accessible

- [ ] 9. Checkpoint - Ensure all tests pass
  - Run all unit tests and property tests
  - Ensure all tests pass, ask the user if questions arise
  - Commit progress: `git commit -m "feat: core import service and models complete with tests"`

- [ ] 10. Create documentation
  - [ ] 10.1 Write README for tool
    - Document CLI usage with examples
    - Document web interface usage
    - Document JSON schema
    - Document pre-packaged datasets
    - _Requirements: All_
    
    - [ ] 10.1.1 Review README completeness
      - Test all CLI examples work as documented
      - Test all web interface instructions are accurate
      - Test JSON schema examples are valid
      - Test dataset descriptions match actual files

  - [ ] 10.2 Add inline code documentation
    - Document all public methods
    - Add usage examples in doc comments
    - Document error conditions
    - _Requirements: All_
    
    - [ ] 10.2.1 Validate code documentation
      - Test all public APIs have doc comments
      - Test doc comments include examples
      - Test error conditions are documented
      - Run `dart doc` to generate documentation

- [ ] 11. Final testing and validation
  - [ ] 11.1 Test CLI with various scenarios
    - Test file import
    - Test dataset import
    - Test clear operation
    - Test dry-run mode
    - Test error handling
    - _Requirements: 1-12_
    
    - [ ] 11.1.1 Write property test for CLI validation
      - **Property 1: JSON Validation Correctness** - For any JSON string, validation should accept it if and only if it conforms to schema
      - **Validates: Requirements 1.1**
    
    - [ ] 11.1.2 Run end-to-end CLI tests
      - Test: `dart run tool/import_data.dart --file test.json`
      - Test: `dart run tool/import_data.dart --dataset small`
      - Test: `dart run tool/import_data.dart --clear --file test.json`
      - Test: `dart run tool/import_data.dart --dry-run --file test.json`
      - Test: `dart run tool/import_data.dart --file invalid.json` (expect error)

  - [ ] 11.2 Test web interface
    - Test file upload
    - Test record editing
    - Test record deletion
    - Test bulk operations
    - Test clear all data
    - _Requirements: 13-15_
    
    - [ ] 11.2.1 Run end-to-end web tests
      - Start server: `dart run tool/import_data.dart --web`
      - Test upload small dataset via web UI
      - Test edit a record via web UI
      - Test delete a record via web UI
      - Test bulk select and delete via web UI
      - Test export records via web UI
      - Test clear all data via web UI

  - [ ] 11.3 Test database operations
    - Verify records are inserted correctly
    - Verify space routing works
    - Verify viewCount clamping
    - Verify date validation
    - _Requirements: 2, 4, 5_
    
    - [ ] 11.3.1 Write property test for viewCount default
      - **Property 11: ViewCount Default** - For any record without viewCount field, stored viewCount should be 0
      - **Validates: Requirements 5.5**
    
    - [ ] 11.3.2 Run database verification tests
      - Import test data and verify record count
      - Query by space and verify isolation
      - Check viewCount values are clamped correctly
      - Check dates are within valid range

- [ ] 12. Final checkpoint - Ensure all tests pass
  - Run complete test suite: `dart test`
  - Ensure all tests pass, ask the user if questions arise
  - Final commit: `git commit -m "feat: bulk test data import tool complete with CLI and web interface"`
