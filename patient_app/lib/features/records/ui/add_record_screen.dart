import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../domain/entities/record.dart';
import 'records_home_state.dart';
import '../../spaces/providers/space_provider.dart';
import '../../../core/domain/entities/space.dart';

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({super.key, this.existing});

  final RecordEntity? existing;

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagsController = TextEditingController();

  String? _type; // Will be initialized from space categories
  DateTime _date = DateTime.now();
  bool _submitting = false;
  late final RecordEntity? _original;
  Space? _currentSpace;

  @override
  void initState() {
    super.initState();
    _original = widget.existing;
    final original = _original;
    if (original != null) {
      _type = original.type;
      _date = original.date;
      _titleController.text = original.title;
      _notesController.text = original.text ?? '';
      _tagsController.text = original.tags.join(', ');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get current space from provider
    final spaceProvider = context.watch<SpaceProvider>();
    _currentSpace = spaceProvider.currentSpace;
    
    // Initialize type from space categories if not set
    if (_type == null && _currentSpace != null) {
      _type = _currentSpace!.categories.first;
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

    final original = _original;
    // Use current space ID for new records
    final spaceId = _currentSpace?.id ?? 'health';
    
    final newRecord = RecordEntity(
      id: original?.id,
      spaceId: spaceId,
      type: _type ?? 'Other',
      date: _date,
      title: _titleController.text.trim(),
      text: cleanedNotes.isEmpty ? null : cleanedNotes,
      tags: tags,
      createdAt: original?.createdAt ?? now,
      updatedAt: now,
      deletedAt: original?.deletedAt,
    );
    final state = context.read<RecordsHomeState>();
    try {
      await state.saveRecord(newRecord);
      if (!mounted) return;
      Navigator.of(context).pop();
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
    
    // Get space-specific title and categories
    final spaceName = _currentSpace?.name ?? 'Record';
    final title = isEdit ? 'Edit $spaceName Record' : 'Add $spaceName Record';
    
    // Build categories list, ensuring existing type is included
    final baseCategories = _currentSpace?.categories ?? ['Other'];
    final categories = <String>[
      ...baseCategories,
      // Add existing type if not already in categories (for backward compatibility)
      if (_type != null && !baseCategories.contains(_type)) _type!,
    ];
    
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            DropdownButtonFormField<String>(
              value: _type,
              isExpanded: true,  // Fix: Prevent overflow by expanding to fill width
              decoration: InputDecoration(
                labelText: 'Category',
                hintText: 'Select a category for this ${spaceName.toLowerCase()} record',
              ),
              items: categories
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(
                        value,
                        overflow: TextOverflow.ellipsis,  // Fix: Truncate long text
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _type = value;
                });
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please select a category';
                }
                return null;
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
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'Enter a descriptive title for this ${spaceName.toLowerCase()} record',
                border: const OutlineInputBorder(),
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
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                        : () => Navigator.of(context).pop(),
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

}
