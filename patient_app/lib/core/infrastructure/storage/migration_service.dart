import 'package:isar/isar.dart';

import '../../../features/records/adapters/storage/record_isar_model.dart';
import '../../../features/records/adapters/storage/space_migration.dart';
import '../../application/ports/space_repository.dart';

/// Service that manages database and user data migrations.
/// Tracks migration versions and ensures migrations run only once.
/// 
/// This service orchestrates both database schema migrations (via SpaceMigration)
/// and user data migrations (setting default spaces for existing users).
/// 
/// Migration versions:
/// - Version 0: Pre-migration state (records without spaceId)
/// - Version 1: Spaces system migration (adds spaceId to all records)
/// 
/// The service uses a heuristic approach to determine migration version:
/// - If no records exist, assumes current version (new installation)
/// - If records exist without spaceId, assumes version 0 (needs migration)
/// - If all records have spaceId, assumes migration complete
class MigrationService {
  MigrationService({
    required Isar db,
    required SpaceRepository spaceRepository,
  })  : _db = db,
        _spaceRepository = spaceRepository;

  final Isar _db;
  final SpaceRepository _spaceRepository;

  // Migration version constants
  static const int _currentMigrationVersion = 1;

  /// Checks if migration is needed and executes it if necessary.
  /// Returns true if migration was successful or not needed.
  Future<bool> checkAndMigrate() async {
    try {
      final currentVersion = await _getMigrationVersion();
      print('[MigrationService] Current migration version: $currentVersion');

      if (currentVersion >= _currentMigrationVersion) {
        print('[MigrationService] No migration needed');
        return true;
      }

      print('[MigrationService] Migration needed from version $currentVersion to $_currentMigrationVersion');
      return await _executeMigrations(currentVersion);
    } catch (e, stackTrace) {
      print('[MigrationService] Migration check failed: $e');
      print('[MigrationService] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Gets the current migration version from storage.
  /// Returns 0 if no version is stored (first run or pre-migration state).
  Future<int> _getMigrationVersion() async {
    // Quick check: if onboarding is complete, migration must be done
    // This avoids expensive database queries on every app launch
    final hasCompletedOnboarding = await _spaceRepository.hasCompletedOnboarding();
    if (hasCompletedOnboarding) {
      // User has completed onboarding, so migration is definitely done
      return _currentMigrationVersion;
    }
    
    // For new users or pre-migration users, check the database
    final totalRecords = await _db.records.count();
    if (totalRecords == 0) {
      // New installation, set to current version
      return _currentMigrationVersion;
    }

    // Check if any records lack spaceId (only for users with existing data)
    final recordsWithoutSpace = await _db.records
        .filter()
        .spaceIdIsEmpty()
        .count();

    if (recordsWithoutSpace > 0) {
      // Pre-migration state
      return 0;
    }

    // All records have spaceId, assume migration complete
    return _currentMigrationVersion;
  }

  /// Executes all migrations from the current version to the latest.
  Future<bool> _executeMigrations(int fromVersion) async {
    try {
      // Execute migrations sequentially
      if (fromVersion < 1) {
        print('[MigrationService] Executing migration to version 1...');
        final success = await _migrateToVersion1();
        if (!success) {
          print('[MigrationService] Migration to version 1 failed');
          return false;
        }
      }

      // Save the new migration version
      await _saveMigrationVersion(_currentMigrationVersion);
      print('[MigrationService] All migrations completed successfully');
      return true;
    } catch (e, stackTrace) {
      print('[MigrationService] Migration execution failed: $e');
      print('[MigrationService] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Migration to version 1: Add spaceId to existing records and set up default space.
  Future<bool> _migrateToVersion1() async {
    try {
      // Step 1: Execute database migration (add spaceId to records)
      print('[MigrationService] Step 1: Migrating database records...');
      final spaceMigration = SpaceMigration(_db);
      final dbMigrationSuccess = await spaceMigration.migrate();
      
      if (!dbMigrationSuccess) {
        print('[MigrationService] Database migration failed');
        return false;
      }

      // Verify database migration
      final verificationSuccess = await spaceMigration.verify();
      if (!verificationSuccess) {
        print('[MigrationService] Database migration verification failed');
        return false;
      }

      // Step 2: Execute user data migration (set default space for existing users)
      print('[MigrationService] Step 2: Migrating user data...');
      final userMigrationSuccess = await _migrateUserData();
      
      if (!userMigrationSuccess) {
        print('[MigrationService] User data migration failed');
        return false;
      }

      print('[MigrationService] Version 1 migration completed successfully');
      return true;
    } catch (e, stackTrace) {
      print('[MigrationService] Version 1 migration failed: $e');
      print('[MigrationService] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Migrates user data: sets default space and marks onboarding complete for existing users.
  Future<bool> _migrateUserData() async {
    try {
      // Check if user has any records (indicates existing user)
      final totalRecords = await _db.records.count();
      
      if (totalRecords > 0) {
        print('[MigrationService] Existing user detected with $totalRecords records');
        
        // Set Health as the default active space
        final activeSpaces = await _spaceRepository.getActiveSpaceIds();
        if (activeSpaces.isEmpty) {
          print('[MigrationService] Setting Health as default active space');
          await _spaceRepository.setActiveSpaceIds(['health']);
        }
        
        // Set Health as current space
        final currentSpace = await _spaceRepository.getCurrentSpaceId();
        if (currentSpace.isEmpty || currentSpace == 'health') {
          print('[MigrationService] Setting Health as current space');
          await _spaceRepository.setCurrentSpaceId('health');
        }
        
        // Mark onboarding as complete for existing users
        final hasCompletedOnboarding = await _spaceRepository.hasCompletedOnboarding();
        if (!hasCompletedOnboarding) {
          print('[MigrationService] Marking onboarding as complete for existing user');
          await _spaceRepository.setOnboardingComplete();
        }
      } else {
        print('[MigrationService] New user detected, no user data migration needed');
      }
      
      return true;
    } catch (e, stackTrace) {
      print('[MigrationService] User data migration failed: $e');
      print('[MigrationService] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Saves the migration version to storage.
  /// Note: Currently a no-op since we use heuristics to determine version.
  /// In a real implementation with shared_preferences, this would persist the version.
  Future<void> _saveMigrationVersion(int version) async {
    // Placeholder: In a real implementation, this would save to SharedPreferences
    print('[MigrationService] Migration version set to $version');
  }
}
