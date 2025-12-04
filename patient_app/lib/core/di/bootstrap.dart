import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:patient_app/core/ai/ai_service.dart';
import 'package:patient_app/core/ai/configurable_ai_service.dart';
import 'package:patient_app/core/ai/fake_ai_service.dart';
import 'package:patient_app/core/ai/logging_ai_service.dart';
import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/configurable_ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/fake_ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/http_ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/logging_ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/repositories/chat_thread_repository.dart';
import 'package:patient_app/core/ai/chat/repositories/chat_thread_repository_impl.dart';
import 'package:patient_app/core/ai/chat/repositories/context_config_repository.dart';
import 'package:patient_app/core/ai/chat/repositories/context_config_repository_impl.dart';
import 'package:patient_app/core/ai/chat/services/error_classifier.dart';
import 'package:patient_app/core/ai/chat/services/fallback_service.dart';
import 'package:patient_app/core/ai/chat/services/message_attachment_handler.dart';
import 'package:patient_app/core/ai/chat/services/message_attachment_handler_impl.dart';
import 'package:patient_app/core/ai/chat/services/network_recovery_strategy.dart';
import 'package:patient_app/core/ai/chat/services/rate_limit_recovery_strategy.dart';
import 'package:patient_app/core/ai/chat/services/resilient_ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/services/server_error_recovery_strategy.dart';
import 'package:patient_app/core/ai/chat/services/timeout_recovery_strategy.dart';
import 'package:patient_app/core/ai/chat/telemetry/interfaces/alert_monitoring_service.dart';
import 'package:patient_app/core/ai/chat/telemetry/interfaces/metrics_aggregation_service.dart';
import 'package:patient_app/core/ai/chat/telemetry/interfaces/telemetry_collector.dart';
import 'package:patient_app/core/ai/chat/telemetry/services/alert_monitoring_service_impl.dart';
import 'package:patient_app/core/ai/chat/telemetry/services/metrics_aggregation_service_impl.dart';
import 'package:patient_app/core/ai/chat/telemetry/services/telemetry_collector_impl.dart';
import 'package:patient_app/core/ai/chat/telemetry/services/telemetry_ingest_service.dart';
import 'package:patient_app/core/ai/chat/telemetry/storage/metrics_store.dart';
import 'package:patient_app/core/ai/repositories/ai_call_log_repository.dart';
import 'package:patient_app/core/ai/repositories/ai_config_repository.dart';
import 'package:patient_app/core/ai/repositories/ai_config_repository_impl.dart';
import 'package:patient_app/core/ai/repositories/ai_consent_repository.dart';
import 'package:patient_app/core/ai/repositories/ai_consent_repository_impl.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';
import 'package:patient_app/core/di/app_container.dart';
import 'package:patient_app/core/infrastructure/storage/migration_service.dart';
import 'package:patient_app/core/infrastructure/storage/space_preferences.dart';
import 'package:patient_app/features/capture_core/capture_core.dart' as capture_core;
import 'package:patient_app/features/capture_modes/document_scan/document_scan_module.dart';
import 'package:patient_app/features/capture_modes/file/file_upload_module.dart';
import 'package:patient_app/features/capture_modes/photo/photo_capture_module.dart';
import 'package:patient_app/features/capture_modes/voice/voice_capture_module.dart';
import 'package:patient_app/features/records/data/records_service.dart';

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
    container.registerLazySingleton<ContextConfigRepository>(
      (c) => ContextConfigRepositoryImpl(c.resolve<SharedPreferences>()),
    );
    await AppLogger.info(
      'ContextConfigRepository registered in container',
      context: {
        'registrationType': 'lazySingleton',
        'stage': 'bootstrap',
      },
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

    // Telemetry wiring
    final telemetryCollector = TelemetryCollectorImpl();
    container.registerSingleton<TelemetryCollector>(telemetryCollector);
    container.registerSingleton<MetricsStore>(MetricsStore());
    container.registerLazySingleton<MetricsAggregationService>(
      (c) => MetricsAggregationServiceImpl(c.resolve<MetricsStore>()),
    );
    container.registerLazySingleton<AlertMonitoringService>(
      (c) => AlertMonitoringServiceImpl(c.resolve<MetricsAggregationService>()),
    );
    container.registerSingleton<TelemetryIngestService>(
      TelemetryIngestService(
        collector: telemetryCollector,
        store: container.resolve<MetricsStore>(),
      ),
    );

    // Register chat dependencies
    container.registerLazySingleton<ChatThreadRepository>(
      (_) => ChatThreadRepositoryImpl(recordsService.db),
    );
    container.registerLazySingleton<MessageAttachmentHandler>(
      (_) => MessageAttachmentHandlerImpl(),
    );
    
    // Register error recovery components
    container.registerLazySingleton<ErrorClassifier>(
      (_) => ErrorClassifier(),
    );
    container.registerLazySingleton<FallbackService>(
      (_) => FallbackService(),
    );
    container.registerLazySingleton<RateLimitRecoveryStrategy>(
      (_) => RateLimitRecoveryStrategy(),
    );
    container.registerLazySingleton<NetworkRecoveryStrategy>(
      (_) => NetworkRecoveryStrategy(),
    );
    container.registerLazySingleton<ServerErrorRecoveryStrategy>(
      (_) => ServerErrorRecoveryStrategy(),
    );
    container.registerLazySingleton<TimeoutRecoveryStrategy>(
      (_) => TimeoutRecoveryStrategy(),
    );
    
    // Register resilient AI chat service with all dependencies
    container.registerLazySingleton<AiChatService>(
      (c) => ResilientAiChatService(
        primaryService: LoggingAiChatService(
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
        errorClassifier: c.resolve<ErrorClassifier>(),
        fallbackService: c.resolve<FallbackService>(),
        recoveryStrategies: [
          c.resolve<RateLimitRecoveryStrategy>(),
          c.resolve<NetworkRecoveryStrategy>(),
          c.resolve<ServerErrorRecoveryStrategy>(),
          c.resolve<TimeoutRecoveryStrategy>(),
        ],
        telemetryCollector: c.resolve<TelemetryCollector>(),
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
