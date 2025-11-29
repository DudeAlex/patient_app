import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:patient_app/core/ai/chat/repositories/context_config_repository_impl.dart';

/// **Feature: context-date-range-fix, Property 1: Date range setting is read from repository**
/// Validates: Requirements 5.5, 1.1
///
/// For any date range value between 1 and 1095, when set via setDateRangeDays()
/// and then read via getDateRangeDays(), the returned value should equal the set value.
void main() {
  test('Property: Date range setting round-trip preserves value', () async {
    final random = Random(42);
    
    // Run 100 iterations to test various random values
    for (int iteration = 0; iteration < 100; iteration++) {
      // Generate random date range value between 1 and 1095 (inclusive)
      final randomDays = 1 + random.nextInt(1095); // 1 to 1095
      
      // Create fresh repository for each iteration
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = ContextConfigRepositoryImpl(prefs);
      
      // Set the date range
      await repository.setDateRangeDays(randomDays);
      
      // Read it back
      final retrievedDays = await repository.getDateRangeDays();
      
      // Assert the value matches
      expect(
        retrievedDays,
        equals(randomDays),
        reason: 'Round-trip failed for value $randomDays on iteration $iteration. '
            'Set: $randomDays, Retrieved: $retrievedDays',
      );
    }
  });

  test('Property: Date range setting round-trip works for boundary values', () async {
    // Test boundary values explicitly
    final boundaryValues = [1, 2, 1094, 1095];
    
    for (final days in boundaryValues) {
      // Create fresh repository for each test
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = ContextConfigRepositoryImpl(prefs);
      
      // Set the date range
      await repository.setDateRangeDays(days);
      
      // Read it back
      final retrievedDays = await repository.getDateRangeDays();
      
      // Assert the value matches
      expect(
        retrievedDays,
        equals(days),
        reason: 'Round-trip failed for boundary value $days. '
            'Set: $days, Retrieved: $retrievedDays',
      );
    }
  });

  test('Property: Date range setting round-trip works for preset values', () async {
    // Test preset values explicitly
    final presetValues = [7, 14, 30];
    
    for (final days in presetValues) {
      // Create fresh repository for each test
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = ContextConfigRepositoryImpl(prefs);
      
      // Set the date range
      await repository.setDateRangeDays(days);
      
      // Read it back
      final retrievedDays = await repository.getDateRangeDays();
      
      // Assert the value matches
      expect(
        retrievedDays,
        equals(days),
        reason: 'Round-trip failed for preset value $days. '
            'Set: $days, Retrieved: $retrievedDays',
      );
    }
  });

  test('Property: Date range setting round-trip works for custom values', () async {
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
      // Create fresh repository for each test
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repository = ContextConfigRepositoryImpl(prefs);
      
      // Set the date range
      await repository.setDateRangeDays(days);
      
      // Read it back
      final retrievedDays = await repository.getDateRangeDays();
      
      // Assert the value matches
      expect(
        retrievedDays,
        equals(days),
        reason: 'Round-trip failed for custom value $days. '
            'Set: $days, Retrieved: $retrievedDays',
      );
    }
  });

  test('Property: Multiple round-trips preserve value', () async {
    final random = Random(456);
    
    // Create repository once
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = ContextConfigRepositoryImpl(prefs);
    
    // Perform multiple set/get operations in sequence
    for (int i = 0; i < 20; i++) {
      final randomDays = 1 + random.nextInt(1095);
      
      // Set the date range
      await repository.setDateRangeDays(randomDays);
      
      // Read it back immediately
      final retrievedDays = await repository.getDateRangeDays();
      
      // Assert the value matches
      expect(
        retrievedDays,
        equals(randomDays),
        reason: 'Round-trip failed on iteration $i for value $randomDays. '
            'Set: $randomDays, Retrieved: $retrievedDays',
      );
    }
  });

  test('Property: Round-trip works after overwriting previous value', () async {
    final random = Random(789);
    
    // Create repository once
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repository = ContextConfigRepositoryImpl(prefs);
    
    // Set initial value
    final initialDays = 1 + random.nextInt(1095);
    await repository.setDateRangeDays(initialDays);
    
    // Overwrite with different values and verify each time
    for (int i = 0; i < 20; i++) {
      final newDays = 1 + random.nextInt(1095);
      
      // Set new value
      await repository.setDateRangeDays(newDays);
      
      // Read it back
      final retrievedDays = await repository.getDateRangeDays();
      
      // Assert the new value matches (not the old one)
      expect(
        retrievedDays,
        equals(newDays),
        reason: 'Round-trip failed after overwrite on iteration $i. '
            'Previous: $initialDays, New: $newDays, Retrieved: $retrievedDays',
      );
    }
  });

  test('Property: Round-trip preserves value across repository instances', () async {
    final random = Random(321);
    
    // Test that values persist across different repository instances
    for (int i = 0; i < 20; i++) {
      final randomDays = 1 + random.nextInt(1095);
      
      // Create first repository instance and set value
      SharedPreferences.setMockInitialValues({});
      final prefs1 = await SharedPreferences.getInstance();
      final repository1 = ContextConfigRepositoryImpl(prefs1);
      await repository1.setDateRangeDays(randomDays);
      
      // Create second repository instance and read value
      final prefs2 = await SharedPreferences.getInstance();
      final repository2 = ContextConfigRepositoryImpl(prefs2);
      final retrievedDays = await repository2.getDateRangeDays();
      
      // Assert the value persisted across instances
      expect(
        retrievedDays,
        equals(randomDays),
        reason: 'Round-trip failed across repository instances on iteration $i. '
            'Set: $randomDays, Retrieved: $retrievedDays',
      );
    }
  });
}
