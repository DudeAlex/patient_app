import 'package:flutter/material.dart';

/// Styled error bubble with optional retry action.
class ErrorMessageBubble extends StatelessWidget {
  const ErrorMessageBubble({
    super.key,
    required this.message,
    this.onRetry,
    this.showRetry = false,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool showRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.error.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: colors.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: colors.error),
                ),
              ),
            ],
          ),
          if (showRetry && onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh, color: colors.error),
              label: Text(
                'Retry',
                style: TextStyle(color: colors.error),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
