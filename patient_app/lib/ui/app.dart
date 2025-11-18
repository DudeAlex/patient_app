import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/application/services/space_manager.dart';
import '../core/di/app_container.dart';
import '../core/diagnostics/app_logger.dart';
import '../core/diagnostics/diagnostic_system.dart';
import '../core/infrastructure/storage/space_preferences.dart';
import '../features/capture_core/capture_core.dart' as capture_core;
import '../features/capture_core/ui/capture_launcher_screen.dart';
import '../features/capture_core/ui/capture_review_screen.dart';
import '../features/records/adapters/repositories/isar_records_repository.dart';
import '../features/records/data/debug_seed.dart';
import '../features/records/data/records_service.dart';
import '../features/records/ui/add_record_screen.dart';
import '../features/records/ui/records_home_modern.dart';
import '../features/records/ui/records_home_state.dart';
import '../features/spaces/domain/space_registry.dart';
import '../features/spaces/providers/space_provider.dart';
import '../features/spaces/ui/onboarding_screen.dart';
import 'settings/settings_screen.dart';
import 'theme/app_theme.dart';

/// App lifecycle observer for logging state changes and handling shutdown
class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppLogger.logAppLifecycle(state.name);
    
    // Handle app termination
    if (state == AppLifecycleState.detached) {
      // App is being terminated - mark graceful shutdown
      DiagnosticSystem.shutdown();
    }
  }
}

class PatientApp extends StatefulWidget {
  const PatientApp({super.key});

  @override
  State<PatientApp> createState() => _PatientAppState();
}

class _PatientAppState extends State<PatientApp> {
  final _lifecycleObserver = _AppLifecycleObserver();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    AppLogger.info('PatientApp widget initialized');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patient App',
      theme: AppTheme.lightTheme,
      home: const _RecordsLoader(),
    );
  }
}

class _RecordsLoader extends StatefulWidget {
  const _RecordsLoader();

  @override
  State<_RecordsLoader> createState() => _RecordsLoaderState();
}

class _RecordsLoaderState extends State<_RecordsLoader> {
  // Track onboarding completion state to trigger rebuilds
  bool _onboardingCompleted = false;
  
  // Cache the space provider initialization to avoid recreating on every build
  Future<SpaceProvider>? _spaceProviderFuture;

  /// Initialize space system components (cached)
  Future<SpaceProvider> _initializeSpaceProvider() {
    // Return cached future if already initialized
    _spaceProviderFuture ??= _createSpaceProvider();
    return _spaceProviderFuture!;
  }
  
  /// Create space provider (called only once)
  Future<SpaceProvider> _createSpaceProvider() async {
    final spacePreferences = SpacePreferences();
    final spaceRegistry = SpaceRegistry();
    final spaceManager = SpaceManager(spacePreferences, spaceRegistry);
    final spaceProvider = SpaceProvider(spaceManager);
    await spaceProvider.initialize();
    return spaceProvider;
  }

  /// Handle onboarding completion
  void _handleOnboardingComplete() {
    setState(() {
      _onboardingCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RecordsService>(
      future: AppContainer.instance.resolve<Future<RecordsService>>(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          AppLogger.error(
            'Failed to initialize records service',
            error: snapshot.error,
            stackTrace: snapshot.stackTrace,
          );
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to initialise records service.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        final service = snapshot.data!;
        AppLogger.info('RecordsService initialized successfully');
        
        // Initialize space provider
        return FutureBuilder<SpaceProvider>(
          future: _initializeSpaceProvider(),
          builder: (context, spaceSnapshot) {
            if (spaceSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (spaceSnapshot.hasError) {
              AppLogger.error(
                'Failed to initialize space system',
                error: spaceSnapshot.error,
                stackTrace: spaceSnapshot.stackTrace,
              );
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Failed to initialise space system.\n${spaceSnapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }
            final spaceProvider = spaceSnapshot.data!;
            AppLogger.info('SpaceProvider initialized successfully');
            
            // Access onboarding status synchronously from cached value
            // (Requirements: 1.1, 1.3, 3.2, 3.3)
            final hasCompletedOnboarding = spaceProvider.onboardingComplete ?? false;
            
            // Show onboarding if first time and not yet completed in this session
            // Requirements: 10.8
            if (!hasCompletedOnboarding && !_onboardingCompleted) {
              AppLogger.logScreenLoad('OnboardingScreen');
              // Don't wrap in Provider - OnboardingScreen doesn't need to listen to changes
              return OnboardingScreen(
                spaceProvider: spaceProvider,
                onComplete: _handleOnboardingComplete,
              );
            }
            
            AppLogger.info('Onboarding completed, loading main app');
            
            // Load spaces if onboarding complete
            return FutureBuilder<void>(
              future: seedDebugRecordsIfEmpty(service.records),
              builder: (context, seedSnapshot) {
                if (seedSnapshot.connectionState != ConnectionState.done) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                if (seedSnapshot.hasError) {
                  AppLogger.error(
                    'Failed to seed debug records',
                    error: seedSnapshot.error,
                    stackTrace: seedSnapshot.stackTrace,
                  );
                  return Scaffold(
                    body: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Failed to seed debug records.\n${seedSnapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }
                AppLogger.logScreenLoad('RecordsHome');
                return ChangeNotifierProvider.value(
                  value: spaceProvider,
                  child: _HomeScaffold(service: service),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _HomeScaffold extends StatelessWidget {
  const _HomeScaffold({required this.service});

  final RecordsService service;

  @override
  Widget build(BuildContext context) {
    final captureController =
        AppContainer.instance.resolve<capture_core.CaptureController>();
    final spaceProvider = context.read<SpaceProvider>();
    
    return ChangeNotifierProvider(
      create: (_) => RecordsHomeState(
        service.fetchRecordsPage,
        service.saveRecord,
        service.deleteRecord,
        service.getRecordById,
        service.dirtyTracker,
        service.records as IsarRecordsRepository,
        spaceProvider,
      )..load(),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Patient'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          body: const RecordsHomeModern(), // Switch to RecordsHomePlaceholder() to see old design
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final state = context.read<RecordsHomeState>();
              final locale = Localizations.localeOf(context);
              final mediaQuery = MediaQuery.maybeOf(context);
              final accessibilityEnabled =
                  mediaQuery?.accessibleNavigation ?? false;
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (launcherContext) => CaptureLauncherScreen(
                    controller: captureController,
                    locale: locale,
                    isAccessibilityEnabled: accessibilityEnabled,
                    onResult: (BuildContext ctx, mode, result) async {
                      if (!result.completed) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${mode.displayName} capture cancelled.',
                            ),
                          ),
                        );
                        return;
                      }
                      await Navigator.of(ctx).push(
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: state,
                            child: CaptureReviewScreen(
                              mode: mode,
                              result: result,
                            ),
                          ),
                        ),
                      );
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                      }
                    },
                    onKeyboardEntry: (ctx) async {
                      await Navigator.of(ctx).push(
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: state,
                            child: const AddRecordScreen(),
                          ),
                        ),
                      );
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                      }
                    },
                    emptyStateBuilder: (_) => const _LauncherEmptyState(),
                  ),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

// End

class _LauncherEmptyState extends StatelessWidget {
  const _LauncherEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.grid_view, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Capture options are coming soon. You can still use the keyboard form.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
