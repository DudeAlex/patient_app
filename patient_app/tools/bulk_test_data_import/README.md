# Bulk Test Data Import Tool

A command-line tool for importing test data into the Patient App database.

## Overview

The Bulk Test Data Import tool provides developers and testers with a streamlined way to populate the Patient App database with realistic test data across multiple spaces (Health, Business, Education) before running the app. This standalone tool addresses the critical need for comprehensive testing of Stage 4 AI context optimization, token budget enforcement, and multi-space functionality without requiring hours of manual data entry.

## Prerequisites

- Dart SDK installed
- Flutter project setup (for database access)

## Installation

The tool is included in the project under the `tools/bulk_test_data_import/` directory and can be run directly using the Dart CLI.

## Usage

### Basic Commands

```bash
# Import from a pre-packaged dataset
dart run tools/bulk_test_data_import/import_data.dart --dataset <dataset_name>

# Import from a custom JSON file
dart run tools/bulk_test_data_import/import_data.dart --file <path_to_json_file>

# Show help
dart run tools/bulk_test_data_import/import_data.dart --help
```

### Available Datasets

- `small` - 20 records (7 health, 7 business, 6 education)
- `medium` - 50 records (17 health, 17 business, 16 education)
- `large` - 89 records (30 health, 30 business, 29 education)
- `stage4` - 96 records optimized for Stage 4 testing (varied dates, viewCounts)

### Command Options

| Option | Alias | Description | Default |
|--------|-------|-------------|---------|
| `--file` | `-f` | Path to JSON file to import | |
| `--dataset` | `-d` | Pre-packaged dataset to import (small, medium, large, stage4) |
| `--db-path` | Path to Isar database file | Default app database location |
| `--device` | | Target device/emulator database via adb (pulls, modifies, and pushes back) | false |
| `--clear` | `-c` | Clear all existing data before import | false |
| `--dry-run` | | Validate and preview import without modifying database | false |
| `--verbose` | `-v` | Enable verbose output | false |
| `--web` | | Start web interface instead of CLI | false |
| `--port` | `-p` | Port for web interface | 8080 |
| `--help` | `-h` | Show this help message | |

### Examples

```bash
# Import the small dataset
dart run tools/bulk_test_data_import/import_data.dart --dataset small

# Import medium dataset with clearing existing data
dart run tools/bulk_test_data_import/import_data.dart --dataset medium --clear

# Preview what would be imported without actually importing
dart run tools/bulk_test_data_import/import_data.dart --file data.json --dry-run

# Import with verbose output
dart run tools/bulk_test_data_import/import_data.dart --dataset stage4 --verbose

# Clear all data without importing anything
dart run tools/bulk_test_data_import/import_data.dart --clear

# Import from custom JSON file
dart run tools/bulk_test_data_import/import_data.dart --file ./path/to/custom_data.json

# Import to device/emulator database (requires connected device)
dart run tools/bulk_test_data_import/import_data.dart --dataset medium --device
```

## JSON Schema

The tool accepts JSON files with the following structure:

```json
{
  "records": [
    {
      "title": "Morning Blood Pressure Reading",
      "type": "vital_signs",
      "date": "2024-11-25T08:00:00Z",
      "content": "Blood pressure: 120/80 mmHg, Pulse: 72 bpm",
      "spaceId": "health",
      "viewCount": 5,
      "tags": ["cardiovascular", "monitoring", "daily"]
    }
  ]
}
```

### Field Requirements

- `title` (string, required): Title of the record
- `spaceId` (string, required): Must be "health", "business", or "education"
- `type` (string, optional): Record type (e.g., "vital_signs", "meeting", "assignment")
- `date` (string, optional): ISO 8601 date format, defaults to current date
- `content` (string, optional): Content of the record
- `viewCount` (integer, optional): View count (0-1000), defaults to 0
- `tags` (array of strings, optional): Tags for the record

## Database Path Resolution

The tool automatically resolves the database path based on the platform:

- **Windows**: `%APPDATA%\com.example.patient_app\isar.isar`
- **macOS**: `~/Library/Application Support/com.example.patient_app/isar.isar`
- **Linux**: `~/.local/share/com.example.patient_app/isar.isar`

You can override this with the `--db-path` option.

## Exit Codes

- `0`: Success
- `1`: Validation error
- `2`: Database error
- `3`: File error
- `4`: Unknown error

## Pre-Packaged Datasets

The tool includes four pre-packaged datasets for different testing scenarios:

1. **Small Dataset** (`--dataset small`): 20 records for quick testing
2. **Medium Dataset** (`--dataset medium`): 50 records for moderate testing
3. **Large Dataset** (`--dataset large`): 89 records for comprehensive testing
4. **Stage 4 Dataset** (`--dataset stage4`): 96 records optimized for Stage 4 AI context testing with varied dates and viewCounts

## Device Import Mode

The tool now supports importing directly to a connected Android device or emulator using the `--device` flag. This feature allows you to populate test data that will appear in the actual app UI on the device.

### Requirements

- Android device connected via USB or emulator running
- Android SDK platform-tools (adb) in your PATH
- Patient app installed on the device/emulator

### Usage

```bash
# Import dataset to device
dart run tools/bulk_test_data_import/import_data.dart --dataset medium --device

# Import from file to device
dart run tools/bulk_test_data_import/import_data.dart --file data.json --device

# Import with clearing existing data on device
dart run tools/bulk_test_data_import/import_data.dart --dataset small --device --clear
```

### How it works

1. The tool pulls the app database from the device using `adb shell run-as`
2. Applies the import operations to the local copy of the database
3. Pushes the updated database back to the device
4. Optionally restarts the app to ensure changes are visible

## Troubleshooting

### Common Issues

1. **File not found**: Ensure the JSON file path is correct and accessible
2. **JSON validation errors**: Check that your JSON file matches the required schema
3. **Database access errors**: Ensure the database path is writable and accessible

### Error Messages

- `File not found`: The specified JSON file could not be accessed
- `JSON validation failed`: The JSON file does not match the required schema
- `Failed to clear data`: An error occurred while clearing existing data
- `Failed to import`: An error occurred during the import process

## Development

### Adding New Pre-Packaged Datasets

To add a new pre-packaged dataset:

1. Create a JSON file in `tools/bulk_test_data_import/test_data/` named `test_data_<name>.json`
2. Ensure it follows the required schema
3. Use it with `dart run tools/bulk_test_data_import/import_data.dart --dataset <name>`

### Testing the Tool

The tool includes comprehensive validation and error handling. You can test it using the `--dry-run` option to preview imports without modifying the database.