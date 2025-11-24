import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:patient_app/core/ai/chat/application/use_cases/send_chat_message_use_case.dart';
import 'package:patient_app/core/ai/chat/models/space_context.dart';
import 'package:patient_app/core/ai/chat/repositories/chat_thread_repository.dart';
import 'package:patient_app/core/diagnostics/app_logger.dart';

import '../models/message_attachment.dart';
import '../application/use_cases/send_chat_message_use_case.dart' as chat_use_cases;

/// Queues chat messages when offline and retries them when connectivity returns.
///
/// Minimal in-memory queue; if durability is required across app restarts, add
/// persistence to storage/Isar in a follow-up.
class MessageQueueService {
  MessageQueueService({
    required SendChatMessageUseCase sendChatMessageUseCase,
    required ChatThreadRepository chatThreadRepository,
    required SharedPreferences preferences,
    DateTime Function()? now,
  })  : _sendChatMessageUseCase = sendChatMessageUseCase,
        _chatThreadRepository = chatThreadRepository,
        _preferences = preferences,
        _now = now ?? DateTime.now;

  static const _storageKey = 'ai_chat_offline_queue_v1';
  static const _maxMessages = 100;
  static const _maxAge = Duration(days: 7);

  final SendChatMessageUseCase _sendChatMessageUseCase;
  final ChatThreadRepository _chatThreadRepository;
  final SharedPreferences _preferences;
  final DateTime Function() _now;

  List<_QueuedMessage> _queue = [];
  bool _processing = false;
  bool _loaded = false;

  /// Adds a message to the offline queue.
  Future<void> enqueue({
    required String threadId,
    required SpaceContext spaceContext,
    required String content,
    required List<MessageAttachment> attachments,
  }) async {
    await _loadQueue();
    final opId = AppLogger.startOperation('enqueue_chat_message');
    try {
      final inputs = attachments.map((attachment) {
        if (attachment.localPath == null) {
          throw StateError('Attachment ${attachment.id} is missing localPath');
        }
        return chat_use_cases.ChatAttachmentInput(
          file: File(attachment.localPath!),
          type: attachment.type,
        );
      }).toList(growable: false);

      _purgeExpired();
      _queue.add(
        _QueuedMessage(
          threadId: threadId,
          spaceContext: spaceContext,
          content: content,
          attachments: inputs,
          enqueuedAt: _now(),
        ),
      );
      _enforceMaxSize();
      await _persist();

      await AppLogger.info('Queued chat message for offline send', context: {
        'threadId': threadId,
        'attachments': attachments.length,
        'queueLength': _queue.length,
      });
    } finally {
      await AppLogger.endOperation(opId);
    }
  }

  /// Attempts to send all queued messages sequentially.
  ///
  /// Messages that fail remain in the queue for the next retry.
  Future<void> processQueue() async {
    await _loadQueue();
    if (_processing || _queue.isEmpty) return;
    _processing = true;
    final opId = AppLogger.startOperation('process_chat_queue');
    try {
      // Iterate over a copy so we can remove from the original safely.
      final pending = List<_QueuedMessage>.from(_queue);
      for (final queued in pending) {
        final messageOp = AppLogger.startOperation(
          'process_chat_queue_item',
          parentId: opId,
        );
        try {
          await _sendChatMessageUseCase.execute(
            threadId: queued.threadId,
            spaceContext: queued.spaceContext,
            messageContent: queued.content,
            attachments: queued.attachments,
          );

          // Refresh thread so callers can update UI if needed.
          await _chatThreadRepository.getById(queued.threadId);

          _queue.remove(queued);
          await _persist();
          await AppLogger.info('Queued chat message sent', context: {
            'threadId': queued.threadId,
            'queueLength': _queue.length,
          });
        } catch (e, stackTrace) {
          await AppLogger.error(
            'Failed to send queued chat message',
            error: e,
            stackTrace: stackTrace,
            context: {'threadId': queued.threadId},
          );
          // Leave in queue for next attempt; consider adding backoff metadata later.
        } finally {
          await AppLogger.endOperation(messageOp);
        }
      }
      _purgeExpired();
      await _persist();
    } finally {
      _processing = false;
      await AppLogger.endOperation(opId);
    }
  }

  int get pendingCount => _queue.length;

  Future<void> _loadQueue() async {
    if (_loaded) return;
    _loaded = true;
    final raw = _preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _queue = [];
      return;
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _queue = decoded
          .map((item) => _QueuedMessage.fromJson(item as Map<String, dynamic>))
          .where((item) => !_isExpired(item))
          .toList(growable: true);
      _enforceMaxSize();
    } catch (e, stackTrace) {
      _queue = [];
      await AppLogger.error(
        'Failed to load queued chat messages; clearing persisted queue',
        error: e,
        stackTrace: stackTrace,
      );
      await _preferences.remove(_storageKey);
    }
  }

  Future<void> _persist() async {
    final payload = _queue.map((item) => item.toJson()).toList();
    await _preferences.setString(_storageKey, jsonEncode(payload));
  }

  void _enforceMaxSize() {
    if (_queue.length <= _maxMessages) return;
    final removed = _queue.length - _maxMessages;
    _queue = _queue.sublist(_queue.length - _maxMessages);
    AppLogger.warning(
      'Trimmed offline chat queue to max size',
      context: {'removed': removed, 'max': _maxMessages},
    );
  }

  void _purgeExpired() {
    final before = _queue.length;
    _queue.removeWhere(_isExpired);
    if (before != _queue.length) {
      AppLogger.info(
        'Purged expired offline chat messages',
        context: {'removed': before - _queue.length},
      );
    }
  }

  bool _isExpired(_QueuedMessage message) {
    return _now().difference(message.enqueuedAt) > _maxAge;
  }
}

class _QueuedMessage {
  _QueuedMessage({
    required this.threadId,
    required this.spaceContext,
    required this.content,
    required this.attachments,
    required this.enqueuedAt,
  });

  final String threadId;
  final SpaceContext spaceContext;
  final String content;
  final List<chat_use_cases.ChatAttachmentInput> attachments;
  final DateTime enqueuedAt;

  Map<String, dynamic> toJson() {
    return {
      'threadId': threadId,
      'spaceContext': {
        'spaceId': spaceContext.spaceId,
        'spaceName': spaceContext.spaceName,
        'persona': spaceContext.persona.name,
        'maxContextRecords': spaceContext.maxContextRecords,
        'recentRecords': spaceContext.limitedRecords
            .map(
              (record) => {
                'title': record.title,
                'category': record.category,
                'tags': record.tags,
                'summaryText': record.summaryText,
                'createdAt': record.createdAt.toIso8601String(),
              },
            )
            .toList(),
      },
      'content': content,
      'attachments': attachments
          .map(
            (attachment) => {
              'type': attachment.type.name,
              'path': attachment.file.path,
            },
          )
          .toList(),
      'enqueuedAt': enqueuedAt.toIso8601String(),
    };
  }

  factory _QueuedMessage.fromJson(Map<String, dynamic> json) {
    final space = json['spaceContext'] as Map<String, dynamic>? ?? const {};
    final recent = (space['recentRecords'] as List<dynamic>? ?? [])
        .map((item) => item as Map<String, dynamic>)
        .map(
          (record) => RecordSummary(
            title: record['title'] as String? ?? '',
            category: record['category'] as String? ?? '',
            tags: (record['tags'] as List<dynamic>? ?? []).cast<String>(),
            summaryText: record['summaryText'] as String?,
            createdAt: DateTime.tryParse(record['createdAt'] as String? ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0),
          ),
        )
        .toList(growable: false);

    final attachmentsJson = (json['attachments'] as List<dynamic>? ?? [])
        .map((item) => item as Map<String, dynamic>);
    final attachmentInputs = attachmentsJson
        .where((item) => (item['path'] as String?)?.isNotEmpty ?? false)
        .map(
          (item) => chat_use_cases.ChatAttachmentInput(
            file: File(item['path'] as String),
            type: AttachmentType.values.firstWhere(
              (t) => t.name == item['type'],
              orElse: () => AttachmentType.file,
            ),
          ),
        )
        .toList(growable: false);

    return _QueuedMessage(
      threadId: json['threadId'] as String? ?? '',
      spaceContext: SpaceContext(
        spaceId: space['spaceId'] as String? ?? '',
        spaceName: space['spaceName'] as String? ?? '',
        persona: _parsePersona(space['persona'] as String?),
        recentRecords: recent,
        maxContextRecords: space['maxContextRecords'] as int? ?? 5,
      ),
      content: json['content'] as String? ?? '',
      attachments: attachmentInputs,
      enqueuedAt: DateTime.tryParse(json['enqueuedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static SpacePersona _parsePersona(String? value) {
    return SpacePersona.values.firstWhere(
      (p) => p.name == value,
      orElse: () => SpacePersona.general,
    );
  }
}
