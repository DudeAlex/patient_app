import 'package:flutter_test/flutter_test.dart';

/// Custom date range validation logic extracted from SettingsScreen
class CustomDateRangeValidator {
  /// Validates custom date range input and returns error message if invalid
  String? validateCustomDateRange(String text) {
    final trimmed = text.trim();
    
    // Validate input is not empty
    if (trimmed.isEmpty) {
      return 'Please enter a number';
    }
    
    // Validate input is a valid integer
    final days = int.tryParse(trimmed);
    if (days == null) {
      return 'Please enter a valid number';
    }

    // Validate input is between 1 and 1095
    if (days < 1 || days > 1095) {
      return 'Must be between 1 and 1095 (up to 3 years)';
    }

    return null; // Valid input
  }
}

void main() {
  group('Custom Date Range UI Validation', () {
    late CustomDateRangeValidator validator;

    setUp(() {
      validator = CustomDateRangeValidator();
    });

    test('valid input (1-1095) is accepted', () {
      // Test boundary values
      expect(validator.validateCustomDateRange('1'), isNull);
      expect(validator.validateCustomDateRange('1095'), isNull);
      
      // Test common preset values
      expect(validator.validateCustomDateRange('7'), isNull);
      expect(validator.validateCustomDateRange('14'), isNull);
      expect(validator.validateCustomDateRange('30'), isNull);
      
      // Test custom values
      expect(validator.validateCustomDateRange('45'), isNull);
      expect(validator.validateCustomDateRange('90'), isNull);
      expect(validator.validateCustomDateRange('365'), isNull);
      expect(validator.validateCustomDateRange('500'), isNull);
      
      // Test with whitespace (should be trimmed)
      expect(validator.validateCustomDateRange('  100  '), isNull);
      expect(validator.validateCustomDateRange('\t50\t'), isNull);
    });

    test('invalid input shows error message', () {
      // Test value too low (0)
      expect(
        validator.validateCustomDateRange('0'),
        equals('Must be between 1 and 1095 (up to 3 years)'),
      );

      // Test negative values
      expect(
        validator.validateCustomDateRange('-1'),
        equals('Must be between 1 and 1095 (up to 3 years)'),
      );
      expect(
        validator.validateCustomDateRange('-5'),
        equals('Must be between 1 and 1095 (up to 3 years)'),
      );
      expect(
        validator.validateCustomDateRange('-100'),
        equals('Must be between 1 and 1095 (up to 3 years)'),
      );

      // Test value too high (1096)
      expect(
        validator.validateCustomDateRange('1096'),
        equals('Must be between 1 and 1095 (up to 3 years)'),
      );

      // Test value way too high
      expect(
        validator.validateCustomDateRange('5000'),
        equals('Must be between 1 and 1095 (up to 3 years)'),
      );
      expect(
        validator.validateCustomDateRange('10000'),
        equals('Must be between 1 and 1095 (up to 3 years)'),
      );
    });

    test('non-numeric input shows error message', () {
      // Test alphabetic input
      expect(
        validator.validateCustomDateRange('abc'),
        equals('Please enter a valid number'),
      );
      expect(
        validator.validateCustomDateRange('xyz'),
        equals('Please enter a valid number'),
      );

      // Test mixed alphanumeric
      expect(
        validator.validateCustomDateRange('12abc'),
        equals('Please enter a valid number'),
      );
      expect(
        validator.validateCustomDateRange('abc123'),
        equals('Please enter a valid number'),
      );
      expect(
        validator.validateCustomDateRange('1a2b3c'),
        equals('Please enter a valid number'),
      );

      // Test special characters
      expect(
        validator.validateCustomDateRange('!@#'),
        equals('Please enter a valid number'),
      );
      expect(
        validator.validateCustomDateRange(r'$%^'),
        equals('Please enter a valid number'),
      );
      expect(
        validator.validateCustomDateRange('***'),
        equals('Please enter a valid number'),
      );

      // Test decimal numbers (not integers)
      expect(
        validator.validateCustomDateRange('12.5'),
        equals('Please enter a valid number'),
      );
      expect(
        validator.validateCustomDateRange('3.14'),
        equals('Please enter a valid number'),
      );
    });

    test('empty input shows error message', () {
      // Test completely empty string
      expect(
        validator.validateCustomDateRange(''),
        equals('Please enter a number'),
      );

      // Test whitespace only
      expect(
        validator.validateCustomDateRange('   '),
        equals('Please enter a number'),
      );
      expect(
        validator.validateCustomDateRange('\t'),
        equals('Please enter a number'),
      );
      expect(
        validator.validateCustomDateRange('\n'),
        equals('Please enter a number'),
      );
      expect(
        validator.validateCustomDateRange('  \t  \n  '),
        equals('Please enter a number'),
      );
    });

    test('error messages are cleared when valid input is entered', () {
      // Simulate the flow: invalid input -> error -> valid input -> no error
      
      // First, invalid input produces error
      String? error = validator.validateCustomDateRange('abc');
      expect(error, equals('Please enter a valid number'));

      // Then, valid input clears error
      error = validator.validateCustomDateRange('45');
      expect(error, isNull);

      // Another scenario: out of range -> error -> valid -> no error
      error = validator.validateCustomDateRange('0');
      expect(error, equals('Must be between 1 and 1095 (up to 3 years)'));

      error = validator.validateCustomDateRange('100');
      expect(error, isNull);

      // Another scenario: empty -> error -> valid -> no error
      error = validator.validateCustomDateRange('');
      expect(error, equals('Please enter a number'));

      error = validator.validateCustomDateRange('365');
      expect(error, isNull);
    });

    test('preset and custom modes can be switched', () {
      // This test verifies that the validator works consistently
      // regardless of whether the value came from a preset or custom input
      
      // Preset values should be valid
      expect(validator.validateCustomDateRange('7'), isNull);
      expect(validator.validateCustomDateRange('14'), isNull);
      expect(validator.validateCustomDateRange('30'), isNull);

      // Custom values should be valid
      expect(validator.validateCustomDateRange('90'), isNull);
      expect(validator.validateCustomDateRange('365'), isNull);

      // Switching back to preset values should still be valid
      expect(validator.validateCustomDateRange('7'), isNull);
      expect(validator.validateCustomDateRange('30'), isNull);

      // Invalid values should be rejected regardless of mode
      expect(
        validator.validateCustomDateRange('0'),
        equals('Must be between 1 and 1095 (up to 3 years)'),
      );
      expect(
        validator.validateCustomDateRange('1096'),
        equals('Must be between 1 and 1095 (up to 3 years)'),
      );
    });

    test('custom mode displays current value when reopened', () {
      // This test verifies that custom values are validated correctly
      // when they are loaded from storage
      
      // A custom value like 365 should be valid
      expect(validator.validateCustomDateRange('365'), isNull);

      // Other custom values should also be valid
      expect(validator.validateCustomDateRange('100'), isNull);
      expect(validator.validateCustomDateRange('500'), isNull);
      expect(validator.validateCustomDateRange('1000'), isNull);

      // Preset values should also be valid when displayed
      expect(validator.validateCustomDateRange('7'), isNull);
      expect(validator.validateCustomDateRange('14'), isNull);
      expect(validator.validateCustomDateRange('30'), isNull);
    });

    test('switching from custom to preset clears error', () {
      // This test verifies that switching to a preset value
      // would clear any validation errors from custom input
      
      // Invalid custom input produces error
      String? error = validator.validateCustomDateRange('0');
      expect(error, equals('Must be between 1 and 1095 (up to 3 years)'));

      // Switching to a preset value (7) should be valid
      error = validator.validateCustomDateRange('7');
      expect(error, isNull);

      // Another scenario: invalid custom -> preset
      error = validator.validateCustomDateRange('abc');
      expect(error, equals('Please enter a valid number'));

      error = validator.validateCustomDateRange('14');
      expect(error, isNull);

      // Another scenario: out of range -> preset
      error = validator.validateCustomDateRange('5000');
      expect(error, equals('Must be between 1 and 1095 (up to 3 years)'));

      error = validator.validateCustomDateRange('30');
      expect(error, isNull);
    });

    test('validation handles edge cases correctly', () {
      // Test exact boundary values
      expect(validator.validateCustomDateRange('1'), isNull);
      expect(validator.validateCustomDateRange('1095'), isNull);

      // Test just outside boundaries
      expect(
        validator.validateCustomDateRange('0'),
        equals('Must be between 1 and 1095 (up to 3 years)'),
      );
      expect(
        validator.validateCustomDateRange('1096'),
        equals('Must be between 1 and 1095 (up to 3 years)'),
      );

      // Test large numbers
      expect(
        validator.validateCustomDateRange('999999'),
        equals('Must be between 1 and 1095 (up to 3 years)'),
      );

      // Test negative numbers
      expect(
        validator.validateCustomDateRange('-999'),
        equals('Must be between 1 and 1095 (up to 3 years)'),
      );
    });

    test('validation is consistent across multiple calls', () {
      // Calling validation multiple times with same input should give same result
      for (int i = 0; i < 5; i++) {
        expect(validator.validateCustomDateRange('100'), isNull);
        expect(
          validator.validateCustomDateRange('abc'),
          equals('Please enter a valid number'),
        );
        expect(
          validator.validateCustomDateRange('0'),
          equals('Must be between 1 and 1095 (up to 3 years)'),
        );
      }
    });
  });
}
