# Design Document

## Overview

This design defines the first two stages of LLM integration for the Universal Life Companion's AI Chat system: HTTP Foundation (Stage 1) and Basic LLM Integration (Stage 2). These stages establish the foundational communication pipeline and enable the transition from mock AI responses to real LLM-generated content.

**Current State:** Fully functional chat UI with FakeAiChatService providing deterministic responses.

**Target State (After Stage 2):** Production-ready HTTP communication with real LLM backend generating contextual responses.

**Architecture Philosophy:**
- Incremental delivery: Each stage adds value independently
- Privacy-first: No sensitive data transmitted
- Clean architecture: Strict layer separation
- Offline-first: Graceful degradation when network unavailable
- Testable: Comprehensive test coverage at each layer

## Architecture

### Current System (with FakeAiChatService)

```
User → ChatComposer → SendChatMessageUseCase
  → FakeAiChatService (deterministic responses)
  → ChatResponse → UI Update
```

### Stage 1: HTTP Foundation

```
User → ChatComposer → SendChatMessageUseCase
  → HttpAiChatService → HTTP POST /api/v1/chat/echo
  → Backend Echo Handler → ChatResponse (echoed message)
  → HttpAiChatService → UseCase → UI Update
```

### Stage 2: Basic LLM Integration

```
User → ChatComposer → SendChatMessageUseCase
  → HttpAiChatService → HTTP POST /api/v1/chat/message
  → Backend → Construct Prompt (system + history + user message)
  → LLM API (Together AI) → LLM Response
  → Backend → Parse Response → ChatResponse
  → HttpAiChatService → UseCase → UI Update
```

## Components and Interfaces

### Stage 1 Components

#### 1. HttpAiChatService (Flutter)

**Purpose:** Implements AiChatService interface using HTTP communication.

**Responsibilities:**
- Send ChatRequest to backend via HTTP POST
- Handle timeouts (30 seconds)
- Implement retry logic with exponential backoff
- Parse ChatResponse from JSON
- Throw appropriate exceptions for errors
- Log all requests with correlation IDs

**Dependencies:**
- `http` package for HTTP client
- `AppLogger` for logging
- `NetworkInfo` for connectivity detection

**Key Methods:**
```dart
class HttpAiChatService implements AiChatService {
  final String baseUrl;
  final http.Client httpClient;
  final Duration timeout;
  
  @override
  Future<ChatResponse> sendMessage(ChatRequest request) async {
    // Generate correlation ID
    // Check network connectivity
    // Build HTTP request
    // Send with timeout
    // Retry on transient failures
    // Parse response
    // Log metrics
  }
}
```


#### 2. Backend Echo Endpoint (Stage 1)

**Purpose:** Validate HTTP connectivity without LLM integration.

**Endpoint:** `POST /api/v1/chat/echo`

**Responsibilities:**
- Receive ChatRequest
- Validate request format
- Echo message back with metadata
- Log request/response
- Return ChatResponse

**Implementation Notes:**
- No LLM calls
- Minimal processing (< 100ms)
- Used for connectivity testing

#### 3. Retry Policy (Flutter)

**Purpose:** Handle transient failures gracefully.

**Strategy:**
- Attempt 1: Immediate
- Attempt 2: 2 seconds delay
- Attempt 3: 4 seconds delay
- Max attempts: 3
- Exponential backoff with jitter

**Retryable Errors:**
- Network timeouts
- HTTP 500, 502, 503, 504
- Connection refused

**Non-Retryable Errors:**
- HTTP 400 (bad request)
- HTTP 401 (unauthorized)
- HTTP 403 (forbidden)
- Invalid JSON

#### 4. Logging Infrastructure (Both)

**Purpose:** Comprehensive observability for debugging and monitoring.

**Flutter Logging:**
```dart
await AppLogger.info('Chat request sent', context: {
  'correlationId': correlationId,
  'threadId': threadId,
  'stage': 1,
  'endpoint': '/api/v1/chat/echo',
});

await AppLogger.info('Chat response received', context: {
  'correlationId': correlationId,
  'latencyMs': latencyMs,
  'statusCode': 200,
});
```

**Backend Logging:**
```json
{
  "event": "chat_request_received",
  "correlationId": "uuid",
  "userId": "uuid",
  "threadId": "uuid",
  "timestamp": "2025-11-24T10:00:00Z"
}
```

### Stage 2 Components

#### 1. LLM Provider Integration (Backend)

**Purpose:** Connect to Together AI (or OpenAI) for response generation.

**Responsibilities:**
- Construct prompts from ChatRequest
- Call LLM API with timeout
- Parse LLM response
- Count tokens
- Handle LLM-specific errors
- Log token usage

**Provider Configuration:**
```json
{
  "provider": "together",
  "model": "meta-llama/Llama-2-70b-chat-hf",
  "apiKey": "<stored-securely>",
  "timeout": 60000,
  "maxTokens": 1000
}
```

#### 2. System Prompt Template (Backend)

**Purpose:** Define AI behavior and persona.

**Template:**
```
You are a compassionate AI companion helping users organize their personal information.

Guidelines:
- Be helpful, empathetic, and respectful
- Provide clear, concise responses
- Acknowledge uncertainty when appropriate
- Never fabricate information
- Respect user privacy

Recent conversation:
{history}

User message: {user_message}
```

**Token Budget:** 500 tokens

#### 3. Message History Manager (Backend)

**Purpose:** Include conversation context for continuity.

**Strategy:**
- Include last 3 conversation turns
- Format as alternating user/assistant messages
- Truncate older messages
- Preserve chronological order

**Example:**
```json
{
  "history": [
    {"role": "user", "content": "Hello"},
    {"role": "assistant", "content": "Hello! How can I help you today?"},
    {"role": "user", "content": "Can you help me organize my records?"}
  ]
}
```

**Token Budget:** 1000 tokens

#### 4. Token Counter (Backend)

**Purpose:** Track token usage for cost management.

**Responsibilities:**
- Count tokens in prompt
- Count tokens in response
- Log usage per request
- Alert on budget overruns

**Implementation:**
- Use provider's tokenizer (tiktoken for GPT, custom for Llama)
- Count before sending request
- Validate response token count
- Log actual vs. estimated

#### 5. Rate Limiter (Backend)

**Purpose:** Prevent abuse and control costs.

**Limits:**
- 10 requests/minute per user
- 100 requests/hour per user
- 500 requests/day per user
- 1000 requests/minute globally

**Implementation:**
- Use Redis or in-memory cache
- Sliding window algorithm
- Return HTTP 429 with retry-after header
- Log violations

## Data Models

### ChatRequest (Extended for Stage 2)

```dart
class ChatRequest {
  final String threadId;
  final String messageContent;
  final List<ChatMessage> messageHistory;  // NEW in Stage 2
  final int maxHistoryMessages;  // NEW in Stage 2
  final DateTime timestamp;
  final String userId;
  
  const ChatRequest({
    required this.threadId,
    required this.messageContent,
    this.messageHistory = const [],
    this.maxHistoryMessages = 3,
    required this.timestamp,
    required this.userId,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'threadId': threadId,
      'message': messageContent,
      'history': messageHistory.take(maxHistoryMessages).map((m) => {
        'role': m.sender == MessageSender.user ? 'user' : 'assistant',
        'content': m.content,
        'timestamp': m.timestamp.toIso8601String(),
      }).toList(),
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
    };
  }
}
```

### ChatResponse (Extended for Stage 2)

```dart
class ChatResponse {
  final String messageContent;
  final AiMetadata metadata;
  final AiError? error;
  
  const ChatResponse({
    required this.messageContent,
    required this.metadata,
    this.error,
  });
  
  bool get isSuccess => error == null;
  
  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      messageContent: json['message'],
      metadata: AiMetadata.fromJson(json['metadata']),
      error: json['error'] != null ? AiError.fromJson(json['error']) : null,
    );
  }
}

class AiMetadata {
  final int tokensUsed;  // NEW in Stage 2
  final int latencyMs;
  final String provider;  // NEW in Stage 2
  final String stage;
  
  const AiMetadata({
    required this.tokensUsed,
    required this.latencyMs,
    required this.provider,
    required this.stage,
  });
  
  factory AiMetadata.fromJson(Map<String, dynamic> json) {
    return AiMetadata(
      tokensUsed: json['tokenUsage']?['total'] ?? 0,
      latencyMs: json['processingTimeMs'],
      provider: json['llmProvider'] ?? 'echo',
      stage: json['stage'],
    );
  }
}
```

## Data Flow Diagrams

### Stage 1: Echo Flow

```
1. User types message in ChatComposer
   ↓
2. User taps send button
   ↓
3. SendChatMessageUseCase.execute()
   - Check AI consent
   - Save user message to Isar
   - Build ChatRequest
   ↓
4. HttpAiChatService.sendMessage()
   - Generate correlation ID
   - Check network connectivity
   - Build HTTP POST request
   - Set 30-second timeout
   ↓
5. HTTP Request → Backend /api/v1/chat/echo
   - Validate request format
   - Log request received
   - Echo message back
   - Log response sent
   ↓
6. Backend Response → HttpAiChatService
   - Parse JSON response
   - Extract message and metadata
   - Log response received
   ↓
7. ChatResponse → SendChatMessageUseCase
   - Save AI message to Isar
   - Update message status
   ↓
8. UI Update
   - Display AI message bubble
   - Show timestamp and metadata
```

**Error Paths:**

```
Network Timeout (30s):
  HttpAiChatService → TimeoutException
  → Retry #1 (2s delay)
  → Retry #2 (4s delay)
  → Retry #3 (8s delay)
  → If all fail: throw TimeoutException
  → UI shows error bubble with retry button

Network Unavailable:
  HttpAiChatService → NetworkException
  → Queue message locally
  → UI shows offline indicator
  → Auto-retry when connectivity restored

Server Error (500):
  Backend → HTTP 500
  → HttpAiChatService → ServerException
  → Retry with exponential backoff
  → If all fail: UI shows error bubble
```

### Stage 2: LLM Flow

```
1. User types message in ChatComposer
   ↓
2. User taps send button
   ↓
3. SendChatMessageUseCase.execute()
   - Check AI consent
   - Save user message to Isar
   - Load last 3 messages from thread
   - Build ChatRequest with history
   ↓
4. HttpAiChatService.sendMessage()
   - Generate correlation ID
   - Check network connectivity
   - Build HTTP POST request with history
   - Set 60-second timeout (longer for LLM)
   ↓
5. HTTP Request → Backend /api/v1/chat/message
   - Validate request format
   - Log request received
   - Extract message and history
   ↓
6. Backend → Construct Prompt
   - Load system prompt template
   - Format history (last 3 turns)
   - Append user message
   - Count tokens (estimate)
   ↓
7. Backend → LLM API Call
   - POST to Together AI / OpenAI
   - Include prompt
   - Set max_tokens: 1000
   - Set timeout: 60s
   - Log LLM request sent
   ↓
8. LLM Provider → Generate Response
   - Process prompt
   - Generate completion
   - Return response with token counts
   ↓
9. Backend → Parse LLM Response
   - Extract message content
   - Extract token usage
   - Extract finish reason
   - Log LLM response received
   ↓
10. Backend → Build ChatResponse
   - Package message and metadata
   - Include token counts
   - Include latency
   - Log response sent
   ↓
11. ChatResponse → HttpAiChatService
   - Parse JSON response
   - Extract message and metadata
   - Log response received
   ↓
12. ChatResponse → SendChatMessageUseCase
   - Save AI message to Isar
   - Update message status
   - Log token usage
   ↓
13. UI Update
   - Display AI message bubble
   - Show timestamp and token count
```

**Error Paths:**

```
LLM Timeout (60s):
  Backend → LLM API timeout
  → Retry once with reduced context
  → If fail: return generic helpful message
  → Log timeout event

LLM Rate Limit (429):
  LLM Provider → HTTP 429
  → Backend waits for retry-after duration
  → Retry request
  → If fail: return error to client
  → Log rate limit hit

LLM Error (500):
  LLM Provider → HTTP 500
  → Backend retries once
  → If fail: return generic helpful message
  → Log LLM error

Token Budget Exceeded:
  Backend → Token count > 2500
  → Truncate history to last 2 messages
  → Retry with reduced context
  → Log budget violation
```


## Backend API Specification

### Stage 1: Echo Endpoint

**Endpoint:** `POST /api/v1/chat/echo`

**Purpose:** Validate HTTP connectivity without LLM integration.

**Request Headers:**
```
Content-Type: application/json
X-Correlation-ID: <uuid>
X-Client-Version: <app-version>
Authorization: Bearer <user-token>
```

**Request Body:**
```json
{
  "threadId": "thread_123",
  "message": "Hello, AI!",
  "timestamp": "2025-11-24T10:00:00Z",
  "userId": "user_456"
}
```

**Response Body (Success - 200):**
```json
{
  "responseId": "response_789",
  "threadId": "thread_123",
  "message": "Echo: Hello, AI!",
  "timestamp": "2025-11-24T10:00:01Z",
  "metadata": {
    "processingTimeMs": 50,
    "stage": "echo",
    "llmProvider": "none",
    "tokenUsage": {
      "prompt": 0,
      "completion": 0,
      "total": 0
    }
  }
}
```

**Response Body (Error):**
```json
{
  "error": {
    "code": "TIMEOUT",
    "message": "Request timed out after 30 seconds",
    "correlationId": "corr_123",
    "retryable": true
  }
}
```

**Status Codes:**
- 200: Success
- 400: Invalid request format
- 401: Authentication failed
- 429: Rate limit exceeded
- 500: Internal server error
- 503: Service unavailable

### Stage 2: LLM Chat Endpoint

**Endpoint:** `POST /api/v1/chat/message`

**Purpose:** Process chat message with LLM integration.

**Request Headers:**
```
Content-Type: application/json
X-Correlation-ID: <uuid>
X-Client-Version: <app-version>
X-Stage: 2
Authorization: Bearer <user-token>
```

**Request Body:**
```json
{
  "threadId": "thread_123",
  "message": "Can you help me organize my records?",
  "timestamp": "2025-11-24T10:00:00Z",
  "userId": "user_456",
  "history": [
    {
      "role": "user",
      "content": "Hello",
      "timestamp": "2025-11-24T09:55:00Z"
    },
    {
      "role": "assistant",
      "content": "Hello! How can I help you today?",
      "timestamp": "2025-11-24T09:55:02Z"
    },
    {
      "role": "user",
      "content": "I need help with my information",
      "timestamp": "2025-11-24T09:56:00Z"
    }
  ]
}
```

**Response Body (Success - 200):**
```json
{
  "responseId": "response_789",
  "threadId": "thread_123",
  "message": "I'd be happy to help you organize your records! I can assist with categorizing information, creating summaries, and suggesting ways to structure your data. What type of records would you like to start with?",
  "timestamp": "2025-11-24T10:00:03Z",
  "metadata": {
    "processingTimeMs": 1850,
    "stage": "2",
    "llmProvider": "together",
    "modelVersion": "meta-llama/Llama-2-70b-chat-hf",
    "tokenUsage": {
      "prompt": 1450,
      "completion": 380,
      "total": 1830
    },
    "finishReason": "stop"
  }
}
```

**Response Body (Error):**
```json
{
  "error": {
    "code": "LLM_TIMEOUT",
    "message": "LLM request timed out after 60 seconds",
    "correlationId": "corr_123",
    "retryable": true
  }
}
```

**Status Codes:**
- 200: Success
- 400: Invalid request format
- 401: Authentication failed
- 429: Rate limit exceeded
- 500: Internal server error
- 503: Service unavailable
- 504: LLM timeout

### Prompt Construction (Stage 2)

**System Prompt Template:**
```
You are a compassionate AI companion helping users organize their personal information.

Guidelines:
- Be helpful, empathetic, and respectful
- Provide clear, concise responses
- Acknowledge uncertainty when appropriate
- Never fabricate information
- Respect user privacy

Recent conversation:
{history}

User message: {user_message}
```

**History Formatting:**
```
User: Hello
Assistant: Hello! How can I help you today?
User: I need help with my information
```

**Complete Prompt Example:**
```
You are a compassionate AI companion helping users organize their personal information.

Guidelines:
- Be helpful, empathetic, and respectful
- Provide clear, concise responses
- Acknowledge uncertainty when appropriate
- Never fabricate information
- Respect user privacy

Recent conversation:
User: Hello
Assistant: Hello! How can I help you today?
User: I need help with my information

User message: Can you help me organize my records?
```

**Token Budget:**
- System prompt: 500 tokens
- History (3 turns): 1000 tokens
- User message: variable (max 500 tokens)
- Response: 1000 tokens
- **Total: ~2500 tokens**

### Rate Limiting

**Limits:**
- Per-user: 10 requests/minute
- Per-user: 100 requests/hour
- Per-user: 500 requests/day
- Global: 1000 requests/minute

**Implementation:**
- Use sliding window algorithm
- Store in Redis or in-memory cache
- Key format: `rate_limit:{userId}:{window}`
- Return HTTP 429 with `Retry-After` header

**Response Headers (when rate limited):**
```
HTTP/1.1 429 Too Many Requests
Retry-After: 60
X-RateLimit-Limit: 10
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1700827200
```

### Logging Requirements

**Request Received:**
```json
{
  "event": "chat_request_received",
  "correlationId": "uuid",
  "userId": "uuid",
  "threadId": "uuid",
  "stage": 2,
  "timestamp": "2025-11-24T10:00:00Z",
  "messageLength": 45,
  "historyLength": 3
}
```

**LLM Request Sent (Stage 2):**
```json
{
  "event": "llm_request_sent",
  "correlationId": "uuid",
  "provider": "together",
  "model": "meta-llama/Llama-2-70b-chat-hf",
  "promptTokens": 1450,
  "timestamp": "2025-11-24T10:00:01Z"
}
```

**LLM Response Received (Stage 2):**
```json
{
  "event": "llm_response_received",
  "correlationId": "uuid",
  "completionTokens": 380,
  "totalTokens": 1830,
  "finishReason": "stop",
  "latencyMs": 1850,
  "timestamp": "2025-11-24T10:00:03Z"
}
```

**Error Event:**
```json
{
  "event": "chat_error",
  "correlationId": "uuid",
  "errorCode": "LLM_TIMEOUT",
  "errorMessage": "LLM request timed out after 60 seconds",
  "stage": 2,
  "retryable": true,
  "timestamp": "2025-11-24T10:01:00Z"
}
```

**Privacy Rules:**
- Never log message content
- Never log user personal information
- Redact sensitive fields before logging
- Log only metadata (lengths, counts, timestamps)

### Retry and Timeout Strategy

**Timeouts:**
- HTTP connection timeout: 10 seconds
- Stage 1 request timeout: 30 seconds
- Stage 2 LLM request timeout: 60 seconds
- Total request timeout: 120 seconds

**Retry Policy:**

**Transient Errors (Retryable):**
- Network timeouts
- HTTP 500, 502, 503, 504
- LLM provider rate limits (429)
- Connection refused

**Retry Strategy:**
- Attempt 1: Immediate
- Attempt 2: 2 seconds delay
- Attempt 3: 4 seconds delay
- Max attempts: 3
- Exponential backoff with jitter (±20%)

**Non-Retryable Errors:**
- HTTP 400 (bad request)
- HTTP 401 (unauthorized)
- HTTP 403 (forbidden)
- Invalid JSON
- Token budget exceeded
- Content policy violations

**Fallback Strategies:**
- Stage 1: Return error to user
- Stage 2: Return generic helpful message if LLM fails
- All stages: Queue message for later retry if offline


## Flutter Client Implementation

### HttpAiChatService

**Purpose:** Implements AiChatService interface using HTTP communication.

**Class Structure:**
```dart
class HttpAiChatService implements AiChatService {
  final String baseUrl;
  final http.Client httpClient;
  final Duration timeout;
  final int maxRetries;
  
  HttpAiChatService({
    required this.baseUrl,
    required this.httpClient,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
  });
  
  @override
  Future<ChatResponse> sendMessage(ChatRequest request) async {
    final correlationId = _generateCorrelationId();
    
    // Check network connectivity
    if (!await _isNetworkAvailable()) {
      throw NetworkException('No internet connection');
    }
    
    // Build HTTP request
    final httpRequest = await _buildHttpRequest(request, correlationId);
    
    // Send with retry logic
    return await _sendWithRetry(httpRequest, correlationId);
  }
  
  Future<http.Response> _sendWithRetry(
    http.Request request,
    String correlationId,
  ) async {
    int attempt = 0;
    Duration delay = Duration.zero;
    
    while (attempt < maxRetries) {
      attempt++;
      
      if (delay > Duration.zero) {
        await Future.delayed(delay);
      }
      
      try {
        await AppLogger.info('Sending chat request', context: {
          'correlationId': correlationId,
          'attempt': attempt,
          'endpoint': request.url.path,
        });
        
        final response = await httpClient
            .send(request)
            .timeout(timeout);
        
        final responseBody = await response.stream.bytesToString();
        
        await AppLogger.info('Chat response received', context: {
          'correlationId': correlationId,
          'statusCode': response.statusCode,
          'latencyMs': /* calculate */,
        });
        
        if (response.statusCode == 200) {
          return _parseResponse(responseBody);
        } else if (_isRetryable(response.statusCode)) {
          delay = _calculateBackoff(attempt);
          continue;
        } else {
          throw _classifyError(response.statusCode, responseBody);
        }
      } on TimeoutException {
        if (attempt < maxRetries) {
          delay = _calculateBackoff(attempt);
          continue;
        }
        throw ChatTimeoutException('Request timed out after $timeout');
      } on SocketException {
        throw NetworkException('Network unavailable');
      }
    }
    
    throw ChatException('Max retries exceeded');
  }
  
  Duration _calculateBackoff(int attempt) {
    // Exponential backoff: 1s, 2s, 4s
    final baseDelay = Duration(seconds: math.pow(2, attempt - 1).toInt());
    // Add jitter (±20%)
    final jitter = (Random().nextDouble() * 0.4 - 0.2) * baseDelay.inMilliseconds;
    return Duration(milliseconds: baseDelay.inMilliseconds + jitter.toInt());
  }
  
  bool _isRetryable(int statusCode) {
    return statusCode >= 500 || statusCode == 429;
  }
  
  Exception _classifyError(int statusCode, String body) {
    switch (statusCode) {
      case 400:
        return ValidationException('Invalid request format');
      case 401:
        return UnauthorizedException('Authentication failed');
      case 429:
        return RateLimitException('Rate limit exceeded');
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException('Server error: $statusCode');
      default:
        return ChatException('Unexpected error: $statusCode');
    }
  }
}
```

### Service Switching

**Configuration:**
```dart
// In AppContainer or dependency injection
AiChatService createAiChatService(AiConfig config) {
  if (config.aiMode == 'fake') {
    return FakeAiChatService(
      simulatedLatency: Duration(milliseconds: 1000),
    );
  } else if (config.aiMode == 'http') {
    return LoggingAiChatService(
      HttpAiChatService(
        baseUrl: config.backendUrl,
        httpClient: http.Client(),
        timeout: Duration(seconds: 30),
      ),
    );
  } else {
    throw ConfigurationException('Invalid ai_mode: ${config.aiMode}');
  }
}
```

**Settings UI:**
```dart
class AiModeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final aiConfig = ref.watch(aiConfigProvider);
    
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(value: 'fake', label: Text('Fake (Dev)')),
        ButtonSegment(value: 'http', label: Text('HTTP (Real)')),
      ],
      selected: {aiConfig.aiMode},
      onSelectionChanged: (Set<String> newSelection) {
        ref.read(aiConfigProvider.notifier).setAiMode(newSelection.first);
      },
    );
  }
}
```

**Chat Header Status Pill:**
```dart
class AiModeStatusPill extends StatelessWidget {
  final String aiMode;
  final bool isOffline;
  
  @override
  Widget build(BuildContext context) {
    final color = isOffline ? Colors.grey : 
                  aiMode == 'fake' ? Colors.orange : Colors.green;
    final label = isOffline ? 'Offline' :
                  aiMode == 'fake' ? 'Fake' : 'Live';
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
```

### Offline Message Queuing

**MessageQueueService:**
```dart
class MessageQueueService {
  final SharedPreferences prefs;
  final NetworkInfo networkInfo;
  
  Future<void> queueMessage(ChatRequest request) async {
    final queue = await _loadQueue();
    queue.add(request);
    await _saveQueue(queue);
    
    await AppLogger.info('Message queued', context: {
      'threadId': request.threadId,
      'queueSize': queue.length,
    });
  }
  
  Future<void> processQueue(AiChatService aiService) async {
    if (!await networkInfo.isConnected) return;
    
    final queue = await _loadQueue();
    if (queue.isEmpty) return;
    
    await AppLogger.info('Processing message queue', context: {
      'queueSize': queue.length,
    });
    
    for (final request in queue) {
      try {
        await aiService.sendMessage(request);
        queue.remove(request);
        await _saveQueue(queue);
      } catch (e) {
        await AppLogger.error('Failed to process queued message', error: e);
        break; // Stop processing on first failure
      }
    }
  }
}
```

**Connectivity Monitoring:**
```dart
class ConnectivityMonitor {
  final MessageQueueService queueService;
  final AiChatService aiService;
  
  StreamSubscription? _subscription;
  
  void start() {
    _subscription = Connectivity().onConnectivityChanged.listen((result) async {
      if (result != ConnectivityResult.none) {
        await AppLogger.info('Connectivity restored, processing queue');
        await queueService.processQueue(aiService);
      }
    });
  }
  
  void stop() {
    _subscription?.cancel();
  }
}
```

### Error Handling UI

**Error Message Bubble:**
```dart
class ErrorMessageBubble extends StatelessWidget {
  final String errorMessage;
  final bool canRetry;
  final VoidCallback? onRetry;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red[900]),
                ),
              ),
            ],
          ),
          if (canRetry && onRetry != null) ...[
            SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh, size: 16),
              label: Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

**User-Friendly Error Messages:**
```dart
String getUserFriendlyErrorMessage(Exception error) {
  if (error is ChatTimeoutException) {
    return 'Request timed out. Please try again.';
  } else if (error is NetworkException) {
    return 'No internet connection. Message will be sent when online.';
  } else if (error is ServerException) {
    return 'Service temporarily unavailable. Please try again later.';
  } else if (error is RateLimitException) {
    return 'Too many requests. Please wait a moment.';
  } else if (error is UnauthorizedException) {
    return 'Session expired. Please sign in again.';
  } else {
    return 'Something went wrong. Please try again.';
  }
}
```


## Risks and Mitigations

### Risk 1: Network Reliability

**Risk:** Unreliable network connections cause frequent timeouts and failed requests.

**Impact:** Poor user experience, lost messages, frustration.

**Mitigation:**
- Implement robust retry logic with exponential backoff
- Queue messages locally when offline
- Auto-retry when connectivity restored
- Show clear offline indicators
- Allow viewing chat history offline

**Monitoring:**
- Track timeout rate
- Track retry success rate
- Alert if timeout rate > 10%

### Risk 2: LLM Provider Outages

**Risk:** LLM provider (Together AI) experiences downtime or degraded performance.

**Impact:** Users cannot get AI responses, service appears broken.

**Mitigation:**
- Implement fallback to generic helpful messages
- Show clear error messages explaining the issue
- Provide retry button for transient failures
- Consider multi-provider strategy in future
- Monitor LLM provider status

**Monitoring:**
- Track LLM error rate
- Track LLM latency (p50, p95, p99)
- Alert if error rate > 5%

### Risk 3: Token Cost Overruns

**Risk:** Uncontrolled token usage leads to unexpected API costs.

**Impact:** Budget exceeded, potential service suspension.

**Mitigation:**
- Enforce strict token budgets (2500 tokens per request)
- Implement rate limiting (10 req/min, 100 req/hour, 500 req/day)
- Track token usage per user
- Alert on unusual usage patterns
- Implement soft/hard limits

**Monitoring:**
- Track daily token usage
- Track per-user token usage
- Alert if daily usage > 80% of budget
- Alert on 10x normal usage patterns

### Risk 4: Privacy Leaks

**Risk:** Sensitive user data accidentally transmitted or logged.

**Impact:** Privacy violation, loss of user trust, potential legal issues.

**Mitigation:**
- Never send record IDs or encryption keys
- Redact sensitive fields from logs
- Audit all data transmission
- Use HTTPS only
- Regular security reviews

**Monitoring:**
- Audit logs for sensitive data patterns
- Regular code reviews
- Automated tests for privacy rules

### Risk 5: Prompt Injection Attacks

**Risk:** Malicious users craft inputs to manipulate LLM behavior.

**Impact:** Inappropriate responses, system abuse, security vulnerabilities.

**Mitigation:**
- Sanitize user input
- Use structured prompts with clear boundaries
- Validate LLM responses
- Implement content moderation
- Rate limiting prevents mass attacks

**Monitoring:**
- Track unusual response patterns
- Flag suspicious inputs
- Review flagged conversations

### Risk 6: Response Quality Degradation

**Risk:** LLM generates low-quality, irrelevant, or inappropriate responses.

**Impact:** Poor user experience, loss of trust in AI features.

**Mitigation:**
- Collect user feedback (thumbs up/down)
- Track quality metrics
- A/B test prompt variations
- Implement response validation
- Provide clear disclaimers

**Monitoring:**
- Track feedback scores
- Alert if quality < 80%
- Review low-rated responses

### Risk 7: Backend Scalability

**Risk:** Backend cannot handle production load, causing slowdowns or failures.

**Impact:** Poor performance, timeouts, service unavailability.

**Mitigation:**
- Load testing before production
- Horizontal scaling capability
- Rate limiting to prevent overload
- Caching where appropriate
- Monitor performance metrics

**Monitoring:**
- Track request rate
- Track response latency
- Track error rate
- Alert on performance degradation

### Risk 8: Breaking Changes in LLM API

**Risk:** LLM provider changes API, breaking integration.

**Impact:** Service outage until code updated.

**Mitigation:**
- Version API calls
- Monitor provider changelogs
- Implement adapter pattern for easy provider switching
- Comprehensive integration tests
- Fallback to Fake service if needed

**Monitoring:**
- Track API version in use
- Monitor provider status pages
- Alert on API errors


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: HTTP Connectivity Round Trip

*For any* valid ChatRequest, when sent to the echo endpoint, the response message should contain the original message prefixed with "Echo: ".

**Validates: Requirements 1.1**

### Property 2: Retry Exponential Backoff

*For any* failed request that is retryable, retry delays should follow the pattern: 1s, 2s, 4s (with ±20% jitter).

**Validates: Requirements 1.3**

### Property 3: Network Exception on Offline

*For any* ChatRequest sent when network is unavailable, the system should throw NetworkException without attempting HTTP request.

**Validates: Requirements 1.4**

### Property 4: Correlation ID Preservation

*For any* request/response pair, the correlation ID in the response should match the correlation ID in the request.

**Validates: Requirements 1.5**

### Property 5: LLM Response Validity

*For any* successful LLM request, the response should contain non-empty message content and valid token usage metadata.

**Validates: Requirements 2.3**

### Property 6: Token Usage Logging

*For any* LLM request, the system should log prompt tokens, completion tokens, and total tokens.

**Validates: Requirements 2.4**

### Property 7: History Limit Enforcement

*For any* ChatRequest with more than 3 messages in history, only the last 3 messages should be included in the LLM prompt.

**Validates: Requirements 3.3**

### Property 8: Message Order Preservation

*For any* message history, messages should be ordered chronologically (oldest first) in the LLM prompt.

**Validates: Requirements 3.4**

### Property 9: Log Content Redaction

*For any* logged event, the log entry should not contain message content, only metadata (lengths, counts, timestamps).

**Validates: Requirements 4.5**

### Property 10: Rate Limit Enforcement

*For any* user making more than 10 requests in 1 minute, the 11th request should return HTTP 429.

**Validates: Requirements 5.1**

### Property 11: Service Mode Consistency

*For any* chat session, all requests should use the same AI service (Fake or HTTP) until mode is explicitly changed.

**Validates: Requirements 6.1, 6.2**

### Property 12: Offline Message Queuing

*For any* message sent while offline, the message should be queued locally and automatically retried when connectivity is restored.

**Validates: Requirements 7.1, 7.2**

### Property 13: HTTPS Only

*For any* HTTP request to backend, the URL scheme should be "https", never "http".

**Validates: Requirements 8.3**

### Property 14: Sensitive Data Exclusion

*For any* ChatRequest payload, the JSON should not contain record IDs, encryption keys, or local file paths.

**Validates: Requirements 8.1**

### Property 15: Error Message User-Friendliness

*For any* error exception, the user-facing error message should be clear, actionable, and non-technical.

**Validates: Requirements 9.1, 9.2, 9.3, 9.4, 9.5**

## Testing Strategy

### Unit Tests

**HttpAiChatService Tests:**
- Test request construction with correlation ID
- Test timeout handling (30s for Stage 1, 60s for Stage 2)
- Test retry logic with exponential backoff
- Test error classification (retryable vs non-retryable)
- Test response parsing
- Mock HTTP client for isolation

**MessageQueueService Tests:**
- Test message queuing when offline
- Test queue persistence
- Test queue processing when online
- Test queue processing stops on first failure
- Mock network connectivity

**Retry Policy Tests:**
- Test exponential backoff calculation (1s, 2s, 4s)
- Test jitter application (±20%)
- Test max retries enforcement (3 attempts)
- Test retry on transient errors only

### Integration Tests

**End-to-End Echo Flow (Stage 1):**
1. Start with empty chat thread
2. Send message via HttpAiChatService
3. Verify backend receives request
4. Verify backend returns echoed message
5. Verify message saved to Isar
6. Verify UI displays message

**End-to-End LLM Flow (Stage 2):**
1. Start with chat thread containing 2 messages
2. Send new message via HttpAiChatService
3. Verify backend receives request with history
4. Verify backend calls LLM API
5. Verify LLM response parsed correctly
6. Verify token usage logged
7. Verify message saved to Isar
8. Verify UI displays message

**Offline/Online Flow:**
1. Disable network
2. Send message
3. Verify message queued locally
4. Verify offline indicator shown
5. Enable network
6. Verify message auto-retried
7. Verify message sent successfully

**Error Handling Flow:**
1. Configure backend to return 500
2. Send message
3. Verify retry attempts (3x)
4. Verify error bubble shown
5. Verify retry button works

### Property-Based Tests

**Property 1: HTTP Connectivity Round Trip**
- Generate random messages
- Send to echo endpoint
- Assert response contains "Echo: " + original message

**Property 2: Retry Exponential Backoff**
- Simulate multiple failures
- Track retry delays
- Assert delays follow 1s, 2s, 4s pattern (±20%)

**Property 7: History Limit Enforcement**
- Generate chat threads with varying message counts (0-10)
- Build ChatRequest
- Assert history contains at most 3 messages

**Property 10: Rate Limit Enforcement**
- Send 11 requests in rapid succession
- Assert 11th request returns HTTP 429

**Property 12: Offline Message Queuing**
- Simulate offline state
- Send multiple messages
- Assert all messages queued
- Simulate online state
- Assert all messages retried

### Manual Testing

**Stage 1 Manual Tests:**
1. **Echo Success:**
   - Open chat
   - Send message "Hello"
   - Verify response "Echo: Hello" appears
   - Verify latency < 1 second

2. **Timeout Handling:**
   - Configure backend with 35s delay
   - Send message
   - Verify timeout after 30s
   - Verify retry attempts
   - Verify error message shown

3. **Offline Handling:**
   - Disable network
   - Send message
   - Verify offline indicator
   - Verify message queued
   - Enable network
   - Verify message sent

4. **Service Switching:**
   - Start with Fake mode
   - Send message, verify fake response
   - Switch to HTTP mode
   - Send message, verify echo response
   - Verify chat history preserved

**Stage 2 Manual Tests:**
1. **LLM Response:**
   - Open chat
   - Send message "Can you help me?"
   - Verify LLM-generated response
   - Verify response is contextually appropriate
   - Verify latency 2-4 seconds

2. **Conversation Continuity:**
   - Send message "Hello"
   - Verify response
   - Send message "What can you do?"
   - Verify response references previous exchange

3. **History Truncation:**
   - Have conversation with 5+ exchanges
   - Send new message
   - Verify only last 3 exchanges included in prompt
   - Check backend logs to confirm

4. **Token Usage:**
   - Send message
   - Check logs for token counts
   - Verify prompt + completion + total logged
   - Verify counts are reasonable (< 2500 total)

5. **Rate Limiting:**
   - Send 10 messages rapidly
   - Verify all succeed
   - Send 11th message
   - Verify rate limit error
   - Wait 1 minute
   - Verify can send again

### Performance Benchmarks

**Stage 1 Targets:**
- Echo latency: < 500ms (p95)
- Timeout handling: exactly 30s
- Retry overhead: < 10s total for 3 attempts
- Queue processing: < 1s per message

**Stage 2 Targets:**
- LLM latency: < 4s (p95)
- Token counting: < 50ms
- Prompt construction: < 100ms
- Total request time: < 5s (p95)

### Acceptance Criteria

**Stage 1 Complete When:**
- ✅ HttpAiChatService implemented and tested
- ✅ Echo endpoint deployed and functional
- ✅ Retry logic working with exponential backoff
- ✅ Offline queuing and auto-retry working
- ✅ Service switching (Fake/HTTP) working
- ✅ All unit tests passing
- ✅ All integration tests passing
- ✅ Manual tests documented in TESTING.md
- ✅ Performance benchmarks met

**Stage 2 Complete When:**
- ✅ LLM provider integration working
- ✅ System prompt template implemented
- ✅ Message history (3 turns) included
- ✅ Token usage logged
- ✅ Rate limiting enforced
- ✅ All unit tests passing
- ✅ All integration tests passing
- ✅ Property-based tests passing
- ✅ Manual tests documented in TESTING.md
- ✅ Performance benchmarks met
- ✅ User feedback positive (>80%)

## Implementation Notes

### Dependency Injection

**Register Services in AppContainer:**
```dart
class AppContainer {
  late final AiChatService aiChatService;
  late final MessageQueueService messageQueueService;
  late final ConnectivityMonitor connectivityMonitor;
  
  Future<void> bootstrap() async {
    // Load configuration
    final config = await _loadAiConfig();
    
    // Create base chat service
    AiChatService baseService;
    if (config.aiMode == 'fake') {
      baseService = FakeAiChatService();
    } else {
      baseService = HttpAiChatService(
        baseUrl: config.backendUrl,
        httpClient: http.Client(),
      );
    }
    
    // Wrap with logging
    aiChatService = LoggingAiChatService(baseService);
    
    // Initialize queue service
    messageQueueService = MessageQueueService(
      prefs: await SharedPreferences.getInstance(),
      networkInfo: NetworkInfo(),
    );
    
    // Start connectivity monitoring
    connectivityMonitor = ConnectivityMonitor(
      queueService: messageQueueService,
      aiService: aiChatService,
    );
    connectivityMonitor.start();
  }
}
```

### Configuration Management

**AI Configuration:**
```dart
class AiConfig {
  final String aiMode;  // 'fake' or 'http'
  final String backendUrl;
  final Duration timeout;
  final int maxRetries;
  
  const AiConfig({
    required this.aiMode,
    required this.backendUrl,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
  });
  
  factory AiConfig.fromJson(Map<String, dynamic> json) {
    return AiConfig(
      aiMode: json['ai_mode'] ?? 'fake',
      backendUrl: json['backend_url'] ?? 'https://api.example.com',
      timeout: Duration(seconds: json['timeout_seconds'] ?? 30),
      maxRetries: json['max_retries'] ?? 3,
    );
  }
}
```

**Configuration File (assets/config/ai_config.json):**
```json
{
  "ai_mode": "fake",
  "backend_url": "https://api.universallifecompanion.com",
  "timeout_seconds": 30,
  "max_retries": 3,
  "rate_limits": {
    "requests_per_minute": 10,
    "requests_per_hour": 100,
    "requests_per_day": 500
  }
}
```

### Logging Integration

**Per `.kiro/steering/logging-guidelines.md`:**
```dart
// Request sent
await AppLogger.info('Chat request sent', context: {
  'correlationId': correlationId,
  'threadId': threadId,
  'stage': stage,
  'endpoint': endpoint,
  'messageLength': messageLength,
  // Never log message content
});

// Response received
await AppLogger.info('Chat response received', context: {
  'correlationId': correlationId,
  'latencyMs': latencyMs,
  'statusCode': statusCode,
  'tokensUsed': tokensUsed,  // Stage 2 only
  // Never log response content
});

// Error occurred
await AppLogger.error('Chat request failed',
  error: error,
  stackTrace: stackTrace,
  context: {
    'correlationId': correlationId,
    'errorType': error.runtimeType.toString(),
    'retryable': isRetryable,
  },
);
```

### Security Considerations

**API Key Storage:**
- Use `flutter_secure_storage` for API keys
- Never commit keys to version control
- Use environment variables for backend
- Rotate keys regularly

**HTTPS Enforcement:**
- All HTTP requests use HTTPS
- Certificate pinning for production
- Reject self-signed certificates

**Input Validation:**
- Sanitize user input before transmission
- Validate message length (max 2000 characters)
- Reject malformed JSON
- Escape special characters

**Privacy Protection:**
- Never send record IDs
- Never send encryption keys
- Never send local file paths
- Redact sensitive fields from logs
- Use correlation IDs for tracing

## References

- `.kiro/specs/ai-chat-companion/` - Existing AI chat spec
- `.kiro/steering/logging-guidelines.md` - Logging requirements
- `.kiro/steering/flutter-ui-performance.md` - Performance guidelines
- `CLEAN_ARCHITECTURE_GUIDE.md` - Architecture patterns
- `AGENTS.md` - Development guidelines
- Together AI API Documentation
- OpenAI API Documentation (alternative provider)
