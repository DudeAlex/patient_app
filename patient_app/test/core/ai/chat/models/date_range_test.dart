import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/models/date_range.dart';

void main() {
  group('DateRange.lastNDays()', () {
    test('lastNDays(7) creates 7-day range', () {
      final range = DateRange.lastNDays(7);
      final actualDays = range.end.difference(range.start).inDays;
      
      expect(actualDays, equals(7));
    });

    test('lastNDays(14) creates 14-day range', () {
      final range = DateRange.lastNDays(14);
      final actualDays = range.end.difference(range.start).inDays;
      
      expect(actualDays, equals(14));
    });

    test('lastNDays(30) creates 30-day range', () {
      final range = DateRange.lastNDays(30);
      final actualDays = range.end.difference(range.start).inDays;
      
      expect(actualDays, equals(30));
    });

    test('lastNDays(45) creates 45-day range (custom)', () {
      final range = DateRange.lastNDays(45);
      final actualDays = range.end.difference(range.start).inDays;
      
      expect(actualDays, equals(45));
    });

    test('lastNDays(1095) creates 1095-day range (boundary)', () {
      final range = DateRange.lastNDays(1095);
      final actualDays = range.end.difference(range.start).inDays;
      
      expect(actualDays, equals(1095));
    });

    test('lastNDays(1) creates 1-day range (boundary)', () {
      final range = DateRange.lastNDays(1);
      final actualDays = range.end.difference(range.start).inDays;
      
      expect(actualDays, equals(1));
    });

    test('end date is always "now"', () {
      final beforeCreation = DateTime.now();
      final range = DateRange.lastNDays(7);
      final afterCreation = DateTime.now();
      
      // The end date should be between beforeCreation and afterCreation
      expect(range.end.isAfter(beforeCreation) || range.end.isAtSameMomentAs(beforeCreation), isTrue);
      expect(range.end.isBefore(afterCreation) || range.end.isAtSameMomentAs(afterCreation), isTrue);
    });

    test('start date is exactly N days before end', () {
      final testCases = [1, 7, 14, 30, 45, 90, 365, 1095];
      
      for (final days in testCases) {
        final range = DateRange.lastNDays(days);
        final actualDays = range.end.difference(range.start).inDays;
        
        expect(
          actualDays,
          equals(days),
          reason: 'Expected $days days, but got $actualDays days',
        );
      }
    });

    test('lastNDays validates days parameter is >= 1', () {
      expect(
        () => DateRange.lastNDays(0),
        throwsA(isA<AssertionError>()),
      );
      
      expect(
        () => DateRange.lastNDays(-1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('lastNDays validates days parameter is <= 1095', () {
      expect(
        () => DateRange.lastNDays(1096),
        throwsA(isA<AssertionError>()),
      );
      
      expect(
        () => DateRange.lastNDays(2000),
        throwsA(isA<AssertionError>()),
      );
    });

    test('convenience factories delegate to lastNDays', () {
      final range7 = DateRange.last7Days();
      final range14 = DateRange.last14Days();
      final range30 = DateRange.last30Days();
      
      expect(range7.end.difference(range7.start).inDays, equals(7));
      expect(range14.end.difference(range14.start).inDays, equals(14));
      expect(range30.end.difference(range30.start).inDays, equals(30));
    });

    test('multiple calls create independent instances', () {
      final range1 = DateRange.lastNDays(7);
      final range2 = DateRange.lastNDays(7);
      
      // They should be different instances
      expect(identical(range1, range2), isFalse);
      
      // But have similar values (within a few milliseconds)
      final diff = range2.end.difference(range1.end).inMilliseconds.abs();
      expect(diff, lessThan(100)); // Should be created within 100ms
    });
  });
}
