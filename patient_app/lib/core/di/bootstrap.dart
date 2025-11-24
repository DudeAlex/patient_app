import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/capture_core/capture_core.dart' as capture_core;
import '../../features/capture_modes/document_scan/document_scan_module.dart';
import '../../features/capture_modes/file/file_upload_module.dart';
import '../../features/capture_modes/photo/photo_capture_module.dart';
import '../../features/capture_modes/voice/voice_capture_module.dart';
import '../../features/records/data/records_service.dart';
import '../ai/configurable_ai_service.dart';
import '../ai/ai_service.dart';
import '../ai/fake_ai_service.dart';
import '../ai/logging_ai_service.dart';
import '../ai/repositories/ai_call_log_repository.dart';
import '../ai/repositories/ai_config_repository.dart';
import '../ai/repositories/ai_config_repository_impl.dart';
import '../ai/repositories/ai_consent_repository.dart';
import '../ai/repositories/ai_consent_repository_impl.dart';
import '../ai/chat/ai_chat_service.dart';
import '../ai/chat/configurable_ai_chat_service.dart';
import '../ai/chat/fake_ai_chat_service.dart';
import '../ai/chat/http_ai_chat_service.dart';
import '../ai/chat/logging_ai_chat_service.dart';
import '../ai/chat/repositories/chat_thread_repository.dart';
import '../ai/chat/repositories/chat_thread_repository_impl.dart';
import '../ai/chat/services/message_attachment_handler.dart';
import '../ai/chat/services/message_attachment_handler_impl.dart';
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

    // SharedPreferences / lightweight storage
    final prefsOp = AppLogger.startOperation('load_shared_preferences', parentId: bootstrapOp);
    final sharedPreferences = await SharedPreferences.getInstance();
    container.registerSingleton<SharedPreferences>(sharedPreferences);
    await AppLogger.endOperation(prefsOp);

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

    // Shared HTTP client
    final httpClient = http.Client();
    container.registerSingleton<http.Client>(httpClient);

    // Register AI dependencies
    final aiConfigRepository = AiConfigRepositoryImpl(sharedPreferences);
    await aiConfigRepository.loadConfig();
    container.registerSingleton<AiConfigRepository>(aiConfigRepository);
    final aiCallLogRepository = AiCallLogRepository();
    container.registerSingleton<AiCallLogRepository>(aiCallLogRepository);
    container.registerLazySingleton<AiConsentRepository>(
      (c) => AiConsentRepositoryImpl(c.resolve<SharedPreferences>()),
    );
    container.registerLazySingleton<AiService>(
      (_) => LoggingAiService(
        ConfigurableAiService(
          configRepository: aiConfigRepository,
          fakeService: FakeAiService(),
          client: httpClient,
        ),
        callLogRepository: aiCallLogRepository,
      ),
    );

    // Register chat dependencies
    container.registerLazySingleton<ChatThreadRepository>(
      (_) => ChatThreadRepositoryImpl(recordsService.db),
    );
    container.registerLazySingleton<MessageAttachmentHandler>(
      (_) => MessageAttachmentHandlerImpl(),
    );
    container.registerLazySingleton<AiChatService>(
      (c) => LoggingAiChatService(
        ConfigurableAiChatService(
          configRepository: aiConfigRepository,
          fakeService: FakeAiChatService(),
          httpService: HttpAiChatService(
            client: httpClient,
            baseUrl: aiConfigRepository.current.remoteUrl,
          ),
        ),
        callLogRepository: aiCallLogRepository,
      ),
    );

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
