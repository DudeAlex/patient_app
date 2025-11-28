import 'package:flutter/material.dart';
import 'package:patient_app/core/ai/chat/models/chat_message.dart';
import 'package:patient_app/features/ai_chat/ui/widgets/chat_message_bubble.dart';

/// A scrollable list of chat messages with lazy loading and auto-scroll behavior.
///
/// Renders messages in a reversed ListView (newest at bottom).
/// Manages a visible window of messages, expanding it as the user scrolls up.
/// Auto-scrolls to the bottom when new messages arrive.
class MessageList extends StatefulWidget {
  const MessageList({
    super.key,
    required this.messages,
    this.onLoadMore,
    this.onRetry,
    this.onCopy,
    this.onActionHintTap,
    this.onFeedback,
    this.initialVisibleCount = 50,
  });

  /// List of messages, ordered from oldest to newest.
  final List<ChatMessage> messages;

  /// Callback triggered when the user scrolls near the top to load more history.
  final VoidCallback? onLoadMore;

  /// Callback for retrying failed messages.
  final VoidCallback? onRetry;

  /// Callback for copying message content.
  final ValueChanged<String>? onCopy;

  /// Callback for tapping an action hint.
  final ValueChanged<String>? onActionHintTap;

  /// Callback for providing feedback on a message.
  final void Function(String messageId, MessageFeedback feedback)? onFeedback;

  /// Number of messages to show initially and to add per page.
  final int initialVisibleCount;

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  late ScrollController _scrollController;
  late int _visibleCount;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _visibleCount = widget.initialVisibleCount;
  }

  @override
  void didUpdateWidget(MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if new messages arrived (added to the end)
    final bool newMessagesArrived = widget.messages.isNotEmpty &&
        (oldWidget.messages.isEmpty ||
            widget.messages.last.id != oldWidget.messages.last.id);

    if (newMessagesArrived) {
      // Reset window and scroll to bottom
      setState(() {
        _visibleCount = widget.initialVisibleCount;
      });
      // Use a post-frame callback to ensure the list has updated before scrolling
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = 80.0;

    // Check if scrolled near the top (maxScrollExtent in reversed list)
    if (maxScroll - currentScroll <= threshold) {
      // Only expand if we have more messages to show
      if (_visibleCount < widget.messages.length) {
        setState(() {
          _visibleCount += widget.initialVisibleCount;
        });
        widget.onLoadMore?.call();
      } else {
        // Even if we are showing all local messages, we might need to fetch more from backend
        // But we should avoid spamming the callback if we just called it.
        // For simplicity, we'll call it if we are at the edge.
        // A more robust implementation might check a loading state.
        widget.onLoadMore?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate how many messages to show
    final int count = widget.messages.length;
    final int showCount = _visibleCount < count ? _visibleCount : count;

    // We want to show the *last* [showCount] messages.
    // In a reversed list, index 0 is the last message (newest).
    // So we can just take the sublist from the end, reversed.
    // Actually, ListView.builder with reverse:true handles the visual reversing.
    // We just need to map index i to the correct message.
    // ListView index 0 -> messages[messages.length - 1] (Newest)
    // ListView index k -> messages[messages.length - 1 - k]

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: showCount,
      itemBuilder: (context, index) {
        // Calculate the index in the source list
        // Source list: [Oldest, ..., Newest]
        // We want to show the last [showCount] items.
        // The item at ListView index 0 is the Newest (messages.last).
        // The item at ListView index [showCount - 1] is the Oldest visible.
        
        final messageIndex = widget.messages.length - 1 - index;
        final message = widget.messages[messageIndex];

        return ChatMessageBubble(
          message: message,
          onRetry: widget.onRetry,
          onCopy: widget.onCopy,
          onActionHintTap: widget.onActionHintTap,
          onFeedback: widget.onFeedback != null
              ? (feedback) => widget.onFeedback!(message.id, feedback)
              : null,
        );
      },
    );
  }
}
