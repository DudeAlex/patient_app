import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:patient_app/features/records/domain/entities/record.dart';
import 'database_service.dart';
import 'models/test_data_import.dart';
import 'models/test_record.dart';
import 'models/import_result.dart';

typedef ProgressCallback = void Function(int current, int total);

class CoreImportService {
  final DatabaseService _dbService;

  CoreImportService(this._dbService);

  /// Validates JSON structure against schema
  Future<ValidationResult> validateJson(String jsonContent) async {
    try {
      final dynamic jsonData = json.decode(jsonContent);

      if (jsonData is! Map<String, dynamic>) {
        return ValidationResult(
          isValid: false,
          errors: [
            ValidationError(message: 'JSON must be an object', field: 'root'),
          ],
        );
      }

      if (!jsonData.containsKey('records')) {
        return ValidationResult(
          isValid: false,
          errors: [
            ValidationError(
              message: 'Missing required field: records',
              field: 'records',
            ),
          ],
        );
      }

      final records = jsonData['records'];
      if (records is! List) {
        return ValidationResult(
          isValid: false,
          errors: [
            ValidationError(
              message: 'Field "records" must be an array',
              field: 'records',
            ),
          ],
        );
      }

      final errors = <ValidationError>[];
      for (int i = 0; i < records.length; i++) {
        final record = records[i];
        if (record is! Map<String, dynamic>) {
          errors.add(
            ValidationError(
              message: 'Record at index $i is not an object',
              field: 'records[$i]',
            ),
          );
          continue;
        }

        // Validate required fields
        if (!record.containsKey('title')) {
          errors.add(
            ValidationError(
              message: 'Record at index $i is missing required field: title',
              field: 'records[$i].title',
            ),
          );
        } else if (record['title'] is! String ||
            (record['title'] as String).isEmpty) {
          errors.add(
            ValidationError(
              message:
                  'Record at index $i has invalid title: must be non-empty string',
              field: 'records[$i].title',
            ),
          );
        }

        if (!record.containsKey('spaceId')) {
          errors.add(
            ValidationError(
              message: 'Record at index $i is missing required field: spaceId',
              field: 'records[$i].spaceId',
            ),
          );
        } else if (record['spaceId'] is! String) {
          errors.add(
            ValidationError(
              message: 'Record at index $i has invalid spaceId: must be string',
              field: 'records[$i].spaceId',
            ),
          );
        } else {
          final spaceId = record['spaceId'] as String;
          if (!['health', 'business', 'education'].contains(spaceId)) {
            errors.add(
              ValidationError(
                message:
                    'Record at index $i has invalid spaceId: must be "health", "business", or "education"',
                field: 'records[$i].spaceId',
              ),
            );
          }
        }

        // Validate optional fields if present
        if (record.containsKey('type') && record['type'] is! String) {
          errors.add(
            ValidationError(
              message: 'Record at index $i has invalid type: must be string',
              field: 'records[$i].type',
            ),
          );
        }

        if (record.containsKey('date') && record['date'] is! String) {
          errors.add(
            ValidationError(
              message:
                  'Record at index $i has invalid date: must be ISO 8601 string',
              field: 'records[$i].date',
            ),
          );
        }

        if (record.containsKey('content') && record['content'] is! String) {
          errors.add(
            ValidationError(
              message: 'Record at index $i has invalid content: must be string',
              field: 'records[$i].content',
            ),
          );
        }

        if (record.containsKey('viewCount') && record['viewCount'] is! int) {
          errors.add(
            ValidationError(
              message:
                  'Record at index $i has invalid viewCount: must be integer',
              field: 'records[$i].viewCount',
            ),
          );
        }

        if (record.containsKey('tags') && record['tags'] is! List) {
          errors.add(
            ValidationError(
              message: 'Record at index $i has invalid tags: must be array',
              field: 'records[$i].tags',
            ),
          );
        }
      }

      return ValidationResult(isValid: errors.isEmpty, errors: errors);
    } catch (e) {
      return ValidationResult(
        isValid: false,
        errors: [
          ValidationError(
            message: 'Invalid JSON format: ${e.toString()}',
            field: 'root',
          ),
        ],
      );
    }
  }

  /// Parses JSON into TestDataImport model
  Future<TestDataImport> parseJson(String jsonContent) async {
    final dynamic jsonData = json.decode(jsonContent);
    final records = jsonData['records'] as List;

    final testRecords = <TestRecord>[];
    for (final record in records) {
      // Parse date
      DateTime date = DateTime.now();
      if (record['date'] != null) {
        try {
          date = DateTime.parse(record['date'] as String);

          // Validate date range (3 years ago to now)
          final threeYearsAgo = DateTime.now().subtract(
            const Duration(days: 365 * 3),
          );
          if (date.isBefore(threeYearsAgo)) {
            date = threeYearsAgo;
          } else if (date.isAfter(DateTime.now())) {
            date = DateTime.now();
          }
        } catch (e) {
          // Use current date if parsing fails
          date = DateTime.now();
        }
      }

      // Parse viewCount with clamping
      int viewCount = 0;
      if (record['viewCount'] != null) {
        final value = record['viewCount'];
        if (value is int) {
          viewCount = value;
        } else if (value is String) {
          viewCount = int.tryParse(value) ?? 0;
        }
        // Clamp to 0-1000 range
        viewCount = viewCount.clamp(0, 1000) as int;
      }

      // Parse tags
      List<String> tags = [];
      if (record['tags'] != null) {
        final tagList = record['tags'] as List?;
        if (tagList != null) {
          tags = tagList.map((tag) => tag.toString()).toList();
        }
      }

      final testRecord = TestRecord(
        title: record['title'] as String? ?? '',
        type: record['type'] as String? ?? 'general',
        date: date,
        content: record['content'] as String? ?? '',
        spaceId: record['spaceId'] as String? ?? 'health',
        viewCount: viewCount,
        tags: tags,
      );

      testRecords.add(testRecord);
    }

    return TestDataImport(records: testRecords);
  }

  /// Imports records into database
  Future<ImportResult> importRecords(
    TestDataImport data, {
    ProgressCallback? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();

    final records = data.records;
    int successCount = 0;
    int failureCount = 0;
    final errors = <ImportError>[];

    // Process in batches of 50
    const batchSize = 50;
    for (int i = 0; i < records.length; i += batchSize) {
      final endIndex = (i + batchSize < records.length)
          ? i + batchSize
          : records.length;
      final batch = records.sublist(i, endIndex);

      try {
        final recordEntities = batch
            .map((testRecord) => testRecord.toRecord())
            .toList();
        await _dbService.insertRecords(recordEntities);
        successCount += batch.length;
      } catch (e) {
        failureCount += batch.length;
        errors.add(
          ImportError(
            recordIndex: i,
            message:
                'Failed to import batch starting at index $i: ${e.toString()}',
          ),
        );
      }

      // Report progress
      if (onProgress != null) {
        onProgress(i + batch.length, records.length);
      }
    }

    stopwatch.stop();

    return ImportResult(
      successCount: successCount,
      failureCount: failureCount,
      errors: errors,
      duration: stopwatch.elapsed,
    );
  }

  /// Clears all test data from database
  Future<ClearResult> clearAllData() async {
    final stopwatch = Stopwatch()..start();

    try {
      final count = await _dbService.deleteAllRecords();
      stopwatch.stop();

      return ClearResult(
        deletedCount: count,
        duration: stopwatch.elapsed,
        success: true,
      );
    } catch (e) {
      stopwatch.stop();
      return ClearResult(
        deletedCount: 0,
        duration: stopwatch.elapsed,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Loads pre-packaged dataset
  Future<String> loadPrepackagedDataset(String datasetType) async {
    final datasetPath = path.join('tool', 'test_data_$datasetType.json');
    final file = File(datasetPath);

    if (!await file.exists()) {
      throw Exception('Pre-packaged dataset not found: $datasetPath');
    }

    return await file.readAsString();
  }

  /// Gets all records grouped by space
  Future<Map<String, List<RecordEntity>>> getAllRecords() async {
    final allRecords = await _dbService.getAllRecords();
    final recordsBySpace = <String, List<RecordEntity>>{};

    for (final record in allRecords) {
      if (!recordsBySpace.containsKey(record.spaceId)) {
        recordsBySpace[record.spaceId] = [];
      }
      recordsBySpace[record.spaceId]!.add(record);
    }

    return recordsBySpace;
  }

  /// Updates a single record
  Future<void> updateRecord(int recordId, RecordEntity record) async {
    await _dbService.updateRecord(record);
  }

  /// Deletes records by IDs
  Future<void> deleteRecords(List<int> recordIds) async {
    await _dbService.deleteRecords(recordIds);
  }

  /// Exports records to JSON
  String exportRecordsToJson(List<RecordEntity> records) {
    final testRecords = records.map((entity) {
      return TestRecord.fromRecord(entity);
    }).toList();

    final testDataImport = TestDataImport(records: testRecords);
    return json.encode({
      'records': testDataImport.records
          .map((record) => record.toJson())
          .toList(),
    });
  }
}
