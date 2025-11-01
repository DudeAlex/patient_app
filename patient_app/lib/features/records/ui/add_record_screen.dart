import 'package:flutter/material.dart';

import '../repo/records_repo.dart';

/// Stub screen for the upcoming Add Record flow. For now it allows returning
/// immediately so navigation wiring can be tested end-to-end.
class AddRecordScreen extends StatelessWidget {
  const AddRecordScreen({super.key, required this.repository});

  final RecordsRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Record')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Record creation flow coming soon. For now, use the buttons '
              'below to complete or cancel.',
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Simulate Save'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
