# Requirements Document

## Introduction

The Universal Life Companion is evolving to include an optional AI assistant that helps users quickly understand their Information Items through intelligent summarization. The system currently stores detailed notes, attachments, and metadata across multiple Spaces (Health, Finance, Education, etc.), but users must read entire entries to extract key information. The AI Summarization feature (v1) will provide short, compassionate summaries that highlight essential details and suggest actionable next steps, while maintaining the app's local-first, privacy-focused architecture.

## Glossary

- **Information Item**: A record stored in the app containing title, category, tags, body text, and attachments
- **Space**: A distinct life area (e.g., Health, Finance, Education) with its own categories and visual identity
- **AI Service**: An abstraction layer that provides AI capabilities without coupling to specific vendors
- **Summary**: A concise, user-friendly text (≤120 words) that captures the essence of an Information Item
- **Action Hints**: Optional bullet points (up to 3, each ≤12 words) suggesting next steps
- **Fake AI Service**: A deterministic implementation used for development and testing
- **HTTP AI Service**: A real implementation that communicates with a backend proxy
- **Logging AI Service**: A decorator that wraps any AI Service to provide diagnostic telemetry
- **Opt-in**: User must explicitly enable AI features through consent flow
- **Local-first**: Data remains on-device by default; AI processing requires explicit user action

## Requirements

### Requirement 1

**User Story:** As a user with many detailed Information Items, I want to see short summaries of my entries, so that I can quickly scan key information without reading entire notes.

#### Acceptance Criteria

1. WHEN a user views an Information Item detail screen, THE System SHALL provide an option to generate a summary
2. WHEN a user requests a summary, THE System SHALL display a loading indicator while processing
3. WHEN summarization completes successfully, THE System SHALL display summary text of 120 words or fewer
4. WHEN summarization completes successfully, THE System SHALL optionally display up to 3 action hints of 12 words or fewer each
5. IF summarization fails, THEN THE System SHALL display a user-friendly error message with retry option

### Requirement 2

**User Story:** As a privacy-conscious user, I want AI features to be opt-in and transparent, so that I understand what data leaves my device and can control AI usage.

#### Acceptance Criteria

1. THE System SHALL disable all AI features by default until user explicitly enables them
2. WHEN a user first attempts to use AI features, THE System SHALL display a consent dialog explaining what data will be processed
3. THE System SHALL clearly indicate which Information Item fields are sent for processing (title, category, tags, notes, attachment descriptors)
4. THE System SHALL never send Information Item IDs or attachment binary data off-device
5. WHEN a user disables AI features, THE System SHALL immediately stop all AI processing and hide AI UI elements

### Requirement 3

**User Story:** As a developer, I want AI functionality to be testable and replaceable, so that I can develop features without depending on external services and can swap providers easily.

#### Acceptance Criteria

1. THE System SHALL define an AiService interface that abstracts all AI operations
2. THE System SHALL provide a FakeAiService implementation that returns deterministic results for testing
3. THE System SHALL provide a LoggingAiService decorator that wraps any AiService and emits diagnostic logs
4. THE System SHALL provide an HttpAiService implementation that communicates with a backend proxy
5. THE System SHALL allow switching between AI service implementations via dependency injection without code changes

### Requirement 4

**User Story:** As a user, I want AI summaries to be compassionate and neutral, so that I feel supported rather than judged or overwhelmed.

#### Acceptance Criteria

1. WHEN generating a summary, THE System SHALL use a neutral-to-positive tone
2. THE System SHALL avoid medical advice, financial recommendations, or prescriptive language
3. THE System SHALL present information in plain, accessible language appropriate for the Space context
4. WHEN generating action hints, THE System SHALL frame suggestions as optional next steps rather than requirements
5. THE System SHALL maintain cultural sensitivity and avoid assumptions about user circumstances

### Requirement 5

**User Story:** As a system administrator monitoring app health, I want comprehensive logging of AI operations, so that I can diagnose issues and track usage patterns.

#### Acceptance Criteria

1. WHEN an AI operation starts, THE System SHALL log the operation with timestamp, Information Item ID, and Space ID
2. WHEN an AI operation completes, THE System SHALL log duration, token usage, provider name, and confidence score
3. IF an AI operation fails, THEN THE System SHALL log error details, retry attempts, and whether the error is retryable
4. THE System SHALL redact sensitive text from logs while preserving diagnostic metadata
5. THE System SHALL make AI operation logs accessible through the Diagnostic System UI

### Requirement 6

**User Story:** As a user on a slow network, I want AI operations to handle timeouts gracefully, so that the app remains responsive even when AI services are unavailable.

#### Acceptance Criteria

1. WHEN an AI request exceeds 30 seconds, THE System SHALL timeout and display an error message
2. WHEN a timeout occurs, THE System SHALL allow the user to retry the operation
3. WHEN network connectivity is lost during AI processing, THE System SHALL detect the failure and provide appropriate feedback
4. THE System SHALL implement exponential backoff for retries with a maximum of 3 attempts
5. WHEN AI services are unavailable, THE System SHALL allow users to continue using all non-AI features without degradation

### Requirement 7

**User Story:** As a developer implementing AI features, I want clear separation between AI logic and UI, so that I can test business logic independently and maintain clean architecture.

#### Acceptance Criteria

1. THE System SHALL define a SummarizeInformationItemUseCase in the application layer
2. THE System SHALL ensure UI components depend only on use cases, never directly on AI services
3. THE System SHALL provide view models or controllers that manage AI operation state (loading, success, error)
4. THE System SHALL keep all AI service implementations in the infrastructure layer
5. THE System SHALL register AI services through dependency injection (AppContainer or Riverpod providers)

### Requirement 8

**User Story:** As a QA engineer, I want to validate AI quality with test fixtures, so that I can ensure summaries meet quality standards before production release.

#### Acceptance Criteria

1. THE System SHALL provide a collection of anonymized test Information Items covering multiple Spaces
2. THE System SHALL document expected summary characteristics (tone, length, correctness, action hint relevance)
3. WHEN running QA tests, THE System SHALL log actual AI responses for comparison against expectations
4. THE System SHALL maintain a quality journal documenting AI behavior and issues discovered during testing
5. THE System SHALL allow QA to toggle between Fake and Real AI services for comparative testing

### Requirement 9

**User Story:** As a product manager, I want AI features to be controlled by feature flags, so that I can enable them gradually and disable them quickly if issues arise.

#### Acceptance Criteria

1. THE System SHALL provide an `ai_enabled` configuration flag that defaults to false
2. THE System SHALL provide an `ai_mode` configuration flag with values `fake` or `remote`
3. WHEN `ai_enabled` is false, THE System SHALL hide all AI UI elements
4. WHEN `ai_mode` is `fake`, THE System SHALL use FakeAiService regardless of other configuration
5. THE System SHALL persist AI configuration flags in SharedPreferences or equivalent local storage

### Requirement 10

**User Story:** As a user, I want AI summaries to respect my Space context, so that summaries are relevant to the type of information I'm viewing.

#### Acceptance Criteria

1. WHEN generating a summary, THE System SHALL include the Space name and category in the AI request context
2. THE System SHALL tailor summary language to the Space domain (e.g., health-appropriate vs. finance-appropriate terminology)
3. WHEN an Information Item has attachments, THE System SHALL include attachment descriptors (type and filename) in the context
4. THE System SHALL use Information Item tags to provide additional context for summarization
5. THE System SHALL ensure summaries reflect the user's organizational structure and terminology
