# Design Document

## Overview

This design introduces an optional AI summarization capability to the Universal Life Companion app. The system will allow users to generate concise, compassionate summaries of their Information Items through a clean abstraction layer that keeps AI logic separate from UI and business rules. The architecture supports multiple AI service implementations (Fake for testing, HTTP for production) and comprehensive logging for diagnostics, all while maintaining the app's local-first, privacy-focused principles.

## Architecture

### Current System (Before AI)

```
User
  ↓
Information Item Detail Screen
  ↓
Information Item Entity (title, category, tags, notes, attachments)
  ↓
Local Storage (Isar)
```

### Proposed System (With AI)

```
User
  ↓
Information Item Detail Screen
  ↓
AI Summary Widget (loading/success/error states)
  ↓
SummarizeInformationItemUseCase (Application Layer)
  ↓
AiService Interface (Port)
  ↓
┌─────────────────────────────────────┐
│ AI Service Implementations:         │
│ - FakeAiService (deterministic)     │
│ - LoggingAiService (decorator)      │
│ - HttpAiService (real backend)      │
└─────────────────────────────────────┘
  ↓
Backend Proxy (HTTPS)
  ↓
AI Provider (Together AI, OpenAI, etc.)
```

### Layer Responsibilities

**Domain Layer:**
- `AiSummaryResult` value object (immutable, contains summary text, action hints, metadata)
- No AI-specific business logic (AI is a capability, not domain concept)

**Application Layer:**
- `SummarizeInformationItemUseCase` - orchestrates AI requests
- `AiService` port (interface) - defines contract for AI operations
- Input/Output DTOs for use case boundaries

**Infrastructure Layer:**
- `FakeAiService` - deterministic implementation for development
- `LoggingAiService` - diagnostic decorator
- `HttpAiService` - real HTTP-backed implementation
- Configuration management (feature flags, API keys)

**Presentation Layer:**
- `InformationItemSummarySheet` widget - displays loading/success/error
- View models/controllers - manage AI operation state
- Consent dialog - explains data usage

## Components and Interfaces

### 1. AiService Interface (Port)

```dart
/// Port for AI operations
abstract class AiService {
  /// Generates a summary for the given Information Item
  /// 
  /// Returns AiSummaryResult containing summary text, action hints, and metadata
  /// Throws AiServiceException on failure
  Future<AiSummaryResult> summarizeItem(InformationItem item);
}
```

### 2. AiSummaryResult (Value Object)

```dart
/// Immutable result from AI summarization
class AiSummaryResult {
  final String summaryText;           // ≤120 words
  final List<String> actionHints;     // Up to 3 hints, each ≤12 words
  final int tokensUsed;                // Token count for cost tracking
  final int latencyMs;                 // Response time in milliseconds
  final String provider;               // e.g., 'together', 'openai', 'fake'
  final double confidence;             // 0.0 to 1.0
  final AiError? error;                // Null if successful
  
  const AiSummaryResult({
    required this.summaryText,
    required this.actionHints,
    required this.tokensUsed,
    required this.latencyMs,
    required this.provider,
    required this.confidence,
    this.error,
  });
  
  bool get isSuccess => error == null;
  bool get hasActionHints => actionHints.isNotEmpty;
}

/// Error information from AI operations
class AiError {
  final String message;
  final bool isRetryable;
  final String? errorCode;
  
  const AiError({
    required this.message,
    required this.isRetryable,
    this.errorCode,
  });
}
```

### 3. SummarizeInformationItemUseCase

```dart
/// Use case for generating AI summaries of Information Items
class SummarizeInformationItemUseCase {
  final AiService _aiService;
  final AiConsentRepository _consentRepository;
  
  SummarizeInformationItemUseCase({
    required AiService aiService,
    required AiConsentRepository consentRepository,
  }) : _aiService = aiService,
       _consentRepository = consentRepository;
  
  Future<AiSummaryResult> execute(String itemId) async {
    // Check consent
    final hasConsent = await _consentRepository.hasAiConsent();
    if (!hasConsent) {
      throw AiConsentRequiredException();
    }
    
    // Load item
    final item = await _itemRepository.getById(itemId);
    if (item == null) {
      throw ItemNotFoundException(itemId);
    }
    
    // Generate summary
    return await _aiService.summarizeItem(item);
  }
}
```

### 4. FakeAiService (Test Implementation)

```dart
/// Deterministic AI service for development and testing
class FakeAiService implements AiService {
  final Duration simulatedLatency;
  final bool shouldFail;
  
  const FakeAiService({
    this.simulatedLatency = const Duration(milliseconds: 500),
    this.shouldFail = false,
  });
  
  @override
  Future<AiSummaryResult> summarizeItem(InformationItem item) async {
    await Future.delayed(simulatedLatency);
    
    if (shouldFail) {
      return AiSummaryResult(
        summaryText: '',
        actionHints: [],
        tokensUsed: 0,
        latencyMs: simulatedLatency.inMilliseconds,
        provider: 'fake',
        confidence: 0.0,
        error: AiError(
          message: 'Simulated failure for testing',
          isRetryable: true,
        ),
      );
    }
    
    // Generate deterministic summary from item data
    final summary = _generateFakeSummary(item);
    final hints = _generateFakeHints(item);
    
    return AiSummaryResult(
      summaryText: summary,
      actionHints: hints,
      tokensUsed: 150,  // Fake token count
      latencyMs: simulatedLatency.inMilliseconds,
      provider: 'fake',
      confidence: 0.95,
    );
  }
  
  String _generateFakeSummary(InformationItem item) {
    // Use first sentence of notes + title
    final firstSentence = item.notes?.split('.').first ?? '';
    return '${item.title}. $firstSentence.';
  }
  
  List<String> _generateFakeHints(InformationItem item) {
    return [
      'Review this ${item.category} entry',
      'Add more details if needed',
      'Share with relevant contacts',
    ];
  }
}
```

### 5. LoggingAiService (Decorator)

```dart
/// Decorator that adds diagnostic logging to any AiService
class LoggingAiService implements AiService {
  final AiService _wrapped;
  
  const LoggingAiService(this._wrapped);
  
  @override
  Future<AiSummaryResult> summarizeItem(InformationItem item) async {
    final startTime = DateTime.now();
    final opId = AppLogger.startOperation('ai_summarize_item');
    
    await AppLogger.info('AI summarization started', context: {
      'itemId': item.id,
      'spaceId': item.spaceId,
      'category': item.category,
      'hasNotes': item.notes != null,
      'attachmentCount': item.attachments.length,
    });
    
    try {
      final result = await _wrapped.summarizeItem(item);
      
      await AppLogger.endOperation(opId);
      
      await AppLogger.info('AI summarization completed', context: {
        'itemId': item.id,
        'success': result.isSuccess,
        'tokensUsed': result.tokensUsed,
        'latencyMs': result.latencyMs,
        'provider': result.provider,
        'confidence': result.confidence,
        'summaryLength': result.summaryText.length,
        'actionHintCount': result.actionHints.length,
      });
      
      return result;
    } catch (e, stackTrace) {
      await AppLogger.endOperation(opId);
      
      await AppLogger.error('AI summarization failed', 
        error: e,
        stackTrace: stackTrace,
        context: {
          'itemId': item.id,
          'spaceId': item.spaceId,
          'duration': DateTime.now().difference(startTime).inMilliseconds,
        },
      );
      
      rethrow;
    }
  }
}
```

### 6. HttpAiService (Production Implementation)

```dart
/// HTTP-backed AI service that communicates with backend proxy
class HttpAiService implements AiService {
  final http.Client _client;
  final String _baseUrl;
  final Duration _timeout;
  final int _maxRetries;
  
  HttpAiService({
    required http.Client client,
    required String baseUrl,
    Duration timeout = const Duration(seconds: 30),
    int maxRetries = 3,
  }) : _client = client,
       _baseUrl = baseUrl,
       _timeout = timeout,
       _maxRetries = maxRetries;
  
  @override
  Future<AiSummaryResult> summarizeItem(InformationItem item) async {
    final request = _buildRequest(item);
    final response = await _sendWithRetry(request);
    return _parseResponse(response);
  }
  
  Map<String, dynamic> _buildRequest(InformationItem item) {
    return {
      'space': item.spaceName,
      'title': item.title,
      'category': item.category,
      'tags': item.tags,
      'body': item.notes ?? '',
      'attachments': item.attachments.map((a) => {
        'type': a.kind,
        'name': a.filename,
      }).toList(),
    };
  }
  
  Future<http.Response> _sendWithRetry(Map<String, dynamic> request) async {
    int attempts = 0;
    Duration backoff = const Duration(seconds: 1);
    
    while (attempts < _maxRetries) {
      try {
        final response = await _client
            .post(
              Uri.parse('$_baseUrl/ai/summarize'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(request),
            )
            .timeout(_timeout);
        
        if (response.statusCode == 200) {
          return response;
        } else if (response.statusCode >= 500) {
          // Server error - retry
          attempts++;
          if (attempts < _maxRetries) {
            await Future.delayed(backoff);
            backoff *= 2;  // Exponential backoff
          }
        } else {
          // Client error - don't retry
          throw AiServiceException(
            'HTTP ${response.statusCode}: ${response.body}',
            isRetryable: false,
          );
        }
      } on TimeoutException {
        attempts++;
        if (attempts >= _maxRetries) {
          throw AiServiceException(
            'Request timed out after $_timeout',
            isRetryable: true,
          );
        }
        await Future.delayed(backoff);
        backoff *= 2;
      }
    }
    
    throw AiServiceException(
      'Max retries exceeded',
      isRetryable: false,
    );
  }
  
  AiSummaryResult _parseResponse(http.Response response) {
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    
    return AiSummaryResult(
      summaryText: json['summary'] as String,
      actionHints: (json['actionHints'] as List<dynamic>)
          .map((h) => h as String)
          .toList(),
      tokensUsed: json['tokensUsed'] as int,
      latencyMs: json['latencyMs'] as int,
      provider: json['provider'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}
```

### 7. UI Components

```dart
/// Widget that displays AI summary with loading/success/error states
class InformationItemSummarySheet extends StatelessWidget {
  final String itemId;
  final VoidCallback onClose;
  
  const InformationItemSummarySheet({
    required this.itemId,
    required this.onClose,
  });
  
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final summaryState = ref.watch(aiSummaryProvider(itemId));
        
        return summaryState.when(
          loading: () => _buildLoading(),
          success: (result) => _buildSuccess(result),
          error: (error) => _buildError(error),
        );
      },
    );
  }
  
  Widget _buildLoading() {
    return Column(
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Generating summary...'),
      ],
    );
  }
  
  Widget _buildSuccess(AiSummaryResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Summary', style: AppTextStyles.h3),
        SizedBox(height: 8),
        Text(result.summaryText),
        if (result.hasActionHints) ...[
          SizedBox(height: 16),
          Text('Suggested Actions', style: AppTextStyles.h4),
          ...result.actionHints.map((hint) => 
            Padding(
              padding: EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.arrow_forward, size: 16),
                  SizedBox(width: 8),
                  Expanded(child: Text(hint)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildError(AiError error) {
    return Column(
      children: [
        Icon(Icons.error_outline, size: 48, color: Colors.red),
        SizedBox(height: 16),
        Text('Failed to generate summary'),
        SizedBox(height: 8),
        Text(error.message, style: TextStyle(color: Colors.grey)),
        if (error.isRetryable) ...[
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _retry(),
            child: Text('Retry'),
          ),
        ],
      ],
    );
  }
}
```

## Data Models

### AiSummaryResult

Immutable value object containing:
- `summaryText`: String (≤120 words)
- `actionHints`: List<String> (up to 3, each ≤12 words)
- `tokensUsed`: int
- `latencyMs`: int
- `provider`: String
- `confidence`: double (0.0-1.0)
- `error`: AiError? (null if successful)

### AiError

Immutable error information:
- `message`: String (user-friendly error description)
- `isRetryable`: bool (whether user should retry)
- `errorCode`: String? (optional technical error code)

### AI Request Payload (HTTP)

```json
{
  "space": "health",
  "title": "Latest cardiology visit",
  "category": "Visit",
  "tags": ["cardiology", "bp"],
  "body": "...note text...",
  "attachments": [
    {"type": "pdf", "name": "lab_results.pdf"}
  ]
}
```

### AI Response Payload (HTTP)

```json
{
  "summary": "Short paragraph...",
  "actionHints": ["Schedule follow-up in 3 months"],
  "tokensUsed": 1250,
  "latencyMs": 1800,
  "provider": "together",
  "confidence": 0.82
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Summary Length Constraint

*For any* Information Item, when summarization succeeds, the summary text length should be 120 words or fewer.

**Validates: Requirements 1.3**

### Property 2: Action Hints Constraint

*For any* Information Item, when summarization succeeds with action hints, there should be at most 3 hints and each hint should be 12 words or fewer.

**Validates: Requirements 1.4**

### Property 3: Consent Enforcement

*For any* AI operation request, if the user has not granted AI consent, the operation should fail with AiConsentRequiredException.

**Validates: Requirements 2.1, 2.5**

### Property 4: Data Privacy

*For any* AI request payload, the payload should never contain Information Item IDs or attachment binary data.

**Validates: Requirements 2.4**

### Property 5: Service Substitutability

*For any* AI service implementation (Fake, Logging, HTTP), when given the same Information Item, all implementations should return AiSummaryResult objects with the same structure (even if content differs).

**Validates: Requirements 3.1, 3.2, 3.3, 3.4**

### Property 6: Logging Completeness

*For any* AI operation, when wrapped in LoggingAiService, there should be exactly one start log entry and one end log entry (success or error).

**Validates: Requirements 5.1, 5.2, 5.3**

### Property 7: Timeout Enforcement

*For any* HTTP AI request, if the request exceeds 30 seconds, the operation should timeout and return an error with isRetryable=true.

**Validates: Requirements 6.1, 6.2**

### Property 8: Exponential Backoff

*For any* failed HTTP AI request, retry delays should follow exponential backoff pattern: 1s, 2s, 4s (up to max 3 retries).

**Validates: Requirements 6.4**

### Property 9: Feature Flag Respect

*For any* UI state, when ai_enabled flag is false, no AI UI elements should be visible.

**Validates: Requirements 9.1, 9.3**

### Property 10: Space Context Inclusion

*For any* AI request, the request payload should include the Space name and category from the Information Item.

**Validates: Requirements 10.1, 10.2**

## Error Handling

### Error Categories

1. **Consent Errors**
   - `AiConsentRequiredException` - User hasn't granted AI consent
   - Recovery: Show consent dialog

2. **Network Errors**
   - `TimeoutException` - Request exceeded 30s timeout
   - `NetworkException` - No connectivity
   - Recovery: Retry with exponential backoff

3. **Server Errors**
   - `ServerException` (5xx) - Backend or AI provider failure
   - Recovery: Retry up to 3 times

4. **Client Errors**
   - `ValidationException` (4xx) - Invalid request data
   - Recovery: Don't retry, show error to user

5. **Configuration Errors**
   - `MissingApiKeyException` - API key not configured
   - Recovery: Show configuration error to admin

### Error Handling Strategy

```dart
try {
  final result = await summarizeUseCase.execute(itemId);
  // Handle success
} on AiConsentRequiredException {
  // Show consent dialog
  showConsentDialog();
} on TimeoutException {
  // Show timeout error with retry
  showError('Request timed out', canRetry: true);
} on NetworkException {
  // Show network error
  showError('No internet connection', canRetry: true);
} on ServerException {
  // Show server error
  showError('Service temporarily unavailable', canRetry: true);
} on ValidationException catch (e) {
  // Show validation error (don't retry)
  showError(e.message, canRetry: false);
} catch (e) {
  // Unknown error
  showError('An unexpected error occurred', canRetry: false);
  AppLogger.error('Unexpected AI error', error: e);
}
```

## Testing Strategy

### Unit Tests

1. **AiSummaryResult Tests**
   - Test immutability
   - Test validation (word counts, constraints)
   - Test JSON serialization/deserialization

2. **FakeAiService Tests**
   - Test deterministic summary generation
   - Test simulated latency
   - Test simulated failures

3. **LoggingAiService Tests**
   - Test log entries are created
   - Test operation tracking
   - Test error logging

4. **HttpAiService Tests**
   - Test request payload construction
   - Test response parsing
   - Test retry logic with exponential backoff
   - Test timeout handling
   - Mock HTTP client for isolation

5. **SummarizeInformationItemUseCase Tests**
   - Test consent checking
   - Test item loading
   - Test error propagation
   - Mock AiService and repositories

### Widget Tests

1. **InformationItemSummarySheet Tests**
   - Test loading state rendering
   - Test success state rendering
   - Test error state rendering
   - Test retry button functionality

### Integration Tests

1. **End-to-End Flow**
   - User taps "Generate Summary"
   - Loading indicator appears
   - Summary displays after completion
   - Action hints are clickable

2. **Error Recovery**
   - Simulate network failure
   - Verify error message
   - Verify retry button
   - Verify successful retry

### Property-Based Tests

1. **Property 1: Summary Length**
   - Generate random Information Items
   - Call FakeAiService.summarizeItem()
   - Assert summary.split(' ').length <= 120

2. **Property 3: Consent Enforcement**
   - Generate random consent states
   - Call use case with various consent values
   - Assert exception thrown when consent=false

3. **Property 8: Exponential Backoff**
   - Simulate multiple failures
   - Track retry delays
   - Assert delays follow 1s, 2s, 4s pattern

### Manual Testing

1. **Quality Evaluation**
   - Use test fixtures from `docs/ai/fixtures/`
   - Generate summaries for each fixture
   - Evaluate tone, length, correctness, relevance
   - Document findings in `docs/ai/ai_quality_journal.md`

2. **Performance Testing**
   - Measure latency for various item sizes
   - Test with slow network conditions
   - Verify timeout behavior

3. **Consent Flow Testing**
   - Test first-time AI usage
   - Test consent dialog
   - Test disabling AI features
   - Verify UI elements hide/show correctly

## Implementation Notes

### Dependency Injection

Register AI services in `AppContainer`:

```dart
class AppContainer {
  late final AiService aiService;
  
  Future<void> bootstrap() async {
    // Load configuration
    final config = await _loadAiConfig();
    
    // Create base service
    AiService baseService;
    if (config.aiMode == 'fake') {
      baseService = FakeAiService();
    } else {
      baseService = HttpAiService(
        client: http.Client(),
        baseUrl: config.backendUrl,
      );
    }
    
    // Wrap with logging
    aiService = LoggingAiService(baseService);
  }
}
```

### Feature Flags

Store in SharedPreferences:

```dart
class AiConfigRepository {
  final SharedPreferences _prefs;
  
  bool get aiEnabled => _prefs.getBool('ai_enabled') ?? false;
  String get aiMode => _prefs.getString('ai_mode') ?? 'fake';
  
  Future<void> setAiEnabled(bool enabled) async {
    await _prefs.setBool('ai_enabled', enabled);
  }
  
  Future<void> setAiMode(String mode) async {
    await _prefs.setString('ai_mode', mode);
  }
}
```

### Logging Requirements

Per `.kiro/steering/logging-guidelines.md`:
- Use `AppLogger.startOperation()` / `endOperation()` for AI operations
- Log with context: itemId, spaceId, tokensUsed, latencyMs, provider
- Redact sensitive text (notes content) from logs
- Include error details with stack traces

### Clean Architecture Compliance

Per `CLEAN_ARCHITECTURE_GUIDE.md`:
- Domain layer: Value objects only (AiSummaryResult, AiError)
- Application layer: Use cases and ports (SummarizeInformationItemUseCase, AiService interface)
- Infrastructure layer: Implementations (FakeAiService, HttpAiService, LoggingAiService)
- Presentation layer: Widgets and view models (InformationItemSummarySheet)

## Design Decisions

### Decision 1: Use Decorator Pattern for Logging

**Rationale:** LoggingAiService wraps any AiService implementation, allowing logging to be added/removed without modifying service implementations. This follows Open/Closed Principle and makes logging optional.

**Trade-off:** Adds one extra layer of indirection, but the flexibility and testability benefits outweigh the minimal complexity.

### Decision 2: Fake Service Returns Deterministic Results

**Rationale:** Deterministic behavior makes tests predictable and allows development without external dependencies. Developers can work on UI and integration without waiting for real AI.

**Trade-off:** Fake summaries won't match real AI quality, but this is acceptable for development and testing purposes.

### Decision 3: 30-Second Timeout for HTTP Requests

**Rationale:** AI operations can be slow, but 30 seconds is a reasonable upper bound for user patience. Longer timeouts would make the app feel unresponsive.

**Trade-off:** Some complex summarizations might need more time, but we prioritize responsiveness over completeness.

### Decision 4: Maximum 3 Retries with Exponential Backoff

**Rationale:** Exponential backoff (1s, 2s, 4s) gives transient failures time to resolve without overwhelming the backend. 3 retries balances persistence with user patience.

**Trade-off:** Total retry time could reach ~7 seconds, but this is acceptable for an optional feature.

### Decision 5: Separate Consent Repository

**Rationale:** Consent management is a cross-cutting concern that may be used by multiple AI features in the future. Separating it into its own repository makes it reusable.

**Trade-off:** Adds another dependency to inject, but improves separation of concerns.

### Decision 6: No Caching of AI Results

**Rationale:** For v1, we generate summaries on-demand. Caching would add complexity around invalidation (when item changes) and storage.

**Trade-off:** Users must wait for regeneration if they close and reopen the summary. Future versions can add caching if needed.

## Performance Impact Estimation

### Expected Latencies

- **FakeAiService**: 500ms (simulated)
- **HttpAiService**: 1-3 seconds (network + AI processing)
- **Worst case**: 30 seconds (timeout)

### Resource Usage

- **Memory**: Minimal (AiSummaryResult is small, ~1KB)
- **Network**: ~2-5KB per request (JSON payload)
- **Tokens**: ~150-500 tokens per summarization (depends on item size)

### UI Impact

- Loading indicator prevents UI blocking
- Async operations don't freeze the app
- Error states allow graceful degradation

## References

- `docs/ai/ai_integration_plan.md` - Original integration plan
- `.kiro/steering/logging-guidelines.md` - Logging requirements
- `CLEAN_ARCHITECTURE_GUIDE.md` - Architecture patterns
- `AGENTS.md` - Development guidelines
- `DIAGNOSTIC_SYSTEM_INTEGRATION.md` - Diagnostic system integration
