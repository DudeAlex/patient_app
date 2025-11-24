# Design Document

## Overview

This design introduces a Space-Aware AI Chat Companion interface to the Universal Life Companion app. The system provides a full-screen conversational experience similar to ChatGPT mobile or Telegram, where users can have interactive dialogues with an AI assistant that understands their Space context (Health, Education, Finance, etc.) and has awareness of their records within that domain. The chat interface supports multi-modal input (text, photos, voice notes, files) and provides contextual, compassionate responses tailored to the active Space.

## Architecture

### Current System (AI Summarization)

```
User
  ↓
Information Item Detail Screen → AI Icon
  ↓
AI Summary Sheet (modal)
  ↓
SummarizeInformationItemUseCase
  ↓
AiService (Fake/HTTP)
```

### Proposed System (AI Chat Companion)

```
User
  ↓
Any Screen → AI Icon
  ↓
AI Chat Screen (full-screen)
  ├─ Header (Space context chip, status pill, overflow menu)
  ├─ Message List (user/AI bubbles with attachments)
  └─ Composer (text input, camera, microphone, file picker)
  ↓
SendChatMessageUseCase
  ↓
AiChatService (extends AiService)
  ├─ Message history context
  ├─ Space-specific context
  ├─ Record context (if applicable)
  └─ Attachment handling
  ↓
Backend Proxy (HTTPS)
  ↓
AI Provider (Together AI, OpenAI, etc.)
```

### Layer Responsibilities

**Domain Layer:**
- `ChatMessage` entity (id, content, sender, timestamp, attachments)
- `ChatThread` entity (id, spaceId, messages, lastUpdated)
- `MessageAttachment` value object (type, metadata, localPath)
- `SpaceContext` value object (spaceId, spaceName, recentRecords)

**Application Layer:**
- `SendChatMessageUseCase` - orchestrates sending messages with context
- `LoadChatHistoryUseCase` - retrieves chat thread for a Space
- `ClearChatThreadUseCase` - deletes messages from a thread
- `SwitchSpaceContextUseCase` - changes active Space context
- `AiChatService` port (interface) - extends AiService for chat operations

**Infrastructure Layer:**
- `FakeAiChatService` - deterministic chat responses for development
- `HttpAiChatService` - real HTTP-backed chat implementation
- `ChatThreadRepository` - Isar-backed persistence for chat threads
- `MessageAttachmentHandler` - manages attachment storage and metadata

**Presentation Layer:**
- `AiChatScreen` - full-screen chat interface
- `ChatMessageBubble` widget - displays individual messages
- `ChatComposer` widget - input area with attachment buttons
- `ChatHeader` widget - context chip and status indicators
- `AiChatController` - Riverpod state management for chat


## Components and Interfaces

### 1. AiChatService Interface (Port)

```dart
/// Port for AI chat operations (extends AiService)
abstract class AiChatService {
  /// Sends a chat message with context and returns AI response
  /// 
  /// Includes message history, Space context, and optional attachments
  /// Returns ChatResponse containing AI message and metadata
  Future<ChatResponse> sendMessage(ChatRequest request);
  
  /// Streams AI response for real-time typing effect
  Stream<ChatResponseChunk> sendMessageStream(ChatRequest request);
}
```

### 2. ChatMessage Entity

```dart
/// Represents a single message in a chat thread
class ChatMessage {
  final String id;
  final String threadId;
  final MessageSender sender;  // user or ai
  final String content;
  final DateTime timestamp;
  final List<MessageAttachment> attachments;
  final MessageStatus status;  // sending, sent, failed
  final AiMetadata? aiMetadata;  // tokens, latency, confidence (for AI messages)
  
  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.attachments = const [],
    required this.status,
    this.aiMetadata,
  });
}

enum MessageSender { user, ai }
enum MessageStatus { sending, sent, failed }
```

### 3. ChatThread Entity

```dart
/// Represents a conversation thread for a specific Space
class ChatThread {
  final String id;
  final String spaceId;
  final String? recordId;  // Optional: if chat is about a specific record
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime lastUpdated;
  
  const ChatThread({
    required this.id,
    required this.spaceId,
    this.recordId,
    required this.messages,
    required this.createdAt,
    required this.lastUpdated,
  });
  
  ChatThread addMessage(ChatMessage message) {
    return ChatThread(
      id: id,
      spaceId: spaceId,
      recordId: recordId,
      messages: [...messages, message],
      createdAt: createdAt,
      lastUpdated: DateTime.now(),
    );
  }
}
```

### 4. MessageAttachment Value Object

```dart
/// Represents an attachment in a chat message
class MessageAttachment {
  final String id;
  final AttachmentType type;  // photo, voice, file
  final String? localPath;  // Path to local file
  final String? fileName;
  final int? fileSizeBytes;
  final String? mimeType;
  final String? transcription;  // For voice notes
  
  const MessageAttachment({
    required this.id,
    required this.type,
    this.localPath,
    this.fileName,
    this.fileSizeBytes,
    this.mimeType,
    this.transcription,
  });
}

enum AttachmentType { photo, voice, file }
```

### 5. SpaceContext Value Object

```dart
/// Represents the Space context for AI chat
class SpaceContext {
  final String spaceId;
  final String spaceName;
  final SpacePersona persona;  // Determines AI tone and behavior
  final List<RecordSummary> recentRecords;  // Recent records for context
  final int maxContextRecords;  // Limit to prevent token overuse
  
  const SpaceContext({
    required this.spaceId,
    required this.spaceName,
    required this.persona,
    required this.recentRecords,
    this.maxContextRecords = 5,
  });
}

enum SpacePersona {
  health,      // Empathetic, cautious, no medical advice
  education,   // Study-focused, constructive
  finance,     // Practical, budget-conscious
  travel,      // Exploratory, planning-focused
  general,     // Neutral, helpful
}

class RecordSummary {
  final String title;
  final String category;
  final List<String> tags;
  final String? summaryText;  // First 200 chars of notes
  final DateTime createdAt;
  
  const RecordSummary({
    required this.title,
    required this.category,
    required this.tags,
    this.summaryText,
    required this.createdAt,
  });
}
```

### 6. ChatRequest and ChatResponse

```dart
/// Request payload for AI chat
class ChatRequest {
  final String threadId;
  final String messageContent;
  final List<MessageAttachment> attachments;
  final SpaceContext spaceContext;
  final List<ChatMessage> messageHistory;  // Recent messages for context
  final int maxHistoryMessages;  // Limit history to prevent token overuse
  
  const ChatRequest({
    required this.threadId,
    required this.messageContent,
    this.attachments = const [],
    required this.spaceContext,
    required this.messageHistory,
    this.maxHistoryMessages = 10,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'threadId': threadId,
      'message': messageContent,
      'attachments': attachments.map((a) => {
        'type': a.type.name,
        'fileName': a.fileName,
        'transcription': a.transcription,
        // Never include binary data or local paths
      }).toList(),
      'spaceContext': {
        'spaceId': spaceContext.spaceId,
        'spaceName': spaceContext.spaceName,
        'persona': spaceContext.persona.name,
        'recentRecords': spaceContext.recentRecords.map((r) => {
          'title': r.title,
          'category': r.category,
          'tags': r.tags,
          'summary': r.summaryText,
        }).toList(),
      },
      'messageHistory': messageHistory.take(maxHistoryMessages).map((m) => {
        'sender': m.sender.name,
        'content': m.content,
        'timestamp': m.timestamp.toIso8601String(),
      }).toList(),
    };
  }
}

/// Response from AI chat
class ChatResponse {
  final String messageContent;
  final List<String> actionHints;  // Optional suggested actions
  final AiMetadata metadata;
  final AiError? error;
  
  const ChatResponse({
    required this.messageContent,
    this.actionHints = const [],
    required this.metadata,
    this.error,
  });
  
  bool get isSuccess => error == null;
}

class AiMetadata {
  final int tokensUsed;
  final int latencyMs;
  final String provider;
  final double confidence;
  
  const AiMetadata({
    required this.tokensUsed,
    required this.latencyMs,
    required this.provider,
    required this.confidence,
  });
}
```

### 7. SendChatMessageUseCase

```dart
/// Use case for sending chat messages with AI
class SendChatMessageUseCase {
  final AiChatService _aiChatService;
  final ChatThreadRepository _threadRepository;
  final AiConsentRepository _consentRepository;
  final MessageAttachmentHandler _attachmentHandler;
  
  SendChatMessageUseCase({
    required AiChatService aiChatService,
    required ChatThreadRepository threadRepository,
    required AiConsentRepository consentRepository,
    required MessageAttachmentHandler attachmentHandler,
  }) : _aiChatService = aiChatService,
       _threadRepository = threadRepository,
       _consentRepository = consentRepository,
       _attachmentHandler = attachmentHandler;
  
  Future<ChatMessage> execute({
    required String threadId,
    required String messageContent,
    required SpaceContext spaceContext,
    List<MessageAttachment> attachments = const [],
  }) async {
    // Check consent
    final hasConsent = await _consentRepository.hasAiConsent();
    if (!hasConsent) {
      throw AiConsentRequiredException();
    }
    
    // Load thread and history
    final thread = await _threadRepository.getById(threadId);
    final messageHistory = thread?.messages ?? [];
    
    // Save user message
    final userMessage = ChatMessage(
      id: _generateId(),
      threadId: threadId,
      sender: MessageSender.user,
      content: messageContent,
      timestamp: DateTime.now(),
      attachments: attachments,
      status: MessageStatus.sending,
    );
    await _threadRepository.addMessage(threadId, userMessage);
    
    // Process attachments
    final processedAttachments = await _attachmentHandler.processAttachments(attachments);
    
    // Build request
    final request = ChatRequest(
      threadId: threadId,
      messageContent: messageContent,
      attachments: processedAttachments,
      spaceContext: spaceContext,
      messageHistory: messageHistory,
    );
    
    // Send to AI
    final response = await _aiChatService.sendMessage(request);
    
    // Save AI response
    final aiMessage = ChatMessage(
      id: _generateId(),
      threadId: threadId,
      sender: MessageSender.ai,
      content: response.messageContent,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      aiMetadata: response.metadata,
    );
    await _threadRepository.addMessage(threadId, aiMessage);
    
    // Update user message status
    await _threadRepository.updateMessageStatus(userMessage.id, MessageStatus.sent);
    
    return aiMessage;
  }
}
```

### 8. FakeAiChatService (Test Implementation)

```dart
/// Deterministic AI chat service for development and testing
class FakeAiChatService implements AiChatService {
  final Duration simulatedLatency;
  final bool shouldFail;
  
  const FakeAiChatService({
    this.simulatedLatency = const Duration(milliseconds: 1000),
    this.shouldFail = false,
  });
  
  @override
  Future<ChatResponse> sendMessage(ChatRequest request) async {
    await Future.delayed(simulatedLatency);
    
    if (shouldFail) {
      return ChatResponse(
        messageContent: '',
        metadata: AiMetadata(
          tokensUsed: 0,
          latencyMs: simulatedLatency.inMilliseconds,
          provider: 'fake',
          confidence: 0.0,
        ),
        error: AiError(
          message: 'Simulated failure for testing',
          isRetryable: true,
        ),
      );
    }
    
    // Generate contextual response based on Space persona
    final response = _generateContextualResponse(request);
    final hints = _generateActionHints(request);
    
    return ChatResponse(
      messageContent: response,
      actionHints: hints,
      metadata: AiMetadata(
        tokensUsed: 200,
        latencyMs: simulatedLatency.inMilliseconds,
        provider: 'fake',
        confidence: 0.92,
      ),
    );
  }
  
  String _generateContextualResponse(ChatRequest request) {
    final persona = request.spaceContext.persona;
    final message = request.messageContent.toLowerCase();
    
    switch (persona) {
      case SpacePersona.health:
        if (message.contains('pain') || message.contains('symptom')) {
          return 'I understand you\'re experiencing discomfort. While I can help you track this information, please consult with a healthcare professional for medical advice. Would you like me to help you organize your health records?';
        }
        return 'I\'m here to help you manage your health information. Remember, I provide guidance only and not medical advice. How can I assist you today?';
        
      case SpacePersona.education:
        if (message.contains('study') || message.contains('exam')) {
          return 'Let\'s create a study plan! Based on your notes, I can help you organize topics and set up a review schedule. What subject are you focusing on?';
        }
        return 'I\'m here to help with your learning journey. I can help organize notes, suggest study strategies, and track your progress. What would you like to work on?';
        
      case SpacePersona.finance:
        if (message.contains('budget') || message.contains('expense')) {
          return 'Let\'s review your financial records. I can help you categorize expenses and identify patterns. Would you like to see a summary of your recent transactions?';
        }
        return 'I\'m here to help you manage your finances. I can assist with budgeting, expense tracking, and financial planning. What would you like to explore?';
        
      case SpacePersona.travel:
        if (message.contains('trip') || message.contains('destination')) {
          return 'Exciting! Let\'s plan your trip. I can help you organize itineraries, track bookings, and manage travel documents. Where are you headed?';
        }
        return 'I\'m here to help with your travel planning. I can assist with itineraries, packing lists, and travel tips. What\'s your next adventure?';
        
      default:
        return 'I\'m here to help! I can assist with organizing your information, answering questions, and providing suggestions. What would you like to know?';
    }
  }
  
  List<String> _generateActionHints(ChatRequest request) {
    final persona = request.spaceContext.persona;
    
    switch (persona) {
      case SpacePersona.health:
        return [
          'View recent health records',
          'Track symptoms over time',
          'Schedule a check-up reminder',
        ];
      case SpacePersona.education:
        return [
          'Create a study schedule',
          'Review recent notes',
          'Set assignment deadlines',
        ];
      case SpacePersona.finance:
        return [
          'View spending summary',
          'Set budget goals',
          'Track recurring expenses',
        ];
      case SpacePersona.travel:
        return [
          'Create trip itinerary',
          'Add travel documents',
          'Check packing list',
        ];
      default:
        return [
          'View recent records',
          'Add new information',
          'Search your data',
        ];
    }
  }
  
  @override
  Stream<ChatResponseChunk> sendMessageStream(ChatRequest request) async* {
    // Simulate streaming response
    final response = await sendMessage(request);
    final words = response.messageContent.split(' ');
    
    for (int i = 0; i < words.length; i++) {
      await Future.delayed(Duration(milliseconds: 50));
      yield ChatResponseChunk(
        content: words.sublist(0, i + 1).join(' '),
        isComplete: i == words.length - 1,
      );
    }
  }
}

class ChatResponseChunk {
  final String content;
  final bool isComplete;
  
  const ChatResponseChunk({
    required this.content,
    required this.isComplete,
  });
}
```

### 9. UI Components

#### AiChatScreen

```dart
/// Full-screen AI chat interface
class AiChatScreen extends ConsumerStatefulWidget {
  final String spaceId;
  final String? recordId;  // Optional: if chat is about a specific record
  
  const AiChatScreen({
    required this.spaceId,
    this.recordId,
  });
  
  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider(widget.spaceId));
    final spaceContext = ref.watch(spaceContextProvider(widget.spaceId));
    
    return Scaffold(
      appBar: ChatHeader(
        spaceContext: spaceContext,
        aiMode: ref.watch(aiConfigProvider).aiMode,
        onClearChat: () => _showClearChatDialog(),
        onChangeContext: () => _showChangeContextDialog(),
      ),
      body: Column(
        children: [
          // Data usage banner (dismissible)
          DataUsageBanner(spaceContext: spaceContext),
          
          // Message list
          Expanded(
            child: chatState.when(
              loading: () => Center(child: CircularProgressIndicator()),
              error: (error, stack) => ErrorView(error: error),
              data: (thread) => MessageList(
                messages: thread.messages,
                scrollController: _scrollController,
                onRetry: (messageId) => _retryMessage(messageId),
                onCopy: (content) => _copyToClipboard(content),
              ),
            ),
          ),
          
          // Composer
          ChatComposer(
            textController: _textController,
            onSend: (message, attachments) => _sendMessage(message, attachments),
            onPhotoTap: () => _pickPhoto(),
            onVoiceTap: () => _recordVoice(),
            onFileTap: () => _pickFile(),
            isOffline: ref.watch(connectivityProvider).isOffline,
          ),
        ],
      ),
    );
  }
}
```

#### ChatMessageBubble

```dart
/// Widget for displaying a single chat message
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onRetry;
  final ValueChanged<String>? onCopy;
  
  const ChatMessageBubble({
    required this.message,
    this.onRetry,
    this.onCopy,
  });
  
  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    
    return RepaintBoundary(  // Performance: isolate repaints
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: () => _showContextMenu(context),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser ? Colors.blue[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Attachments
                if (message.attachments.isNotEmpty)
                  ...message.attachments.map((a) => AttachmentPreview(attachment: a)),
                
                // Message content with markdown support
                MarkdownBody(
                  data: message.content,
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                ),
                
                // Action hints (for AI messages)
                if (!isUser && message.aiMetadata != null)
                  ActionHintsRow(hints: _extractActionHints(message.content)),
                
                // Timestamp and status
                SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTimestamp(message.timestamp),
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                    if (message.status == MessageStatus.sending)
                      Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 1),
                        ),
                      ),
                    if (message.status == MessageStatus.failed)
                      IconButton(
                        icon: Icon(Icons.refresh, size: 16),
                        onPressed: onRetry,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

#### ChatComposer

```dart
/// Input area with text field and attachment buttons
class ChatComposer extends StatefulWidget {
  final TextEditingController textController;
  final Function(String message, List<MessageAttachment> attachments) onSend;
  final VoidCallback onPhotoTap;
  final VoidCallback onVoiceTap;
  final VoidCallback onFileTap;
  final bool isOffline;
  
  const ChatComposer({
    required this.textController,
    required this.onSend,
    required this.onPhotoTap,
    required this.onVoiceTap,
    required this.onFileTap,
    required this.isOffline,
  });
  
  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final List<MessageAttachment> _attachments = [];
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Attachment chips
          if (_attachments.isNotEmpty)
            AttachmentChipsRow(
              attachments: _attachments,
              onRemove: (attachment) => setState(() => _attachments.remove(attachment)),
            ),
          
          // Input row
          Row(
            children: [
              // Attachment buttons
              IconButton(
                icon: Icon(Icons.photo_camera),
                onPressed: widget.isOffline ? null : widget.onPhotoTap,
                tooltip: 'Add photo',
              ),
              IconButton(
                icon: Icon(Icons.mic),
                onPressed: widget.isOffline ? null : widget.onVoiceTap,
                tooltip: 'Record voice note',
              ),
              IconButton(
                icon: Icon(Icons.attach_file),
                onPressed: widget.isOffline ? null : widget.onFileTap,
                tooltip: 'Attach file',
              ),
              
              // Text input
              Expanded(
                child: TextField(
                  controller: widget.textController,
                  decoration: InputDecoration(
                    hintText: widget.isOffline ? 'Offline - cannot send' : 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  enabled: !widget.isOffline,
                ),
              ),
              
              // Send button
              IconButton(
                icon: Icon(Icons.send),
                onPressed: widget.isOffline || widget.textController.text.isEmpty 
                    ? null 
                    : _handleSend,
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _handleSend() {
    final message = widget.textController.text.trim();
    if (message.isEmpty && _attachments.isEmpty) return;
    
    widget.onSend(message, List.from(_attachments));
    widget.textController.clear();
    setState(() => _attachments.clear());
  }
}
```

## Data Models

### Chat Thread Storage (Isar)

```dart
@collection
class ChatThreadEntity {
  Id id = Isar.autoIncrement;
  
  @Index()
  late String threadId;
  
  @Index()
  late String spaceId;
  
  String? recordId;
  
  late DateTime createdAt;
  late DateTime lastUpdated;
  
  // Messages stored as embedded objects
  List<ChatMessageEntity> messages = [];
}

@embedded
class ChatMessageEntity {
  late String messageId;
  late String sender;  // 'user' or 'ai'
  late String content;
  late DateTime timestamp;
  late String status;  // 'sending', 'sent', 'failed'
  
  // Attachments
  List<MessageAttachmentEntity> attachments = [];
  
  // AI metadata (for AI messages)
  int? tokensUsed;
  int? latencyMs;
  String? provider;
  double? confidence;
}

@embedded
class MessageAttachmentEntity {
  late String attachmentId;
  late String type;  // 'photo', 'voice', 'file'
  String? localPath;
  String? fileName;
  int? fileSizeBytes;
  String? mimeType;
  String? transcription;  // For voice notes
}
```

### HTTP Request/Response Payloads

#### Chat Request (JSON)

```json
{
  "threadId": "thread_123",
  "message": "Can you help me understand my recent health records?",
  "attachments": [
    {
      "type": "photo",
      "fileName": "lab_results.jpg",
      "transcription": null
    }
  ],
  "spaceContext": {
    "spaceId": "health",
    "spaceName": "Health",
    "persona": "health",
    "recentRecords": [
      {
        "title": "Cardiology Visit",
        "category": "Appointment",
        "tags": ["cardiology", "bp"],
        "summary": "Follow-up appointment for blood pressure monitoring..."
      }
    ]
  },
  "messageHistory": [
    {
      "sender": "user",
      "content": "Hello, I need help organizing my health records",
      "timestamp": "2025-11-21T10:00:00Z"
    },
    {
      "sender": "ai",
      "content": "I'm here to help! I can assist with organizing your health information...",
      "timestamp": "2025-11-21T10:00:02Z"
    }
  ]
}
```

#### Chat Response (JSON)

```json
{
  "message": "I can see you have a recent cardiology visit in your records. Based on the information, it looks like you're monitoring blood pressure. While I can help you track this data, please remember to consult with your healthcare provider for medical advice. Would you like me to help you organize related records or set up tracking?",
  "actionHints": [
    "View all cardiology records",
    "Track blood pressure readings",
    "Schedule next appointment reminder"
  ],
  "metadata": {
    "tokensUsed": 450,
    "latencyMs": 1850,
    "provider": "together",
    "confidence": 0.88
  }
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Space Context Inheritance

*For any* Space, when the chat screen opens from that Space, the chat context should include the Space ID and persona.

**Validates: Requirements 1.2**

### Property 2: Record Context Inclusion

*For any* record detail screen, when the chat opens from that screen, the chat context should include that record's information.

**Validates: Requirements 1.3**

### Property 3: Consent Enforcement

*For any* chat message send attempt, if the user has not granted AI consent, the operation should fail with AiConsentRequiredException.

**Validates: Requirements 1.5**

### Property 4: Message Persistence

*For any* sent message, it should appear in the chat thread history when the thread is reloaded.

**Validates: Requirements 3.5**

### Property 5: Attachment Privacy

*For any* chat request payload, the payload should never contain attachment binary data or local file paths.

**Validates: Requirements 4.5, 7.4**

### Property 6: Space-Specific Tone (Health)

*For any* Health Space chat response, the response should not contain prescriptive medical phrases like "you should take" or "you must".

**Validates: Requirements 12.2**

### Property 7: Context Scope Limitation

*For any* chat request, the context should only include records from the active Space, never from other Spaces.

**Validates: Requirements 14.2**

### Property 8: Sensitive Data Redaction

*For any* chat request payload, the payload should not contain Information Item IDs or encryption keys.

**Validates: Requirements 14.3**

### Property 9: Message History Limit

*For any* chat request, the message history should not exceed the configured maximum (default 10 messages).

**Validates: Requirements 14.5**

### Property 10: Offline Message Queuing

*For any* message sent while offline, the message should be queued locally and automatically retried when connectivity is restored.

**Validates: Requirements 16.1, 16.2**

### Property 11: Exponential Backoff

*For any* failed chat request, retry delays should follow exponential backoff pattern: 1s, 2s, 4s (up to max 3 retries).

**Validates: Requirements 16.5**

### Property 12: Markdown Rendering

*For any* AI response containing markdown syntax (bold, italic, lists), the syntax should be rendered correctly in the message bubble.

**Validates: Requirements 17.1**

### Property 13: Logging Completeness

*For any* chat message sent, there should be a corresponding log entry with timestamp, Space context, and metadata (but not message content).

**Validates: Requirements 18.1, 18.4**

### Property 14: Attachment Metadata Logging

*For any* attachment sent, the log should contain attachment type and size but not the attachment content.

**Validates: Requirements 18.3**

### Property 15: Chat Screen Render Performance

*For any* chat screen load, the initial render should complete in under 500ms.

**Validates: Requirements 20.1**

### Property 16: Message List Lazy Loading

*For any* chat thread with more than 50 messages, only the most recent 50 should be rendered initially, with more loaded on scroll.

**Validates: Requirements 20.2, 20.3**

## Error Handling

### Error Categories

1. **Consent Errors**
   - `AiConsentRequiredException` - User hasn't granted AI consent
   - Recovery: Show consent dialog before opening chat

2. **Network Errors**
   - `TimeoutException` - Request exceeded 30s timeout
   - `NetworkException` - No connectivity
   - Recovery: Queue message locally, retry with exponential backoff

3. **Server Errors**
   - `ServerException` (5xx) - Backend or AI provider failure
   - Recovery: Show error bubble with retry button, retry up to 3 times

4. **Client Errors**
   - `ValidationException` (4xx) - Invalid request data
   - `AttachmentTooLargeException` - File exceeds size limit
   - Recovery: Show error message, don't retry

5. **Storage Errors**
   - `ThreadNotFoundException` - Chat thread not found
   - `MessageSaveException` - Failed to persist message
   - Recovery: Create new thread or show error to user

### Error Handling Strategy

```dart
try {
  final aiMessage = await sendChatMessageUseCase.execute(
    threadId: threadId,
    messageContent: message,
    spaceContext: spaceContext,
    attachments: attachments,
  );
  // Handle success
} on AiConsentRequiredException {
  // Show consent dialog
  await showConsentDialog();
  // Retry after consent granted
} on NetworkException {
  // Queue message locally
  await queueMessageForRetry(message);
  showSnackbar('Message queued - will send when online');
} on TimeoutException {
  // Show error bubble with retry
  showErrorBubble('Request timed out', canRetry: true);
} on ServerException {
  // Show error bubble with retry
  showErrorBubble('Service temporarily unavailable', canRetry: true);
} on AttachmentTooLargeException catch (e) {
  // Show error, don't retry
  showErrorBubble('File too large: ${e.maxSize}', canRetry: false);
} on ValidationException catch (e) {
  // Show error, don't retry
  showErrorBubble(e.message, canRetry: false);
} catch (e, stackTrace) {
  // Unknown error
  await AppLogger.error('Unexpected chat error', error: e, stackTrace: stackTrace);
  showErrorBubble('An unexpected error occurred', canRetry: false);
}
```

## Testing Strategy

### Unit Tests

1. **ChatMessage Entity Tests**
   - Test immutability
   - Test JSON serialization/deserialization
   - Test message status transitions

2. **ChatThread Entity Tests**
   - Test adding messages
   - Test message ordering
   - Test thread updates

3. **SpaceContext Tests**
   - Test context building with different Spaces
   - Test record summary generation
   - Test context size limits

4. **FakeAiChatService Tests**
   - Test deterministic responses for each Space persona
   - Test action hint generation
   - Test simulated latency and failures

5. **SendChatMessageUseCase Tests**
   - Test consent checking
   - Test message persistence
   - Test attachment processing
   - Test error propagation
   - Mock AiChatService and repositories

6. **ChatThreadRepository Tests**
   - Test CRUD operations
   - Test message querying
   - Test thread filtering by Space

### Widget Tests

1. **AiChatScreen Tests**
   - Test initial render with empty thread
   - Test message list display
   - Test composer interactions
   - Test header context chip

2. **ChatMessageBubble Tests**
   - Test user vs AI message styling
   - Test attachment previews
   - Test markdown rendering
   - Test long-press context menu

3. **ChatComposer Tests**
   - Test text input
   - Test attachment buttons
   - Test send button enable/disable
   - Test offline state

4. **ChatHeader Tests**
   - Test Space context display
   - Test status pill (Fake/Remote/Offline)
   - Test overflow menu options

### Integration Tests

1. **End-to-End Chat Flow**
   - User opens chat from Space
   - User sends text message
   - AI responds with message
   - Message history persists

2. **Attachment Flow**
   - User attaches photo
   - Photo preview appears
   - Message sends with attachment
   - AI responds with photo insights

3. **Space Context Switching**
   - User changes Space context
   - Chat clears with warning
   - New Space context loads
   - AI persona changes

4. **Offline Handling**
   - User goes offline
   - Message queues locally
   - User comes online
   - Message sends automatically

### Property-Based Tests

1. **Property 1: Space Context Inheritance**
   - Generate random Spaces
   - Open chat from each Space
   - Assert context includes correct Space ID and persona

2. **Property 3: Consent Enforcement**
   - Generate random consent states
   - Attempt to send messages
   - Assert exception thrown when consent=false

3. **Property 5: Attachment Privacy**
   - Generate random attachments
   - Build chat request payloads
   - Assert payloads never contain binary data or local paths

4. **Property 7: Context Scope Limitation**
   - Generate random Spaces with records
   - Build chat requests
   - Assert context only includes records from active Space

5. **Property 11: Exponential Backoff**
   - Simulate multiple failures
   - Track retry delays
   - Assert delays follow 1s, 2s, 4s pattern

6. **Property 16: Message List Lazy Loading**
   - Generate chat threads with varying message counts
   - Render message list
   - Assert only N messages rendered initially (where N <= 50)

### Manual Testing

1. **Space Persona Testing**
   - Test Health Space: verify empathetic tone, safety disclaimers
   - Test Education Space: verify study-focused suggestions
   - Test Finance Space: verify budget-conscious advice
   - Test Travel Space: verify planning-focused responses

2. **Multi-Modal Input Testing**
   - Send text messages
   - Attach and send photos
   - Record and send voice notes
   - Attach and send files
   - Verify all attachment types display correctly

3. **Performance Testing**
   - Load chat with 100+ messages
   - Verify smooth scrolling
   - Measure render time
   - Check memory usage

4. **Offline Testing**
   - Disable network
   - Send messages
   - Verify queuing
   - Re-enable network
   - Verify automatic retry

## Implementation Notes

### Dependency Injection

Register chat services in `AppContainer`:

```dart
class AppContainer {
  late final AiChatService aiChatService;
  late final ChatThreadRepository chatThreadRepository;
  late final MessageAttachmentHandler attachmentHandler;
  
  Future<void> bootstrap() async {
    // Load configuration
    final config = await _loadAiConfig();
    
    // Create base chat service
    AiChatService baseService;
    if (config.aiMode == 'fake') {
      baseService = FakeAiChatService();
    } else {
      baseService = HttpAiChatService(
        client: http.Client(),
        baseUrl: config.backendUrl,
      );
    }
    
    // Wrap with logging
    aiChatService = LoggingAiChatService(baseService);
    
    // Initialize repositories
    chatThreadRepository = ChatThreadRepositoryImpl(isar: isar);
    attachmentHandler = MessageAttachmentHandlerImpl();
  }
}
```

### Performance Optimizations

Per `.kiro/steering/flutter-ui-performance.md`:

1. **Lazy Loading**
   - Load only 50 most recent messages initially
   - Load more on scroll to top
   - Use `ListView.builder` for efficient rendering

2. **RepaintBoundary**
   - Wrap each `ChatMessageBubble` in `RepaintBoundary`
   - Isolates repaints to individual messages
   - Prevents full list repaints

3. **Build Method Optimization**
   - No heavy work in `build` methods
   - Pre-process message formatting in use case
   - Cache markdown rendering results

4. **State Management**
   - Use Riverpod for granular rebuilds
   - Only rebuild affected message bubbles
   - Separate composer state from message list state

5. **Image Optimization**
   - Use `CachedNetworkImage` for attachment previews
   - Provide width/height constraints
   - Compress images before sending

### Logging Requirements

Per `.kiro/steering/logging-guidelines.md`:

```dart
// Message send logging
await AppLogger.info('Chat message sent', context: {
  'threadId': threadId,
  'spaceId': spaceContext.spaceId,
  'hasAttachments': attachments.isNotEmpty,
  'attachmentTypes': attachments.map((a) => a.type.name).toList(),
  // Never log message content
});

// AI response logging
await AppLogger.info('Chat response received', context: {
  'threadId': threadId,
  'tokensUsed': response.metadata.tokensUsed,
  'latencyMs': response.metadata.latencyMs,
  'provider': response.metadata.provider,
  'confidence': response.metadata.confidence,
  'responseLength': response.messageContent.length,
  // Never log response content
});

// Error logging
await AppLogger.error('Chat message failed', 
  error: e,
  stackTrace: stackTrace,
  context: {
    'threadId': threadId,
    'spaceId': spaceContext.spaceId,
    'errorType': e.runtimeType.toString(),
  },
);
```

### Clean Architecture Compliance

Per `CLEAN_ARCHITECTURE_GUIDE.md`:

**Domain Layer:**
- `ChatMessage` entity - pure domain model
- `ChatThread` entity - aggregate root
- `MessageAttachment` value object - immutable
- `SpaceContext` value object - immutable
- No framework dependencies

**Application Layer:**
- `SendChatMessageUseCase` - orchestrates chat operations
- `LoadChatHistoryUseCase` - retrieves threads
- `ClearChatThreadUseCase` - manages thread lifecycle
- `AiChatService` port - defines contract
- DTOs for use case boundaries

**Infrastructure Layer:**
- `FakeAiChatService` - test implementation
- `HttpAiChatService` - production implementation
- `LoggingAiChatService` - decorator
- `ChatThreadRepositoryImpl` - Isar persistence
- `MessageAttachmentHandlerImpl` - file system operations

**Presentation Layer:**
- `AiChatScreen` - full-screen UI
- `ChatMessageBubble` - message display
- `ChatComposer` - input widget
- `AiChatController` - Riverpod state management
- No business logic in widgets

## Design Decisions

### Decision 1: Full-Screen Chat vs Modal

**Rationale:** Full-screen provides more space for conversation history and better matches user expectations from messaging apps like Telegram and WhatsApp. Modal would feel cramped for extended conversations.

**Trade-off:** Requires navigation away from current screen, but the improved UX justifies this.

### Decision 2: Space-Specific Chat Threads

**Rationale:** Separate threads per Space prevent context confusion and allow AI to maintain appropriate persona. Users can have different conversations about Health vs Education without mixing contexts.

**Trade-off:** Users can't easily reference information across Spaces in a single conversation, but this is acceptable for privacy and clarity.

### Decision 3: Message History Limit (10 messages)

**Rationale:** Balances context richness with token usage and cost. 10 messages provide sufficient context for most conversations without excessive API costs.

**Trade-off:** Very long conversations may lose early context, but users can scroll to review history manually.

### Decision 4: Lazy Loading (50 messages)

**Rationale:** Prevents performance issues with long chat histories. 50 messages is enough to show recent conversation while keeping render time under 500ms.

**Trade-off:** Users must scroll to load older messages, but this is standard in messaging apps.

### Decision 5: Inline Error Bubbles vs Toast Messages

**Rationale:** Error bubbles in the message list provide clear context about which message failed and allow per-message retry. Toast messages would be less specific.

**Trade-off:** Error bubbles take up space in the chat, but the improved UX justifies this.

### Decision 6: Attachment Metadata Only (No Binaries)

**Rationale:** Sending attachment binaries off-device raises privacy concerns and increases payload size. Metadata (filename, type, transcription) provides sufficient context for AI.

**Trade-off:** AI can't analyze actual image content without binaries, but this is acceptable for v1 privacy-first approach.

### Decision 7: Streaming Response Support

**Rationale:** Streaming provides real-time typing effect similar to ChatGPT, improving perceived responsiveness. Users see AI "thinking" rather than waiting for complete response.

**Trade-off:** Adds complexity to implementation, but significantly improves UX.

### Decision 8: Per-Space Personas

**Rationale:** Different life domains require different tones and behaviors. Health needs empathy and caution, Education needs constructive feedback, Finance needs practical advice.

**Trade-off:** Requires maintaining multiple prompt templates and testing each persona, but essential for appropriate AI behavior.

### Decision 9: No Cross-Space Context

**Rationale:** Prevents privacy leaks and maintains clear boundaries. Health information shouldn't leak into Finance conversations.

**Trade-off:** Users can't ask "show me all my records" across Spaces, but this is acceptable for privacy.

### Decision 10: Offline Message Queuing

**Rationale:** Allows users to compose messages while offline and automatically sends when connectivity returns. Matches user expectations from messaging apps.

**Trade-off:** Adds complexity for queue management and retry logic, but essential for mobile app reliability.

## Performance Impact Estimation

### Expected Latencies

- **Chat screen initial render**: < 500ms (target)
- **Message send (Fake mode)**: 1 second (simulated)
- **Message send (Remote mode)**: 2-4 seconds (network + AI processing)
- **Streaming response**: 50ms per word chunk
- **Worst case timeout**: 30 seconds

### Resource Usage

- **Memory per message**: ~2KB (text + metadata)
- **Memory for 50 messages**: ~100KB
- **Network per request**: 5-15KB (JSON payload)
- **Tokens per message**: 300-800 (depends on context size)
- **Storage per thread**: ~50KB for 100 messages

### UI Impact

- Lazy loading prevents memory issues with long histories
- RepaintBoundary isolates message bubble repaints
- Async operations don't freeze UI
- Streaming provides perceived responsiveness

## Security Considerations

### Data Privacy

1. **Never send off-device:**
   - Information Item IDs
   - Encryption keys
   - Attachment binary data
   - Local file paths

2. **Redact from logs:**
   - Message content
   - Attachment content
   - User personal information

3. **Consent enforcement:**
   - Check consent before every AI operation
   - Show clear data usage banners
   - Allow users to revoke consent anytime

### Network Security

1. **HTTPS only** for all AI requests
2. **API key storage** via `flutter_secure_storage`
3. **Request signing** to prevent tampering
4. **Rate limiting** to prevent abuse

### Storage Security

1. **Encrypted backups** include chat threads
2. **Local storage** uses Isar encryption
3. **Attachment files** stored in app-private directory
4. **Secure deletion** when user clears chat

## References

- `.kiro/specs/ai-summarization/` - Existing AI summarization spec
- `docs/ai/ai_integration_plan.md` - AI integration strategy
- `AI_ASSISTED_LIFE_COMPANION_PLAN.md` - Overall AI vision
- `.kiro/steering/logging-guidelines.md` - Logging requirements
- `.kiro/steering/flutter-ui-performance.md` - Performance guidelines
- `CLEAN_ARCHITECTURE_GUIDE.md` - Architecture patterns
- `AGENTS.md` - Development guidelines
