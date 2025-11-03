import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/capture_core/capture_core.dart' as capture_core;
import '../features/capture_core/ui/capture_launcher_screen.dart';
import '../features/capture_core/ui/capture_review_screen.dart';
import '../features/capture_modes/document_scan/document_scan_module.dart';
import '../features/capture_modes/photo/photo_capture_module.dart';
import '../features/capture_modes/voice/voice_capture_module.dart';
import '../features/records/data/debug_seed.dart';
import '../features/records/data/records_service.dart';
import '../features/records/ui/add_record_screen.dart';
import '../features/records/ui/records_home_placeholder.dart';
import '../features/records/ui/records_home_state.dart';
import 'settings/settings_screen.dart';

class PatientApp extends StatelessWidget {
  const PatientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patient App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const _RecordsLoader(),
    );
  }
}

class _RecordsLoader extends StatelessWidget {
  const _RecordsLoader();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RecordsService>(
      future: RecordsService.instance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
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
        return FutureBuilder<void>(
          future: seedDebugRecordsIfEmpty(service.records),
          builder: (context, seedSnapshot) {
            if (seedSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (seedSnapshot.hasError) {
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
            return _HomeScaffold(service: service);
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
    final captureController = capture_core.buildCaptureController([
      PhotoCaptureModule(),
      DocumentScanModule(),
      VoiceCaptureModule(),
    ]);
    return ChangeNotifierProvider(
      create: (_) => RecordsHomeState(
        service.records,
        service.dirtyTracker,
        service.syncState,
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
          body: const RecordsHomePlaceholder(),
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
                          builder: (_) => CaptureReviewScreen(
                            mode: mode,
                            result: result,
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
