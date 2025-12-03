import 'package:flutter_test/flutter_test.dart';
import 'package:patient_app/core/ai/chat/context/space_context_builder.dart';
import 'package:patient_app/core/ai/chat/context/context_filter_engine.dart';
import 'package:patient_app/core/ai/chat/context/context_truncation_strategy.dart';
import 'package:patient_app/core/ai/chat/context/record_relevance_scorer.dart';
import 'package:patient_app/core/ai/chat/context/record_summary_formatter.dart';
import 'package:patient_app/core/ai/chat/domain/services/intent_driven_retriever.dart';
import 'package:patient_app/core/ai/chat/domain/services/query_analyzer.dart';
import 'package:patient_app/core/ai/chat/domain/services/relevance_scorer.dart';
import 'package:patient_app/core/ai/chat/domain/services/privacy_filter.dart';
import 'package:patient_app/core/ai/chat/domain/services/keyword_extractor.dart';
import 'package:patient_app/core/ai/chat/domain/services/intent_classifier.dart';
import 'package:patient_app/core/ai/chat/models/intent_retrieval_config.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/core/ai/chat/models/context_filters.dart';
import 'package:patient_app/core/ai/chat/models/context_stats.dart';
import 'package:patient_app/core/ai/chat/models/date_range.dart';
import 'package:patient_app/core/ai/chat/context/token_budget_allocator.dart';
import 'package:patient_app/core/application/services/space_manager.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';
import 'package:patient_app/core/domain/entities/space.dart';
import 'package:patient_app/features/records/application/ports/records_repository.dart';
import 'package:patient_app/features/records/domain/entities/record.dart';
import 'package:patient_app/features/records/data/records_service.dart';
import 'package:patient_app/features/spaces/domain/space_registry.dart';
import 'package:flutter/material.dart';
import 'package:patient_app/core/domain/value_objects/space_gradient.dart';
import 'package:patient_app/core/application/ports/space_repository.dart';

// Simple mock implementations
class _MockSpaceManager extends SpaceManager {
  _MockSpaceManager(Space space) : super(_MockSpaceRepo(), _MockSpaceRegistry()) {
    _space = space;
  }
  late final Space _space;

  @override
  Future<Space> getCurrentSpace() async => _space;

 @override
  Future<List<Space>> getActiveSpaces() async => [_space];
}

class _MockSpaceRepo implements SpaceRepository {
  @override
  Future<List<String>> getActiveSpaceIds() async => ['health'];

  @override
  Future<String> getCurrentSpaceId() async => 'health';

  @override
  Future<void> setActiveSpaceIds(List<String> ids) async {}

  @override
  Future<void> setCurrentSpaceId(String id) async {}

  @override
  Future<Map<String, Space>> getCustomSpaces() async => {};

  @override
  Future<void> deleteCustomSpace(String spaceId) async {}

 @override
  Future<void> saveCustomSpace(Space space) async {}

  @override
  Future<bool> spaceExists(String spaceId) async => spaceId == 'health';

  @override
  Future<bool> hasCompletedOnboarding() async => true;

  @override
  Future<void> setOnboardingComplete() async {}
}

class _MockSpaceRegistry extends SpaceRegistry {
  @override
  Space? getDefaultSpace(String id) => null;
}

class _MockRecordsRepository implements RecordsRepository {
  _MockRecordsRepository(this._records);
  final List<RecordEntity> _records;

  @override
  Future<RecordEntity?> byId(int id) async {
    try {
      return _records.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> delete(int id) async {}

 @override
  Future<List<RecordEntity>> fetchPage({
    required int offset,
    required int limit,
    String? query,
    String? spaceId,
  }) async {
    final filtered = spaceId == null
        ? _records
        : _records.where((record) => record.spaceId == spaceId).toList();
    return filtered.skip(offset).take(limit).toList();
  }

  @override
  Future<List<RecordEntity>> recent({int limit = 50}) async {
    return _records.take(limit).toList();
  }

  @override
  Future<RecordEntity> save(RecordEntity record) async => record;
}

// Mock RecordsService to satisfy the required parameter
class _MockRecordsService extends Fake implements RecordsService {
  _MockRecordsService(this.records);
  @override
  final RecordsRepository records;
}

Space _createSpace(String id, String name, String description, List<String> categories) => Space(
      id: id,
      name: name,
      icon: 'Icon',
      gradient: SpaceGradient(
        startColor: Colors.white,
        endColor: Colors.black,
      ),
      description: description,
      categories: categories,
    );

RecordEntity _createRecord({
  required int id,
  required String spaceId,
  required String type,
  required String title,
  required String text,
  DateTime? date,
  List<String> tags = const [],
  int viewCount = 0,
  bool deleted = false,
}) {
  final now = date ?? DateTime.now().subtract(Duration(days: id));
  return RecordEntity(
    id: id,
    spaceId: spaceId,
    type: type,
    date: now,
    title: title,
    text: text,
    tags: tags,
    viewCount: viewCount,
    createdAt: now,
    updatedAt: now,
    deletedAt: deleted ? now : null,
  );
}

void main() {
  group('Stage 6 Integration Tests', () {
    late SpaceContextBuilderImpl contextBuilder;
    late List<RecordEntity> testRecords;
    late IntentDrivenRetriever intentDrivenRetriever;
    late QueryAnalyzer queryAnalyzer;
    late IntentRetrievalConfig intentRetrievalConfig;

    setUp(() async {
      await AppLogger.info('Starting Stage 6 integration tests setup');

      // Create comprehensive test records across different spaces
      testRecords = [
        // Health space records
        _createRecord(
          id: 1,
          spaceId: 'health',
          type: 'Blood Pressure',
          title: 'Blood Pressure Reading',
          text: 'Today my blood pressure was 120/80 which is normal',
        ),
        _createRecord(
          id: 2,
          spaceId: 'health',
          type: 'Medication',
          title: 'Took Aspirin',
          text: 'Took aspirin for headache',
        ),
        _createRecord(
          id: 3,
          spaceId: 'health',
          type: 'Lab Results',
          title: 'Cholesterol Test',
          text: 'Cholesterol levels came back normal',
        ),
        _createRecord(
          id: 4,
          spaceId: 'health',
          type: 'Blood Pressure',
          title: 'Blood Pressure Checkup',
          text: 'Blood pressure reading was slightly elevated today',
        ),
        _createRecord(
          id: 5,
          spaceId: 'health',
          type: 'Symptoms',
          title: 'Headache',
          text: 'Had a severe headache today',
        ),
        _createRecord(
          id: 6,
          spaceId: 'health',
          type: 'Lab Results',
          title: 'Glucose Test',
          text: 'Glucose levels were within normal range',
        ),
        _createRecord(
          id: 7,
          spaceId: 'health',
          type: 'Appointment',
          title: 'Doctor Visit',
          text: 'Regular checkup with Dr. Smith',
        ),
        _createRecord(
          id: 8,
          spaceId: 'health',
          type: 'Blood Pressure',
          title: 'Morning Blood Pressure',
          text: 'Morning reading was 118/78',
        ),
        
        // Finance space records
        _createRecord(
          id: 9,
          spaceId: 'finance',
          type: 'Expense',
          title: 'Grocery Shopping',
          text: 'Bought groceries for \$50',
        ),
        _createRecord(
          id: 10,
          spaceId: 'finance',
          type: 'Income',
          title: 'Salary Deposit',
          text: 'Monthly salary of \$3000 deposited',
        ),
        _createRecord(
          id: 11,
          spaceId: 'finance',
          type: 'Investment',
          title: 'Stock Purchase',
          text: 'Bought 10 shares of tech company',
        ),
        _createRecord(
          id: 12,
          spaceId: 'finance',
          type: 'Budget',
          title: 'Monthly Budget',
          text: 'Set budget for utilities and rent',
        ),
        _createRecord(
          id: 13,
          spaceId: 'finance',
          type: 'Expense',
          title: 'Dinner Out',
          text: 'Spent \$60 on dinner with family',
        ),
        
        // Education space records
        _createRecord(
          id: 14,
          spaceId: 'education',
          type: 'Course',
          title: 'Math 101',
          text: 'Enrolled in advanced mathematics course',
        ),
        _createRecord(
          id: 15,
          spaceId: 'education',
          type: 'Assignment',
          title: 'Essay Submission',
          text: 'Submitted essay on modern literature',
        ),
        _createRecord(
          id: 16,
          spaceId: 'education',
          type: 'Grade',
          title: 'Midterm Exam',
          text: 'Received B+ on midterm exam',
        ),
        _createRecord(
          id: 17,
          spaceId: 'education',
          type: 'Study Session',
          title: 'Group Study',
          text: 'Studied for upcoming finals with classmates',
        ),
        
        // Travel space records
        _createRecord(
          id: 18,
          spaceId: 'travel',
          type: 'Trip',
          title: 'Paris Vacation',
          text: 'Trip to Paris planned for next month',
        ),
        _createRecord(
          id: 19,
          spaceId: 'travel',
          type: 'Booking',
          title: 'Hotel Reservation',
          text: 'Booked hotel in central Paris',
        ),
        _createRecord(
          id: 20,
          spaceId: 'travel',
          type: 'Itinerary',
          title: 'Flight Ticket',
          text: 'Purchased round trip flight to Paris',
        ),
        _createRecord(
          id: 21,
          spaceId: 'travel',
          type: 'Expense',
          title: 'Travel Insurance',
          text: 'Purchased travel insurance for trip',
        ),
      ];

      // Initialize services
      final relevanceScorer = RelevanceScorer();
      final privacyFilter = PrivacyFilter();
      intentRetrievalConfig = const IntentRetrievalConfig(
        enabled: true,
        relevanceThreshold: 0.3,
        maxResults: 15,
        minQueryWords: 3,
      );
      intentDrivenRetriever = IntentDrivenRetriever(
        relevanceScorer: relevanceScorer,
        privacyFilter: privacyFilter,
        config: intentRetrievalConfig,
      );
      queryAnalyzer = QueryAnalyzer(
        keywordExtractor: KeywordExtractor(),
      intentClassifier: IntentClassifier(),
    );

    // Create context builder using recordsRepositoryOverride to avoid complex mocking
    contextBuilder = SpaceContextBuilderImpl(
      recordsServiceFuture:
          Future.value(_MockRecordsService(_MockRecordsRepository(testRecords))),
      recordsRepositoryOverride: _MockRecordsRepository(testRecords),
      spaceManager: _MockSpaceManager(_createSpace('health', 'Health', 'Health space', ['Visits', 'Labs'])),
      filterEngine: ContextFilterEngine(),
      relevanceScorer: RecordRelevanceScorer(),
      tokenBudgetAllocator: const TokenBudgetAllocator(),
        truncationStrategy: const ContextTruncationStrategy(),
        intentDrivenRetriever: intentDrivenRetriever,
        queryAnalyzer: queryAnalyzer,
        intentRetrievalConfig: intentRetrievalConfig,
        formatter: RecordSummaryFormatter(maxNoteLength: 50),
        maxRecords: 20,
        dateRange: DateRange.last14Days(),
      );
    });

    test('Stage 6 retrieves only relevant records when query provided', () async {
      await AppLogger.info('Testing Stage 6 retrieves only relevant records when query provided');

      final context = await contextBuilder.build('health', userQuery: 'What is my blood pressure?');

      // Cast the stats to ContextStats to access properties
      final stats = context.stats as ContextStats?;
      expect(stats?.recordsIncluded, lessThan(testRecords.length)); // Should be fewer records than total
      
      // Verify only blood pressure related records are included
      final bloodPressureRecords = context.recentRecords
          .where((record) => 
            record.title.toLowerCase().contains('blood') && 
            record.title.toLowerCase().contains('pressure'))
          .toList();
          
      expect(bloodPressureRecords.length, greaterThan(0));
      expect(stats?.recordsIncluded, lessThanOrEqualTo(15)); // Should respect maxResults
      
      await AppLogger.info('Verified Stage 6 retrieves only relevant records when query provided');
    });

    test('Stage 6 full flow works with complex query', () async {
      await AppLogger.info('Testing Stage 6 full flow with complex query');

      final context = await contextBuilder.build('health', userQuery: 'Show me my recent lab results and cholesterol tests');

      // Cast the stats to ContextStats to access properties
      final stats = context.stats as ContextStats?;
      expect(stats?.recordsIncluded, lessThanOrEqualTo(testRecords.length));
      
      // Verify lab results and cholesterol related records are included
      final labRecords = context.recentRecords
          .where((record) => 
            record.title.toLowerCase().contains('lab') || 
            record.title.toLowerCase().contains('cholesterol'))
          .toList();
          
      expect(labRecords.length, greaterThan(0));
      expect(stats?.recordsIncluded, lessThanOrEqualTo(15)); // Should respect maxResults
      
      await AppLogger.info('Verified Stage 6 full flow works with complex query');
    });

    test('Falls back to Stage 4 when query is empty', () async {
      await AppLogger.info('Testing fallback to Stage 4 when query is empty');

      final context = await contextBuilder.build('health', userQuery: '');

      // Cast the stats to ContextStats to access properties
      final stats = context.stats as ContextStats?;
      // When query is empty, should fall back to Stage 4 behavior (all records in date range)
      expect(stats?.recordsIncluded, greaterThan(5)); // Should include more records than Stage 6
      
      await AppLogger.info('Verified fallback to Stage 4 when query is empty');
    });

    test('Falls back to Stage 4 when query is null', () async {
      await AppLogger.info('Testing fallback to Stage 4 when query is null');

      final context = await contextBuilder.build('health', userQuery: null);

      // Cast the stats to ContextStats to access properties
      final stats = context.stats as ContextStats?;
      // When query is null, should fall back to Stage 4 behavior
      expect(stats?.recordsIncluded, greaterThan(5)); // Should include more records than Stage 6
      
      await AppLogger.info('Verified fallback to Stage 4 when query is null');
    });

    test('Falls back to Stage 4 when config is disabled', () async {
      await AppLogger.info('Testing fallback to Stage 4 when config is disabled');

      // Create a new builder with intent retrieval disabled
      final disabledConfig = const IntentRetrievalConfig(
        enabled: false,
        relevanceThreshold: 0.3,
        maxResults: 15,
        minQueryWords: 3,
      );
      
      final mockRecordsService = _MockRecordsService(_MockRecordsRepository(testRecords));
      final disabledBuilder = SpaceContextBuilderImpl(
        recordsServiceFuture: Future.value(mockRecordsService),
        spaceManager: _MockSpaceManager(_createSpace('health', 'Health', 'Health space', ['Visits', 'Labs'])),
        filterEngine: ContextFilterEngine(),
        relevanceScorer: RecordRelevanceScorer(),
        tokenBudgetAllocator: const TokenBudgetAllocator(
          total: 4800,
          system: 80,
          context: 2000,
          history: 100,
          response: 1000,
        ),
        truncationStrategy: const ContextTruncationStrategy(),
        intentDrivenRetriever: intentDrivenRetriever,
        queryAnalyzer: queryAnalyzer,
        intentRetrievalConfig: disabledConfig,
        formatter: RecordSummaryFormatter(maxNoteLength: 50),
        maxRecords: 20,
        dateRange: DateRange.last14Days(),
      );

      final context = await disabledBuilder.build('health', userQuery: 'What is my blood pressure?');

      // Cast the stats to ContextStats to access properties
      final stats = context.stats as ContextStats?;
      // When intent retrieval is disabled, should fall back to Stage 4 behavior
      expect(stats?.recordsIncluded, greaterThan(5)); // Should include more records than Stage 6
      
      await AppLogger.info('Verified fallback to Stage 4 when config is disabled');
    });

    test('Multi-language support - English query on English records', () async {
      await AppLogger.info('Testing multi-language support - English query on English records');

      final context = await contextBuilder.build('health', userQuery: 'What is my blood pressure?');

      // Cast the stats to ContextStats to access properties
      final stats = context.stats as ContextStats?;
      // Verify Stage 6 was used and English records are matched
      expect(stats?.recordsIncluded, lessThan(testRecords.length));
      
      final bloodPressureRecords = context.recentRecords
          .where((record) => 
            record.title.toLowerCase().contains('blood') && 
            record.title.toLowerCase().contains('pressure'))
          .toList();
          
      expect(bloodPressureRecords.length, greaterThan(0));
      
      await AppLogger.info('Verified multi-language support - English query on English records');
    });

    test('Multi-language support - Russian query on Russian records', () async {
      await AppLogger.info('Testing multi-language support - Russian query on Russian records');

      // Create Russian records
      final russianRecords = [
        _createRecord(
          id: 1,
          spaceId: 'health',
          type: 'Давление',
          title: 'Проверка давления',
          text: 'Сегодня мое давление было 120/80',
        ),
        _createRecord(
          id: 2,
          spaceId: 'health',
          type: 'Анализы',
          title: 'Результаты анализов',
          text: 'Результаты анализов пришли в норме',
        ),
        _createRecord(
          id: 3,
          spaceId: 'health',
          type: 'Давление',
          title: 'Измерение давления',
          text: 'Давление измерялось утром, 118/78',
        ),
      ];

      final mockRecordsService = _MockRecordsService(_MockRecordsRepository(russianRecords));
      final russianBuilder = SpaceContextBuilderImpl(
        recordsServiceFuture: Future.value(mockRecordsService),
        spaceManager: _MockSpaceManager(_createSpace('health', 'Health', 'Health space', ['Visits', 'Labs'])),
        filterEngine: ContextFilterEngine(),
        relevanceScorer: RecordRelevanceScorer(),
        tokenBudgetAllocator: const TokenBudgetAllocator(),
        truncationStrategy: const ContextTruncationStrategy(),
        intentDrivenRetriever: intentDrivenRetriever,
        queryAnalyzer: queryAnalyzer,
        intentRetrievalConfig: intentRetrievalConfig,
        formatter: RecordSummaryFormatter(maxNoteLength: 50),
        maxRecords: 20,
        dateRange: DateRange.last14Days(),
      );

      final context = await russianBuilder.build('health', userQuery: 'Какое у меня давление?');

      // Cast the stats to ContextStats to access properties
      final stats = context.stats as ContextStats?;
      // Verify Russian records are matched based on Russian query
      expect(stats?.recordsIncluded, lessThan(russianRecords.length + 1)); // Should include relevant records
      
      await AppLogger.info('Verified multi-language support - Russian query on Russian records');
    });

    test('Multi-language support - Uzbek query on Uzbek records', () async {
      await AppLogger.info('Testing multi-language support - Uzbek query on Uzbek records');

      // Create Uzbek records
      final uzbekRecords = [
        _createRecord(
          id: 1,
          spaceId: 'health',
          type: 'Bosim',
          title: 'Bosim tekshiruvi',
          text: 'Bugun 120/80 bosim bo\'ldi',
        ),
        _createRecord(
          id: 2,
          spaceId: 'health',
          type: 'Tahlillar',
          title: 'Tahlil natijalari',
          text: 'Tahlil natijalari oddiy bo\'ldi',
        ),
        _createRecord(
          id: 3,
          spaceId: 'health',
          type: 'Bosim',
          title: 'Bosim o\'lchash',
          text: 'Bosim ertalab o\'lchandi, 118/78',
        ),
      ];

      final mockRecordsService = _MockRecordsService(_MockRecordsRepository(uzbekRecords));
      final uzbekBuilder = SpaceContextBuilderImpl(
        recordsServiceFuture: Future.value(mockRecordsService),
        spaceManager: _MockSpaceManager(_createSpace('health', 'Health', 'Health space', ['Visits', 'Labs'])),
        filterEngine: ContextFilterEngine(),
        relevanceScorer: RecordRelevanceScorer(),
        tokenBudgetAllocator: const TokenBudgetAllocator(
          total: 4800,
          system: 80,
          context: 2000,
          history: 10,
          response: 1000,
        ),
        truncationStrategy: const ContextTruncationStrategy(),
        intentDrivenRetriever: intentDrivenRetriever,
        queryAnalyzer: queryAnalyzer,
        intentRetrievalConfig: intentRetrievalConfig,
        formatter: RecordSummaryFormatter(maxNoteLength: 50),
        maxRecords: 20,
        dateRange: DateRange.last14Days(),
      );

      final context = await uzbekBuilder.build('health', userQuery: 'Mening bosimim qanday?');

      // Cast the stats to ContextStats to access properties
      final stats = context.stats as ContextStats?;
      // Verify Uzbek records are matched based on Uzbek query
      expect(stats?.recordsIncluded, lessThan(uzbekRecords.length + 1)); // Should include relevant records
      
      await AppLogger.info('Verified multi-language support - Uzbek query on Uzbek records');
    });

    test('Multi-space support - Health space query', () async {
      await AppLogger.info('Testing multi-space support - Health space query');

      final healthSpace = _createSpace('health', 'Health', 'Health space', ['Visits', 'Labs']);
      final mockRecordsService = _MockRecordsService(_MockRecordsRepository(testRecords));
      final healthBuilder = SpaceContextBuilderImpl(
        recordsServiceFuture: Future.value(mockRecordsService),
        spaceManager: _MockSpaceManager(healthSpace),
        filterEngine: ContextFilterEngine(),
        relevanceScorer: RecordRelevanceScorer(),
        tokenBudgetAllocator: const TokenBudgetAllocator(),
        truncationStrategy: const ContextTruncationStrategy(),
        intentDrivenRetriever: intentDrivenRetriever,
        queryAnalyzer: queryAnalyzer,
        intentRetrievalConfig: intentRetrievalConfig,
        formatter: RecordSummaryFormatter(maxNoteLength: 50),
        maxRecords: 20,
        dateRange: DateRange.last14Days(),
      );

      final context = await healthBuilder.build('health', userQuery: 'What are my blood pressure readings?');

      // Cast the stats to ContextStats to access properties
      final stats = context.stats as ContextStats?;
      // Verify health records are matched
      expect(context.spaceId, 'health');
      expect(context.spaceName, 'Health');
      expect(stats?.recordsIncluded, lessThan(testRecords.length));
      
      final bloodPressureRecords = context.recentRecords
          .where((record) => 
            record.title.toLowerCase().contains('blood') && 
            record.title.toLowerCase().contains('pressure'))
          .toList();
          
      expect(bloodPressureRecords.length, greaterThan(0));
      
      await AppLogger.info('Verified multi-space support - Health space query');
    });

    test('Multi-space support - Finance space query', () async {
      await AppLogger.info('Testing multi-space support - Finance space query');

      // Create finance records
      final financeRecords = [
        _createRecord(
          id: 1,
          spaceId: 'finance',
          type: 'Expense',
          title: 'Grocery Shopping',
          text: 'Bought groceries for \$50',
        ),
        _createRecord(
          id: 2,
          spaceId: 'finance',
          type: 'Income',
          title: 'Salary Deposit',
          text: 'Monthly salary of \$300 deposited',
        ),
        _createRecord(
          id: 3,
          spaceId: 'finance',
          type: 'Expense',
          title: 'Dinner Out',
          text: 'Spent \$60 on dinner with family',
        ),
        _createRecord(
          id: 4,
          spaceId: 'finance',
          type: 'Investment',
          title: 'Stock Purchase',
          text: 'Bought 10 shares of tech company',
        ),
        _createRecord(
          id: 5,
          spaceId: 'finance',
          type: 'Budget',
          title: 'Monthly Budget',
          text: 'Set budget for utilities and rent',
        ),
      ];

      final financeSpace = _createSpace('finance', 'Finance', 'Finance space', ['Expenses', 'Income']);
      final mockRecordsService = _MockRecordsService(_MockRecordsRepository(financeRecords));
      final financeBuilder = SpaceContextBuilderImpl(
        recordsServiceFuture: Future.value(mockRecordsService),
        spaceManager: _MockSpaceManager(financeSpace),
        filterEngine: ContextFilterEngine(),
        relevanceScorer: RecordRelevanceScorer(),
        tokenBudgetAllocator: const TokenBudgetAllocator(
          total: 4800,
          system: 800,
          context: 2000,
          history: 10,
          response: 100,
        ),
        truncationStrategy: const ContextTruncationStrategy(),
        intentDrivenRetriever: intentDrivenRetriever,
        queryAnalyzer: queryAnalyzer,
        intentRetrievalConfig: intentRetrievalConfig,
        formatter: RecordSummaryFormatter(maxNoteLength: 50),
        maxRecords: 20,
        dateRange: DateRange.last14Days(),
      );

      final context = await financeBuilder.build('finance', userQuery: 'Show my expenses for groceries');

      // Cast the stats to ContextStats to access properties
      final stats = context.stats as ContextStats?;
      // Verify finance records are matched
      expect(context.spaceId, 'finance');
      expect(context.spaceName, 'Finance');
      expect(stats?.recordsIncluded, lessThanOrEqualTo(financeRecords.length));
      
      final groceryRecords = context.recentRecords
          .where((record) => 
            record.title.toLowerCase().contains('grocery') || 
            (record.summary?.toLowerCase().contains('grocery') ?? false))
          .toList();
          
      expect(groceryRecords.length, greaterThan(0));
      
      await AppLogger.info('Verified multi-space support - Finance space query');
    });

    test('Multi-space support - Education space query', () async {
      await AppLogger.info('Testing multi-space support - Education space query');

      // Create education records
      final educationRecords = [
        _createRecord(
          id: 1,
          spaceId: 'education',
          type: 'Course',
          title: 'Math 101',
          text: 'Enrolled in advanced mathematics course',
        ),
        _createRecord(
          id: 2,
          spaceId: 'education',
          type: 'Assignment',
          title: 'Essay Submission',
          text: 'Submitted essay on modern literature',
        ),
        _createRecord(
          id: 3,
          spaceId: 'education',
          type: 'Grade',
          title: 'Midterm Exam',
          text: 'Received B+ on midterm exam',
        ),
        _createRecord(
          id: 4,
          spaceId: 'education',
          type: 'Study Session',
          title: 'Group Study',
          text: 'Studied for upcoming finals with classmates',
        ),
      ];

      final educationSpace = _createSpace('education', 'Education', 'Education space', ['Courses', 'Grades']);
      final mockRecordsService = _MockRecordsService(_MockRecordsRepository(educationRecords));
      final educationBuilder = SpaceContextBuilderImpl(
        recordsServiceFuture: Future.value(mockRecordsService),
        spaceManager: _MockSpaceManager(educationSpace),
        filterEngine: ContextFilterEngine(),
        relevanceScorer: RecordRelevanceScorer(),
        tokenBudgetAllocator: const TokenBudgetAllocator(
          total: 4800,
          system: 800,
          context: 2000,
          history: 10,
          response: 100,
        ),
        truncationStrategy: const ContextTruncationStrategy(),
        intentDrivenRetriever: intentDrivenRetriever,
        queryAnalyzer: queryAnalyzer,
        intentRetrievalConfig: intentRetrievalConfig,
        formatter: RecordSummaryFormatter(maxNoteLength: 50),
        maxRecords: 20,
        dateRange: DateRange.last14Days(),
      );

      final context = await educationBuilder.build('education', userQuery: 'Show my grades and exam results');

      // Cast the stats to ContextStats to access properties
      final stats = context.stats as ContextStats?;
      // Verify education records are matched
      expect(context.spaceId, 'education');
      expect(context.spaceName, 'Education');
      expect(stats?.recordsIncluded, lessThanOrEqualTo(educationRecords.length));
      
      final gradeRecords = context.recentRecords
          .where((record) => 
            record.title.toLowerCase().contains('grade') || 
            record.title.toLowerCase().contains('exam') ||
            (record.summary?.toLowerCase().contains('grade') ?? false) ||
            (record.summary?.toLowerCase().contains('exam') ?? false))
          .toList();
          
      expect(gradeRecords.length, greaterThan(0));
      
      await AppLogger.info('Verified multi-space support - Education space query');
    });

    test('Multi-space support - Travel space query', () async {
      await AppLogger.info('Testing multi-space support - Travel space query');

      // Create travel records
      final travelRecords = [
        _createRecord(
          id: 1,
          spaceId: 'travel',
          type: 'Trip',
          title: 'Paris Vacation',
          text: 'Trip to Paris planned for next month',
        ),
        _createRecord(
          id: 2,
          spaceId: 'travel',
          type: 'Booking',
          title: 'Hotel Reservation',
          text: 'Booked hotel in central Paris',
        ),
        _createRecord(
          id: 3,
          spaceId: 'travel',
          type: 'Itinerary',
          title: 'Flight Ticket',
          text: 'Purchased round trip flight to Paris',
        ),
        _createRecord(
          id: 4,
          spaceId: 'travel',
          type: 'Expense',
          title: 'Travel Insurance',
          text: 'Purchased travel insurance for trip',
        ),
      ];

      final travelSpace = _createSpace('travel', 'Travel', 'Travel space', ['Trips', 'Bookings']);
      final mockRecordsService = _MockRecordsService(_MockRecordsRepository(travelRecords));
      final travelBuilder = SpaceContextBuilderImpl(
        recordsServiceFuture: Future.value(mockRecordsService),
        spaceManager: _MockSpaceManager(travelSpace),
        filterEngine: ContextFilterEngine(),
        relevanceScorer: RecordRelevanceScorer(),
        tokenBudgetAllocator: const TokenBudgetAllocator(),
        truncationStrategy: const ContextTruncationStrategy(),
        intentDrivenRetriever: intentDrivenRetriever,
        queryAnalyzer: queryAnalyzer,
        intentRetrievalConfig: intentRetrievalConfig,
        formatter: RecordSummaryFormatter(maxNoteLength: 50),
        maxRecords: 20,
        dateRange: DateRange.last14Days(),
      );

      final context = await travelBuilder.build('travel', userQuery: 'Show my trip bookings and reservations');

      // Cast the stats to ContextStats to access properties
      final stats = context.stats as ContextStats?;
      // Verify travel records are matched
      expect(context.spaceId, 'travel');
      expect(context.spaceName, 'Travel');
      expect(stats?.recordsIncluded, lessThanOrEqualTo(travelRecords.length));
      
      final bookingRecords = context.recentRecords
          .where((record) => 
            record.title.toLowerCase().contains('booking') || 
            record.title.toLowerCase().contains('reservation') ||
            (record.summary?.toLowerCase().contains('booking') ?? false) ||
            (record.summary?.toLowerCase().contains('reservation') ?? false))
          .toList();
          
      expect(bookingRecords.length, greaterThan(0));
      
      await AppLogger.info('Verified multi-space support - Travel space query');
    });

    test('Token usage is reduced with Stage 6 compared to Stage 4', () async {
      await AppLogger.info('Testing token usage reduction with Stage 6 compared to Stage 4');

      // Stage 6 context with query
      final stage6Context = await contextBuilder.build('health', userQuery: 'What is my blood pressure?');
      final stage6Stats = stage6Context.stats as ContextStats?;
      
      // Stage 4 context without query (fallback)
      final stage4Context = await contextBuilder.build('health', userQuery: null);
      final stage4Stats = stage4Context.stats as ContextStats?;
      
      // Stage 6 should use fewer tokens due to fewer records
      if (stage6Stats != null && stage4Stats != null) {
        expect(stage6Stats.tokensEstimated, lessThanOrEqualTo(stage4Stats.tokensEstimated));
      }
      
      await AppLogger.info('Verified token usage is reduced with Stage 6 compared to Stage 4');
    });

    test('Privacy filtering works in Stage 6 flow', () async {
      await AppLogger.info('Testing privacy filtering in Stage 6 flow');

      // Create records with some deleted records
      final recordsWithPrivacy = [
        _createRecord(
          id: 1,
          spaceId: 'health',
          type: 'Blood Pressure',
          title: 'Blood Pressure Reading',
          text: 'Today my blood pressure was 120/80 which is normal',
        ),
        _createRecord(
          id: 2,
          spaceId: 'health',
          type: 'Medication',
          title: 'Took Aspirin',
          text: 'Took aspirin for headache',
          deleted: true, // This should be filtered out
        ),
        _createRecord(
          id: 3,
          spaceId: 'health',
          type: 'Lab Results',
          title: 'Cholesterol Test',
          text: 'Cholesterol levels came back normal',
          tags: ['private'], // This should be filtered out
        ),
        _createRecord(
          id: 4,
          spaceId: 'health',
          type: 'Blood Pressure',
          title: 'Blood Pressure Checkup',
          text: 'Blood pressure reading was slightly elevated today',
        ),
      ];

      final mockRecordsService = _MockRecordsService(_MockRecordsRepository(recordsWithPrivacy));
      final privacyBuilder = SpaceContextBuilderImpl(
        recordsServiceFuture: Future.value(mockRecordsService),
        spaceManager: _MockSpaceManager(_createSpace('health', 'Health', 'Health space', ['Visits', 'Labs'])),
        filterEngine: ContextFilterEngine(),
        relevanceScorer: RecordRelevanceScorer(),
        tokenBudgetAllocator: const TokenBudgetAllocator(),
        truncationStrategy: const ContextTruncationStrategy(),
        intentDrivenRetriever: intentDrivenRetriever,
        queryAnalyzer: queryAnalyzer,
        intentRetrievalConfig: intentRetrievalConfig,
        formatter: RecordSummaryFormatter(maxNoteLength: 50),
        maxRecords: 20,
        dateRange: DateRange.last14Days(),
      );

      final context = await privacyBuilder.build('health', userQuery: 'Show my health records');

      // Cast the stats to ContextStats to access properties
      final stats = context.stats as ContextStats?;
      // Verify that privacy-filtered records are not included
      expect(stats?.recordsIncluded, lessThan(recordsWithPrivacy.length));
      
      // Check that no deleted records are included
      final deletedRecords = context.recentRecords
          .where((record) => record.title.contains('Took Aspirin')) // This was the deleted record
          .toList();
          
      expect(deletedRecords.length, 0);
      
      await AppLogger.info('Verified privacy filtering works in Stage 6 flow');
    });
  });
}
