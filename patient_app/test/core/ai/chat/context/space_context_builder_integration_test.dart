import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:patient_app/core/ai/chat/application/interfaces/space_context_builder.dart';
import 'package:patient_app/core/ai/chat/context/context_filter_engine.dart';
import 'package:patient_app/core/ai/chat/context/context_truncation_strategy.dart';
import 'package:patient_app/core/ai/chat/context/record_relevance_scorer.dart';
import 'package:patient_app/core/ai/chat/context/record_summary_formatter.dart';
import 'package:patient_app/core/ai/chat/context/space_context_builder.dart';
import 'package:patient_app/core/ai/chat/context/token_budget_allocator.dart';
import 'package:patient_app/core/ai/chat/domain/services/intent_driven_retriever.dart';
import 'package:patient_app/core/ai/chat/domain/services/query_analyzer.dart';
import 'package:patient_app/core/ai/chat/models/date_range.dart';
import 'package:patient_app/core/ai/chat/models/intent_retrieval_config.dart';
import 'package:patient_app/core/ai/chat/models/query_analysis.dart';
import 'package:patient_app/core/ai/chat/models/query_intent.dart';
import 'package:patient_app/core/application/services/space_manager.dart';
import 'package:patient_app/core/domain/entities/space.dart';
import 'package:patient_app/features/records/application/ports/records_repository.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';

class MockRecordsService extends Mock {
  late RecordsRepository records;
}

class MockSpaceManager extends Mock implements SpaceManager {}
class MockContextFilterEngine extends Mock implements ContextFilterEngine {}
class MockRecordRelevanceScorer extends Mock implements RecordRelevanceScorer {}
class MockTokenBudgetAllocator extends Mock implements TokenBudgetAllocator {}
class MockContextTruncationStrategy extends Mock implements ContextTruncationStrategy {}
class MockIntentDrivenRetriever extends Mock implements IntentDrivenRetriever {}
class MockQueryAnalyzer extends Mock implements QueryAnalyzer {}

void main() {
  late SpaceContextBuilderImpl builder;
  late MockRecordsService mockRecordsService;
  late MockSpaceManager mockSpaceManager;
  late MockContextFilterEngine mockFilterEngine;
  late MockRecordRelevanceScorer mockRelevanceScorer;
  late MockTokenBudgetAllocator mockTokenBudgetAllocator;
  late MockContextTruncationStrategy mockTruncationStrategy;
  late MockIntentDrivenRetriever mockIntentDrivenRetriever;
  late MockQueryAnalyzer mockQueryAnalyzer;

  setUp(() {
    mockRecordsService = MockRecordsService();
    mockSpaceManager = MockSpaceManager();
    mockFilterEngine = MockContextFilterEngine();
    mockRelevanceScorer = MockRecordRelevanceScorer();
    mockTokenBudgetAllocator = MockTokenBudgetAllocator();
    mockTruncationStrategy = MockContextTruncationStrategy();
    mockIntentDrivenRetriever = MockIntentDrivenRetriever();
    mockQueryAnalyzer = MockQueryAnalyzer();
    
    builder = SpaceContextBuilderImpl(
      recordsServiceFuture: Future.value(mockRecordsService),
      spaceManager: mockSpaceManager,
      filterEngine: mockFilterEngine,
      relevanceScorer: mockRelevanceScorer,
      tokenBudgetAllocator: mockTokenBudgetAllocator,
      truncationStrategy: mockTruncationStrategy,
      intentDrivenRetriever: mockIntentDrivenRetriever,
      queryAnalyzer: mockQueryAnalyzer,
    );
  });

  group('SpaceContextBuilderImpl - Integration with Intent-Driven Retrieval', () {
    test('should use intent-driven retrieval when user query is provided', () async {
      // Setup
      final space = Space(
        id: 'health',
        name: 'Health',
        description: 'Health records',
        categories: ['checkup', 'lab', 'medication'],
      );
      
      final records = [
        RecordEntity(
          id: 1,
          spaceId: 'health',
          type: 'Blood Pressure',
          date: DateTime.now(),
          title: 'Blood Pressure Checkup',
          text: 'Today my blood pressure was 120/80 which is normal',
          tags: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      
      when(mockSpaceManager.getCurrentSpace()).thenAnswer((_) async => space);
      when(mockFilterEngine.filterRecords(any, spaceId: anyNamed('spaceId'), dateRange: anyNamed('dateRange')))
          .thenAnswer((_) async => records);
      when(mockRelevanceScorer.sortByRelevance(any)).thenAnswer((_) async => records);
      when(mockTokenBudgetAllocator.allocate()).thenReturn(const TokenBudgetAllocator().allocate());
      when(mockTruncationStrategy.truncateToFit(any, availableTokens: anyNamed('availableTokens'), formatter: anyNamed('formatter'), maxRecords: anyNamed('maxRecords')))
          .thenAnswer((invocation) => invocation.positionalArguments[0]); // Return input as-is for test
      when(mockQueryAnalyzer.analyze(any)).thenAnswer((_) async => QueryAnalysis(
        originalQuery: 'What was my blood pressure?',
        keywords: ['blood', 'pressure'],
        intent: QueryIntent.question,
        intentConfidence: 0.8,
      ));
      
      // Execute
      final context = await builder.build(
        'health',
        userQuery: 'What was my blood pressure?',
      );
      
      // Verify
      expect(context.spaceId, 'health');
      verify(mockQueryAnalyzer.analyze('What was my blood pressure?')).called(1);
      verify(mockIntentDrivenRetriever.retrieve(
        query: anyNamed('query'),
        candidateRecords: anyNamed('candidateRecords'),
        activeSpaceId: anyNamed('activeSpaceId'),
      )).called(1); // Should use intent-driven retrieval
    });

    test('should use traditional approach when no user query is provided', () async {
      // Setup
      final space = Space(
        id: 'health',
        name: 'Health',
        description: 'Health records',
        categories: ['checkup', 'lab', 'medication'],
      );
      
      final records = [
        RecordEntity(
          id: 1,
          spaceId: 'health',
          type: 'Blood Pressure',
          date: DateTime.now(),
          title: 'Blood Pressure Checkup',
          text: 'Today my blood pressure was 120/80 which is normal',
          tags: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      
      when(mockSpaceManager.getCurrentSpace()).thenAnswer((_) async => space);
      when(mockFilterEngine.filterRecords(any, spaceId: anyNamed('spaceId'), dateRange: anyNamed('dateRange')))
          .thenAnswer((_) async => records);
      when(mockRelevanceScorer.sortByRelevance(any)).thenAnswer((_) async => records);
      when(mockTokenBudgetAllocator.allocate()).thenReturn(const TokenBudgetAllocator().allocate());
      when(mockTruncationStrategy.truncateToFit(any, availableTokens: anyNamed('availableTokens'), formatter: anyNamed('formatter'), maxRecords: anyNamed('maxRecords')))
          .thenAnswer((invocation) => invocation.positionalArguments[0]); // Return input as-is for test
      
      // Execute
      final context = await builder.build(
        'health',
        userQuery: null, // No query provided
      );
      
      // Verify
      expect(context.spaceId, 'health');
      verifyNever(mockQueryAnalyzer.analyze(any));
      verifyNever(mockIntentDrivenRetriever.retrieve(
        query: anyNamed('query'),
        candidateRecords: anyNamed('candidateRecords'),
        activeSpaceId: anyNamed('activeSpaceId'),
      )); // Should not use intent-driven retrieval
      verify(mockRelevanceScorer.sortByRelevance(any)).called(1); // Should use traditional approach
    });

    test('should handle empty user query by using traditional approach', () async {
      // Setup
      final space = Space(
        id: 'health',
        name: 'Health',
        description: 'Health records',
        categories: ['checkup', 'lab', 'medication'],
      );
      
      final records = [
        RecordEntity(
          id: 1,
          spaceId: 'health',
          type: 'Blood Pressure',
          date: DateTime.now(),
          title: 'Blood Pressure Checkup',
          text: 'Today my blood pressure was 120/80 which is normal',
          tags: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      
      when(mockSpaceManager.getCurrentSpace()).thenAnswer((_) async => space);
      when(mockFilterEngine.filterRecords(any, spaceId: anyNamed('spaceId'), dateRange: anyNamed('dateRange')))
          .thenAnswer((_) async => records);
      when(mockRelevanceScorer.sortByRelevance(any)).thenAnswer((_) async => records);
      when(mockTokenBudgetAllocator.allocate()).thenReturn(const TokenBudgetAllocator().allocate());
      when(mockTruncationStrategy.truncateToFit(any, availableTokens: anyNamed('availableTokens'), formatter: anyNamed('formatter'), maxRecords: anyNamed('maxRecords')))
          .thenAnswer((invocation) => invocation.positionalArguments[0]); // Return input as-is for test
      
      // Execute
      final context = await builder.build(
        'health',
        userQuery: '', // Empty query
      );
      
      // Verify
      expect(context.spaceId, 'health');
      verifyNever(mockQueryAnalyzer.analyze(any));
      verifyNever(mockIntentDrivenRetriever.retrieve(
        query: anyNamed('query'),
        candidateRecords: anyNamed('candidateRecords'),
        activeSpaceId: anyNamed('activeSpaceId'),
      )); // Should not use intent-driven retrieval
      verify(mockRelevanceScorer.sortByRelevance(any)).called(1); // Should use traditional approach
    });
  });
}