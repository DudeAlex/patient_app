# Design Document

## Overview

Stage 7a enhances the AI Chat Companion with two major capabilities:

1. **AI Personas**: Space-specific AI behavior that adapts tone, style, and guidance based on the active Space (Health, Finance, Education, Travel)
2. **Error Recovery**: Robust error handling with automatic recovery strategies, fallback mechanisms, and graceful degradation

This stage builds on the foundation of Stages 1-6, adding intelligence and reliability to create a production-ready AI system.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter Client                           │
│  ┌──────────────────────────────────────────────────────┐  │
│  │           AiChatController                            │  │
│  │  - Manages chat state                                 │  │
│  │  - Handles user interactions                          │  │
│  └──────────────────────────────────────────────────────┘  │
│                          │                                   │
│                          ▼                                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │      SendChatMessageUseCase                           │  │
│  │  - Orchestrates message sending                       │  │
│  │  - Builds context with persona                        │  │
│  └──────────────────────────────────────────────────────┘  │
│                          │                                   │
│                          ▼                                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │      ResilientAiChatService (NEW)                     │  │
│  │  - Wraps HttpAiChatService                            │  │
│  │  - Implements error recovery                          │  │
│  │  - Manages fallback behavior                          │  │
│  └──────────────────────────────────────────────────────┘  │
│                          │                                   │
│                          ▼                                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │      HttpAiChatService                                │  │
│  │  - HTTP communication                                 │  │
│  │  - Request/response handling                          │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼ HTTP
┌─────────────────────────────────────────────────────────────┐
│                    Backend Server                            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │      PersonaManager (NEW)                             │  │
│  │  - Loads persona configurations                       │  │
│  │  - Selects persona based on Space                     │  │
│  │  - Builds persona-specific prompts                    │  │
│  └──────────────────────────────────────────────────────┘  │
│                          │                                   │
│                          ▼                                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │      PromptBuilder                                     │  │
│  │  - Combines persona + context + history               │  │
│  │  - Generates final LLM prompt                         │  │
│  └──────────────────────────────────────────────────────┘  │
│                          │                                   │
│                          ▼                                   │
│  ┌──────────────────────────────────────────────────────┐  │
│  │      TogetherAI Client                                │  │
│  │  - LLM API communication                              │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. PersonaManager (Backend - NEW)

**Purpose:** Manages AI persona configurations and selects appropriate persona based on Space.

**Interface:**
```javascript
class PersonaManager {
  constructor(configPath)
  
  // Load persona configurations from file
  loadPersonas()
  
  // Get persona for a specific Space
  getPersona(spaceName): Persona
  
  // Validate persona configuration
  validatePersona(persona): boolean
}
```

**Persona Configuration Format:**
```json
{
  "health": {
    "name": "Health Companion",
    "tone": "empathetic, cautious, supportive",
    "guidelines": [
      "Always include medical disclaimers",
      "Encourage consulting healthcare professionals",
      "Be sensitive to health concerns",
      "Focus on wellness and prevention"
    ],
    "systemPromptAddition": "You are a health companion. Always remind users that you are not a medical professional..."
  },
  "finance": {
    "name": "Finance Advisor",
    "tone": "practical, budget-conscious, clear",
    "guidelines": [
      "Focus on budgeting and saving",
      "Provide practical money management tips",
      "Be clear about financial concepts",
      "Encourage responsible spending"
    ],
    "systemPromptAddition": "You are a finance advisor. Focus on practical money management..."
  }
}
```

### 2. ResilientAiChatService (Flutter - NEW)

**Purpose:** Wraps HttpAiChatService with error recovery and fallback capabilities.

**Interface:**
```dart
class ResilientAiChatService implements AiChatService {
  ResilientAiChatService({
    required AiChatService primaryService,
    required ErrorRecoveryStrategy recoveryStrategy,
    required FallbackService fallbackService,
  });
  
  @override
  Future<ChatResponse> sendMessage(ChatRequest request);
  
  // Internal methods
  Future<ChatResponse> _attemptRecovery(
    ChatRequest request,
    AiServiceException error,
    int attemptNumber,
  );
  
  Future<ChatResponse> _fallback(ChatRequest request);
}
```

### 3. ErrorRecoveryStrategy (Flutter - NEW)

**Purpose:** Defines recovery strategies for different error types.

**Interface:**
```dart
abstract class ErrorRecoveryStrategy {
  Future<ChatResponse> recover(
    ChatRequest request,
    AiServiceException error,
    int attemptNumber,
  );
  
  bool canRecover(AiServiceException error);
  Duration getRetryDelay(int attemptNumber);
}

class RateLimitRecoveryStrategy extends ErrorRecoveryStrategy {
  // Wait for rate limit to reset
}

class NetworkRecoveryStrategy extends ErrorRecoveryStrategy {
  // Retry with exponential backoff
}

class ServerErrorRecoveryStrategy extends ErrorRecoveryStrategy {
  // Try alternative endpoint or fallback
}
```

### 4. FallbackService (Flutter - NEW)

**Purpose:** Provides simplified responses when primary service fails.

**Interface:**
```dart
class FallbackService {
  Future<ChatResponse> generateFallbackResponse(ChatRequest request);
  
  // Generate helpful error message
  String _generateHelpfulMessage(AiServiceException error);
}
```

## Data Models

### Persona Model (Backend)

```javascript
class Persona {
  constructor(name, tone, guidelines, systemPromptAddition) {
    this.name = name;
    this.tone = tone;
    this.guidelines = guidelines;
    this.systemPromptAddition = systemPromptAddition;
  }
  
  buildSystemPrompt(basePrompt) {
    return `${basePrompt}\n\n${this.systemPromptAddition}`;
  }
}
```

### ErrorRecoveryAttempt Model (Flutter)

```dart
class ErrorRecoveryAttempt {
  final int attemptNumber;
  final String strategyUsed;
  final DateTime timestamp;
  final Duration duration;
  final bool success;
  final String? errorMessage;
  
  ErrorRecoveryAttempt({
    required this.attemptNumber,
    required this.strategyUsed,
    required this.timestamp,
    required this.duration,
    required this.success,
    this.errorMessage,
  });
  
  Map<String, dynamic> toJson();
}
```

### RecoveryMetrics Model (Flutter)

```dart
class RecoveryMetrics {
  final int totalAttempts;
  final int successfulRecoveries;
  final int failedRecoveries;
  final int fallbacksUsed;
  final Duration averageRecoveryTime;
  final Map<String, int> errorTypeCount;
  
  double get successRate => successfulRecoveries / totalAttempts;
  double get fallbackRate => fallbacksUsed / totalAttempts;
}
```


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Persona Selection Consistency
*For any* Space name, calling getPersona() multiple times should return the same persona configuration.
**Validates: Requirements 1.1-1.4, 8.4**

### Property 2: Persona Prompt Inclusion
*For any* valid Space, the generated system prompt should include the persona-specific additions.
**Validates: Requirements 1.1-1.4, 2.1-2.4**

### Property 3: Error Classification Determinism
*For any* error, classifying it multiple times should produce the same error type.
**Validates: Requirements 6.1-6.5**

### Property 4: Recovery Strategy Selection
*For any* error type, the selected recovery strategy should be appropriate for that error type.
**Validates: Requirements 4.1-4.5, 6.2-6.4**

### Property 5: Recovery Attempt Limit
*For any* failed request, the system should attempt no more than 2 recovery strategies before falling back.
**Validates: Requirements 3.1, 3.2**

### Property 6: Fallback Always Succeeds
*For any* request, the fallback service should always return a valid response (never throw).
**Validates: Requirements 5.1-5.5**

### Property 7: Recovery Time Bounds
*For any* recovery attempt, the total time should not exceed 10 seconds.
**Validates: Requirements 9.1-9.3**

### Property 8: Persona Switch Consistency
*For any* conversation, switching Spaces mid-conversation should apply the new persona on the next response.
**Validates: Requirements 1.5**

### Property 9: Error Message User-Friendliness
*For any* error shown to users, it should contain no technical jargon or stack traces.
**Validates: Requirements 7.4**

### Property 10: Metrics Accuracy
*For any* sequence of recovery attempts, the calculated success rate should match actual successes divided by total attempts.
**Validates: Requirements 10.1-10.3**


## Error Handling

### Error Classification

Errors are classified into the following types:

1. **Rate Limit Errors** (HTTP 429)
   - Strategy: Wait for specified delay, then retry
   - Max wait: 5 seconds
   - Fallback: If wait > 5s, use fallback service

2. **Network Errors** (Connection timeout, DNS failure)
   - Strategy: Exponential backoff retry (1s, 2s)
   - Max attempts: 2
   - Fallback: Queue message for later if still failing

3. **Server Errors** (HTTP 500, 502, 503)
   - Strategy: Immediate fallback
   - No retry (server issues need time to resolve)

4. **Validation Errors** (HTTP 400)
   - Strategy: No retry (client error)
   - Log error and show user-friendly message

5. **Timeout Errors** (Request > 30s)
   - Strategy: Retry once with shorter timeout
   - Fallback: If second timeout, use fallback service

6. **Unknown Errors**
   - Strategy: Single retry attempt
   - Fallback: If retry fails, use fallback service

### Recovery Flow

\\\
Request → Primary Service
    ↓ (error)
Classify Error
    ↓
Select Strategy
    ↓
Recovery Attempt 1
    ↓ (still failing)
Recovery Attempt 2
    ↓ (still failing)
Fallback Service
    ↓
Return Response (always succeeds)
\\\

### Fallback Behavior

When all recovery attempts fail, the fallback service:

1. Generates a helpful, context-aware message
2. Includes actionable guidance based on error type
3. Maintains conversation continuity
4. Logs fallback event for monitoring

**Example Fallback Messages:**

- Network Error: "I'm having trouble connecting right now. Please check your internet connection and try again."
- Rate Limit: "I'm receiving a lot of requests right now. Please wait a moment and try again."
- Server Error: "The AI service is temporarily unavailable. Your message has been saved and I'll respond when the service is back."


## Testing Strategy

### Unit Tests

**PersonaManager Tests:**
- Load personas from configuration file
- Get persona for each Space type
- Handle missing persona gracefully (default persona)
- Validate persona configuration format
- Build system prompts with persona additions

**ResilientAiChatService Tests:**
- Successful request (no errors)
- Single recovery attempt succeeds
- Multiple recovery attempts before success
- All recovery attempts fail, fallback used
- Different error types trigger correct strategies

**ErrorRecoveryStrategy Tests:**
- Rate limit strategy waits correct duration
- Network strategy uses exponential backoff
- Server error strategy goes directly to fallback
- Timeout strategy retries with shorter timeout

**FallbackService Tests:**
- Generates appropriate messages for each error type
- Never throws exceptions
- Returns valid ChatResponse
- Includes helpful guidance

### Property-Based Tests

**Property 1 Test:** Generate random Space names, verify persona consistency
**Property 2 Test:** Generate random Spaces, verify prompt includes persona text
**Property 3 Test:** Generate random errors, verify classification consistency
**Property 4 Test:** Generate random error types, verify strategy selection
**Property 5 Test:** Simulate failures, verify max 2 recovery attempts
**Property 6 Test:** Generate random requests, verify fallback never throws
**Property 7 Test:** Simulate recoveries, verify time bounds
**Property 8 Test:** Generate Space switches, verify persona changes
**Property 9 Test:** Generate errors, verify user messages have no jargon
**Property 10 Test:** Generate recovery sequences, verify metrics accuracy

### Integration Tests

1. **End-to-End Persona Test:**
   - Send message in Health Space
   - Verify response has empathetic tone
   - Switch to Finance Space
   - Verify response has practical tone

2. **End-to-End Recovery Test:**
   - Simulate network failure
   - Verify automatic retry
   - Verify eventual success or fallback

3. **Fallback Integration Test:**
   - Simulate complete service failure
   - Verify fallback response
   - Verify user can continue conversation

### Manual Testing Scenarios

1. **Persona Testing:**
   - Create records in each Space
   - Ask similar questions in each Space
   - Verify tone and guidance differ appropriately

2. **Error Recovery Testing:**
   - Disconnect network mid-request
   - Verify retry and recovery
   - Reconnect and verify success

3. **Fallback Testing:**
   - Stop backend server
   - Send message
   - Verify fallback response
   - Restart server
   - Verify normal operation resumes


## Implementation Notes

### Persona System

1. **Configuration File Location:** server/config/personas.json
2. **Default Persona:** Used when Space has no specific persona defined
3. **Persona Loading:** Loaded on server startup, cached in memory
4. **Hot Reload:** Support configuration updates without server restart

### Error Recovery

1. **Recovery Timeout:** Each recovery attempt has 30s timeout
2. **Total Recovery Time:** Max 10s total (including all attempts)
3. **Retry Delays:** 
   - First retry: 1s delay
   - Second retry: 2s delay
   - Rate limit: Use server-provided delay (max 5s)

4. **Fallback Trigger:** Automatic after 2 failed recovery attempts
5. **Logging:** All recovery attempts logged with correlation IDs

### Performance Considerations

1. **Persona Lookup:** O(1) - cached in memory
2. **Error Classification:** O(1) - simple type checking
3. **Recovery Overhead:** 1-4s additional latency in error cases
4. **Fallback Response:** < 100ms (no external calls)

### Monitoring

1. **Metrics to Track:**
   - Recovery success rate by error type
   - Average recovery time
   - Fallback usage rate
   - Persona usage distribution

2. **Alerts:**
   - Recovery success rate < 80%
   - Fallback rate > 5%
   - Average recovery time > 5s

### Configuration

**Persona Configuration (server/config/personas.json):**
`json
{
  "health": { ... },
  "finance": { ... },
  "education": { ... },
  "travel": { ... },
  "default": { ... }
}
`

**Recovery Configuration (lib/core/ai/chat/config/recovery_config.dart):**
`dart
class RecoveryConfig {
  static const int maxRecoveryAttempts = 2;
  static const Duration maxRecoveryTime = Duration(seconds: 10);
  static const Duration firstRetryDelay = Duration(seconds: 1);
  static const Duration secondRetryDelay = Duration(seconds: 2);
  static const Duration maxRateLimitWait = Duration(seconds: 5);
}
`

## References

- **Requirements:** .kiro/specs/llm-stage-7a-personas-error-recovery/requirements.md
- **LLM Stages Overview:** docs/modules/ai/LLM_STAGES_OVERVIEW.md
- **Stage 6 Design:** .kiro/specs/llm-stage-6-intent-retrieval/design.md
- **Stage 4 Documentation:** docs/modules/ai/STAGE_4_TESTING_COMPLETE.md

---

**Created:** December 1, 2025  
**Status:** Ready for task breakdown phase
