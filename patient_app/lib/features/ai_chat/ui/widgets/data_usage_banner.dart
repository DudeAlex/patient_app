import 'package:flutter/material.dart';

/// Banner explaining what data the AI can access for the current space.
class DataUsageBanner extends StatelessWidget {
  const DataUsageBanner({
    super.key,
    required this.spaceName,
    this.recordTitle,
    this.onDismissed,
  });

  final String spaceName;
  final String? recordTitle;
  final VoidCallback? onDismissed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Dismissible(
      key: const Key('data_usage_banner'),
      direction: onDismissed != null
          ? DismissDirection.horizontal
          : DismissDirection.none,
      onDismissed: (_) => onDismissed?.call(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.secondaryContainer.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.secondary.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.shield_outlined, color: colors.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI can access your $spaceName records only.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recordTitle != null
                        ? 'Using $recordTitle as context.'
                        : 'Context stays within this space; attachments remain local.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (onDismissed != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.close, color: colors.onSecondaryContainer),
                tooltip: 'Dismiss',
                onPressed: onDismissed,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
