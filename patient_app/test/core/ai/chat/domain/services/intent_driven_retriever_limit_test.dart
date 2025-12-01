import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/domain/services/intent_driven_retriever.dart';
import 'package:patient_app/core/ai/chat/domain/services/relevance_scorer.dart';
import 'package:patient_app/core/ai/chat/domain/services/privacy_filter.dart';
import 'package:patient_app/core/ai/chat/models/intent_retrieval_config.dart';
import 'package:patient_app/core/ai/chat/models/query_analysis.dart';
import 'package:patient_app/core/ai/chat/models/query_intent.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

void main() {
  group('IntentDrivenRetriever - Limit Tests', () {
    late IntentDrivenRetriever retriever;

    setUp(() {
      final config = IntentRetrievalConfig(
        enabled: true,
        relevanceThreshold: 0.1, // Low threshold to allow more records
        maxResults: 10, // Default max results
        minQueryWords: 1,
      );
      retriever = IntentDrivenRetriever(
        relevanceScorer: RelevanceScorer(),
        privacyFilter: PrivacyFilter(),
        config: config,
      );
    });

    test('fewer records returns all', () async {
      // Arrange
      final now = DateTime.now();
      final records = <RecordEntity>[];
      // Create 5 test records
      for (int i = 1; i <= 5; i++) {
        records.add(
          RecordEntity(
            id: i,
            spaceId: 'health',
            type: 'Blood Pressure',
            date: now,
            title: 'Blood Pressure Reading $i',
            text: 'Blood pressure reading number $i with value 120/80',
            tags: ['reading', 'pressure'],
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      
      final config = IntentRetrievalConfig(
        enabled: true,
        relevanceThreshold: 0.1, // Low threshold to allow more records
        maxResults: 10, // Set maxResults to 10
        minQueryWords: 1,
      );
      final testRetriever = IntentDrivenRetriever(
        relevanceScorer: RelevanceScorer(),
        privacyFilter: PrivacyFilter(),
        config: config,
      );
      
      // Act
      final result = await testRetriever.retrieve(
        query: QueryAnalysis(
          originalQuery: 'blood pressure readings',
          keywords: ['blood', 'pressure', 'readings'],
          intent: QueryIntent.question,
          intentConfidence: 0.8,
        ),
        candidateRecords: records,
        activeSpaceId: 'health',
      );
      
      // Assert
      expect(result.records.length, equals(5)); // Should return all 5 records
    });

    test('results never exceed maxResults', () async {
      // Arrange
      final now = DateTime.now();
      final records = <RecordEntity>[];
      // Create 20 test records
      for (int i = 1; i <= 20; i++) {
        records.add(
          RecordEntity(
            id: i,
            spaceId: 'health',
            type: 'Blood Pressure',
            date: now,
            title: 'Blood Pressure Reading $i',
            text: 'Blood pressure reading number $i with value 120/80',
            tags: ['reading', 'pressure'],
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      
      final config = IntentRetrievalConfig(
        enabled: true,
        relevanceThreshold: 0.1, // Low threshold to allow more records
        maxResults: 10, // Set maxResults to 10
        minQueryWords: 1,
      );
      final testRetriever = IntentDrivenRetriever(
        relevanceScorer: RelevanceScorer(),
        privacyFilter: PrivacyFilter(),
        config: config,
      );
      
      // Act
      final result = await testRetriever.retrieve(
        query: QueryAnalysis(
          originalQuery: 'blood pressure readings',
          keywords: ['blood', 'pressure', 'readings'],
          intent: QueryIntent.question,
          intentConfidence: 0.8,
        ),
        candidateRecords: records,
        activeSpaceId: 'health',
      );
      
      // Assert
      expect(result.records.length, lessThanOrEqualTo(10)); // Results should not exceed 10
    });
  });
}