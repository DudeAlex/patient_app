import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/exceptions/chat_exceptions.dart';
import 'package:patient_app/core/ai/chat/services/error_classifier.dart';

void main() {
  late ErrorClassifier classifier;

  setUp(() {
    classifier = ErrorClassifier();
  });

  group('ErrorClassifier - classify', () {
    test('classifies RateLimitException as rateLimit', () {
      final exception = RateLimitException(message: 'Rate limit exceeded');
      final result = classifier.classify(exception);
      
      expect(result, ErrorType.rateLimit);
    });

    test('classifies NetworkException as network', () {
      final exception = NetworkException(message: 'No internet connection');
      final result = classifier.classify(exception);
      
      expect(result, ErrorType.network);
    });

    test('classifies ServerException with rate limit indicators as rateLimit', () {
      final exception = ServerException(message: 'Too many requests, please wait');
      final result = classifier.classify(exception);
      
      expect(result, ErrorType.rateLimit);
    });

    test('classifies ServerException with network indicators as network', () {
      final exception = ServerException(message: 'Connection timeout');
      final result = classifier.classify(exception);
      
      expect(result, ErrorType.network);
    });

    test('classifies ServerException without specific indicators as server', () {
      final exception = ServerException(message: 'Internal server error');
      final result = classifier.classify(exception);
      
      expect(result, ErrorType.server);
    });

    test('classifies ChatTimeoutException as timeout', () {
      final exception = ChatTimeoutException(timeout: Duration(seconds: 30));
      final result = classifier.classify(exception);
      
      expect(result, ErrorType.timeout);
    });

    test('classifies ValidationException as validation', () {
      final exception = ValidationException(message: 'Invalid request parameters');
      final result = classifier.classify(exception);
      
      expect(result, ErrorType.validation);
    });

    test('classifies error with "rate" in message as rateLimit', () {
      final exception = ServerException(message: 'API rate limit exceeded');
      final result = classifier.classify(exception);
      
      expect(result, ErrorType.rateLimit);
    });

    test('classifies error with "limit" in message as rateLimit', () {
      final exception = ServerException(message: 'Request limit reached');
      final result = classifier.classify(exception);
      
      expect(result, ErrorType.rateLimit);
    });

    test('classifies error with "too many requests" in message as rateLimit', () {
      final exception = ServerException(message: 'Too many requests in short time');
      final result = classifier.classify(exception);
      
      expect(result, ErrorType.rateLimit);
    });

    test('classifies error with "429" in message as rateLimit', () {
      final exception = ServerException(message: 'HTTP 429 Too Many Requests');
      final result = classifier.classify(exception);
      
      expect(result, ErrorType.rateLimit);
    });

    test('classifies error with "network" in message as network', () {
      final exception = ServerException(message: 'Network error occurred');
      final result = classifier.classify(exception);
      
      expect(result, ErrorType.network);
    });

    test('classifies error with "connection" in message as network', () {
      final exception = ServerException(message: 'Connection refused');
      final result = classifier.classify(exception);
      
      expect(result, ErrorType.network);
    });

    test('classifies error with "offline" in message as network', () {
      final exception = ServerException(message: 'Device is offline');
      final result = classifier.classify(exception);
      
      expect(result, ErrorType.network);
    });

    test('classifies error with "timeout" in message as timeout', () {
      final exception = ServerException(message: 'Request timed out');
      final result = classifier.classify(exception);
      
      expect(result, ErrorType.timeout);
    });

    test('classifies error with "validation" in message as validation', () {
      final exception = ServerException(message: 'Validation failed');
      final result = classifier.classify(exception);
      
      expect(result, ErrorType.validation);
    });

    test('classifies error with "invalid" in message as validation', () {
      final exception = ServerException(message: 'Invalid input provided');
      final result = classifier.classify(exception);
      
      expect(result, ErrorType.validation);
    });

    test('classifies error with "bad request" in message as validation', () {
      final exception = ServerException(message: 'Bad request received');
      final result = classifier.classify(exception);
      
      expect(result, ErrorType.validation);
    });

    test('classifies error with "server" in message as server', () {
      final exception = ServerException(message: 'Server error occurred');
      final result = classifier.classify(exception);
      
      expect(result, ErrorType.server);
    });

    test('classifies error with "500" in message as server', () {
      final exception = ServerException(message: 'HTTP 500 Internal Server Error');
      final result = classifier.classify(exception);
      
      expect(result, ErrorType.server);
    });

    test('classifies error with "502" in message as server', () {
      final exception = ServerException(message: 'HTTP 502 Bad Gateway');
      final result = classifier.classify(exception);
      
      expect(result, ErrorType.server);
    });

    test('classifies error with "503" in message as server', () {
      final exception = ServerException(message: 'HTTP 503 Service Unavailable');
      final result = classifier.classify(exception);
      
      expect(result, ErrorType.server);
    });

    test('classifies error with "504" in message as server', () {
      final exception = ServerException(message: 'HTTP 504 Gateway Timeout');
      final result = classifier.classify(exception);
      
      expect(result, ErrorType.server);
    });

    test('classifies unknown error type as unknown', () {
      final exception = ServerException(message: 'Some other error');
      final result = classifier.classify(exception);
      
      expect(result, ErrorType.unknown);
    });
  });

  group('ErrorClassifier - classification consistency', () {
    test('same error type consistently returns same classification', () {
      final exception = RateLimitException(message: 'Rate limit exceeded');
      
      for (int i = 0; i < 5; i++) {
        final result = classifier.classify(exception);
        expect(result, ErrorType.rateLimit);
      }
    });
  });
}