import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:patient_app/core/ai/chat/repositories/context_config_repository_impl.dart';

/// **Feature: context-date-range-fix, Property 4: Default fallback is consistent**
/// Validates: Requirements 5.5, 3.1, 3.2, 3.3
///
/// For any invalid date range value (< 1 or > 1095), when attempting to set via
/// setDateRangeDays() it should throw, OR when stored directly in SharedPreferences
/// and read via getDateRangeDays(), the returned value should be 14 (default).
void main() {
  test('Property: Invalid values via setDateRangeDays throw ArgumentError', () async {
    final random = Random(42);
    
    // Run 100 iterations to test various invalid values
    for (int iteration = 0; iteration < 100; iteration++) {
      // Generate random invalid values
      // 50% chance of being too low (< 1), 50% chance of being too high (> 1095)
      final invalidDays = random.nextBool()
          ? random.nextInt(100) - 100 // Negative or zero: -100 to 0
          : 1096 + random.nextInt(1000); // Too high: 1096 to 2095
      
      // Create fresh repository for each iteration
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = ContextConfigRepositoryImpl(prefs);
      
      // Attempt to set the invalid date range - should throw
      expect(
        () async => await repository.setDateRangeDays(invalidDays),
        throwsA(isA<ArgumentError>()),
        reason: 'setDateRangeDays($invalidDays) should throw ArgumentError on iteration $iteration',
      );
    }
  });

  test('Property: Invalid values below 1 throw ArgumentError', () async {
    final random = Random(123);
    
    // Test specifically values below 1
    for (int i = 0; i < 50; i++) {
      final invalidDays = random.nextInt(100) - 100; // -100 to 0
      
      // Create fresh repository
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = ContextConfigRepositoryImpl(prefs);
      
      // Should throw
      expect(
        () async => await repository.setDateRangeDays(invalidDays),
        throwsA(isA<ArgumentError>()),
        reason: 'setDateRangeDays($invalidDays) should throw ArgumentError (value < 1)',
      );
    }
  });

  test('Property: Invalid values above 1095 throw ArgumentError', () async {
    final random = Random(456);
    
    // Test specifically values above 1095
    for (int i = 0; i < 50; i++) {
      final invalidDays = 1096 + random.nextInt(1000); // 1096 to 2095
      
      // Create fresh repository
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = ContextConfigRepositoryImpl(prefs);
      
      // Should throw
      expect(
        () async => await repository.setDateRangeDays(invalidDays),
        throwsA(isA<ArgumentError>()),
        reason: 'setDateRangeDays($invalidDays) should throw ArgumentError (value > 1095)',
      );
    }
  });

  test('Property: Invalid values stored directly return default (14)', () async {
    final random = Random(789);
    
    // Run 100 iterations to test various invalid values
    for (int iteration = 0; iteration < 100; iteration++) {
      // Generate random invalid values
      final invalidDays = random.nextBool()
          ? random.nextInt(100) - 100 // Negative or zero: -100 to 0
          : 1096 + random.nextInt(1000); // Too high: 1096 to 2095
      
      // Create fresh repository and store invalid value directly in SharedPreferences
      SharedPreferences.setMockInitialValues({
        'context_date_range_days': invalidDays,
      });
      final prefs = await SharedPreferences.getInstance();
      final repository = ContextConfigRepositoryImpl(prefs);
      
      // Read the value - should return default (14)
      final retrievedDays = await repository.getDateRangeDays();
      
      // Assert default is returned
      expect(
        retrievedDays,
        equals(14),
        reason: 'getDateRangeDays() should return default (14) for invalid stored value $invalidDays on iteration $iteration. '
            'Stored: $invalidDays, Retrieved: $retrievedDays',
      );
    }
  });

  test('Property: Invalid values below 1 stored directly return default', () async {
    final random = Random(321);
    
    // Test specifically values below 1
    for (int i = 0; i < 50; i++) {
      final invalidDays = random.nextInt(100) - 100; // -100 to 0
      
      // Store invalid value directly
      SharedPreferences.setMockInitialValues({
        'context_date_range_days': invalidDays,
      });
      final prefs = await SharedPreferences.getInstance();
      final repository = ContextConfigRepositoryImpl(prefs);
      
      // Read should return default
      final retrievedDays = await repository.getDateRangeDays();
      
      expect(
        retrievedDays,
        equals(14),
        reason: 'getDateRangeDays() should return default (14) for invalid value $invalidDays (< 1). '
            'Stored: $invalidDays, Retrieved: $retrievedDays',
      );
    }
  });

  test('Property: Invalid values above 1095 stored directly return default', () async {
    final random = Random(654);
    
    // Test specifically values above 1095
    for (int i = 0; i < 50; i++) {
      final invalidDays = 1096 + random.nextInt(1000); // 1096 to 2095
      
      // Store invalid value directly
      SharedPreferences.setMockInitialValues({
        'context_date_range_days': invalidDays,
      });
      final prefs = await SharedPreferences.getInstance();
      final repository = ContextConfigRepositoryImpl(prefs);
      
      // Read should return default
      final retrievedDays = await repository.getDateRangeDays();
      
      expect(
        retrievedDays,
        equals(14),
        reason: 'getDateRangeDays() should return default (14) for invalid value $invalidDays (> 1095). '
            'Stored: $invalidDays, Retrieved: $retrievedDays',
      );
    }
  });

  test('Property: Boundary invalid values (0 and 1096) behave correctly', () async {
    // Test exact boundary values
    final boundaryInvalidValues = [0, -1, 1096, 1097];
    
    for (final invalidDays in boundaryInvalidValues) {
      // Test that setDateRangeDays throws
      SharedPreferences.setMockInitialValues({});
      final prefs1 = await SharedPreferences.getInstance();
      final repository1 = ContextConfigRepositoryImpl(prefs1);
      
      expect(
        () async => await repository1.setDateRangeDays(invalidDays),
        throwsA(isA<ArgumentError>()),
        reason: 'setDateRangeDays($invalidDays) should throw ArgumentError',
      );
      
      // Test that getDateRangeDays returns default when value is stored directly
      SharedPreferences.setMockInitialValues({
        'context_date_range_days': invalidDays,
      });
      final prefs2 = await SharedPreferences.getInstance();
      final repository2 = ContextConfigRepositoryImpl(prefs2);
      
      final retrievedDays = await repository2.getDateRangeDays();
      
      expect(
        retrievedDays,
        equals(14),
        reason: 'getDateRangeDays() should return default (14) for boundary invalid value $invalidDays. '
            'Stored: $invalidDays, Retrieved: $retrievedDays',
      );
    }
  });

  test('Property: Missing value returns default (14)', () async {
    // Test that missing setting returns default
    for (int i = 0; i < 10; i++) {
      // Create repository with no stored value
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = ContextConfigRepositoryImpl(prefs);
      
      // Read should return default
      final retrievedDays = await repository.getDateRangeDays();
      
      expect(
        retrievedDays,
        equals(14),
        reason: 'getDateRangeDays() should return default (14) when no value is stored. '
            'Retrieved: $retrievedDays',
      );
    }
  });

  test('Property: Default is consistent across multiple reads', () async {
    final random = Random(987);
    
    // Test that default is consistently returned for various invalid values
    for (int i = 0; i < 20; i++) {
      final invalidDays = random.nextBool()
          ? random.nextInt(100) - 100
          : 1096 + random.nextInt(1000);
      
      // Store invalid value
      SharedPreferences.setMockInitialValues({
        'context_date_range_days': invalidDays,
      });
      final prefs = await SharedPreferences.getInstance();
      final repository = ContextConfigRepositoryImpl(prefs);
      
      // Read multiple times
      final read1 = await repository.getDateRangeDays();
      final read2 = await repository.getDateRangeDays();
      final read3 = await repository.getDateRangeDays();
      
      // All reads should return the same default
      expect(read1, equals(14));
      expect(read2, equals(14));
      expect(read3, equals(14));
      expect(read1, equals(read2));
      expect(read2, equals(read3));
    }
  });

  test('Property: Valid value can be set after invalid attempt', () async {
    final random = Random(111);
    
    // Test that after an invalid attempt, a valid value can still be set
    for (int i = 0; i < 20; i++) {
      // Create repository
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = ContextConfigRepositoryImpl(prefs);
      
      // Try to set invalid value
      final invalidDays = random.nextBool()
          ? random.nextInt(100) - 100
          : 1096 + random.nextInt(1000);
      
      expect(
        () async => await repository.setDateRangeDays(invalidDays),
        throwsA(isA<ArgumentError>()),
      );
      
      // Now set a valid value
      final validDays = 1 + random.nextInt(1095);
      await repository.setDateRangeDays(validDays);
      
      // Read should return the valid value
      final retrievedDays = await repository.getDateRangeDays();
      
      expect(
        retrievedDays,
        equals(validDays),
        reason: 'After invalid attempt, valid value should be settable. '
            'Set: $validDays, Retrieved: $retrievedDays',
      );
    }
  });

  test('Property: Invalid value does not corrupt valid stored value', () async {
    final random = Random(222);
    
    // Test that attempting to set an invalid value doesn't corrupt existing valid value
    for (int i = 0; i < 20; i++) {
      // Create repository and set valid value
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = ContextConfigRepositoryImpl(prefs);
      
      final validDays = 1 + random.nextInt(1095);
      await repository.setDateRangeDays(validDays);
      
      // Try to set invalid value (should throw)
      final invalidDays = random.nextBool()
          ? random.nextInt(100) - 100
          : 1096 + random.nextInt(1000);
      
      expect(
        () async => await repository.setDateRangeDays(invalidDays),
        throwsA(isA<ArgumentError>()),
      );
      
      // Read should still return the original valid value
      final retrievedDays = await repository.getDateRangeDays();
      
      expect(
        retrievedDays,
        equals(validDays),
        reason: 'Invalid attempt should not corrupt existing valid value. '
            'Original: $validDays, Retrieved after invalid attempt: $retrievedDays',
      );
    }
  });

  test('Property: Extremely large invalid values return default', () async {
    // Test with very large numbers
    final extremeValues = [
      10000,
      100000,
      1000000,
      2147483647, // Max int32
    ];
    
    for (final invalidDays in extremeValues) {
      // Store invalid value directly
      SharedPreferences.setMockInitialValues({
        'context_date_range_days': invalidDays,
      });
      final prefs = await SharedPreferences.getInstance();
      final repository = ContextConfigRepositoryImpl(prefs);
      
      // Read should return default
      final retrievedDays = await repository.getDateRangeDays();
      
      expect(
        retrievedDays,
        equals(14),
        reason: 'getDateRangeDays() should return default (14) for extreme value $invalidDays. '
            'Stored: $invalidDays, Retrieved: $retrievedDays',
      );
    }
  });

  test('Property: Extremely negative invalid values return default', () async {
    // Test with very negative numbers
    final extremeValues = [
      -10000,
      -100000,
      -1000000,
      -2147483648, // Min int32
    ];
    
    for (final invalidDays in extremeValues) {
      // Store invalid value directly
      SharedPreferences.setMockInitialValues({
        'context_date_range_days': invalidDays,
      });
      final prefs = await SharedPreferences.getInstance();
      final repository = ContextConfigRepositoryImpl(prefs);
      
      // Read should return default
      final retrievedDays = await repository.getDateRangeDays();
      
      expect(
        retrievedDays,
        equals(14),
        reason: 'getDateRangeDays() should return default (14) for extreme negative value $invalidDays. '
            'Stored: $invalidDays, Retrieved: $retrievedDays',
      );
    }
  });
}
