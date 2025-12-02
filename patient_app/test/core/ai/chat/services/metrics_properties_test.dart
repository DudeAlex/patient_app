import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/exceptions/chat_exceptions.dart';
import 'package:patient_app/core/ai/chat/models/recovery_metrics.dart';
import 'package:patient_app/core/ai/chat/services/error_classifier.dart';
import 'package:patient_app/core/ai/exceptions/ai_exceptions.dart';

void main() {
  group('Metrics Properties', () {
    test('Property 10: Metrics accuracy - success rate calculation', () {
      // Verify that success rate equals successfulRecoveries / totalAttempts
      final totalAttempts = 10;
      final successfulRecoveries = 7;
      final failedRecoveries = 1;
      final fallbacksUsed = 2;
      
      final metrics = RecoveryMetrics(
        totalAttempts: totalAttempts,
        successfulRecoveries: successfulRecoveries,
        failedRecoveries: failedRecoveries,
        fallbacksUsed: fallbacksUsed,
        averageRecoveryTime: const Duration(milliseconds: 500),
        errorTypeCount: const {},
      );

      // Verify the mathematical relationship: total = successful + failed + fallbacks
      expect(totalAttempts, equals(successfulRecoveries + failedRecoveries + fallbacksUsed));
      
      // Verify success rate calculation
      final expectedSuccessRate = successfulRecoveries / totalAttempts;
      expect(metrics.successRate, closeTo(expectedSuccessRate, 0.0001));
      
      // Verify that success rate is between 0 and 1
      expect(metrics.successRate >= 0.0, isTrue);
      expect(metrics.successRate <= 1.0, isTrue);
    });

    test('Property 10: Metrics accuracy - fallback rate calculation', () {
      // Verify that fallback rate equals fallbacksUsed / totalAttempts
      final totalAttempts = 5;
      final successfulRecoveries = 0;
      final failedRecoveries = 0;
      final fallbacksUsed = 5;
      
      final metrics = RecoveryMetrics(
        totalAttempts: totalAttempts,
        successfulRecoveries: successfulRecoveries,
        failedRecoveries: failedRecoveries,
        fallbacksUsed: fallbacksUsed,
        averageRecoveryTime: Duration.zero,
        errorTypeCount: const {},
      );

      // Verify the mathematical relationship: total = successful + failed + fallbacks
      expect(totalAttempts, equals(successfulRecoveries + failedRecoveries + fallbacksUsed));
      
      // Verify fallback rate calculation
      final expectedFallbackRate = fallbacksUsed / totalAttempts;
      expect(metrics.fallbackRate, closeTo(expectedFallbackRate, 0.0001));
      
      // Verify that fallback rate is between 0 and 1
      expect(metrics.fallbackRate >= 0.0, isTrue);
      expect(metrics.fallbackRate <= 1.0, isTrue);
    });

    test('Property 10: Metrics accuracy - error type tracking', () {
      final classifier = ErrorClassifier();
      final errors = [
        NetworkException(message: 'Network error'),
        RateLimitException(message: 'Rate limit exceeded'),
        ChatTimeoutException(),
        ServerException(message: 'Server error'),
        ValidationException(message: 'Validation error'),
        AiServiceException('Unknown'),
      ];

      final errorCounts = <String, int>{};
      for (final error in errors) {
        final type = classifier.classify(error).name;
        errorCounts[type] = (errorCounts[type] ?? 0) + 1;
      }

      final metrics = RecoveryMetrics(
        totalAttempts: errors.length,
        successfulRecoveries: 0,
        failedRecoveries: errors.length,
        fallbacksUsed: 0,
        averageRecoveryTime: const Duration(milliseconds: 10),
        errorTypeCount: errorCounts,
      );

      expect(metrics.errorTypeCount['network'], 1);
      expect(metrics.errorTypeCount['rateLimit'], 1);
      expect(metrics.errorTypeCount['timeout'], 1);
      expect(metrics.errorTypeCount['server'], 1);
      expect(metrics.errorTypeCount['validation'], 1);
      expect(metrics.errorTypeCount['unknown'], 1);
      expect(
        metrics.errorTypeCount.values.reduce((a, b) => a + b),
        errors.length,
      );
    });

    test('Property 10: Metrics accuracy - mathematical relationships', () {
      // Test various combinations to verify mathematical relationships hold
      final testCases = [
        {'total': 10, 'success': 7, 'failed': 1, 'fallback': 2},
        {'total': 100, 'success': 85, 'failed': 5, 'fallback': 10},
        {'total': 50, 'success': 20, 'failed': 15, 'fallback': 15},
        {'total': 25, 'success': 0, 'failed': 10, 'fallback': 15},
        {'total': 15, 'success': 10, 'failed': 0, 'fallback': 5},
      ];
      
      for (final testCase in testCases) {
        final total = testCase['total']!;
        final success = testCase['success']!;
        final failed = testCase['failed']!;
        final fallback = testCase['fallback']!;
        
        // Verify the fundamental equation: total = success + failed + fallback
        expect(total, equals(success + failed + fallback),
            reason: 'Total attempts (${total}) should equal sum of success (${success}), failed (${failed}), and fallback (${fallback})');
        
        final metrics = RecoveryMetrics(
          totalAttempts: total,
          successfulRecoveries: success,
          failedRecoveries: failed,
          fallbacksUsed: fallback,
          averageRecoveryTime: const Duration(milliseconds: 100),
          errorTypeCount: const {},
        );
        
        // Verify success rate
        final expectedSuccessRate = success / total;
        expect(metrics.successRate, closeTo(expectedSuccessRate, 0.0001),
            reason: 'Success rate should be success/total');
        
        // Verify fallback rate
        final expectedFallbackRate = fallback / total;
        expect(metrics.fallbackRate, closeTo(expectedFallbackRate, 0.0001),
            reason: 'Fallback rate should be fallback/total');
        
        // Verify rates are in valid range
        expect(metrics.successRate >= 0.0 && metrics.successRate <= 1.0, isTrue,
            reason: 'Success rate should be between 0 and 1');
        expect(metrics.fallbackRate >= 0.0 && metrics.fallbackRate <= 1.0, isTrue,
            reason: 'Fallback rate should be between 0 and 1');
      }
    });
    
    test('Property 10: Metrics accuracy - zero attempts guarded', () {
      final metrics = RecoveryMetrics(
        totalAttempts: 0,
        successfulRecoveries: 0,
        failedRecoveries: 0,
        fallbacksUsed: 0,
        averageRecoveryTime: Duration.zero,
        errorTypeCount: const {},
      );

      expect(metrics.successRate, 0.0);
      expect(metrics.fallbackRate, 0.0);
    });
  });
}
