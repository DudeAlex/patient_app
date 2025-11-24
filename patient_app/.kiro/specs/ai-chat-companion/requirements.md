# Requirements Document

## Introduction

The Universal Life Companion app currently provides AI summarization for individual Information Items. Users want a more interactive, conversational AI experience similar to ChatGPT mobile or Telegram, where they can have ongoing dialogues with an AI assistant that understands their Space context (Health, Education, Finance, etc.) and has awareness of their records within that domain. This Space-Aware AI Chat Interface will provide a full-screen chat experience where users can send text messages, photos, voice recordings, and files, receiving contextual, compassionate responses tailored to their current Space.

## Glossary

- **AI Chat Screen**: A full-screen conversational interface with message bubbles, similar to messaging apps
- **Space Context**: The current Space (Health, Education, Finance, etc.) that determines AI tone, behavior, and available records
- **Message Bubble**: A chat message displayed in the conversation, either from the user or AI
- **Composer**: The input area at the bottom of the chat screen with text field and attachment buttons
- **Chat Thread**: A conversation history associated with a specific Space or record
- **Attachment**: A photo, voice recording, or file sent within the chat
- **Context Chip**: A UI element showing which Space/record context the AI is using
- **Voice Note**: An audio recording sent as a message attachment
- **AI Persona**: The tone and behavior the AI adopts based on the Space (e.g., empathetic for Health, study-focused for Education)
- **Message History**: Previous messages in the conversation used as context for AI responses
- **Inline Preview**: A thumbnail or preview of an attachment shown within a message bubble

## Requirements

### Requirement 1

**User Story:** As a user, I want to access a conversational AI chat interface from any Space, so that I can have interactive dialogues about my records in that domain.

#### Acceptance Criteria

1. WHEN a user taps the AI icon from any screen, THE System SHALL open a full-screen AI chat interface
2. WHEN the chat screen opens, THE System SHALL inherit the current Space context (Health, Education, Finance, etc.)
3. WHEN the chat screen opens from a record detail screen, THE System SHALL include that record as additional context
4. THE System SHALL display a context chip in the header showing the active Space name and icon
5. WHEN AI features are disabled or consent is missing, THE System SHALL show the consent dialog before opening the chat screen

### Requirement 2

**User Story:** As a user, I want the AI to understand my Space context and behave appropriately, so that responses are relevant and use appropriate tone for the domain.

#### Acceptance Criteria

1. WHEN the active Space is Health, THE System SHALL use an empathetic, cautious tone and avoid medical advice
2. WHEN the active Space is Education, THE System SHALL use a study-focused, constructive tone
3. WHEN the active Space is Finance, THE System SHALL use a practical, budget-conscious tone
4. WHEN the active Space is Travel, THE System SHALL use an exploratory, planning-focused tone
5. THE System SHALL tailor suggestions and responses to match the Space domain

### Requirement 3

**User Story:** As a user, I want to send text messages to the AI, so that I can ask questions and have conversations about my records.

#### Acceptance Criteria

1. THE System SHALL provide a text input field in the composer at the bottom of the screen
2. WHEN a user types a message and taps send, THE System SHALL display the message as a user bubble
3. WHEN a message is sent, THE System SHALL show a loading indicator while the AI processes the request
4. WHEN the AI responds, THE System SHALL display the response as an AI bubble with timestamp
5. THE System SHALL maintain message history in the conversation thread

### Requirement 4

**User Story:** As a user, I want to send photos to the AI, so that I can get help understanding images related to my records.

#### Acceptance Criteria

1. THE System SHALL provide a camera/photo picker button in the composer
2. WHEN a user selects a photo, THE System SHALL display a thumbnail preview in the composer
3. WHEN a user sends a message with a photo, THE System SHALL include the photo in the user bubble
4. WHEN the AI processes a photo, THE System SHALL extract relevant information and respond with insights
5. THE System SHALL never send photo binary data off-device without explicit consent

### Requirement 5

**User Story:** As a user, I want to record and send voice messages to the AI, so that I can communicate hands-free like in Telegram.

#### Acceptance Criteria

1. THE System SHALL provide a microphone button in the composer
2. WHEN a user taps the microphone button, THE System SHALL start recording audio
3. WHILE recording, THE System SHALL display a duration indicator and waveform visualization
4. WHEN a user stops recording, THE System SHALL display the voice note as an attachment chip
5. WHEN a voice note is sent, THE System SHALL transcribe it and include both audio and text in the AI request

### Requirement 6

**User Story:** As a user, I want to send files to the AI, so that I can get help with documents related to my records.

#### Acceptance Criteria

1. THE System SHALL provide a file picker button in the composer
2. WHEN a user selects a file, THE System SHALL display the filename and file type in the composer
3. WHEN a user sends a message with a file, THE System SHALL include file metadata in the AI request
4. THE System SHALL support common file types (PDF, images, text documents)
5. THE System SHALL display file size limits and warn users before sending large files

### Requirement 7

**User Story:** As a privacy-conscious user, I want to understand what data the AI can access, so that I can make informed decisions about sharing information.

#### Acceptance Criteria

1. WHEN the chat screen opens, THE System SHALL display a banner explaining what data is accessible
2. THE System SHALL clearly indicate that the AI can access records from the current Space only
3. THE System SHALL show which specific record is being used as context (if applicable)
4. THE System SHALL never send Information Item IDs or encryption keys off-device
5. WHEN a user sends an attachment, THE System SHALL show a confirmation with data usage details

### Requirement 8

**User Story:** As a user, I want the chat interface to look and feel like modern messaging apps, so that it's familiar and easy to use.

#### Acceptance Criteria

1. THE System SHALL display messages as bubbles with user messages right-aligned and AI messages left-aligned
2. THE System SHALL show timestamps for each message
3. THE System SHALL display an avatar or icon for AI messages
4. THE System SHALL auto-scroll to the latest message when new messages arrive
5. THE System SHALL support smooth scrolling through message history

### Requirement 9

**User Story:** As a user, I want to see loading states and error messages clearly, so that I understand what's happening with my requests.

#### Acceptance Criteria

1. WHEN the AI is processing a request, THE System SHALL display an inline loading indicator in the chat
2. WHEN a request fails, THE System SHALL display an error message bubble with retry option
3. WHEN the network is unavailable, THE System SHALL show an offline indicator in the header
4. WHEN a response is truncated due to length limits, THE System SHALL indicate this to the user
5. THE System SHALL provide clear error messages for different failure types (timeout, network, server error)

### Requirement 10

**User Story:** As a user, I want to manage my chat history, so that I can clear conversations or review past interactions.

#### Acceptance Criteria

1. THE System SHALL provide a "Clear Chat" option in the header overflow menu
2. WHEN a user clears the chat, THE System SHALL delete all messages from the current thread
3. THE System SHALL persist chat threads per Space so conversations resume when returning
4. THE System SHALL allow users to view chat history even when offline
5. THE System SHALL include chat data in encrypted backups

### Requirement 11

**User Story:** As a developer, I want the chat interface to work with both Fake and Real AI services, so that I can develop and test without external dependencies.

#### Acceptance Criteria

1. THE System SHALL display a status pill in the header showing AI mode (Fake/Remote/Offline)
2. WHEN ai_mode is 'fake', THE System SHALL use FakeAiService for all chat interactions
3. WHEN ai_mode is 'remote', THE System SHALL use HttpAiService for all chat interactions
4. THE System SHALL allow switching between modes via Settings without losing chat history
5. THE System SHALL handle mode transitions gracefully with appropriate user feedback

### Requirement 12

**User Story:** As a user in the Health Space, I want the AI to provide empathetic, safety-conscious responses, so that I feel supported without receiving medical advice.

#### Acceptance Criteria

1. WHEN the Space is Health, THE System SHALL include safety disclaimers in AI responses
2. THE System SHALL avoid prescriptive medical advice or diagnoses
3. THE System SHALL use compassionate, supportive language
4. THE System SHALL suggest consulting healthcare professionals for medical decisions
5. THE System SHALL highlight when information is guidance-only, not medical advice

### Requirement 13

**User Story:** As a user in the Education Space, I want the AI to help me organize study materials and suggest learning strategies, so that I can improve my academic performance.

#### Acceptance Criteria

1. WHEN the Space is Education, THE System SHALL use constructive, study-oriented language
2. THE System SHALL suggest study plans, note organization, and deadline tracking
3. THE System SHALL help break down complex topics into manageable chunks
4. THE System SHALL provide encouragement and learning tips
5. THE System SHALL avoid overconfidence and acknowledge when topics require expert instruction

### Requirement 14

**User Story:** As a user, I want the AI to be aware of my existing records in the current Space, so that responses are contextually relevant to my data.

#### Acceptance Criteria

1. WHEN generating a response, THE System SHALL include recent records from the current Space as context
2. THE System SHALL limit context to records within the active Space only
3. THE System SHALL redact sensitive identifiers (IDs, keys) from the context payload
4. THE System SHALL include record titles, categories, tags, and summary text in the context
5. THE System SHALL respect a maximum context size to avoid token overuse

### Requirement 15

**User Story:** As a user, I want to switch Space context during a chat session, so that I can discuss different life areas without starting over.

#### Acceptance Criteria

1. THE System SHALL provide a "Change Context" option in the header overflow menu
2. WHEN a user changes Space context, THE System SHALL clear the current chat thread
3. WHEN a user changes Space context, THE System SHALL update the context chip and AI persona
4. THE System SHALL warn users before clearing the chat when changing context
5. THE System SHALL load the appropriate chat history for the new Space

### Requirement 16

**User Story:** As a user on a slow or unreliable network, I want the chat to handle connectivity issues gracefully, so that I can continue using the app.

#### Acceptance Criteria

1. WHEN the network is unavailable, THE System SHALL queue messages locally
2. WHEN connectivity is restored, THE System SHALL automatically retry queued messages
3. THE System SHALL show a clear offline indicator in the header status pill
4. WHEN in offline mode, THE System SHALL allow viewing chat history but disable sending
5. THE System SHALL implement exponential backoff for retry attempts

### Requirement 17

**User Story:** As a user, I want to see rich formatting in AI responses, so that information is easy to read and understand.

#### Acceptance Criteria

1. THE System SHALL support markdown formatting in AI response bubbles (bold, italic, lists)
2. THE System SHALL display action hints as tappable chips within AI bubbles
3. THE System SHALL support inline code blocks and links in responses
4. THE System SHALL render bullet points and numbered lists clearly
5. THE System SHALL maintain consistent typography and spacing in formatted text

### Requirement 18

**User Story:** As a system administrator, I want comprehensive logging of chat interactions, so that I can diagnose issues and monitor AI usage.

#### Acceptance Criteria

1. WHEN a chat message is sent, THE System SHALL log the event with timestamp and Space context
2. WHEN an AI response is received, THE System SHALL log token usage, latency, and confidence
3. WHEN an attachment is sent, THE System SHALL log attachment type and size (not content)
4. THE System SHALL redact message content from logs while preserving metadata
5. THE System SHALL make chat interaction logs accessible through the Diagnostic System UI

### Requirement 19

**User Story:** As a user, I want to copy text from AI responses, so that I can use the information elsewhere.

#### Acceptance Criteria

1. WHEN a user long-presses an AI message bubble, THE System SHALL show a context menu
2. THE System SHALL provide a "Copy" option in the context menu
3. WHEN a user selects "Copy", THE System SHALL copy the message text to the clipboard
4. THE System SHALL provide visual feedback when text is copied
5. THE System SHALL allow copying formatted text while preserving structure

### Requirement 20

**User Story:** As a user, I want the chat interface to be performant and responsive, so that conversations feel natural and fluid.

#### Acceptance Criteria

1. THE System SHALL render the chat screen in under 500ms
2. THE System SHALL use lazy loading for message history (load more on scroll)
3. THE System SHALL limit the number of messages rendered at once to prevent performance issues
4. THE System SHALL use RepaintBoundary to isolate message bubble repaints
5. THE System SHALL avoid heavy work in the build method per Flutter performance guidelines
