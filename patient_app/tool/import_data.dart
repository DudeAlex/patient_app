import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'lib/database_service.dart';
import 'lib/core_import_service.dart';
import 'lib/models/test_data_import.dart';

class CliArgs {
  final String? filePath;
  final String? datasetName;
  final String? dbPath;
 final bool clear;
  final bool dryRun;
  final bool verbose;
  final bool web;
  final int port;

  CliArgs({
    this.filePath,
    this.datasetName,
    this.dbPath,
    required this.clear,
    required this.dryRun,
    required this.verbose,
    required this.web,
    required this.port,
  });
}

class CliInterface {
  /// Parses command-line arguments
  CliArgs parseArgs(List<String> args) {
    final parser = ArgParser()
      ..addOption('file', abbr: 'f', help: 'Path to JSON file to import')
      ..addOption(
        'dataset',
        abbr: 'd',
        help: 'Pre-packaged dataset to import (small, medium, large, stage4)',
      )
      ..addOption('db-path', help: 'Path to Isar database file')
      ..addFlag(
        'clear',
        abbr: 'c',
        help: 'Clear all existing data before import',
        defaultsTo: false,
      )
      ..addFlag(
        'dry-run',
        help: 'Validate and preview import without modifying database',
        defaultsTo: false,
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Enable verbose output',
        defaultsTo: false,
      )
      ..addFlag(
        'web',
        help: 'Start web interface instead of CLI',
        defaultsTo: false,
      )
      ..addOption(
        'port',
        abbr: 'p',
        help: 'Port for web interface',
        defaultsTo: '8080',
      );

    try {
      final results = parser.parse(args);

      // Validate argument combinations
      if (results['file'] != null && results['dataset'] != null) {
        throw UsageException(
          'Cannot specify both --file and --dataset options',
          parser.usage,
        );
      }

      if (results['web'] &&
          (results['file'] != null ||
              results['dataset'] != null ||
              results['clear'])) {
        throw UsageException(
          'Web interface cannot be combined with import options',
          parser.usage,
        );
      }

      return CliArgs(
        filePath: results['file'],
        datasetName: results['dataset'],
        dbPath: results['db-path'],
        clear: results['clear'],
        dryRun: results['dry-run'],
        verbose: results['verbose'],
        web: results['web'],
        port: int.tryParse(results['port']) ?? 8080,
      );
    } on FormatException catch (e) {
      throw UsageException(e.message, parser.usage);
    }
 }

  /// Runs the CLI command
  Future<int> run(List<String> args) async {
    try {
      final cliArgs = parseArgs(args);
      
      if (cliArgs.web) {
        // Import and start web interface here
        outputError('Web interface not yet implemented in this file. This would start the web server.');
        return 1;
      }

      // Determine database path
      String dbPath = cliArgs.dbPath ?? _getDefaultDbPath();

      // Create database service
      final dbService = DatabaseService(dbPath);
      await dbService.open();

      // Create import service with database service
      final importService = CoreImportService(dbService);

      // Handle clear operation if requested
      if (cliArgs.clear) {
        if (!cliArgs.dryRun) {
          outputSuccess('Clearing all existing records...');
          final clearResult = await importService.clearAllData();
          if (clearResult.success) {
            outputSuccess(
              'Cleared ${clearResult.deletedCount} records in ${clearResult.duration.inMilliseconds}ms',
            );
          } else {
            outputError('Failed to clear data: ${clearResult.error}');
            return 2; // Database error
          }
        } else {
          outputSuccess('DRY RUN: Would clear all existing records');
        }
      }

      // Determine input source
      String jsonContent = '';
      if (cliArgs.filePath != null) {
        // Load from file
        final file = File(cliArgs.filePath!);
        if (!await file.exists()) {
          outputError('File not found: ${cliArgs.filePath}');
          return 3; // File error
        }
        jsonContent = await file.readAsString();
        if (cliArgs.verbose) {
          outputSuccess(
            'Loaded ${jsonContent.length} characters from ${cliArgs.filePath}',
          );
        }
      } else if (cliArgs.datasetName != null) {
        // Load from pre-packaged dataset
        try {
          jsonContent = await importService.loadPrepackagedDataset(
            cliArgs.datasetName!,
          );
          if (cliArgs.verbose) {
            outputSuccess(
              'Loaded pre-packaged dataset: ${cliArgs.datasetName}',
            );
          }
        } catch (e) {
          outputError(
            'Failed to load dataset ${cliArgs.datasetName}: ${e.toString()}',
          );
          return 3; // File error
        }
      } else if (!cliArgs.clear) {
        // No input specified, show usage
        displayUsage();
        return 1; // Validation error
      }

      if (jsonContent.isNotEmpty) {
        // Validate JSON
        outputProgress('Validating JSON...', 0, 1);
        final validationResult = await importService.validateJson(jsonContent);

        if (!validationResult.isValid) {
          outputError('JSON validation failed:');
          for (final error in validationResult.errors) {
            outputError('  - ${error.message} (field: ${error.field})');
          }
          return 1; // Validation error
        }

        outputSuccess(
          'JSON validation passed (${validationResult.errors.length} warnings)',
        );

        if (cliArgs.dryRun) {
          // Parse and show preview in dry run mode
          final testDataImport = await importService.parseJson(jsonContent);
          outputSuccess(
            'DRY RUN: Would import ${testDataImport.totalRecords} records:',
          );

          // Show breakdown by space
          final breakdown = testDataImport.recordsBySpace;
          for (final entry in breakdown.entries) {
            outputSuccess('  ${entry.key}: ${entry.value} records');
          }

          // Show first 5 records as sample
          final sampleRecords = testDataImport.records.take(5).toList();
          outputSuccess('Sample records:');
          for (int i = 0; i < sampleRecords.length; i++) {
            final record = sampleRecords[i];
            outputSuccess(
              '  ${i + 1}. ${record.title} (${record.type}) - ${record.date}',
            );
          }

          if (testDataImport.totalRecords > 5) {
            outputSuccess(
              '  ... and ${testDataImport.totalRecords - 5} more records',
            );
          }
        } else {
          // Parse JSON
          outputProgress('Parsing JSON...', 0, 1);
          final testDataImport = await importService.parseJson(jsonContent);

          // Import records with progress callback
          outputSuccess(
            'Starting import of ${testDataImport.totalRecords} records...',
          );
          final importResult = await importService.importRecords(
            testDataImport,
            onProgress: (current, total) {
              outputProgress('Importing...', current, total);
            },
          );

          // Output results
          outputSuccess('Import completed in ${importResult.duration.inMilliseconds}ms');
          outputSuccess('Successfully imported: ${importResult.successCount} records');
          if (importResult.failureCount > 0) {
            outputError('Failed to import: ${importResult.failureCount} records');
            for (final error in importResult.errors) {
              outputError('  - Record ${error.recordIndex}: ${error.message}');
            }
          }
        }
      } else if (cliArgs.clear) {
        outputSuccess('Database cleared successfully');
      }

      await dbService.close();
      return 0; // Success
    } catch (e) {
      if (e is UsageException) {
        outputError(e.message);
        displayUsage();
        return 1; // Validation error
      } else {
        outputError('Unexpected error: ${e.toString()}');
        return 4; // Unknown error
      }
    }
 }

  /// Outputs progress updates
  void outputProgress(String message, int current, int total) {
    final percent = total > 0 ? (current / total * 100).round() : 0;
    stdout.write('\r$message $current/$total (${percent}%)');
    if (current == total && total > 0) {
      stdout.writeln(); // New line when complete
    }
 }

  /// Outputs error messages
  void outputError(String message) {
    stderr.writeln('ERROR: $message');
  }

  /// Outputs success messages
 void outputSuccess(String message) {
    stdout.writeln('SUCCESS: $message');
  }

  /// Displays usage instructions
  void displayUsage() {
    print('Usage: dart run tool/import_data.dart [options]');
    print('');
    print('Options:');
    print('  -f, --file <path>          Path to JSON file to import');
    print('  -d, --dataset <name>       Pre-packaged dataset to import (small, medium, large, stage4)');
    print('  --db-path <path>           Path to Isar database file');
    print('  -c, --clear                Clear all existing data before import');
    print('  --dry-run                  Validate and preview import without modifying database');
    print('  -v, --verbose              Enable verbose output');
    print('  --web                      Start web interface instead of CLI');
    print('  -p, --port <number>        Port for web interface (default: 8080)');
    print('  -h, --help                 Show this help message');
    print('');
    print('Examples:');
    print('  Import from file: dart run tool/import_data.dart --file data.json');
    print('  Import dataset:   dart run tool/import_data.dart --dataset medium --clear');
    print('  Dry run:          dart run tool/import_data.dart --file data.json --dry-run');
    print('  Start web:        dart run tool/import_data.dart --web');
  }

  /// Gets default database path based on platform
  String _getDefaultDbPath() {
    String dbDir;
    if (Platform.isWindows) {
      dbDir = path.join(
        Platform.environment['APPDATA'] ?? 'C:\\temp',
        'com.example.patient_app',
      );
    } else if (Platform.isMacOS) {
      dbDir = path.join(
        Platform.environment['HOME'] ?? '/tmp',
        'Library/Application Support/com.example.patient_app',
      );
    } else {
      // Linux or other Unix-like
      dbDir = path.join(
        Platform.environment['HOME'] ?? '/tmp',
        '.local/share/com.example.patient_app',
      );
    }

    return path.join(dbDir, 'isar.isar');
  }
}

void main(List<String> args) async {
  // Create CLI interface and run
  final cli = CliInterface();
  final exitCode = await cli.run(args);
 exit(exitCode);
}
