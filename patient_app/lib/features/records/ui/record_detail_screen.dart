import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/record.dart';
import '../model/record_types.dart';

/// Temporary detail screen that shows the core fields for the selected record.
/// This keeps navigation wiring incremental while the full detail design is
/// still in progress (see M2 plan).
class RecordDetailScreen extends StatelessWidget {
  const RecordDetailScreen({super.key, required this.record});

  final Record record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat.yMMMMd();
    final dateTimeFormatter = DateFormat.yMMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(title: Text(record.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(label: 'Type', value: _formatType(record.type)),
            const SizedBox(height: 12),
            _DetailRow(label: 'Date', value: dateFormatter.format(record.date)),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Created',
              value: dateTimeFormatter.format(record.createdAt),
            ),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Last updated',
              value: dateTimeFormatter.format(record.updatedAt),
            ),
            if (record.text != null && record.text!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(record.text!, style: theme.textTheme.bodyLarge),
            ],
            if (record.tags.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Tags', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: record.tags
                    .map((tag) => Chip(label: Text(tag)))
                    .toList(growable: false),
              ),
            ],
            const SizedBox(height: 32),
            Text('Attachments', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            const Text(
              'Attachment support is coming soon.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _formatType(String type) {
    switch (type) {
      case RecordTypes.visit:
        return 'Visit';
      case RecordTypes.lab:
        return 'Lab';
      case RecordTypes.medication:
        return 'Medication';
      case RecordTypes.note:
        return 'Note';
      default:
        return type;
    }
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
