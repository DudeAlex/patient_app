# Requirements Document - Bulk Test Data Import

## Introduction

This document specifies the requirements for a bulk test data import tool that allows developers and testers to quickly populate the Patient App database with realistic test data across multiple spaces (Health, Business, Education) before running the app. This standalone script/module is essential for comprehensive testing of Stage 4 AI context optimization, token budget enforcement, performance testing, and multi-space functionality.

## Glossary

- **Test Data Import Tool**: A standalone Dart script or module that populates the database with test records
- **JSON Schema**: The structured format defining how test records are represented in JSON files
- **Space**: A category/domain for organizing records (Health, Business, Education)
- **Record**: A single data entry within a space (e.g., blood pressure reading, meeting note)
- **Bulk Import**: The process of importing multiple records (50-100+) at once
- **ViewCount**: A metric tracking how many times a record has been viewed, used for relevance scoring
- **Import Script**: The executable Dart script that processes JSON files and populates the database
- **Database Path**: The file system location of the Isar database to be populated

## Requirements

### Requirement 1: JSON-Based Data Import

**User Story:** As a developer, I want to run a script that imports test records from JSON files into the database, so that I can quickly populate the app with realistic test data before launching it.

#### Acceptance Criteria

1. WHEN a developer runs the import script with a JSON file path THEN the Test Data Import Tool SHALL validate the file structure against the defined schema
2. WHEN the JSON file is valid THEN the Test Data Import Tool SHALL parse all records from the file
3. WHEN parsing is complete THEN the Test Data Import Tool SHALL import all valid records into the database
4. WHEN import is complete THEN the Test Data Import Tool SHALL output a summary showing the count of successfully imported records
5. IF the JSON file contains invalid data THEN the Test Data Import Tool SHALL output specific error messages indicating which records failed validation

### Requirement 2: Multi-Space Support

**User Story:** As a tester, I want to import records for different spaces (Health, Business, Education), so that I can test multi-space functionality and space isolation.

#### Acceptance Criteria

1. WHEN a JSON file contains records with spaceId "health" THEN the Test Data Import Tool SHALL import those records into the Health space
2. WHEN a JSON file contains records with spaceId "business" THEN the Test Data Import Tool SHALL import those records into the Business space
3. WHEN a JSON file contains records with spaceId "education" THEN the Test Data Import Tool SHALL import those records into the Education space
4. WHEN a JSON file contains records for multiple spaces THEN the Test Data Import Tool SHALL import all records to their respective spaces
5. IF a record specifies an invalid spaceId THEN the Test Data Import Tool SHALL reject that record and output an error

### Requirement 3: Record Type Variety

**User Story:** As a tester, I want to import various types of records (vital signs, meetings, assignments, etc.), so that I can test the app with realistic diverse data.

#### Acceptance Criteria

1. WHEN importing Health records THEN the Test Data Import Tool SHALL support types including vital_signs, medication, doctor_visit, lab_result, symptom, and exercise
2. WHEN importing Business records THEN the Test Data Import Tool SHALL support types including meeting, proposal, client_note, project_update, invoice, contract, and task
3. WHEN importing Education records THEN the Test Data Import Tool SHALL support types including assignment, course, study_note, exam, research, lecture, and grade
4. WHEN a record specifies a type THEN the Test Data Import Tool SHALL store that type with the record
5. IF a record type is not recognized THEN the Test Data Import Tool SHALL import the record with a default "general" type

### Requirement 4: Date Range Configuration

**User Story:** As a tester, I want to import records with various dates (recent, old, specific ranges), so that I can test date-based filtering and context optimization.

#### Acceptance Criteria

1. WHEN a record specifies a date in ISO 8601 format THEN the Test Data Import Tool SHALL parse and store that date correctly
2. WHEN importing records THEN the Test Data Import Tool SHALL support dates ranging from 3 years ago to the current date
3. WHEN a record date is in the future THEN the Test Data Import Tool SHALL reject that record
4. WHEN a record date is more than 3 years old THEN the Test Data Import Tool SHALL reject that record
5. IF a record date is invalid or missing THEN the Test Data Import Tool SHALL use the current date as default

### Requirement 5: ViewCount Support

**User Story:** As a tester, I want to import records with predefined viewCounts, so that I can test relevance scoring without manually viewing records multiple times.

#### Acceptance Criteria

1. WHEN a record specifies a viewCount value THEN the Test Data Import Tool SHALL store that viewCount with the record
2. WHEN a record viewCount is between 0 and 1000 THEN the Test Data Import Tool SHALL accept that value
3. WHEN a record viewCount is negative THEN the Test Data Import Tool SHALL set viewCount to 0
4. WHEN a record viewCount exceeds 1000 THEN the Test Data Import Tool SHALL set viewCount to 1000
5. IF a record does not specify viewCount THEN the Test Data Import Tool SHALL default to 0

### Requirement 6: Pre-Packaged Test Data Sets

**User Story:** As a tester, I want to use pre-packaged test data sets, so that I can quickly import standard test scenarios without creating custom JSON files.

#### Acceptance Criteria

1. WHEN the tool is distributed THEN the system SHALL include a small dataset with 20 mixed-space records
2. WHEN the tool is distributed THEN the system SHALL include a medium dataset with 50 mixed-space records
3. WHEN the tool is distributed THEN the system SHALL include a large dataset with 100 mixed-space records
4. WHEN the tool is distributed THEN the system SHALL include a Stage 4 optimized dataset for token testing
5. WHEN a developer runs the script with a dataset name THEN the Test Data Import Tool SHALL import that pre-packaged dataset

### Requirement 7: Command Line Interface

**User Story:** As a developer, I want to run the import script from the command line with arguments, so that I can easily integrate it into my testing workflow.

#### Acceptance Criteria

1. WHEN a developer runs the script with a file path argument THEN the Test Data Import Tool SHALL read the specified JSON file
2. WHEN a developer runs the script with a dataset name argument THEN the Test Data Import Tool SHALL load the corresponding pre-packaged dataset
3. WHEN a developer runs the script without arguments THEN the Test Data Import Tool SHALL display usage instructions
4. WHEN a developer runs the script with a --clear flag THEN the Test Data Import Tool SHALL clear all existing records before importing
5. IF file reading fails THEN the Test Data Import Tool SHALL output an error message with the failure reason and exit with non-zero code

### Requirement 8: Clear Test Data

**User Story:** As a tester, I want to clear all test data before importing, so that I can start fresh for a new test scenario.

#### Acceptance Criteria

1. WHEN a developer runs the script with --clear flag THEN the Test Data Import Tool SHALL delete all records from all spaces
2. WHEN deletion is requested THEN the system SHALL output a warning that all records will be deleted
3. WHEN deletion is complete THEN the Test Data Import Tool SHALL output a success message with the count of deleted records
4. WHEN deletion completes successfully THEN the Test Data Import Tool SHALL proceed with import if a file or dataset is specified
5. IF deletion fails THEN the Test Data Import Tool SHALL output an error message and exit without importing

### Requirement 9: Dry Run Mode

**User Story:** As a developer, I want to preview what will be imported without modifying the database, so that I can verify the data is correct before committing changes.

#### Acceptance Criteria

1. WHEN a developer runs the script with --dry-run flag THEN the Test Data Import Tool SHALL parse and validate the file without importing
2. WHEN dry run mode is active THEN the system SHALL output the total count of records to be imported
3. WHEN dry run mode is active THEN the system SHALL output a breakdown by space (Health, Business, Education)
4. WHEN dry run mode is active THEN the system SHALL output a sample of the first 5 records
5. WHEN dry run completes THEN the Test Data Import Tool SHALL exit without modifying the database

### Requirement 10: Database Path Configuration

**User Story:** As a developer, I want to specify the database path, so that I can populate different database instances for different testing scenarios.

#### Acceptance Criteria

1. WHEN a developer runs the script without specifying a database path THEN the Test Data Import Tool SHALL use the default app database location
2. WHEN a developer runs the script with --db-path argument THEN the Test Data Import Tool SHALL use the specified database path
3. WHEN the specified database path does not exist THEN the Test Data Import Tool SHALL create a new database at that location
4. WHEN the database path is invalid THEN the Test Data Import Tool SHALL output an error message and exit
5. WHEN import completes THEN the Test Data Import Tool SHALL output the database path that was populated

### Requirement 11: Import Progress Feedback

**User Story:** As a developer, I want to see progress during import, so that I know the system is working and how long the import will take.

#### Acceptance Criteria

1. WHEN import begins THEN the Test Data Import Tool SHALL output a message indicating import has started
2. WHEN importing records THEN the system SHALL output progress updates showing percentage complete
3. WHEN importing records THEN the system SHALL output the count of records imported so far
4. WHEN import is processing large datasets THEN the system SHALL output progress updates at regular intervals
5. WHEN import completes or fails THEN the system SHALL output a final summary with total time elapsed

### Requirement 12: Validation and Error Handling

**User Story:** As a developer, I want clear error messages when import fails, so that I can fix the JSON file and retry.

#### Acceptance Criteria

1. WHEN JSON parsing fails THEN the Test Data Import Tool SHALL output the line number and error description
2. WHEN a record fails validation THEN the system SHALL output which field caused the failure
3. WHEN multiple records fail THEN the system SHALL output a summary of all failures
4. WHEN some records succeed and others fail THEN the system SHALL import the valid records and output the failures
5. IF all records fail validation THEN the system SHALL not modify the database and output a comprehensive error report

### Requirement 13: Web Interface

**User Story:** As a developer, I want a simple web interface to manage test data, so that I can visually browse, edit, delete, and upload records without using the command line.

#### Acceptance Criteria

1. WHEN a developer starts the web server THEN the Test Data Import Tool SHALL serve a single-page web interface
2. WHEN the web interface loads THEN the system SHALL display all existing records grouped by space
3. WHEN a developer clicks on a record THEN the system SHALL display an edit form with all record fields
4. WHEN a developer edits a record and saves THEN the system SHALL update that record in the database
5. WHEN a developer clicks delete on a record THEN the system SHALL remove that record from the database after confirmation

### Requirement 14: Web File Upload

**User Story:** As a developer, I want to upload JSON files through the web interface, so that I can import test data without using the command line.

#### Acceptance Criteria

1. WHEN the web interface displays THEN the system SHALL show a file upload area
2. WHEN a developer drags a JSON file to the upload area THEN the system SHALL accept the file
3. WHEN a developer clicks the upload area THEN the system SHALL open a file picker dialog
4. WHEN a file is uploaded THEN the Test Data Import Tool SHALL validate and import the records
5. WHEN import completes THEN the web interface SHALL refresh to show the newly imported records

### Requirement 15: Web Bulk Operations

**User Story:** As a developer, I want to perform bulk operations through the web interface, so that I can efficiently manage large amounts of test data.

#### Acceptance Criteria

1. WHEN the web interface displays records THEN the system SHALL provide checkboxes for selecting multiple records
2. WHEN records are selected THEN the system SHALL display bulk action buttons (delete, export)
3. WHEN a developer clicks bulk delete THEN the system SHALL delete all selected records after confirmation
4. WHEN a developer clicks export THEN the system SHALL download selected records as a JSON file
5. WHEN a developer clicks "Clear All Data" THEN the system SHALL delete all records from all spaces after confirmation

---

**Document Version:** 1.0  
**Created:** November 29, 2024  
**Status:** Draft - Ready for Review
