import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patient_app/core/ai/chat/ai_chat_service.dart';
import 'package:patient_app/core/ai/chat/application/use_cases/clear_chat_thread_use_case.dart';
import 'package:patient_app/core/ai/chat/application/use_cases/load_chat_history_use_case.dart';
import 'package:patient_app/core/ai/chat/application/use_cases/send_chat_message_use_case.dart';
import 'package:patient_app/core/ai/chat/application/use_cases/switch_space_context_use_case.dart';
import 'package:patient_app/core/ai/chat/models/chat_message.dart';
import 'package:patient_app/core/ai/chat/models/chat_thread.dart';
import 'package:patient_app/core/ai/chat/models/message_attachment.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/core/ai/chat/application/interfaces/space_context_builder.dart';
import 'package:patient_app/core/ai/chat/repositories/chat_thread_repository.dart';
import 'package:patient_app/core/ai/chat/services/message_attachment_handler.dart';
import 'package:patient_app/core/ai/chat/providers/space_context_provider.dart';
import 'package:patient_app/core/ai/chat/application/use_cases/send_chat_message_use_case.dart'
    as chat_use_cases;
import 'package:patient_app/core/ai/repositories/ai_consent_repository.dart';
import 'package:patient_app/core/di/app_container.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';
import 'package:patient_app/core/ai/chat/services/message_queue_service.dart';
import 'package:patient_app/core/ai/chat/services/connectivity_monitor.dart';

/// Riverpod controller handling AI chat state for a given space.
class AiChatController extends StateNotifier<AiChatState> {
  AiChatController({
    required this.spaceId,
    required SendChatMessageUseCase sendChatMessageUseCase,
    required LoadChatHistoryUseCase loadChatHistoryUseCase,
    required ClearChatThreadUseCase clearChatThreadUseCase,
    required SwitchSpaceContextUseCase switchSpaceContextUseCase,
    required ChatThreadRepository chatThreadRepository,
    required SpaceContextBuilder spaceContextBuilder,
    required MessageQueueService messageQueueService,
    required ConnectivityMonitor connectivityMonitor,
  })  : _sendChatMessageUseCase = sendChatMessageUseCase,
        _loadChatHistoryUseCase = loadChatHistoryUseCase,
        _clearChatThreadUseCase = clearChatThreadUseCase,
        _switchSpaceContextUseCase = switchSpaceContextUseCase,
        _chatThreadRepository = chatThreadRepository,
        _spaceContextBuilder = spaceContextBuilder,
        _messageQueueService = messageQueueService,
        _connectivityMonitor = connectivityMonitor,
        super(AiChatState.loading()) {
    loadInitial();
  }

  final String spaceId;
  final SendChatMessageUseCase _sendChatMessageUseCase;
  final LoadChatHistoryUseCase _loadChatHistoryUseCase;
  final ClearChatThreadUseCase _clearChatThreadUseCase;
  final SwitchSpaceContextUseCase _switchSpaceContextUseCase;
  final ChatThreadRepository _chatThreadRepository;
  final SpaceContextBuilder _spaceContextBuilder;
  final MessageQueueService _messageQueueService;
  final ConnectivityMonitor _connectivityMonitor;

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final thread = await _loadChatHistoryUseCase.execute(spaceId);
      final context = await _spaceContextBuilder.build(spaceId);
      state = state.copyWith(
        isLoading: false,
        thread: thread,
        spaceContext: context,
      );
    } catch (e, stackTrace) {
      await AppLogger.error(
        'Failed to load chat thread',
        error: e,
        stackTrace: stackTrace,
        context: {'spaceId': spaceId},
      );
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  @override
  void dispose() {
    _connectivityMonitor.stop();
    super.dispose();
  }

  Future<void> startConnectivityMonitoring() {
    return _connectivityMonitor.start();
  }

  void setOffline(bool isOffline) {
    state = state.copyWith(isOffline: isOffline);
    if (!isOffline) {
      _messageQueueService.processQueue();
    }
  }

  void addAttachment(MessageAttachment attachment) {
    final updated = [...state.attachments, attachment];
    state = state.copyWith(attachments: updated);
  }

  void removeAttachment(String attachmentId) {
    final updated = state.attachments.where((a) => a.id != attachmentId).toList();
    state = state.copyWith(attachments: updated);
  }

  Future<void> sendMessage(String content) async {
    if (state.thread == null || state.spaceContext == null) return;
    if (state.isOffline) {
      await _queueOffline(content);
      return;
    }

    state = state.copyWith(isSending: true, errorMessage: null);
    try {
      final attachmentInputs = state.attachments.map((a) {
        if (a.localPath == null) {
          throw StateError('Attachment ${a.id} is missing localPath');
        }
        return chat_use_cases.ChatAttachmentInput(
          file: File(a.localPath!),
          type: a.type,
        );
      }).toList();

      await _sendChatMessageUseCase.execute(
        threadId: state.thread!.id,
        spaceId: state.spaceContext!.spaceId,
        spaceContextOverride: state.spaceContext,
        messageContent: content,
        attachments: attachmentInputs,
      );

      // Refresh thread from repository to reflect new messages/status.
      final refreshed = await _chatThreadRepository.getById(state.thread!.id);
      state = state.copyWith(
        thread: refreshed ?? state.thread,
        attachments: const [],
        isSending: false,
      );
    } catch (e, stackTrace) {
      await AppLogger.error(
        'Failed to send chat message',
        error: e,
        stackTrace: stackTrace,
        context: {'threadId': state.thread?.id},
      );
      state = state.copyWith(isSending: false, errorMessage: e.toString());
    }
  }

  Future<void> _queueOffline(String content) async {
    try {
      await _messageQueueService.enqueue(
        threadId: state.thread!.id,
        spaceContext: state.spaceContext!,
        content: content,
        attachments: state.attachments,
      );
      state = state.copyWith(
        attachments: const [],
        isSending: false,
        errorMessage: 'Message queued for send when online',
      );
    } catch (e, stackTrace) {
      await AppLogger.error(
        'Failed to queue chat message offline',
        error: e,
        stackTrace: stackTrace,
        context: {'threadId': state.thread?.id},
      );
      state = state.copyWith(isSending: false, errorMessage: e.toString());
    }
  }

  Future<void> provideFeedback(String messageId, MessageFeedback feedback) async {
    if (state.thread == null) return;
    try {
      await _chatThreadRepository.updateMessageFeedback(
        state.thread!.id,
        messageId,
        feedback,
      );
      // Reload thread to update UI
      await loadInitial();
    } catch (e, stackTrace) {
      await AppLogger.error(
        'Failed to provide message feedback',
        error: e,
        stackTrace: stackTrace,
        context: {
          'threadId': state.thread?.id,
          'messageId': messageId,
          'feedback': feedback.name,
        },
      );
    }
  }

  Future<void> clearChat() async {
    if (state.thread == null) return;
    await _clearChatThreadUseCase.execute(state.thread!.id);
    await loadInitial();
  }

  Future<void> switchSpace(String newSpaceId, {bool shouldClearCurrent = false}) async {
    state = state.copyWith(isLoading: true, errorMessage: null, attachments: const []);
    try {
      final result = await _switchSpaceContextUseCase.execute(
        currentThreadId: state.thread?.id ?? '',
        newSpaceId: newSpaceId,
        shouldClearCurrentThread: shouldClearCurrent,
      );
      state = state.copyWith(
        isLoading: false,
        thread: result.newThread,
        spaceContext: result.spaceContext,
      );
    } catch (e, stackTrace) {
      await AppLogger.error(
        'Failed to switch chat space',
        error: e,
        stackTrace: stackTrace,
        context: {'currentSpace': spaceId, 'newSpace': newSpaceId},
      );
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

/// Provider for AiChatController scoped by space id.
final aiChatControllerProvider = StateNotifierProvider.family<AiChatController, AiChatState, String>(
  (ref, spaceId) {
    final container = AppContainer.instance;
    final chatRepo = container.resolve<ChatThreadRepository>();
    final attachmentHandler = container.resolve<MessageAttachmentHandler>();
    final spaceBuilder = ref.read(spaceContextBuilderProvider);
    final loadUseCase = LoadChatHistoryUseCase(chatThreadRepository: chatRepo);
    final clearUseCase = ClearChatThreadUseCase(
      chatThreadRepository: chatRepo,
      attachmentHandler: attachmentHandler,
    );
    final sendUseCase = SendChatMessageUseCase(
      aiChatService: container.resolve<AiChatService>(),
      chatThreadRepository: chatRepo,
      consentRepository: container.resolve<AiConsentRepository>(),
      attachmentHandler: attachmentHandler,
      spaceContextBuilder: spaceBuilder,
    );
    final queueService = MessageQueueService(
      sendChatMessageUseCase: sendUseCase,
      chatThreadRepository: chatRepo,
      preferences: container.resolve(),
    );
    late final AiChatController controller;
    final connectivityMonitor = ConnectivityMonitor(
      messageQueueService: queueService,
      onStatusChanged: (isOffline) => controller.setOffline(isOffline),
    );
    final switchUseCase = SwitchSpaceContextUseCase(
      loadChatHistoryUseCase: loadUseCase,
      clearChatThreadUseCase: clearUseCase,
      spaceContextBuilder: spaceBuilder,
    );

    controller = AiChatController(
      spaceId: spaceId,
      sendChatMessageUseCase: sendUseCase,
      loadChatHistoryUseCase: loadUseCase,
      clearChatThreadUseCase: clearUseCase,
      switchSpaceContextUseCase: switchUseCase,
      chatThreadRepository: chatRepo,
      spaceContextBuilder: spaceBuilder,
      messageQueueService: queueService,
      connectivityMonitor: connectivityMonitor,
    );
    controller.startConnectivityMonitoring();
    return controller;
  },
);

/// Immutable UI state for the AI chat surface.
class AiChatState {
  const AiChatState({
    required this.isLoading,
    required this.isSending,
    required this.isOffline,
    this.thread,
    this.spaceContext,
    this.errorMessage,
    this.attachments = const [],
  });

  final bool isLoading;
  final bool isSending;
  final bool isOffline;
  final ChatThread? thread;
  final SpaceContext? spaceContext;
  final String? errorMessage;
  final List<MessageAttachment> attachments;

  factory AiChatState.loading() => const AiChatState(
        isLoading: true,
        isSending: false,
        isOffline: false,
      );

  AiChatState copyWith({
    bool? isLoading,
    bool? isSending,
    bool? isOffline,
    ChatThread? thread,
    SpaceContext? spaceContext,
    String? errorMessage,
    List<MessageAttachment>? attachments,
  }) {
    return AiChatState(
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      isOffline: isOffline ?? this.isOffline,
      thread: thread ?? this.thread,
      spaceContext: spaceContext ?? this.spaceContext,
      errorMessage: errorMessage,
      attachments: attachments ?? this.attachments,
    );
  }
}
