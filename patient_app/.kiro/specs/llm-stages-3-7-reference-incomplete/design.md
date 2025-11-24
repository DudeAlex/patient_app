# Design Document

## Overview

This design defines the seven-stage evolution of LLM integration for the Universal Life Companion's AI Chat system. The system progresses from basic HTTP connectivity through to a production-ready intelligent contextual AI with token optimization, intent-driven retrieval, error recovery, and extensibility. Each stage delivers incremental value and can be validated independently before proceeding to the next.

**Current State:** Fully functional chat UI with FakeAiChatService providing deterministic responses.

**Target State:** Production AI system with real LLM backend, intelligent context management, privacy safeguards, and robust error handling.

**Architecture Philosophy:**
- Incremental delivery: Each stage adds value independently
- Privacy-first: All filtering happens client-side before transmission
- Token-conscious: Aggressive optimization to control costs
- Clean architecture: Strict layer separation maintained throughout
- Offline-first: Graceful degradation when network unavailable

## Multi-Stage Evolution Architecture

### Stage 1: HTTP Foundation Layer

**Goal:** Establish reliable HTTP communication without LLM integration.

**Components:**
- HttpAiChatService (Flutter)
- Echo endpoint (Backend)
- Retry middleware (Backend)
- Logging infrastructure (Both)

**Data Flow:**
```
User → ChatComposer → SendChatMessageUseCase
  → HttpAiChatService → HTTP POST /api/v1/chat/echo
  → Backend Echo Handler → ChatResponse
  → HttpAiChatService → UseCase → UI Update
```

**Key Decisions:**
- 30-second timeout for all requests
- 3 retry attempts with exponential backoff (1s, 2s, 4s)
- Correlation IDs for request tracing
- Structured JSON logging

**Deliverables:**
- HttpAiChatService implementation
- Backend echo endpoint
- Retry policy configuration
- Logging integration with AppLogger
- Network connectivity detection
- Manual test scenarios


### Stage 2: Basic LLM Integration

**Goal:** Connect backend to real LLM provider and generate contextual responses.

**Components:**
- LLM provider integration (Backend)
- System prompt template (Backend)
- Token counting utilities (Backend)
- Rate limiting middleware (Backend)

**Data Flow:**
```
User → HttpAiChatService → HTTP POST /api/v1/chat/message
  → Backend → Construct Prompt (system + history + user message)
  → LLM API (Together AI / OpenAI) → LLM Response
  → Backend → Parse Response → ChatResponse
  → HttpAiChatService → UI Update
```

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
{last_3_messages}

User message: {user_message}
```

**Token Budget:** 2500 tokens total
- System prompt: 500 tokens
- Message history: 1000 tokens (last 3 exchanges)
- Response: 1000 tokens

**Key Decisions:**
- Use Together AI as primary provider (Llama 70B)
- Include last 3 conversation turns for continuity
- 60-second timeout for LLM requests
- Rate limit: 10 requests/minute per user

**Deliverables:**
- LLM provider integration module
- System prompt template (versioned)
- Token counting utilities
- Rate limiting middleware
- LLM error classification
- Token usage analytics


### Stage 3: Basic Space Context Integration

**Goal:** Enhance LLM responses with awareness of user's active Space and recent records.

**Components:**
- SpaceContextBuilder (Flutter)
- RecordSummaryFormatter (Flutter)
- Context assembly pipeline (Backend)

**Data Flow:**
```
User → SendChatMessageUseCase
  → Build SpaceContext (active Space + last 10 records)
  → HttpAiChatService → HTTP POST with context payload
  → Backend → Construct Prompt (system + context + history + message)
  → LLM API → LLM Response
  → Backend → ChatResponse
  → UI Update
```

**Context Payload Structure:**
```json
{
  "spaceContext": {
    "spaceId": "health",
    "spaceName": "Health",
    "description": "Medical records and wellness tracking",
    "categories": ["Appointment", "Lab", "Medication"],
    "recentRecords": [
      {
        "title": "Cardiology Visit",
        "type": "Appointment",
        "date": "2025-11-20",
        "tags": ["cardiology", "bp"],
        "summary": "Follow-up appointment for blood pressure monitoring..."
      }
    ]
  }
}
```

**Enhanced System Prompt:**
```
You are a compassionate AI companion helping users organize their personal information.

Current Space: {space_name}
Space Description: {space_description}
Available Categories: {categories}

Recent Records:
{record_summaries}

Guidelines:
- Reference user's actual records when relevant
- Use space-specific terminology
- Suggest appropriate categories for new information
- Be helpful, empathetic, and respectful

Conversation History:
{history}

User message: {user_message}
```

**Token Budget:** 4000 tokens total
- System prompt: 500 tokens
- Space context: 1500 tokens (10 records × 150 tokens each)
- Message history: 1000 tokens
- Response: 1000 tokens

**Key Decisions:**
- Limit to last 10 records from active Space
- Truncate record summaries to 100 characters
- Exclude deleted records
- Never include records from other Spaces

**Deliverables:**
- SpaceContextBuilder module
- RecordSummaryFormatter
- Context assembly pipeline
- Token budget enforcement
- Space metadata serialization
- Context validation rules


### Stage 4: Context Optimization Layer

**Goal:** Implement intelligent filtering and prioritization to maximize context relevance within token budget.

**Components:**
- ContextFilterEngine (Flutter)
- TokenBudgetAllocator (Flutter)
- RecordRelevanceScorer (Flutter)
- ContextTruncationStrategy (Flutter)

**Data Flow:**
```
User → SendChatMessageUseCase
  → Load all records from active Space
  → Apply date range filter (default 14 days)
  → Score records by relevance (recency + access frequency)
  → Sort by relevance score
  → Allocate token budget (system/context/history/response)
  → Truncate to fit budget
  → Build optimized context
  → HttpAiChatService → Backend → LLM
```

**Token Budget Allocation:**
```
Total: 4800 tokens
- System prompt + persona: 800 tokens
- Context (optimized): 2000 tokens
- Message history: 1000 tokens
- Response reservation: 1000 tokens
```

**Filtering Strategy:**
1. Filter by date range (configurable: 7/14/30 days)
2. Filter by Space (active Space only)
3. Exclude deleted records
4. Score by relevance:
   - Recency: newer records score higher
   - Access frequency: frequently viewed records score higher
   - Keyword match: records matching query terms score higher
5. Sort by score descending
6. Take top N records that fit token budget

**Truncation Strategy:**
- If context exceeds budget, remove lowest-scoring records first
- Never truncate system prompt or response reservation
- Log truncation statistics for monitoring

**Enhanced System Prompt:**
```
You are a compassionate AI companion helping users organize their personal information.

Active Space: {space_name} ({space_description})

Relevant Records (filtered by date and relevance):
{optimized_record_summaries}

Context Notes:
- Showing {records_included} of {total_records} records
- Date range: {date_range}
- Older records summarized for brevity

Guidelines:
- Reference user's actual records when relevant
- Acknowledge if information might be incomplete
- Suggest exploring other time periods if needed

Conversation History:
{history}

User message: {user_message}
```

**Key Decisions:**
- Default date window: 14 days (configurable)
- Maximum records after filtering: 20
- Context token budget: 2000 tokens
- Minimum response reservation: 1000 tokens

**Deliverables:**
- Context filtering engine
- Token budget allocator
- Record relevance scorer
- Date range filter implementation
- Context truncation strategies
- Budget enforcement middleware
- Context selection telemetry


### Stage 5: Context Compression Engine

**Goal:** Reduce token consumption through intelligent summarization and deduplication.

**Components:**
- RecordSummarizationEngine (Flutter)
- DeduplicationAlgorithm (Flutter)
- SummaryCache (Flutter)
- ProgressiveDetailReducer (Flutter)

**Data Flow:**
```
User → SendChatMessageUseCase
  → Load filtered records (from Stage 4)
  → Check summary cache for each record
  → Generate summaries for uncached records:
    - Recent (< 7 days): full detail (100 tokens)
    - Medium (7-30 days): moderate summary (50 tokens)
    - Old (> 30 days): minimal summary (25 tokens)
  → Deduplicate repeated information
  → Cache new summaries (TTL: 7 days)
  → Build compressed context
  → HttpAiChatService → Backend → LLM
```

**Progressive Detail Reduction:**

| Record Age | Detail Level | Token Budget | Example |
|------------|--------------|--------------|---------|
| < 7 days | Full | 100 tokens | "Cardiology visit on Nov 20. Dr. Smith reviewed blood pressure readings: 135/85 (slightly elevated). Discussed medication adjustment. Follow-up in 3 months. Patient reports occasional dizziness." |
| 7-30 days | Moderate | 50 tokens | "Cardiology visit Nov 20. BP: 135/85. Medication adjusted. Follow-up in 3 months." |
| > 30 days | Minimal | 25 tokens | "Cardiology visit Nov 20. BP monitoring." |

**Deduplication Strategy:**
1. Extract key entities from each record (dates, names, categories)
2. Identify records with overlapping entities
3. Merge duplicate information:
   - Keep most recent version
   - Combine unique details
   - Mark as "consolidated from N records"
4. Log deduplication statistics

**Summary Cache:**
- Storage: SharedPreferences (key: recordId + age bucket)
- TTL: 7 days
- Invalidation: on record update or deletion
- Max size: 1000 summaries
- Eviction: LRU (Least Recently Used)

**Token Savings Metrics:**
```
Before compression: 2500 tokens (10 records × 250 tokens avg)
After compression: 800 tokens (10 records × 80 tokens avg)
Savings: 68%
```

**Key Decisions:**
- Age thresholds: 7 days (recent), 30 days (old)
- Cache TTL: 7 days
- Maximum cache size: 1000 summaries
- Deduplication threshold: 70% entity overlap

**Deliverables:**
- Record summarization engine
- Deduplication algorithm
- Summary cache implementation
- Progressive detail reducer
- Cache invalidation logic
- Token savings analytics
- Compression ratio metrics


### Stage 6: Intent-Driven Context Retrieval

**Goal:** Dynamically select context based on user query intent, implementing RAG-like behavior.

**Components:**
- IntentClassifier (Flutter)
- KeywordExtractor (Flutter)
- RelevanceScorer (Flutter)
- PrivacyFilterEnforcer (Flutter)
- CrossSpaceRetriever (Flutter)

**Data Flow:**
```
User → SendChatMessageUseCase
  → Analyze user query:
    - Extract keywords
    - Classify intent (question/command/statement)
    - Identify entities (dates, categories, names)
  → Retrieve records:
    - Match keywords (case-insensitive, stemmed)
    - Score relevance per record
    - Apply privacy filters
    - Allow cross-space if query mentions space
  → Sort by relevance
  → Take top 15 matches
  → Apply compression (from Stage 5)
  → Build intent-matched context
  → HttpAiChatService → Backend → LLM
```

**Intent Classification:**

| Intent Type | Indicators | Example Query | Retrieval Strategy |
|-------------|-----------|---------------|-------------------|
| Question | "what", "when", "how", "?" | "What were my health appointments last month?" | Retrieve records matching keywords + time range |
| Command | "show", "find", "list" | "Show me all cardiology records" | Retrieve records matching category/tag |
| Statement | Declarative sentence | "I had a doctor visit today" | Retrieve recent similar records for context |

**Keyword Extraction:**
1. Tokenize query
2. Remove stop words ("the", "a", "is", etc.)
3. Apply stemming (e.g., "running" → "run")
4. Extract entities:
   - Dates: "last month", "November", "2025-11-20"
   - Categories: "appointment", "lab", "medication"
   - Tags: "cardiology", "bp", "diabetes"
5. Weight by importance:
   - Entities: 3x weight
   - Content words: 1x weight

**Relevance Scoring:**
```
score = (keyword_matches × 10) + (entity_matches × 30) + (recency_score × 5)

where:
- keyword_matches = count of query keywords in record
- entity_matches = count of extracted entities in record
- recency_score = 10 - (days_old / 30) clamped to [0, 10]
```

**Privacy Filters:**
- Exclude records marked "private"
- Exclude records from disabled Spaces
- Redact sensitive fields before transmission:
  - Never include record IDs
  - Never include encryption keys
  - Never include local file paths

**Cross-Space Retrieval:**
- Enabled only if query explicitly mentions another Space
- Example: "Compare my health and finance records"
- Requires explicit Space name match
- Limited to 5 records per Space

**Enhanced System Prompt:**
```
You are a compassionate AI companion helping users organize their personal information.

User's Active Space: {space_name}
Query Intent: {intent_classification}

Relevant Information (selected based on your query):
{intent_matched_records}

{persona_specific_guidelines}

Core Guidelines:
- Reference specific records when answering
- Acknowledge limitations in available data
- Maintain {persona_tone} throughout
- Provide actionable suggestions when appropriate

Recent Conversation:
{history}

User query: {user_message}
```

**Token Budget:** 5300 tokens total
- System prompt + persona: 800 tokens
- Intent-matched context: 2500 tokens
- Message history: 1000 tokens
- Response reservation: 1000 tokens

**Key Decisions:**
- Intent analysis timeout: 100ms
- Maximum records retrieved: 15
- Keyword matching: case-insensitive, stemmed
- Privacy filters: always enforced
- Cross-space: explicit mention required

**Deliverables:**
- Intent classification module
- Keyword extraction engine
- Relevance scoring algorithm
- Privacy filter enforcement
- Cross-space retrieval logic
- Intent-based retrieval pipeline
- Retrieval audit logging


### Stage 7: Full Intelligent Contextual AI

**Goal:** Deliver production-ready AI companion with robust prompting, error recovery, telemetry, and extensibility.

**Components:**
- PersonaSystem (Flutter + Backend)
- ErrorRecoveryOrchestrator (Backend)
- TelemetryCollector (Both)
- QualityMonitor (Backend)
- ToolRegistry (Backend)
- FeedbackCollector (Flutter)

**Data Flow:**
```
User → SendChatMessageUseCase
  → Select AI persona based on Space
  → Build comprehensive context (Stages 4-6)
  → HttpAiChatService → Backend
  → Construct persona-specific prompt
  → LLM API call with error recovery:
    - Attempt 1: Full context
    - Attempt 2 (if fail): Reduced context
    - Fallback: Generic helpful response
  → Parse response
  → Check for tool invocations
  → Execute tools if needed
  → Collect telemetry
  → Monitor quality
  → Return ChatResponse
  → Prompt for user feedback
  → UI Update
```

**Persona System:**

| Space | Persona | Tone | Guidelines | Example Response |
|-------|---------|------|------------|------------------|
| Health | Health Companion | Empathetic, cautious | Avoid medical advice, suggest consulting professionals, use safety disclaimers | "I can see you're tracking blood pressure. While I can help organize this data, please consult your doctor for medical guidance." |
| Education | Study Coach | Constructive, encouraging | Focus on learning strategies, break down complex topics, provide study tips | "Let's break this topic into manageable chunks. I can help you create a study schedule and organize your notes." |
| Finance | Financial Advisor | Practical, budget-conscious | Focus on budgeting, expense tracking, savings goals | "I notice several recurring expenses. Let's categorize them and see where you might optimize your budget." |
| Travel | Travel Planner | Exploratory, organized | Focus on itineraries, bookings, packing lists | "Exciting trip! Let's organize your itinerary and make sure you have all necessary documents." |

**Comprehensive System Prompt Template:**
```
You are {persona_description}.

User's Active Space: {space_name}
Query Intent: {intent_classification}

Relevant Information (selected based on your query):
{intent_matched_records}

{persona_specific_guidelines}

Core Guidelines:
- Reference specific records when answering
- Acknowledge limitations in available data
- Maintain {persona_tone} throughout
- Provide actionable suggestions when appropriate
- Never fabricate information
- Respect user privacy

Recent Conversation:
{history}

User query: {user_message}
```

**Error Recovery Strategies:**

1. **Strategy 1: Reduce Context**
   - Remove oldest records
   - Reduce history to last 2 messages
   - Retry with smaller payload

2. **Strategy 2: Simplify Prompt**
   - Use minimal system prompt
   - Remove persona guidelines
   - Include only user message

3. **Fallback: Generic Response**
   - Return helpful message without LLM
   - Suggest trying again later
   - Queue for retry when service recovers

**Telemetry Collection:**

```json
{
  "event": "chat_request_complete",
  "correlationId": "uuid",
  "userId": "uuid",
  "threadId": "uuid",
  "spaceId": "health",
  "persona": "health_companion",
  "stage": 7,
  "metrics": {
    "intentAnalysisMs": 45,
    "contextAssemblyMs": 120,
    "llmLatencyMs": 1850,
    "totalLatencyMs": 2015,
    "tokensPrompt": 3200,
    "tokensCompletion": 450,
    "tokensTotal": 3650,
    "recordsFiltered": 50,
    "recordsIncluded": 12,
    "compressionRatio": 0.68,
    "cacheHitRate": 0.75
  },
  "quality": {
    "confidence": 0.88,
    "userFeedback": null
  }
}
```

**Quality Monitoring:**
- Track percentage of positive feedback
- Alert if quality drops below 80%
- Identify problematic query patterns
- A/B test prompt variations

**Tool Registry:**

```dart
abstract class AiTool {
  String get name;
  String get description;
  Future<ToolResult> execute(Map<String, dynamic> parameters);
}

class ToolRegistry {
  final Map<String, AiTool> _tools = {};
  
  void register(AiTool tool) {
    _tools[tool.name] = tool;
  }
  
  Future<ToolResult> invoke(String toolName, Map<String, dynamic> params) {
    final tool = _tools[toolName];
    if (tool == null) throw ToolNotFoundException(toolName);
    return tool.execute(params);
  }
}

// Example tools:
// - WebSearchTool: Search the web for information
// - CalculatorTool: Perform calculations
// - CalendarTool: Check user's calendar
// - ReminderTool: Set reminders
```

**Token Budget:** 5800 tokens total
- System prompt + persona: 800 tokens
- Intent-matched context: 2500 tokens
- Message history: 1000 tokens
- Response reservation: 1500 tokens

**Key Decisions:**
- Error recovery attempts: 2 (with different strategies)
- Telemetry overhead: < 50ms per request
- Quality threshold: 80% positive feedback
- Tool execution timeout: 10 seconds
- Persona switching: seamless within thread

**Deliverables:**
- Persona system architecture
- Comprehensive system prompt templates
- Error recovery strategies
- Telemetry integration
- Quality monitoring dashboard
- User feedback collection UI
- Tool registry and invocation framework
- Production readiness checklist


## Backend Requirements

### Endpoint Structure

#### Stage 1: Echo Endpoint

**Endpoint:** `POST /api/v1/chat/echo`

**Purpose:** Validate HTTP connectivity and request/response cycle.

**Request Headers:**
- `Content-Type: application/json`
- `X-Correlation-ID: <uuid>`
- `X-Client-Version: <app-version>`
- `Authorization: Bearer <user-token>`

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
    "stage": "echo"
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

#### Stage 2-7: LLM Chat Endpoint

**Endpoint:** `POST /api/v1/chat/message`

**Purpose:** Process chat message with LLM integration and context.

**Request Headers:**
- `Content-Type: application/json`
- `X-Correlation-ID: <uuid>`
- `X-Client-Version: <app-version>`
- `X-Stage: <stage-number>`
- `Authorization: Bearer <user-token>`

**Request Body (Evolves by Stage):**

**Stage 2:**
```json
{
  "threadId": "thread_123",
  "message": "Can you help me organize my health records?",
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
    }
  ]
}
```

**Stage 3-7 (Additional Fields):**
```json
{
  "threadId": "thread_123",
  "message": "What were my recent health appointments?",
  "timestamp": "2025-11-24T10:00:00Z",
  "userId": "user_456",
  "history": [...],
  "context": {
    "activeSpace": {
      "id": "health",
      "name": "Health",
      "description": "Medical records and wellness tracking",
      "categories": ["Appointment", "Lab", "Medication"]
    },
    "records": [
      {
        "id": "rec_789",
        "title": "Cardiology Visit",
        "type": "Appointment",
        "date": "2025-11-20",
        "tags": ["cardiology", "bp"],
        "summary": "Follow-up appointment for blood pressure monitoring..."
      }
    ],
    "filters": {
      "dateRange": {
        "start": "2025-11-10",
        "end": "2025-11-24"
      },
      "maxRecords": 20
    }
  },
  "intent": {
    "classification": "question",
    "keywords": ["recent", "health", "appointments"],
    "entities": ["health", "appointments"]
  },
  "persona": "health_companion",
  "tokenBudget": {
    "system": 800,
    "context": 2500,
    "history": 1000,
    "response": 1500
  }
}
```

**Response Body (Success - 200):**
```json
{
  "responseId": "response_789",
  "threadId": "thread_123",
  "message": "Based on your records, you had a cardiology visit on November 20th for blood pressure monitoring. Would you like me to help you track your BP readings or schedule a follow-up?",
  "timestamp": "2025-11-24T10:00:03Z",
  "metadata": {
    "processingTimeMs": 1850,
    "stage": "7",
    "tokenUsage": {
      "prompt": 3200,
      "completion": 450,
      "total": 3650
    },
    "llmProvider": "together",
    "modelVersion": "llama-70b",
    "finishReason": "stop",
    "contextStats": {
      "recordsIncluded": 12,
      "recordsFiltered": 50,
      "compressionRatio": 0.68
    },
    "qualityScore": 0.88
  },
  "references": [
    {
      "recordId": "rec_789",
      "title": "Cardiology Visit",
      "relevance": 0.95
    }
  ]
}
```


### Prompt Construction Rules

#### Stage 2: Base System Prompt

**Template:**
```
You are a compassionate AI companion helping users organize their personal information.

Guidelines:
- Be helpful, empathetic, and respectful
- Provide clear, concise responses
- Acknowledge uncertainty when appropriate
- Never fabricate information
- Respect user privacy

Current conversation:
{history}

User message: {user_message}
```

**Token Budget:** 500 tokens

#### Stage 3: Space-Aware Prompt

**Template:**
```
You are a compassionate AI companion helping users organize their personal information.

Current Space: {space_name}
Space Description: {space_description}
Available Categories: {categories}

Recent Records:
{record_summaries}

Guidelines:
- Reference user's actual records when relevant
- Use space-specific terminology
- Suggest appropriate categories for new information
- Be helpful, empathetic, and respectful

Conversation History:
{history}

User message: {user_message}
```

**Token Budget:** 500 (system) + 1500 (context) = 2000 tokens

#### Stage 4-5: Optimized Context Prompt

**Template:**
```
You are a compassionate AI companion helping users organize their personal information.

Active Space: {space_name} ({space_description})

Relevant Records (filtered by date and relevance):
{optimized_record_summaries}

Context Notes:
- Showing {records_included} of {total_records} records
- Date range: {date_range}
- Older records summarized for brevity

Guidelines:
- Reference user's actual records when relevant
- Acknowledge if information might be incomplete
- Suggest exploring other time periods if needed

Conversation History:
{history}

User message: {user_message}
```

**Token Budget:** 800 (system) + 2000 (context) + 1000 (history) = 3800 tokens

#### Stage 6-7: Intent-Driven Prompt with Persona

**Template:**
```
You are {persona_description}.

User's Active Space: {space_name}
Query Intent: {intent_classification}

Relevant Information (selected based on your query):
{intent_matched_records}

{persona_specific_guidelines}

Core Guidelines:
- Reference specific records when answering
- Acknowledge limitations in available data
- Maintain {persona_tone} throughout
- Provide actionable suggestions when appropriate

Recent Conversation:
{history}

User query: {user_message}
```

**Persona Descriptions:**
- **Health Companion:** "You are a caring health companion helping users track their wellness. Provide empathetic support while avoiding medical advice. Always suggest consulting healthcare professionals for medical decisions."
- **Study Coach:** "You are a supportive study coach helping users achieve their academic goals. Provide constructive feedback, learning strategies, and organizational tips."
- **Financial Advisor:** "You are a practical financial advisor helping users manage their finances. Focus on budgeting, expense tracking, and savings goals."
- **Travel Planner:** "You are an enthusiastic travel planner helping users organize their trips. Focus on itineraries, bookings, and travel tips."

**Token Budget:** 800 (system + persona) + 2500 (context) + 1000 (history) = 4300 tokens

### Safety Rules

**Privacy Protection:**
- Never log user messages or LLM responses containing PHI
- Redact sensitive fields before logging (names, addresses, SSNs, etc.)
- Enforce privacy filters on record summaries
- Exclude records marked "private" from context
- Audit all context inclusion decisions

**Content Safety:**
- Validate LLM responses for harmful content
- Block responses containing medical advice beyond general wellness
- Reject responses suggesting illegal activities
- Flag responses with high uncertainty for review
- Implement content moderation filters

**Rate Limiting:**
- Per-user: 10 requests/minute
- Per-user: 100 requests/hour
- Per-user: 500 requests/day
- Global: 1000 requests/minute
- Implement exponential backoff on rate limit hits

**Input Validation:**
- Maximum message length: 2000 characters
- Maximum thread history: 50 messages
- Maximum context records: 20
- Reject malformed JSON
- Sanitize user input for prompt injection

**Token Budget Enforcement:**
- Hard limit: 8000 tokens per request
- Reserve minimum 1000 tokens for response
- Truncate context if budget exceeded
- Log budget violations
- Alert on repeated violations

### Token Usage Policy

**Budget Allocation by Stage:**

| Stage | System | Context | History | Response | Total |
|-------|--------|---------|---------|----------|-------|
| 1     | 0      | 0       | 0       | 0        | 0     |
| 2     | 500    | 0       | 1000    | 1000     | 2500  |
| 3     | 500    | 1500    | 1000    | 1000     | 4000  |
| 4     | 800    | 2000    | 1000    | 1000     | 4800  |
| 5     | 800    | 2000    | 1000    | 1000     | 4800  |
| 6     | 800    | 2500    | 1000    | 1000     | 5300  |
| 7     | 800    | 2500    | 1000    | 1500     | 5800  |

**Token Counting:**
- Use LLM provider's tokenizer (e.g., tiktoken for GPT models)
- Count tokens before sending request
- Validate response token count
- Log actual vs. estimated token usage
- Alert on significant discrepancies (>10%)

**Cost Management:**
- Track token usage per user per day
- Implement soft limits (warn at 80% of daily budget)
- Implement hard limits (block at 100% of daily budget)
- Provide usage dashboard for users
- Alert administrators on unusual usage patterns

### Logging and Observability

**Required Log Events:**

**Request Received:**
```json
{
  "event": "chat_request_received",
  "correlationId": "uuid",
  "userId": "uuid",
  "threadId": "uuid",
  "stage": 7,
  "timestamp": "2025-11-24T10:00:00Z",
  "messageLength": 45
}
```

**Context Assembly:**
```json
{
  "event": "context_assembled",
  "correlationId": "uuid",
  "stage": 7,
  "recordsFiltered": 50,
  "recordsIncluded": 12,
  "tokenEstimate": 2500,
  "compressionRatio": 0.68,
  "assemblyTimeMs": 120
}
```

**LLM Request:**
```json
{
  "event": "llm_request_sent",
  "correlationId": "uuid",
  "provider": "together",
  "model": "llama-70b",
  "promptTokens": 3200,
  "timestamp": "2025-11-24T10:00:01Z"
}
```

**LLM Response:**
```json
{
  "event": "llm_response_received",
  "correlationId": "uuid",
  "completionTokens": 450,
  "totalTokens": 3650,
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
  "errorCode": "TIMEOUT",
  "errorMessage": "Request timed out after 30 seconds",
  "stage": 7,
  "retryable": true,
  "timestamp": "2025-11-24T10:00:30Z"
}
```

**Metrics to Track:**
- Request rate (per minute, hour, day)
- Average response latency
- Token usage (prompt, completion, total)
- Error rate by type
- Context assembly time
- Cache hit rate (Stage 5+)
- Intent classification accuracy (Stage 6+)
- User feedback scores (Stage 7)

**Observability Tools:**
- Structured logging (JSON format)
- Correlation IDs for request tracing
- Distributed tracing (OpenTelemetry compatible)
- Real-time metrics dashboard
- Alert rules for anomalies

### Retry and Timeout Strategy

**Timeout Configuration:**
- HTTP connection timeout: 10 seconds
- LLM request timeout: 60 seconds (Stage 2-5), 90 seconds (Stage 6-7)
- Context assembly timeout: 5 seconds
- Total request timeout: 120 seconds

**Retry Policy:**

**Transient Errors (Retryable):**
- Network timeouts
- HTTP 500, 502, 503, 504
- LLM provider rate limits (429)
- Temporary unavailability

**Retry Strategy:**
- Attempt 1: Immediate
- Attempt 2: 2 seconds delay
- Attempt 3: 4 seconds delay
- Max attempts: 3
- Exponential backoff with jitter

**Non-Retryable Errors:**
- HTTP 400 (bad request)
- HTTP 401 (unauthorized)
- HTTP 403 (forbidden)
- Invalid JSON
- Token budget exceeded
- Content policy violations

**Fallback Strategies:**
- Stage 2-3: Return generic helpful message
- Stage 4-7: Return response without context
- All stages: Queue message for later retry if offline
- All stages: Notify user of degraded service

