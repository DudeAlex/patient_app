import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../model/record.dart';
import '../model/record_types.dart';
import '../repo/records_repo.dart';

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({super.key, required this.repository, this.existing});

  final RecordsRepository repository;
  final Record? existing;

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagsController = TextEditingController();

  String _type = RecordTypes.note;
  DateTime _date = DateTime.now();
  bool _submitting = false;
  late final Record? _original;

  @override
  void initState() {
    super.initState();
    _original = widget.existing;
    if (_original != null) {
      _type = _original!.type;
      _date = _original!.date;
      _titleController.text = _original!.title;
      _notesController.text = _original!.text ?? '';
      _tagsController.text = _original!.tags.join(', ');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final now = DateTime.now();
    final cleanedNotes = _notesController.text.trim();
    final tags = _parseTags(_tagsController.text);

    final record = Record()
      ..type = _type
      ..date = _date
      ..title = _titleController.text.trim()
      ..text = cleanedNotes.isEmpty ? null : cleanedNotes
      ..tags = tags
      ..updatedAt = now;

    if (_original != null) {
      record.id = _original!.id;
      record.createdAt = _original!.createdAt;
      record.deletedAt = _original!.deletedAt;
    } else {
      record.createdAt = now;
    }
    try {
      await widget.repository.add(record);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save record: $e')));
      setState(() => _submitting = false);
    }
  }

  List<String> _parseTags(String input) {
    return input
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _original != null;
    final dateLabel = DateFormat.yMMMMd().format(_date);
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Record' : 'Add Record')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: RecordTypes.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(_formatType(value)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _type = value;
                });
              },
            ),
            const SizedBox(height: 16),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(dateLabel),
                  TextButton(onPressed: _pickDate, child: const Text('Change')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              minLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Text('Attachments', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Card(
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Capture photos, scans, and files here once attachments are enabled.',
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
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEdit ? 'Update' : 'Save'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
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
