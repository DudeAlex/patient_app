import 'package:patient_app/core/ai/chat/models/query_intent.dart';

/// Classifies the intent of a user query using pattern matching.
/// 
/// This implementation uses a language-agnostic approach:
/// 1. If query contains '?' → QueryIntent.question
/// 2. If keywords.length <= 2 → QueryIntent.greeting
/// 3. Default → QueryIntent.question (safest for retrieval)
/// 
/// This simplified approach works universally across languages without
/// requiring language-specific patterns or NLP libraries.
class IntentClassifier {
  /// Classifies the intent of a query and returns it with confidence score.
  /// 
  /// Returns:
  /// - QueryIntent.question with 0.8 confidence if query contains '?'
  /// - QueryIntent.greeting with 0.6 confidence if keywords <= 2
  /// - QueryIntent.question with 0.5 confidence as default (safest for retrieval)
  IntentClassification classify(String query, List<String> keywords) {
    // Check for question mark pattern (universal across languages)
    if (query.contains('?')) {
      return IntentClassification(
        intent: QueryIntent.question,
        confidence: 0.8,
      );
    }
    
    // Check for very short queries (likely greetings)
    if (keywords.length <= 2) {
      return IntentClassification(
        intent: QueryIntent.greeting,
        confidence: 0.6,
      );
    }
    
    // Default to question (safest for information retrieval)
    return IntentClassification(
      intent: QueryIntent.question,
      confidence: 0.5,
    );
  }
}

/// Result of intent classification containing the intent and confidence score.
class IntentClassification {
  const IntentClassification({
    required this.intent,
    required this.confidence,
  });

  /// The classified intent (question, command, statement, greeting).
  final QueryIntent intent;

  /// Confidence score for the classification (0.0-1.0).
  final double confidence;
}