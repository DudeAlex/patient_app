# Stage 7a: AI Personas & Error Recovery

## Overview

Stage 7a implements two major capabilities for the AI Chat Companion:

1. **AI Personas**: Space-specific AI behavior that adapts tone, style, and guidance based on the active Space (Health, Finance, Education, Travel)
2. **Error Recovery**: Robust error handling with automatic recovery strategies, fallback mechanisms, and graceful degradation

This stage builds on the foundation of Stages 1-6, adding intelligence and reliability to create a production-ready AI system.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────┐
│                     Flutter Client                           │
│  ┌──────────────────────────────────────────────────────┐  │
│  │           AiChatController                            │  │
│  │  - Manages chat state                                 │  │
│  │  - Handles user interactions                          │  │
│  └──────────────────────────────────────────────────────┘  │
│                          │                                   │
│                          ▼                                   │
│  ┌──────────────────────────────────────────────┐  │
│  │      SendChatMessageUseCase                           │  │
│  │  - Orchestrates message sending                       │  │
│  │  - Builds context with persona                        │  │
│  └──────────────────────────────────────────────────────┘  │
│                          │                                   │
│                          ▼                                   │
│  ┌──────────────────────────────────────────────┐  │
│  │      ResilientAiChatService                          │  │
│  │  - Wraps primary AI service                           │  │
│  │  - Implements error recovery                          │  │
│  │  - Manages fallback behavior                          │  │
│  └──────────────────────────────────────────────────────┘  │
│                          │                                   │
│                          ▼                                   │
│  ┌──────────────────────────────────────────────┐  │
│  │      Primary AI Service (ConfigurableAiChatService)  │  │
│  │  - HTTP communication                                 │  │
│  │  - Request/response handling                          │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. ResilientAiChatService

**Purpose:** Wraps the primary AI service with error recovery and fallback capabilities.

**Key Features:**
- Automatic error classification and recovery
- Multiple recovery strategies for different error types
- Fallback mechanism when all recovery attempts fail
- Timeout enforcement
- Comprehensive logging

### 2. Error Recovery Strategies

**Purpose:** Different strategies for handling various error types:

- **RateLimitRecoveryStrategy**: Waits for rate limit reset and retries
- **NetworkRecoveryStrategy**: Uses exponential backoff (1s, 2s) for retries
- **ServerErrorRecoveryStrategy**: Immediate fallback (no retry for server errors)
- **TimeoutRecoveryStrategy**: Retries once with shorter timeout

### 3. FallbackService

**Purpose:** Provides helpful, user-friendly responses when all recovery attempts fail.

**Features:**
- Space-context aware error messages
- Actionable suggestions for users
- No technical jargon in user-facing messages
- Maintains conversation continuity

### 4. ErrorClassifier

**Purpose:** Classifies AI service errors by type for appropriate recovery strategies.

**Supported Error Types:**
- Rate limit errors
- Network connectivity errors
- Server errors
- Validation errors
- Timeout errors
- Unknown errors

## Implementation Details

### Error Recovery Flow

```
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
```

### Fallback Behavior

When all recovery attempts fail, the fallback service:
1. Generates a helpful, context-aware message
2. Includes actionable guidance based on error type
3. Maintains conversation continuity
4. Logs fallback event for monitoring

## Personas Configuration

### Health Persona
- **Tone:** Empathetic, cautious, supportive
- **Guidelines:** Include medical disclaimers, encourage consulting professionals
- **System Prompt Addition:** "You are a health companion. Always remind users that you are not a medical professional..."

### Finance Persona
- **Tone:** Practical, budget-conscious, clear
- **Guidelines:** Focus on budgeting and saving, provide practical money management tips
- **System Prompt Addition:** "You are a finance advisor. Focus on practical money management..."

### Education Persona
- **Tone:** Study-focused, constructive, encouraging
- **Guidelines:** Provide study tips, encourage learning
- **System Prompt Addition:** "You are an education advisor. Help with study planning and learning..."

### Travel Persona
- **Tone:** Exploratory, enthusiastic, planning-focused
- **Guidelines:** Help with planning, encourage discovery
- **System Prompt Addition:** "You are a travel advisor. Focus on exploration and planning..."

## Error Handling

### Error Classification
Errors are classified into the following types:
- **Rate Limit Errors** (HTTP 429): Handled with wait-and-retry strategy
- **Network Errors**: Handled with exponential backoff retry
- **Server Errors** (HTTP 500, 502, 503): Handled with immediate fallback
- **Validation Errors** (HTTP 400): Handled with no retry (client error)
- **Timeout Errors**: Handled with single retry attempt
- **Unknown Errors**: Handled with single retry attempt

### Recovery Configuration
- Maximum 2 recovery attempts before fallback
- Maximum 10 seconds total recovery time
- Individual attempt timeout: 30 seconds
- Rate limit wait: Up to 5 seconds
- Network retry delays: 1s, 2s (exponential backoff)

## Testing Strategy

### Unit Tests
- ResilientAiChatService functionality
- Error recovery strategies
- Fallback service behavior
- Error classifier accuracy

### Property-Based Tests
- Error classification determinism
- Recovery attempt limits
- Fallback always succeeds property
- Recovery time bounds
- User message friendliness

### Integration Tests
- End-to-end persona behavior
- Complete error recovery flow
- Fallback integration
- Dependency injection wiring

## Performance Considerations

- **Persona Lookup**: O(1) - cached in memory
- **Error Classification**: O(1) - simple type checking
- **Recovery Overhead**: 1-4s additional latency in error cases
- **Fallback Response**: < 100ms (no external calls)

## Monitoring

### Metrics Tracked
- Recovery success rate by error type
- Average recovery time
- Fallback usage rate
- Persona usage distribution

### Alerts
- Recovery success rate < 80%
- Fallback rate > 5%
- Average recovery time > 5s

## Configuration

### Recovery Configuration
```dart
class RecoveryConfig {
  static const int maxRecoveryAttempts = 2;
  static const Duration maxRecoveryTime = Duration(seconds: 10);
  static const Duration firstRetryDelay = Duration(seconds: 1);
  static const Duration secondRetryDelay = Duration(seconds: 2);
  static const Duration maxRateLimitWait = Duration(seconds: 5);
}
```

## Success Criteria

Stage 7a is complete when:
- All personas work correctly with appropriate tone and guidelines
- Error recovery handles all supported error types appropriately
- Fallback mechanism provides helpful user messages
- All property-based tests pass (10 properties validated)
- All unit and integration tests pass
- Performance requirements met
- No technical jargon in user-facing error messages
- Conversation continuity maintained during errors

## References

- **Requirements:** `.kiro/specs/llm-stage-7a-personas-error-recovery/requirements.md`
- **Design:** `.kiro/specs/llm-stage-7a-personas-error-recovery/design.md`
- **Task Breakdown:** `.kiro/specs/llm-stage-7a-personas-error-recovery/tasks.md`
- **LLM Stages Overview:** `docs/modules/ai/LLM_STAGES_OVERVIEW.md`