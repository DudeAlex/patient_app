import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:patient_app/core/ai/ai_providers.dart';
import 'package:patient_app/core/ai/models/ai_call_log_entry.dart';

/// Displays context optimization metrics for AI chat.
///
/// Shows key performance indicators:
/// - Average records included per request (Placeholder)
/// - Average token usage per request
/// - Average context assembly time (Latency as proxy)
/// - Truncation frequency (Placeholder)
///
/// Note: Metrics are collected via AppLogger. This widget provides
/// a summary view. For detailed metrics, check application logs.
class ContextMetricsCard extends ConsumerWidget {
  const ContextMetricsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(aiCallLogStreamProvider);

    return logsAsync.when(
      data: (logs) {
        final chatLogs = logs.where((e) => e.domainId == 'chat').toList();
        final metrics = _calculateMetrics(chatLogs);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Context Metrics',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Performance metrics for AI context optimization (last ${chatLogs.length} requests)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                _MetricRow(
                  icon: Icons.list_alt,
                  label: 'Records per Request',
                  value: 'Check logs', // Not currently in AiCallLogEntry
                  tooltip: 'Average number of records included in context',
                ),
                const SizedBox(height: 12),
                _MetricRow(
                  icon: Icons.token,
                  label: 'Avg Token Usage',
                  value: '${metrics.avgTokens.toStringAsFixed(0)} tokens',
                  tooltip: 'Average tokens used per request',
                ),
                const SizedBox(height: 12),
                _MetricRow(
                  icon: Icons.speed,
                  label: 'Avg Latency',
                  value: '${metrics.avgLatency.toStringAsFixed(0)} ms',
                  tooltip: 'Average time to build context and get response',
                ),
                const SizedBox(height: 12),
                _MetricRow(
                  icon: Icons.content_cut,
                  label: 'Success Rate',
                  value: '${(metrics.successRate * 100).toStringAsFixed(1)}%',
                  tooltip: 'Percentage of successful requests',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Detailed metrics (like records included) are logged with each AI request. '
                          'Use the diagnostic logs to analyze performance trends.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Metrics tracked:',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const _BulletPoint(
                    text: 'recordsFiltered: Total records after date filtering'),
                const _BulletPoint(
                    text: 'recordsIncluded: Records in context (≤20)'),
                const _BulletPoint(
                    text: 'tokensEstimated: Estimated tokens for context'),
                const _BulletPoint(
                    text: 'tokensAvailable: Available token budget'),
                const _BulletPoint(
                    text: 'compressionRatio: Included/filtered ratio'),
                const _BulletPoint(
                    text: 'assemblyTime: Context build duration'),
                const _BulletPoint(
                    text: 'truncationReasons: Why records were dropped'),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))),
      error: (err, stack) => Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Error loading metrics: $err'))),
    );
  }

  _Metrics _calculateMetrics(List<AiCallLogEntry> logs) {
    if (logs.isEmpty) {
      return const _Metrics(avgTokens: 0, avgLatency: 0, successRate: 0);
    }

    final totalTokens = logs.fold(0, (sum, e) => sum + e.tokensUsed);
    final totalLatency = logs.fold(0, (sum, e) => sum + e.latencyMs);
    final successCount = logs.where((e) => e.success).length;

    return _Metrics(
      avgTokens: totalTokens / logs.length,
      avgLatency: totalLatency / logs.length,
      successRate: successCount / logs.length,
    );
  }
}

class _Metrics {
  const _Metrics({
    required this.avgTokens,
    required this.avgLatency,
    required this.successRate,
  });

  final double avgTokens;
  final double avgLatency;
  final double successRate;
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.tooltip,
  });

  final IconData icon;
  final String label;
  final String value;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  const _BulletPoint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
