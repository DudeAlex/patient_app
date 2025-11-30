import 'dart:io';
import 'package:args/args.dart';
import 'package:args/src/usage_exception.dart';
import 'package:path/path.dart' as path;
import 'lib/database_service.dart';
import 'lib/core_import_service.dart';

class CliArgs {
  final String? filePath;
  final String? datasetName;
  final String? dbPath;
  final bool device;
  final bool clear;
  final bool dryRun;
  final bool verbose;
  final bool web;
  final int port;

  CliArgs({
    this.filePath,
    this.datasetName,
    this.dbPath,
    required this.device,
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
         'device',
         help: 'Target device/emulator database via adb (pulls, modifies, and pushes back)',
         defaultsTo: false,
       )
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
       )
       ..addFlag(
         'help',
         abbr: 'h',
         help: 'Show this help message',
         defaultsTo: false,
       );

    try {
      final results = parser.parse(args);

      // Check if help was requested
      if (results['help']) {
        displayUsage();
        exit(0);
      }

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
        device: results['device'],
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
      
      // Handle device mode if requested
      if (cliArgs.device) {
        outputSuccess('Device mode enabled - pulling database from device...');
        final deviceDbPath = await _pullDatabaseFromDevice();
        if (deviceDbPath == null) {
          outputError('Failed to pull database from device');
          return 5; // Device error
        }
        dbPath = deviceDbPath;
        
        // Add cleanup hook to push database back to device on success
        // We'll handle this after the import operations
      }

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

      // Close database connection
      await dbService.close();
      
      // If in device mode, push the updated database back to the device
      if (cliArgs.device) {
        outputSuccess('Device mode enabled - pushing updated database back to device...');
        final pushResult = await _pushDatabaseToDevice(dbPath);
        if (!pushResult) {
          outputError('Failed to push database back to device');
          return 6; // Device push error
        }
        outputSuccess('Database successfully pushed back to device');
      }

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
    stdout.write('\r$message $current/$total ($percent%)');
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
    print('Usage: dart run tools/bulk_test_data_import/import_data.dart [options]');
    print('');
    print('Options:');
    print('  -f, --file <path>          Path to JSON file to import');
    print('  -d, --dataset <name>       Pre-packaged dataset to import (small, medium, large, stage4)');
    print('  --db-path <path>           Path to Isar database file');
    print('  --device                   Target device/emulator database via adb (pulls, modifies, and pushes back)');
    print('  -c, --clear                Clear all existing data before import');
    print('  --dry-run                  Validate and preview import without modifying database');
    print('  -v, --verbose              Enable verbose output');
    print('  --web                      Start web interface instead of CLI');
    print('  -p, --port <number>        Port for web interface (default: 8080)');
    print('  -h, --help                 Show this help message');
    print('');
    print('Examples:');
    print('  Import from file: dart run tools/bulk_test_data_import/import_data.dart --file data.json');
    print('  Import dataset:   dart run tools/bulk_test_data_import/import_data.dart --dataset medium --clear');
    print('  Dry run:          dart run tools/bulk_test_data_import/import_data.dart --file data.json --dry-run');
    print('  Device import:    dart run tools/bulk_test_data_import/import_data.dart --dataset medium --device');
    print('  Start web:        dart run tools/bulk_test_data_import/import_data.dart --web');
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

    return path.join(dbDir, 'patient.isar');
  }

  /// Pulls the database from the device via adb
  Future<String?> _pullDatabaseFromDevice() async {
    try {
      // Check if adb is available
      final adbResult = await Process.run('adb', ['version']);
      if (adbResult.exitCode != 0) {
        outputError('adb is not available in PATH. Please install Android SDK platform-tools.');
        return null;
      }

      outputProgress('Checking for connected devices...', 0, 1);
      
      // Check for connected devices
      final devicesResult = await Process.run('adb', ['devices']);
      if (devicesResult.exitCode != 0) {
        outputError('Failed to list connected devices: ${devicesResult.stderr}');
        return null;
      }

      final deviceOutput = devicesResult.stdout.toString();
      if (!deviceOutput.contains('device') || deviceOutput.contains('device\n') || deviceOutput.contains('device\r\n')) {
        // Check if there's actually a connected device (excluding the header line)
        final lines = deviceOutput.split('\n');
        bool hasDevice = false;
        for (final line in lines) {
          if (line.trim().isNotEmpty && !line.contains('List of devices attached') && line.contains('\tdevice') && !line.contains('unauthorized')) {
            hasDevice = true;
            break;
          }
        }
        if (!hasDevice) {
          outputError('No connected Android device found. Please connect a device or start an emulator.');
          return null;
        }
      }

      outputProgress('Pulling database from device...', 0, 1);
      
      // Create a temporary file to store the pulled database
      final tempDir = Directory.systemTemp;
      final tempDbFile = File('${tempDir.path}/patient_device.isar');
      
      // Pull the database from the device using run-as
      final appId = 'com.example.patient_app';
      final deviceDbPath = '/data/user/0/$appId/app_flutter/patient.isar';
      
      // Ensure the database exists on device
      final existsResult = await Process.run('adb', [
        'shell',
        'run-as',
        appId,
        'sh',
        '-c',
        '[ -f $deviceDbPath ] && echo exists || echo missing',
      ]);
      final exists = existsResult.exitCode == 0 &&
          (existsResult.stdout as String).trim().contains('exists');
      
      if (!exists) {
        outputSuccess('Database not found on device; creating a fresh database locally.');
        // Create an empty database locally so we can import into it and push back.
        final tempDb = DatabaseService(tempDbFile.path);
        await tempDb.open();
        await tempDb.close();
        return tempDbFile.path;
      }
      
      // Use run-as to read the database file and save it locally
      final result = await Process.run('adb', [
        'exec-out',
        'run-as',
        appId,
        'cat',
        deviceDbPath
      ]);
      
      if (result.exitCode != 0) {
        outputError('Failed to pull database from device: ${result.stderr}');
        return null;
      }

      // Write the database content to the temporary file
      await tempDbFile.writeAsBytes(result.stdout is List<int> ? result.stdout as List<int> : (result.stdout as String).codeUnits);
      outputSuccess('Database pulled successfully to: ${tempDbFile.path}');
      
      return tempDbFile.path;
    } catch (e) {
      outputError('Error pulling database from device: $e');
      return null;
    }
  }

  /// Pushes the updated database back to the device via adb
  Future<bool> _pushDatabaseToDevice(String localDbPath) async {
    try {
      outputProgress('Pushing database back to device...', 0, 1);
      
      final appId = 'com.example.patient_app';
      final deviceDbPath = '/data/user/0/$appId/app_flutter/patient.isar';
      final tempPushPath = '/data/local/tmp/patient_import.isar';

      // Ensure target directory exists
      final mkdirResult = await Process.run('adb', [
        'shell',
        'run-as',
        appId,
        'mkdir',
        '-p',
        '/data/user/0/$appId/app_flutter'
      ]);
      if (mkdirResult.exitCode != 0) {
        outputError('Failed to create app_flutter directory: ${mkdirResult.stderr}');
        return false;
      }

      // Push file to a temporary world-readable location
      final pushResult = await Process.run('adb', [
        'push',
        localDbPath,
        tempPushPath,
      ]);
      if (pushResult.exitCode != 0) {
        outputError('Failed to push database to temp path: ${pushResult.stderr}');
        return false;
      }

      // Move the file into the app sandbox using run-as (has access to temp path)
      final moveResult = await Process.run('adb', [
        'shell',
        'run-as',
        appId,
        'cp',
        tempPushPath,
        deviceDbPath,
      ]);
      if (moveResult.exitCode != 0) {
        outputError('Failed to move database to app directory: ${moveResult.stderr}');
        return false;
      }

      // Clean up temp file
      await Process.run('adb', ['shell', 'rm', tempPushPath]);

      // Optionally, restart the app to make sure Isar picks up the changes
      final restartResult = await Process.run('adb', [
        'shell',
        'am',
        'force-stop',
        appId
      ]);
      
      if (restartResult.exitCode != 0) {
        outputError('Warning: Failed to restart app after database update: ${restartResult.stderr}');
        // We don't fail the operation for this, just warn the user
      } else {
        outputSuccess('App restarted successfully');
      }

      outputSuccess('Database pushed back to device successfully');
      return true;
    } catch (e) {
      outputError('Error pushing database to device: $e');
      return false;
    }
  }
}

void main(List<String> args) async {
  // Create CLI interface and run
  final cli = CliInterface();
  final exitCode = await cli.run(args);
 exit(exitCode);
}
