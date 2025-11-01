import 'package:flutter/material.dart';

import '../features/records/data/records_service.dart';
import '../features/records/repo/records_repo.dart';
import '../features/records/ui/records_home_placeholder.dart';
import '../features/records/data/debug_seed.dart';
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
        seedDebugRecordsIfEmpty(service.records);
        return _HomeScaffold(repository: service.records);
      },
    );
  }
}

class _HomeScaffold extends StatelessWidget {
  const _HomeScaffold({required this.repository});

  final RecordsRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: RecordsHomePlaceholder(repository: repository),
    );
  }
}

// End
