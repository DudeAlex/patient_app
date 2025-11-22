import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ai/ai_providers.dart';
import '../../core/ai/models/ai_call_log_entry.dart';

class AiDiagnosticsScreen extends ConsumerWidget {
  const AiDiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEntries = ref.watch(aiCallLogStreamProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Calls'),
      ),
      body: asyncEntries.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Text('No AI activity recorded this session.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (_, index) =>
                _AiCallTile(entry: entries[index]),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: entries.length,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Failed to load AI logs: $error'),
        ),
      ),
    );
  }
}

class _AiCallTile extends StatelessWidget {
  const _AiCallTile({required this.entry});

  final AiCallLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor =
        entry.success ? Colors.green : theme.colorScheme.error;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                entry.success ? Icons.check_circle : Icons.error_outline,
                color: statusColor,
              ),
              const SizedBox(width: 8),
              Text(
                '${entry.spaceId} • ${entry.domainId}',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Provider: ${entry.provider}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Latency: ${entry.latencyMs} ms  •  Tokens: ${entry.tokensUsed}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Confidence: ${(entry.confidence * 100).toStringAsFixed(0)}%',
            style: theme.textTheme.bodySmall,
          ),
          if (!entry.success && entry.errorMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              entry.errorMessage!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            entry.timestamp.toLocal().toString(),
            style:
                theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
