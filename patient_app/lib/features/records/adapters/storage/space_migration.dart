import 'package:isar/isar.dart';

import 'record_isar_model.dart';

/// Handles migration of existing records to include spaceId field.
/// Sets spaceId='health' for all existing records to maintain backward compatibility.
class SpaceMigration {
  SpaceMigration(this._db);

  final Isar _db;

  /// Executes the migration to add spaceId to existing records.
  /// Returns true if migration was successful, false otherwise.
  /// 
  /// Logs progress to console for debugging purposes.
  Future<bool> migrate() async {
    try {
      print('[SpaceMigration] Starting space migration...');

      // Count records that need migration (those without spaceId or with empty spaceId)
      final totalRecords = await _db.records.count();
      print('[SpaceMigration] Found $totalRecords total records in database');

      if (totalRecords == 0) {
        print('[SpaceMigration] No records to migrate');
        return true;
      }

      // Process records in batches to avoid memory issues
      const batchSize = 100;
      int migratedCount = 0;
      int offset = 0;

      while (offset < totalRecords) {
        final batch = await _db.records
            .where()
            .offset(offset)
            .limit(batchSize)
            .findAll();

        if (batch.isEmpty) break;

        // Update records that need migration
        await _db.writeTxn(() async {
          for (final record in batch) {
            // Only update if spaceId is not set or is empty
            if (record.spaceId.isEmpty) {
              record.spaceId = 'health';
              await _db.records.put(record);
              migratedCount++;
            }
          }
        });

        offset += batchSize;
        print('[SpaceMigration] Migration progress: $offset/$totalRecords records processed');
      }

      print('[SpaceMigration] Space migration completed successfully. Migrated $migratedCount records.');
      return true;
    } catch (e, stackTrace) {
      print('[SpaceMigration] Space migration failed: $e');
      print('[SpaceMigration] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Verifies that all records have a valid spaceId.
  /// Returns true if all records are properly migrated.
  Future<bool> verify() async {
    try {
      print('[SpaceMigration] Verifying space migration...');

      final recordsWithoutSpace = await _db.records
          .filter()
          .spaceIdIsEmpty()
          .count();

      if (recordsWithoutSpace > 0) {
        print('[SpaceMigration] Warning: Found $recordsWithoutSpace records without spaceId');
        return false;
      }

      final totalRecords = await _db.records.count();
      print('[SpaceMigration] Migration verification passed: all $totalRecords records have spaceId');
      return true;
    } catch (e, stackTrace) {
      print('[SpaceMigration] Migration verification failed: $e');
      print('[SpaceMigration] Stack trace: $stackTrace');
      return false;
    }
  }
}
