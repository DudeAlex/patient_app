import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/models/date_range.dart';

/// **Feature: context-date-range-fix, Property 2: Date range calculation matches setting**
/// Validates: Requirements 5.5, 1.2
///
/// For any date range value between 1 and 1095, when creating a DateRange using
/// lastNDays(n), the difference between end and start should equal the input value.
void main() {
  test('Property: Date range calculation matches setting for random values', () {
    final random = Random(42);
    
    // Run 100 iterations to test various random values
    for (int iteration = 0; iteration < 100; iteration++) {
      // Generate random date range value between 1 and 1095 (inclusive)
      final randomDays = 1 + random.nextInt(1095); // 1 to 1095
      
      // Create DateRange using lastNDays
      final dateRange = DateRange.lastNDays(randomDays);
      
      // Calculate the actual difference in days
      final actualDays = dateRange.end.difference(dateRange.start).inDays;
      
      // Assert the difference matches the input
      expect(
        actualDays,
        equals(randomDays),
        reason: 'Date range calculation failed for value $randomDays on iteration $iteration. '
            'Expected: $randomDays days, Actual: $actualDays days. '
            'Start: ${dateRange.start}, End: ${dateRange.end}',
      );
    }
  });

  test('Property: Date range calculation matches setting for boundary values', () {
    // Test boundary values explicitly
    final boundaryValues = [1, 2, 1094, 1095];
    
    for (final days in boundaryValues) {
      // Create DateRange using lastNDays
      final dateRange = DateRange.lastNDays(days);
      
      // Calculate the actual difference in days
      final actualDays = dateRange.end.difference(dateRange.start).inDays;
      
      // Assert the difference matches the input
      expect(
        actualDays,
        equals(days),
        reason: 'Date range calculation failed for boundary value $days. '
            'Expected: $days days, Actual: $actualDays days. '
            'Start: ${dateRange.start}, End: ${dateRange.end}',
      );
    }
  });

  test('Property: Date range calculation matches setting for preset values', () {
    // Test preset values explicitly
    final presetValues = [7, 14, 30];
    
    for (final days in presetValues) {
      // Create DateRange using lastNDays
      final dateRange = DateRange.lastNDays(days);
      
      // Calculate the actual difference in days
      final actualDays = dateRange.end.difference(dateRange.start).inDays;
      
      // Assert the difference matches the input
      expect(
        actualDays,
        equals(days),
        reason: 'Date range calculation failed for preset value $days. '
            'Expected: $days days, Actual: $actualDays days. '
            'Start: ${dateRange.start}, End: ${dateRange.end}',
      );
    }
  });

  test('Property: Date range calculation matches setting for custom values', () {
    final random = Random(123);
    
    // Generate 50 random custom values (not 7, 14, or 30)
    final customValues = <int>[];
    while (customValues.length < 50) {
      final value = 1 + random.nextInt(1095);
      if (value != 7 && value != 14 && value != 30) {
        customValues.add(value);
      }
    }
    
    for (final days in customValues) {
      // Create DateRange using lastNDays
      final dateRange = DateRange.lastNDays(days);
      
      // Calculate the actual difference in days
      final actualDays = dateRange.end.difference(dateRange.start).inDays;
      
      // Assert the difference matches the input
      expect(
        actualDays,
        equals(days),
        reason: 'Date range calculation failed for custom value $days. '
            'Expected: $days days, Actual: $actualDays days. '
            'Start: ${dateRange.start}, End: ${dateRange.end}',
      );
    }
  });

  test('Property: Date range calculation is consistent across multiple calls', () {
    final random = Random(456);
    
    // Test that multiple calls with the same value produce consistent results
    for (int i = 0; i < 20; i++) {
      final randomDays = 1 + random.nextInt(1095);
      
      // Create multiple DateRange instances with the same value
      final dateRange1 = DateRange.lastNDays(randomDays);
      final dateRange2 = DateRange.lastNDays(randomDays);
      final dateRange3 = DateRange.lastNDays(randomDays);
      
      // Calculate differences
      final actualDays1 = dateRange1.end.difference(dateRange1.start).inDays;
      final actualDays2 = dateRange2.end.difference(dateRange2.start).inDays;
      final actualDays3 = dateRange3.end.difference(dateRange3.start).inDays;
      
      // All should match the input
      expect(actualDays1, equals(randomDays));
      expect(actualDays2, equals(randomDays));
      expect(actualDays3, equals(randomDays));
      
      // All should be consistent with each other
      expect(actualDays1, equals(actualDays2));
      expect(actualDays2, equals(actualDays3));
    }
  });

  test('Property: Date range calculation works for all valid values', () {
    // Test a comprehensive range of values
    final testValues = <int>[];
    
    // Add boundary values
    testValues.addAll([1, 2, 1094, 1095]);
    
    // Add preset values
    testValues.addAll([7, 14, 30]);
    
    // Add some common custom values
    testValues.addAll([15, 45, 60, 90, 180, 365, 730]);
    
    // Add random values throughout the range
    final random = Random(789);
    for (int i = 0; i < 50; i++) {
      testValues.add(1 + random.nextInt(1095));
    }
    
    for (final days in testValues) {
      // Create DateRange using lastNDays
      final dateRange = DateRange.lastNDays(days);
      
      // Calculate the actual difference in days
      final actualDays = dateRange.end.difference(dateRange.start).inDays;
      
      // Assert the difference matches the input
      expect(
        actualDays,
        equals(days),
        reason: 'Date range calculation failed for value $days. '
            'Expected: $days days, Actual: $actualDays days. '
            'Start: ${dateRange.start}, End: ${dateRange.end}',
      );
    }
  });

  test('Property: Date range end is always close to now', () {
    final random = Random(321);
    
    // Test that the end date is always close to DateTime.now()
    for (int i = 0; i < 20; i++) {
      final randomDays = 1 + random.nextInt(1095);
      
      // Capture time before and after creation
      final beforeCreation = DateTime.now();
      final dateRange = DateRange.lastNDays(randomDays);
      final afterCreation = DateTime.now();
      
      // The end date should be between beforeCreation and afterCreation
      expect(
        dateRange.end.isAfter(beforeCreation) || dateRange.end.isAtSameMomentAs(beforeCreation),
        isTrue,
        reason: 'End date ${dateRange.end} should be after or equal to $beforeCreation',
      );
      expect(
        dateRange.end.isBefore(afterCreation) || dateRange.end.isAtSameMomentAs(afterCreation),
        isTrue,
        reason: 'End date ${dateRange.end} should be before or equal to $afterCreation',
      );
      
      // And the calculation should still be correct
      final actualDays = dateRange.end.difference(dateRange.start).inDays;
      expect(actualDays, equals(randomDays));
    }
  });

  test('Property: Date range start is exactly N days before end', () {
    final random = Random(654);
    
    // Test that start is exactly N days before end
    for (int i = 0; i < 50; i++) {
      final randomDays = 1 + random.nextInt(1095);
      
      // Create DateRange
      final dateRange = DateRange.lastNDays(randomDays);
      
      // Calculate expected start date
      final expectedStart = dateRange.end.subtract(Duration(days: randomDays));
      
      // The actual start should be very close to expected start
      // (within a few milliseconds due to execution time)
      final startDifference = dateRange.start.difference(expectedStart).inMilliseconds.abs();
      
      expect(
        startDifference,
        lessThan(100),
        reason: 'Start date calculation is off by $startDifference ms for $randomDays days. '
            'Expected: $expectedStart, Actual: ${dateRange.start}',
      );
      
      // And the day difference should be exact
      final actualDays = dateRange.end.difference(dateRange.start).inDays;
      expect(actualDays, equals(randomDays));
    }
  });

  test('Property: Date range calculation handles edge cases around day boundaries', () {
    // Test values that might be sensitive to time-of-day issues
    final testValues = [1, 2, 3, 7, 14, 30, 365, 1095];
    
    for (final days in testValues) {
      // Create multiple instances at different times (simulated by loop)
      for (int attempt = 0; attempt < 5; attempt++) {
        final dateRange = DateRange.lastNDays(days);
        final actualDays = dateRange.end.difference(dateRange.start).inDays;
        
        expect(
          actualDays,
          equals(days),
          reason: 'Date range calculation failed for $days days on attempt $attempt. '
              'Expected: $days days, Actual: $actualDays days. '
              'Start: ${dateRange.start}, End: ${dateRange.end}',
        );
      }
    }
  });
}
