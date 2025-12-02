import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/models/chat_request.dart';
import 'package:patient_app/core/ai/chat/models/chat_response.dart';
import 'package:patient_app/core/ai/exceptions/ai_exceptions.dart';

/// Abstract base class for error recovery strategies.
///
/// Each strategy handles a specific type of error and implements the appropriate
/// recovery approach (retry, wait, fallback, etc.).
abstract class ErrorRecoveryStrategy {
  /// Attempts to recover from the provided error by retrying the request.
  ///
  /// Returns the recovered response if successful, or throws the error
  /// if recovery fails.
  Future<ChatResponse> recover(
    ChatRequest request,
    AiServiceException error,
    int attemptNumber,
    AiChatService service,
  );

  /// Determines if this strategy can handle the provided error.
  bool canRecover(AiServiceException error);

  /// Gets the delay to use before attempting recovery.
  ///
  /// The [attemptNumber] indicates which recovery attempt this is (1-indexed).
  Duration getRetryDelay(int attemptNumber);

  /// Gets the name of this strategy for logging and metrics purposes.
  String get strategyName;
}
