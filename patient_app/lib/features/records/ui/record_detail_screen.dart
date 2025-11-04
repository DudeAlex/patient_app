import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:provider/provider.dart';

import '../model/record.dart';
import '../model/record_types.dart';
import 'add_record_screen.dart';
import 'records_home_state.dart';

/// Temporary detail screen that shows the core fields for the selected record.
/// This keeps navigation wiring incremental while the full detail design is
/// still in progress (see M2 plan).
class RecordDetailScreen extends StatefulWidget {
  const RecordDetailScreen({super.key, required this.recordId});

  final Id recordId;

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
  Record? _record;

  @override
  void initState() {
    super.initState();
    final state = context.read<RecordsHomeState>();
    _record = state.recordById(widget.recordId);
  }

  String get _title => _record?.title ?? 'Record';

  Future<void> _refreshRecord() async {
    final state = context.read<RecordsHomeState>();
    final latest = state.recordById(widget.recordId);
    if (latest != null && mounted) {
      setState(() {
        _record = latest;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RecordsHomeState>();
    _record = state.recordById(widget.recordId) ?? _record;
    final record = _record;
    if (record == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Record')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('This record is no longer available.'),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final containerColor = theme.colorScheme.surfaceContainerHighest;
    final dateFormatter = DateFormat.yMMMMd();
    final dateTimeFormatter = DateFormat.yMMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit record',
            onPressed: () => _editRecord(context, record),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete record',
            onPressed: () => _confirmDelete(context, record),
          ),
        ],
      ),
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
            Card(
              color: containerColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attachment support is coming soon.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Add attachment (coming soon)'),
                    ),
                  ],
                ),
              ),
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

  Future<void> _editRecord(BuildContext context, Record record) async {
    final state = context.read<RecordsHomeState>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: state,
          child: AddRecordScreen(existing: record),
        ),
      ),
    );
    await _refreshRecord();
  }

  Future<void> _confirmDelete(BuildContext context, Record record) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete record?'),
            content: const Text(
              'This will permanently remove the record from your device.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!context.mounted) return;
    if (!confirmed) return;

    try {
      await context.read<RecordsHomeState>().deleteRecord(record.id);
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete record: $e')));
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
