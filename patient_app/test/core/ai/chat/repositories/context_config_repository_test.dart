import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:patient_app/core/ai/chat/repositories/context_config_repository_impl.dart';

void main() {
  late ContextConfigRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repository = ContextConfigRepositoryImpl(prefs);
  });

  group('ContextConfigRepository validation tests', () {
    group('setDateRangeDays - valid values', () {
      test('accepts value 1 (minimum boundary)', () async {
        await repository.setDateRangeDays(1);
        final result = await repository.getDateRangeDays();
        expect(result, 1);
      });

      test('accepts value 7 (preset)', () async {
        await repository.setDateRangeDays(7);
        final result = await repository.getDateRangeDays();
        expect(result, 7);
      });

      test('accepts value 14 (preset)', () async {
        await repository.setDateRangeDays(14);
        final result = await repository.getDateRangeDays();
        expect(result, 14);
      });

      test('accepts value 30 (preset)', () async {
        await repository.setDateRangeDays(30);
        final result = await repository.getDateRangeDays();
        expect(result, 30);
      });

      test('accepts value 45 (custom)', () async {
        await repository.setDateRangeDays(45);
        final result = await repository.getDateRangeDays();
        expect(result, 45);
      });

      test('accepts value 365 (custom)', () async {
        await repository.setDateRangeDays(365);
        final result = await repository.getDateRangeDays();
        expect(result, 365);
      });

      test('accepts value 1095 (maximum boundary)', () async {
        await repository.setDateRangeDays(1095);
        final result = await repository.getDateRangeDays();
        expect(result, 1095);
      });
    });

    group('setDateRangeDays - invalid values', () {
      test('rejects value 0', () async {
        expect(
          () => repository.setDateRangeDays(0),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Date range must be between 1 and 1095'),
          )),
        );
      });

      test('rejects negative value -1', () async {
        expect(
          () => repository.setDateRangeDays(-1),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Date range must be between 1 and 1095'),
          )),
        );
      });

      test('rejects negative value -100', () async {
        expect(
          () => repository.setDateRangeDays(-100),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Date range must be between 1 and 1095'),
          )),
        );
      });

      test('rejects value 1096 (just above maximum)', () async {
        expect(
          () => repository.setDateRangeDays(1096),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Date range must be between 1 and 1095'),
          )),
        );
      });

      test('rejects value 2000 (far above maximum)', () async {
        expect(
          () => repository.setDateRangeDays(2000),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Date range must be between 1 and 1095'),
          )),
        );
      });
    });

    group('getDateRangeDays - default fallback', () {
      test('returns default (14) when setting is missing', () async {
        final result = await repository.getDateRangeDays();
        expect(result, 14);
      });

      test('returns default (14) when stored value is 0', () async {
        // Directly set invalid value in SharedPreferences
        SharedPreferences.setMockInitialValues({'context_date_range_days': 0});
        final prefs = await SharedPreferences.getInstance();
        final repo = ContextConfigRepositoryImpl(prefs);

        final result = await repo.getDateRangeDays();
        expect(result, 14);
      });

      test('returns default (14) when stored value is negative', () async {
        // Directly set invalid value in SharedPreferences
        SharedPreferences.setMockInitialValues({'context_date_range_days': -5});
        final prefs = await SharedPreferences.getInstance();
        final repo = ContextConfigRepositoryImpl(prefs);

        final result = await repo.getDateRangeDays();
        expect(result, 14);
      });

      test('returns default (14) when stored value is above maximum', () async {
        // Directly set invalid value in SharedPreferences
        SharedPreferences.setMockInitialValues({'context_date_range_days': 2000});
        final prefs = await SharedPreferences.getInstance();
        final repo = ContextConfigRepositoryImpl(prefs);

        final result = await repo.getDateRangeDays();
        expect(result, 14);
      });

      test('returns default (14) when stored value is 1096', () async {
        // Directly set invalid value in SharedPreferences
        SharedPreferences.setMockInitialValues({'context_date_range_days': 1096});
        final prefs = await SharedPreferences.getInstance();
        final repo = ContextConfigRepositoryImpl(prefs);

        final result = await repo.getDateRangeDays();
        expect(result, 14);
      });
    });

    group('round-trip persistence', () {
      test('persists and retrieves preset value 7', () async {
        await repository.setDateRangeDays(7);
        final result = await repository.getDateRangeDays();
        expect(result, 7);
      });

      test('persists and retrieves preset value 14', () async {
        await repository.setDateRangeDays(14);
        final result = await repository.getDateRangeDays();
        expect(result, 14);
      });

      test('persists and retrieves preset value 30', () async {
        await repository.setDateRangeDays(30);
        final result = await repository.getDateRangeDays();
        expect(result, 30);
      });

      test('persists and retrieves custom value 90', () async {
        await repository.setDateRangeDays(90);
        final result = await repository.getDateRangeDays();
        expect(result, 90);
      });

      test('persists and retrieves custom value 365', () async {
        await repository.setDateRangeDays(365);
        final result = await repository.getDateRangeDays();
        expect(result, 365);
      });

      test('persists and retrieves boundary value 1', () async {
        await repository.setDateRangeDays(1);
        final result = await repository.getDateRangeDays();
        expect(result, 1);
      });

      test('persists and retrieves boundary value 1095', () async {
        await repository.setDateRangeDays(1095);
        final result = await repository.getDateRangeDays();
        expect(result, 1095);
      });
    });
  });
}
