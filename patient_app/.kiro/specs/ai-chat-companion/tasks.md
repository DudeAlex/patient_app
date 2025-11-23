# Implementation Plan

- [x] 1. Create domain models for chat entities *(done — domain/value objects added in lib/core/ai/chat/models)*





  - Create `lib/core/ai/chat/models/chat_message.dart` entity
  - Create `lib/core/ai/chat/models/chat_thread.dart` entity
  - Create `lib/core/ai/chat/models/message_attachment.dart` value object
  - Create `lib/core/ai/chat/models/space_context.dart` value object
  - Create `lib/core/ai/chat/models/chat_request.dart` and `chat_response.dart` DTOs
  - Ensure all models are immutable and follow clean architecture principles
  - _Requirements: 1.1, 1.2, 1.3, 3.5, 4.3, 5.4, 6.3_

- [x] 2. Create Isar schemas for chat persistence *(done — thread collection + embedded message/attachment entities with indexes)*
  - Create `lib/core/ai/chat/data/entities/chat_thread_entity.dart` Isar collection
  - Create `lib/core/ai/chat/data/entities/chat_message_entity.dart` embedded object
  - Create `lib/core/ai/chat/data/entities/message_attachment_entity.dart` embedded object
  - Add indexes for threadId and spaceId for efficient querying
  - _Requirements: 10.3, 10.4_

- [x] 3. Implement ChatThreadRepository *(done — interface and implementation with Isar created and tested)*
  - Create `lib/core/ai/chat/repositories/chat_thread_repository.dart` interface
  - Create `lib/core/ai/chat/repositories/chat_thread_repository_impl.dart` using Isar
  - Implement CRUD operations: create, getById, getBySpaceId, addMessage, updateMessageStatus, delete
  - Implement message querying and filtering
  - _Requirements: 10.3, 10.4, 10.5_

- [x] 4. Implement MessageAttachmentHandler *(done — implemented with local storage management and validation)*
  - Create `lib/core/ai/chat/services/message_attachment_handler.dart` interface
  - Create `lib/core/ai/chat/services/message_attachment_handler_impl.dart`
  - Implement attachment processing: save to local storage, generate metadata
  - Implement attachment cleanup when messages are deleted
  - Handle file size validation and limits
  - _Requirements: 4.2, 4.3, 5.4, 6.2, 6.5_

- [x] 5. Extend AiService for chat operations *(done — created AiChatService interface)*
  - Create `lib/core/ai/chat/ai_chat_service.dart` interface extending AiService
  - Define sendMessage() method with ChatRequest parameter
  - Define sendMessageStream() method for streaming responses
  - _Requirements: 3.3, 3.4, 11.2, 11.3_

- [x] 6. Implement FakeAiChatService *(done — persona-aware deterministic responses with streaming and configurable latency)*
  - Create `lib/core/ai/chat/fake_ai_chat_service.dart`
  - Implement deterministic responses based on Space persona (Health, Education, Finance, Travel)
  - Implement contextual action hints generation
  - Add configurable simulated latency (default 1000ms)
  - Add streaming response support with word-by-word chunks
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 11.2, 12.1, 12.2, 12.3, 12.4, 12.5, 13.1, 13.2, 13.3, 13.4, 13.5_

- [x] 7. Implement HttpAiChatService *(done — JSON payloads, timeout + retry/backoff, and parsing)*
  - Create `lib/core/ai/chat/http_ai_chat_service.dart`
  - Implement request payload construction with Space context and message history
  - Implement HTTP POST to backend endpoint with JSON payload
  - Implement response parsing to ChatResponse
  - Implement 30-second timeout
  - Implement retry logic with exponential backoff (1s, 2s, 4s, max 3 retries)
  - Handle network errors, timeouts, 4xx, 5xx responses
  - _Requirements: 9.2, 9.3, 9.4, 9.5, 11.3, 16.1, 16.2, 16.3, 16.5_

- [x] 8. Implement LoggingAiChatService decorator *(done — wrapper logs send/stream start/complete/errors without content)*
  - Create `lib/core/ai/chat/logging_ai_chat_service.dart`
  - Wrap any AiChatService implementation with diagnostic logging
  - Log message send with threadId, spaceId, attachment types (not content)
  - Log AI response with tokensUsed, latencyMs, provider, confidence
  - Log errors with full context and stack traces
  - Use AppLogger.startOperation() and endOperation() for tracking
  - Redact message content from logs
  - _Requirements: 18.1, 18.2, 18.3, 18.4, 18.5_

- [x] 9. Implement SendChatMessageUseCase *(done — consent check, attachment processing, persistence, AI call + response storage, tests)*
  - Create `lib/core/ai/chat/application/use_cases/send_chat_message_use_case.dart`
  - Inject AiChatService, ChatThreadRepository, AiConsentRepository, MessageAttachmentHandler
  - Implement consent checking before sending messages
  - Implement user message persistence
  - Implement attachment processing
  - Implement AI request with Space context and message history
  - Implement AI response persistence
  - Handle all error cases with appropriate exceptions
  - _Requirements: 1.5, 3.2, 3.3, 3.4, 3.5, 7.1, 7.2, 7.3, 14.1, 14.2, 14.3, 14.4, 14.5_

- [x] 10. Implement LoadChatHistoryUseCase *(done — creates thread if missing, sorts messages)*
  - Create `lib/core/ai/chat/application/use_cases/load_chat_history_use_case.dart`
  - Load chat thread by Space ID
  - Create new thread if none exists
  - Return messages in chronological order
  - _Requirements: 10.3, 10.4_

- [x] 11. Implement ClearChatThreadUseCase *(done — deletes thread and attachment files)*
  - Create `lib/core/ai/chat/application/use_cases/clear_chat_thread_use_case.dart`
  - Delete all messages from a thread
  - Clean up associated attachments
  - _Requirements: 10.1, 10.2_

- [x] 12. Implement SwitchSpaceContextUseCase *(done — clears current thread when requested and loads new space context)*
  - Create `lib/core/ai/chat/application/use_cases/switch_space_context_use_case.dart`
  - Load new Space context
  - Clear current chat thread with user confirmation
  - Update AI persona based on new Space
  - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5_

- [x] 13. Set up dependency injection for chat services *(done — DI registers chat repo/handler and configurable Fake/HTTP chat service wrapped with logging, plus Riverpod providers)*
  - Update `lib/core/di/app_container.dart` to register chat services
  - Create Riverpod providers for AiChatService, ChatThreadRepository, MessageAttachmentHandler
  - Wire FakeAiChatService as default implementation
  - Wrap with LoggingAiChatService decorator
  - Switch between Fake and HTTP based on ai_mode configuration
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

- [x] 14. Create SpaceContext provider *(done — persona mapping + recent record summaries with truncation)*
  - Create `lib/core/ai/chat/providers/space_context_provider.dart`
  - Build SpaceContext from Space ID
  - Load recent records from the Space (limit to 5)
  - Generate record summaries (title, category, tags, first 200 chars of notes)
  - Map Space to appropriate persona (Health → health, Education → education, etc.)
  - _Requirements: 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 2.4, 2.5, 14.1, 14.2, 14.3, 14.4, 14.5_

- [ ] 15. Create ChatHeader widget
  - Create `lib/features/ai_chat/ui/widgets/chat_header.dart`
  - Display Space name and icon in context chip
  - Display status pill showing AI mode (Fake/Remote/Offline)
  - Implement overflow menu with "Clear Chat" and "Change Context" options
  - _Requirements: 1.4, 11.1, 15.1_

- [ ] 16. Create DataUsageBanner widget
  - Create `lib/features/ai_chat/ui/widgets/data_usage_banner.dart`
  - Display banner explaining what data is accessible
  - Show which Space records are available to AI
  - Show which specific record is being used as context (if applicable)
  - Make banner dismissible
  - _Requirements: 7.1, 7.2, 7.3_

- [ ] 17. Create ChatMessageBubble widget
  - Create `lib/features/ai_chat/ui/widgets/chat_message_bubble.dart`
  - Display user messages right-aligned, AI messages left-aligned
  - Show timestamps for each message
  - Display avatar/icon for AI messages
  - Render markdown formatting (bold, italic, lists, code blocks, links)
  - Display attachment previews inline
  - Show loading indicator for messages being sent
  - Show retry button for failed messages
  - Wrap in RepaintBoundary for performance
  - _Requirements: 8.1, 8.2, 8.3, 9.1, 9.2, 17.1, 17.2, 17.3, 17.4, 17.5, 20.4_

- [ ] 18. Implement long-press context menu for messages
  - Add GestureDetector to ChatMessageBubble
  - Show context menu on long-press
  - Implement "Copy" option
  - Copy message text to clipboard
  - Show visual feedback when copied
  - _Requirements: 19.1, 19.2, 19.3, 19.4, 19.5_

- [ ] 19. Create AttachmentPreview widget
  - Create `lib/features/ai_chat/ui/widgets/attachment_preview.dart`
  - Display photo thumbnails inline
  - Display voice note waveform with duration
  - Display file icon with filename and size
  - Handle different attachment types (photo, voice, file)
  - _Requirements: 4.3, 5.4, 6.3_

- [ ] 20. Create ActionHintsRow widget
  - Create `lib/features/ai_chat/ui/widgets/action_hints_row.dart`
  - Display action hints as tappable chips
  - Handle chip tap events
  - Style chips consistently with app theme
  - _Requirements: 17.2_

- [ ] 21. Create MessageList widget
  - Create `lib/features/ai_chat/ui/widgets/message_list.dart`
  - Use ListView.builder for lazy loading
  - Load only 50 most recent messages initially
  - Implement "load more" on scroll to top
  - Auto-scroll to latest message when new messages arrive
  - Support smooth scrolling
  - _Requirements: 8.4, 8.5, 20.1, 20.2, 20.3_

- [ ] 22. Create ChatComposer widget
  - Create `lib/features/ai_chat/ui/widgets/chat_composer.dart`
  - Implement text input field with multi-line support
  - Add camera/photo picker button
  - Add microphone button for voice recording
  - Add file picker button
  - Display attachment chips when attachments are selected
  - Implement send button (enabled only when message or attachments present)
  - Disable all inputs when offline
  - Show "Offline - cannot send" hint when offline
  - _Requirements: 3.1, 4.1, 5.1, 6.1, 9.3, 16.4_

- [ ] 23. Implement photo picker integration
  - Integrate with existing photo capture functionality from M5
  - Show thumbnail preview in composer
  - Validate file size before attaching
  - Show confirmation dialog with data usage details
  - _Requirements: 4.1, 4.2, 6.5, 7.5_

- [ ] 24. Implement voice recording integration
  - Integrate with existing voice recording functionality from M5
  - Show recording indicator with duration and waveform
  - Stop recording on button release or tap
  - Transcribe voice note using existing transcription pipeline
  - Display voice note as attachment chip
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [ ] 25. Implement file picker integration
  - Add file_picker package dependency
  - Support PDF, images, and text documents
  - Display filename and file type in composer
  - Validate file size and show warnings for large files
  - Show confirmation dialog with data usage details
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 7.5_

- [ ] 26. Create AiChatController for state management
  - Create `lib/features/ai_chat/ui/controllers/ai_chat_controller.dart`
  - Use Riverpod for state management
  - Manage chat thread loading state
  - Manage message sending state
  - Manage attachment state
  - Manage offline/online state
  - Provide methods for sending messages, clearing chat, switching context
  - _Requirements: 3.2, 3.3, 3.4, 9.1, 9.2, 9.3, 16.3_

- [ ] 27. Create AiChatScreen
  - Create `lib/features/ai_chat/ui/screens/ai_chat_screen.dart`
  - Implement full-screen layout with header, message list, and composer
  - Pass Space ID and optional record ID as parameters
  - Check AI consent on screen open, show consent dialog if missing
  - Load chat thread for the Space
  - Build SpaceContext from Space ID and records
  - Handle message sending via controller
  - Handle attachment selection
  - Handle offline state
  - Implement smooth scrolling to latest message
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 8.4, 20.1_

- [ ] 28. Add AI icon to app navigation
  - Add AI icon to app bar or bottom navigation
  - Pass current Space ID when opening chat
  - Pass current record ID if on record detail screen
  - Hide icon when ai_enabled is false
  - _Requirements: 1.1, 1.2, 1.3_

- [ ] 29. Implement offline message queuing
  - Create `lib/core/ai/chat/services/message_queue_service.dart`
  - Queue messages locally when offline
  - Monitor connectivity changes
  - Automatically retry queued messages when online
  - Implement exponential backoff for retries
  - Update message status in UI as messages send
  - _Requirements: 16.1, 16.2, 16.3, 16.4, 16.5_

- [ ] 30. Add chat diagnostics to Diagnostic System UI
  - Create AI Chat section in Diagnostic System
  - Display last N chat interactions with timestamps
  - Show success/failure status, latency, tokens used
  - Allow filtering by Space
  - Source data from AppLogger logs
  - _Requirements: 18.5_

- [ ] 31. Implement chat data backup
  - Extend backup system to include chat threads
  - Encrypt chat messages in backups
  - Include attachment metadata (not binaries) in backups
  - Implement restore functionality for chat threads
  - _Requirements: 10.5_

- [ ] 32. Write unit tests for domain models
  - Test ChatMessage immutability and JSON serialization
  - Test ChatThread message addition and ordering
  - Test MessageAttachment validation
  - Test SpaceContext building and record summary generation
  - Test ChatRequest and ChatResponse serialization
  - _Requirements: 1.2, 1.3, 3.5, 14.1, 14.2, 14.3, 14.4, 14.5_

- [ ] 33. Write unit tests for repositories
  - Test ChatThreadRepository CRUD operations
  - Test message querying and filtering
  - Test thread persistence and retrieval
  - Mock Isar for isolation
  - _Requirements: 10.3, 10.4_

- [ ] 34. Write unit tests for FakeAiChatService
  - Test deterministic responses for each Space persona
  - Test Health persona: empathetic tone, safety disclaimers
  - Test Education persona: study-focused suggestions
  - Test Finance persona: budget-conscious advice
  - Test Travel persona: planning-focused responses
  - Test action hint generation
  - Test simulated latency and failures
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 11.2, 12.1, 12.2, 12.3, 12.4, 12.5, 13.1, 13.2, 13.3, 13.4, 13.5_

- [ ] 35. Write unit tests for HttpAiChatService
  - Test request payload construction
  - Test response parsing
  - Test retry logic with exponential backoff
  - Test timeout handling
  - Test error handling for different HTTP status codes
  - Mock HTTP client for isolation
  - _Requirements: 9.2, 9.3, 9.4, 9.5, 16.5_

- [ ] 36. Write unit tests for LoggingAiChatService
  - Test log entries are created for message send
  - Test log entries are created for AI response
  - Test operation tracking with startOperation/endOperation
  - Test error logging
  - Test message content redaction
  - _Requirements: 18.1, 18.2, 18.3, 18.4_

- [ ] 37. Write unit tests for use cases
  - Test SendChatMessageUseCase consent checking
  - Test SendChatMessageUseCase message persistence
  - Test SendChatMessageUseCase attachment processing
  - Test SendChatMessageUseCase error propagation
  - Test LoadChatHistoryUseCase thread loading
  - Test ClearChatThreadUseCase message deletion
  - Test SwitchSpaceContextUseCase context switching
  - Mock AiChatService and repositories
  - _Requirements: 1.5, 3.2, 3.3, 3.4, 3.5, 10.1, 10.2, 10.3, 15.1, 15.2, 15.3_

- [ ] 38. Write widget tests for UI components
  - Test AiChatScreen initial render
  - Test ChatHeader context chip and status pill
  - Test DataUsageBanner display and dismissal
  - Test ChatMessageBubble user vs AI styling
  - Test ChatMessageBubble markdown rendering
  - Test ChatMessageBubble attachment previews
  - Test ChatMessageBubble long-press context menu
  - Test MessageList lazy loading
  - Test ChatComposer text input and send button
  - Test ChatComposer attachment buttons
  - Test ChatComposer offline state
  - _Requirements: 1.4, 4.3, 5.4, 7.1, 8.1, 8.2, 8.3, 9.3, 11.1, 17.1, 19.1, 20.2_

- [ ]* 39. Write property-based test for Space context inheritance
  - **Property 1: Space Context Inheritance**
  - **Validates: Requirements 1.2**
  - Generate random Spaces
  - Open chat from each Space
  - Assert context includes correct Space ID and persona

- [ ]* 40. Write property-based test for record context inclusion
  - **Property 2: Record Context Inclusion**
  - **Validates: Requirements 1.3**
  - Generate random records
  - Open chat from record detail screens
  - Assert context includes record information

- [ ]* 41. Write property-based test for consent enforcement
  - **Property 3: Consent Enforcement**
  - **Validates: Requirements 1.5**
  - Generate random consent states
  - Attempt to send messages
  - Assert AiConsentRequiredException thrown when consent=false

- [ ]* 42. Write property-based test for message persistence
  - **Property 4: Message Persistence**
  - **Validates: Requirements 3.5**
  - Generate random messages
  - Send messages and reload thread
  - Assert all messages appear in history

- [ ]* 43. Write property-based test for attachment privacy
  - **Property 5: Attachment Privacy**
  - **Validates: Requirements 4.5, 7.4**
  - Generate random attachments
  - Build chat request payloads
  - Assert payloads never contain binary data or local paths

- [ ]* 44. Write property-based test for Health Space tone
  - **Property 6: Space-Specific Tone (Health)**
  - **Validates: Requirements 12.2**
  - Generate random Health Space messages
  - Get AI responses
  - Assert responses don't contain prescriptive phrases

- [ ]* 45. Write property-based test for context scope limitation
  - **Property 7: Context Scope Limitation**
  - **Validates: Requirements 14.2**
  - Generate random Spaces with records
  - Build chat requests
  - Assert context only includes records from active Space

- [ ]* 46. Write property-based test for sensitive data redaction
  - **Property 8: Sensitive Data Redaction**
  - **Validates: Requirements 14.3**
  - Generate random chat requests
  - Assert payloads don't contain IDs or encryption keys

- [ ]* 47. Write property-based test for message history limit
  - **Property 9: Message History Limit**
  - **Validates: Requirements 14.5**
  - Generate chat threads with varying message counts
  - Build chat requests
  - Assert message history doesn't exceed configured maximum

- [ ]* 48. Write property-based test for offline message queuing
  - **Property 10: Offline Message Queuing**
  - **Validates: Requirements 16.1, 16.2**
  - Simulate offline state
  - Send messages
  - Assert messages are queued and retried when online

- [ ]* 49. Write property-based test for exponential backoff
  - **Property 11: Exponential Backoff**
  - **Validates: Requirements 16.5**
  - Simulate multiple failures
  - Track retry delays
  - Assert delays follow 1s, 2s, 4s pattern

- [ ]* 50. Write property-based test for markdown rendering
  - **Property 12: Markdown Rendering**
  - **Validates: Requirements 17.1**
  - Generate random markdown syntax
  - Render in message bubbles
  - Assert syntax is rendered correctly

- [ ]* 51. Write property-based test for logging completeness
  - **Property 13: Logging Completeness**
  - **Validates: Requirements 18.1, 18.4**
  - Send random messages
  - Check logs
  - Assert log entries exist with correct metadata (not content)

- [ ]* 52. Write property-based test for attachment metadata logging
  - **Property 14: Attachment Metadata Logging**
  - **Validates: Requirements 18.3**
  - Send messages with random attachments
  - Check logs
  - Assert logs contain type and size but not content

- [ ]* 53. Write property-based test for chat screen render performance
  - **Property 15: Chat Screen Render Performance**
  - **Validates: Requirements 20.1**
  - Generate chat threads with varying sizes
  - Measure render time
  - Assert render completes in under 500ms

- [ ]* 54. Write property-based test for message list lazy loading
  - **Property 16: Message List Lazy Loading**
  - **Validates: Requirements 20.2, 20.3**
  - Generate chat threads with 50+ messages
  - Render message list
  - Assert only 50 messages rendered initially

- [ ] 55. Manual testing and QA
  - Test end-to-end flow: open chat → send message → receive response
  - Test Space persona behavior for Health, Education, Finance, Travel
  - Test multi-modal input: text, photos, voice notes, files
  - Test attachment previews and display
  - Test offline message queuing and retry
  - Test Space context switching with warning
  - Test chat history persistence across app restarts
  - Test clear chat functionality
  - Test long-press copy functionality
  - Test markdown rendering in AI responses
  - Test performance with 100+ message threads
  - Test smooth scrolling and lazy loading
  - Document findings in TESTING.md
  - _Requirements: All_

- [ ] 56. Update documentation
  - Update AI_ASSISTED_LIFE_COMPANION_PLAN.md with chat interface details
  - Update SPEC.md with AI chat requirements
  - Update ARCHITECTURE.md with chat service layer
  - Update README.md with AI chat features description
  - Create user-facing documentation for AI chat
  - Document Space persona behaviors
  - Document attachment handling and limits
  - _Requirements: All_

- [ ] 57. Final checkpoint - Ensure all tests pass
  - Run all unit tests
  - Run all widget tests
  - Run all property-based tests
  - Run manual QA checklist
  - Verify no regressions in existing features
  - Confirm AI chat can be disabled via feature flag
  - Verify performance targets met (< 500ms render, smooth scrolling)
  - Ask user if questions arise
