import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:patient_app/core/ai/ai_providers.dart';
import 'package:patient_app/core/ai/models/ai_call_log_entry.dart';

class AiDiagnosticsScreen extends ConsumerStatefulWidget {
  const AiDiagnosticsScreen({super.key});

  @override
  ConsumerState<AiDiagnosticsScreen> createState() => _AiDiagnosticsScreenState();
}

class _AiDiagnosticsScreenState extends ConsumerState<AiDiagnosticsScreen> {
  String? _spaceFilter;
  String _domainFilter = 'chat'; // default to chat logs per diagnostics task

  @override
  Widget build(BuildContext context) {
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

          final spaceOptions = <String?>{null, ...entries.map((e) => e.spaceId)};
          final domainOptions = <String>{'all', ...entries.map((e) => e.domainId)};

          final filtered = entries.where((entry) {
            final matchesSpace = _spaceFilter == null || entry.spaceId == _spaceFilter;
            final matchesDomain =
                _domainFilter == 'all' || entry.domainId == _domainFilter;
            return matchesSpace && matchesDomain;
          }).toList(growable: false);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _FilterDropdown<String?>(
                        label: 'Space',
                        value: _spaceFilter,
                        options: spaceOptions.toList(),
                        display: (value) => value ?? 'All',
                        onChanged: (value) {
                          setState(() {
                            _spaceFilter = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FilterDropdown<String>(
                        label: 'Domain',
                        value: _domainFilter,
                        options: domainOptions.toList(),
                        display: (value) => value == 'all' ? 'All' : value,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _domainFilter = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No entries match the filters.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (_, index) =>
                            _AiCallTile(entry: filtered[index]),
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: 12),
                        itemCount: filtered.length,
                      ),
              ),
            ],
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

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.display,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> options;
  final String Function(T) display;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: options
              .map(
                (opt) => DropdownMenuItem<T>(
                  value: opt,
                  child: Text(display(opt)),
                ),
              )
              .toList(),
          onChanged: onChanged,
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
