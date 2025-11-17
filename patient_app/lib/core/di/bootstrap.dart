import '../../features/capture_core/capture_core.dart' as capture_core;
import '../../features/capture_modes/document_scan/document_scan_module.dart';
import '../../features/capture_modes/file/file_upload_module.dart';
import '../../features/capture_modes/photo/photo_capture_module.dart';
import '../../features/capture_modes/voice/voice_capture_module.dart';
import '../../features/records/data/records_service.dart';
import '../diagnostics/app_logger.dart';
import '../infrastructure/storage/migration_service.dart';
import '../infrastructure/storage/space_preferences.dart';
import 'app_container.dart';

/// Registers core dependencies so presentation layers can resolve them via the
/// [AppContainer] without reinitialising state.
Future<void> bootstrapAppContainer() async {
  final bootstrapOp = AppLogger.startOperation('bootstrap_app_container');
  
  try {
    final container = AppContainer.instance;
    container.reset();

    // Initialize RecordsService (which opens the database)
    final dbInitOp = AppLogger.startOperation('initialize_database', parentId: bootstrapOp);
    final recordsServiceFuture = RecordsService.instance();
    container.registerLazySingleton<Future<RecordsService>>(
      (_) => recordsServiceFuture,
    );
    final recordsService = await recordsServiceFuture;
    await AppLogger.endOperation(dbInitOp);

    // Run migrations after database is initialized
    final migrationOp = AppLogger.startOperation('run_migrations', parentId: bootstrapOp);
    final spaceRepository = SpacePreferences();
    final migrationService = MigrationService(
      db: recordsService.db,
      spaceRepository: spaceRepository,
    );

    await AppLogger.info('Running database migrations');
    final migrationSuccess = await migrationService.checkAndMigrate();
    
    if (!migrationSuccess) {
      await AppLogger.warning('Migration failed, app may not function correctly');
    } else {
      await AppLogger.info('Migrations completed successfully');
    }
    await AppLogger.endOperation(migrationOp);

    // Register capture controller
    final captureOp = AppLogger.startOperation('register_capture_controller', parentId: bootstrapOp);
    container.registerLazySingleton<capture_core.CaptureController>(
      (_) => capture_core.buildCaptureController(
        [
          PhotoCaptureModule(),
          DocumentScanModule(),
          VoiceCaptureModule(),
          FileUploadModule(),
        ],
      ),
    );
    await AppLogger.endOperation(captureOp);
    
    await AppLogger.endOperation(bootstrapOp);
  } catch (e, stackTrace) {
    await AppLogger.error(
      'Bootstrap failed',
      error: e,
      stackTrace: stackTrace,
    );
    await AppLogger.endOperation(bootstrapOp);
    rethrow;
  }
}
