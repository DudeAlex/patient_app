import 'test_record.dart';

class TestDataImport {
  final List<TestRecord> records;

  TestDataImport({required this.records});

  int get totalRecords => records.length;

  List<TestRecord> get healthRecords =>
      records.where((r) => r.spaceId == 'health').toList();

  List<TestRecord> get businessRecords =>
      records.where((r) => r.spaceId == 'business').toList();

  List<TestRecord> get educationRecords =>
      records.where((r) => r.spaceId == 'education').toList();

  Map<String, int> get recordsBySpace {
    final Map<String, int> breakdown = {};
    for (final record in records) {
      breakdown[record.spaceId] = (breakdown[record.spaceId] ?? 0) + 1;
    }
    return breakdown;
  }
}
