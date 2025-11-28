import 'package:flutter/material.dart';

/// Displays context optimization metrics for AI chat.
///
/// Shows key performance indicators:
/// - Average records included per request
/// - Average token usage per request  
/// - Average context assembly time
/// - Truncation frequency
///
/// Note: Metrics are collected via AppLogger. This widget provides
/// a summary view. For detailed metrics, check application logs.
class ContextMetricsCard extends StatelessWidget {
  const ContextMetricsCard({super.key});

  @override
  Widget build(BuildContext context) {
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
              'Performance metrics for AI context optimization',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _MetricRow(
              icon: Icons.list_alt,
              label: 'Records per Request',
              value: 'Tracked in logs',
              tooltip: 'Average number of records included in context',
            ),
            const SizedBox(height: 12),
            _MetricRow(
              icon: Icons.token,
              label: 'Token Usage',
              value: 'Tracked in logs',
              tooltip: 'Average tokens used per request',
            ),
            const SizedBox(height: 12),
            _MetricRow(
              icon: Icons.speed,
              label: 'Assembly Time',
              value: 'Tracked in logs',
              tooltip: 'Average time to build context',
            ),
            const SizedBox(height: 12),
            _MetricRow(
              icon: Icons.content_cut,
              label: 'Truncation Events',
              value: 'Tracked in logs',
              tooltip: 'Frequency of context truncation',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
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
                      'Detailed metrics are logged with each AI request. '
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
            _BulletPoint(text: 'recordsFiltered: Total records after date filtering'),
            _BulletPoint(text: 'recordsIncluded: Records in context (≤20)'),
            _BulletPoint(text: 'tokensEstimated: Estimated tokens for context'),
            _BulletPoint(text: 'tokensAvailable: Available token budget'),
            _BulletPoint(text: 'compressionRatio: Included/filtered ratio'),
            _BulletPoint(text: 'assemblyTime: Context build duration'),
            _BulletPoint(text: 'truncationReasons: Why records were dropped'),
          ],
        ),
      ),
    );
  }
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
