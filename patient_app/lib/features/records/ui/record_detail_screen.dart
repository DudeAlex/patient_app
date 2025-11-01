import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/record.dart';

/// Temporary detail screen that shows the core fields for the selected record.
/// This keeps navigation wiring incremental while the full detail design is
/// still in progress (see M2 plan).
class RecordDetailScreen extends StatelessWidget {
  const RecordDetailScreen({super.key, required this.record});

  final Record record;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(record.title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(label: 'Type', value: record.type),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Date',
              value: DateFormat.yMMMMd().format(record.date),
            ),
            if (record.text != null && record.text!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(record.text!, style: Theme.of(context).textTheme.bodyLarge),
            ],
            if (record.tags.isNotEmpty) ...[
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: record.tags
                    .map((tag) => Chip(label: Text(tag)))
                    .toList(growable: false),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}
