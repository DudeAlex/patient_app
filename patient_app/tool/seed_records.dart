import 'package:patient_app/features/records/data/records_service.dart';
import 'package:patient_app/features/records/model/record.dart';
import 'package:patient_app/features/records/model/record_types.dart';

Future<void> main() async {
  final service = await RecordsService.instance();
  final repo = service.records;

  final now = DateTime.now();

  final samples = <Record>[
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
      ..date = now.subtract(const Duration(days: 10))
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

  for (final record in samples) {
    await repo.add(record);
  }

  // ignore: avoid_print
  print('Seeded ${samples.length} records.');
}
