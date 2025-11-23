import 'package:flutter/material.dart';
import 'package:patient_app/core/ai/ai_config.dart';

/// Header for the AI chat screen showing space context and AI status.
class ChatHeader extends StatelessWidget implements PreferredSizeWidget {
  const ChatHeader({
    super.key,
    required this.spaceName,
    required this.spaceIcon,
    required this.status,
    required this.onClearChat,
    required this.onChangeContext,
  });

  final String spaceName;
  final IconData spaceIcon;
  final ChatHeaderStatus status;
  final VoidCallback onClearChat;
  final VoidCallback onChangeContext;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      title: Row(
        children: [
          _ContextChip(spaceName: spaceName, spaceIcon: spaceIcon),
          const SizedBox(width: 12),
          _StatusPill(status: status),
        ],
      ),
      actions: [
        PopupMenuButton<_ChatMenuAction>(
          icon: const Icon(Icons.more_vert),
          onSelected: (action) {
            switch (action) {
              case _ChatMenuAction.clearChat:
                onClearChat();
                break;
              case _ChatMenuAction.changeContext:
                onChangeContext();
                break;
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: _ChatMenuAction.clearChat,
              child: Text('Clear Chat'),
            ),
            PopupMenuItem(
              value: _ChatMenuAction.changeContext,
              child: Text('Change Context'),
            ),
          ],
        ),
      ],
    );
  }
}

enum ChatHeaderStatus { fake, remote, offline }

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final ChatHeaderStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = switch (status) {
      ChatHeaderStatus.fake => 'Fake',
      ChatHeaderStatus.remote => 'Remote',
      ChatHeaderStatus.offline => 'Offline',
    };
    final color = switch (status) {
      ChatHeaderStatus.fake => colors.secondary,
      ChatHeaderStatus.remote => colors.primary,
      ChatHeaderStatus.offline => colors.error,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _ContextChip extends StatelessWidget {
  const _ContextChip({required this.spaceName, required this.spaceIcon});

  final String spaceName;
  final IconData spaceIcon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(spaceIcon, size: 18, color: colors.primary),
          const SizedBox(width: 6),
          Text(
            spaceName,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

enum _ChatMenuAction { clearChat, changeContext }
