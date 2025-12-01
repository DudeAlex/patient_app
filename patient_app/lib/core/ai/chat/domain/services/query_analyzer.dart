import 'package:patient_app/core/ai/chat/domain/services/intent_classifier.dart';
import 'package:patient_app/core/ai/chat/domain/services/keyword_extractor.dart';
import 'package:patient_app/core/ai/chat/models/query_analysis.dart';
import 'package:patient_app/core/ai/chat/models/query_context.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';

/// Analyzes user queries to extract keywords and classify intent.
///
/// This service orchestrates the analysis process by:
/// 1. Extracting keywords using [KeywordExtractor]
/// 2. Classifying intent using [IntentClassifier]
/// 3. Processing conversation history for context
/// 4. Logging analysis results for monitoring
class QueryAnalyzer {
  QueryAnalyzer({
    required KeywordExtractor keywordExtractor,
    required IntentClassifier intentClassifier,
  })  : _keywordExtractor = keywordExtractor,
        _intentClassifier = intentClassifier;

  final KeywordExtractor _keywordExtractor;
  final IntentClassifier _intentClassifier;

  /// Analyzes the given [query] string.
  ///
  /// [history] is an optional list of previous messages in the conversation.
  /// Only the last 2 messages are considered for context (as per requirement 8.5).
  ///
  /// Returns a [QueryAnalysis] object containing the extracted keywords,
  /// classified intent, confidence score, and context.
  Future<QueryAnalysis> analyze(String query, {List<String>? history}) async {
    final startTime = DateTime.now();

    // 1. Extract keywords
    final keywords = _keywordExtractor.extract(query);

    // 2. Classify intent
    final classification = _intentClassifier.classify(query, keywords);

    // 3. Process context
    QueryContext? context;
    if (history != null && history.isNotEmpty) {
      // Limit to last 2 messages (requirement 8.5)
      final recentHistory = history.length > 2 
          ? history.sublist(history.length - 2) 
          : history;
          
      // Simple reference resolution for pronouns
      final resolvedReferences = <String, String>{};
      final lowerQuery = query.toLowerCase();
      if (lowerQuery.contains('it') || lowerQuery.contains('that') || lowerQuery.contains('this')) {
        // In a real implementation, we would analyze the history to resolve what "it" refers to
        // For now, we just mark that we detected a reference
        resolvedReferences['detected'] = 'pronoun_reference';
      }

      context = QueryContext(
        conversationHistory: recentHistory,
        resolvedReferences: resolvedReferences,
      );
    }

    final analysis = QueryAnalysis(
      originalQuery: query,
      keywords: keywords,
      intent: classification.intent,
      intentConfidence: classification.confidence,
      context: context,
    );

    // 4. Log results
    final duration = DateTime.now().difference(startTime);
    await AppLogger.info(
      'Query analyzed',
      context: {
        'category': 'intent_retrieval',
        'event': 'query_analysis',
        'originalQuery': query,
        'keywords': keywords,
        'keywordCount': keywords.length,
        'intent': classification.intent.name,
        'intentConfidence': classification.confidence,
        'hasContext': context != null,
        'historyCount': context?.conversationHistory.length ?? 0,
        'analysisTimeMs': duration.inMilliseconds,
      },
    );

    return analysis;
  }
}
