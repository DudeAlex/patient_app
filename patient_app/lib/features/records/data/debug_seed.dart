import 'package:flutter/foundation.dart';

import '../model/record.dart';
import '../model/record_types.dart';
import '../repo/records_repo.dart';

/// Inserts a few sample records when running in debug builds so the emulator
/// has data for manual testing. No-op in release/profile modes.
Future<void> seedDebugRecordsIfEmpty(RecordsRepository repository) async {
  if (!kDebugMode) return;

  final existing = await repository.recent(limit: 1);
  if (existing.isNotEmpty) return;

  final now = DateTime.now();
  final records = <Record>[
    Record()
      ..type = RecordTypes.visit
      ..date = now.subtract(const Duration(days: 2))
      ..title = 'Primary care follow-up'
      ..text = 'Discussed medication adjustments and ordered labs.'
      ..tags = ['visit', 'follow-up']
      ..createdAt = now
      ..updatedAt = now,
    Record()
      ..type = RecordTypes.lab
      ..date = now.subtract(const Duration(days: 7))
      ..title = 'Blood panel results'
      ..text = 'Cholesterol slightly elevated; schedule recheck.'
      ..tags = ['lab']
      ..createdAt = now
      ..updatedAt = now,
    Record()
      ..type = RecordTypes.note
      ..date = now
      ..title = 'Daily symptoms log'
      ..text = 'Energy better today; mild headache in the evening.'
      ..tags = ['note', 'symptoms']
      ..createdAt = now
      ..updatedAt = now,
  ];

  for (final record in records) {
    await repository.add(record);
  }
}
