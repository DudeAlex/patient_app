import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../adapters/presenters/capture_review_presenter.dart';
import '../api/capture_artifact.dart';
import '../api/capture_mode.dart';
import '../api/capture_result.dart';
import '../../records/domain/entities/record.dart';
import '../../records/model/attachment.dart';
import '../../records/model/record_types.dart';
import '../../records/ui/records_home_state.dart';

class CaptureReviewScreen extends StatefulWidget {
  const CaptureReviewScreen({
    super.key,
    required this.mode,
    required this.result,
  });

  final CaptureMode mode;
  final CaptureResult result;

  @override
  State<CaptureReviewScreen> createState() => _CaptureReviewScreenState();
}

class _CaptureReviewScreenState extends State<CaptureReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late final TextEditingController _tagsController;

  String _type = RecordTypes.note;
  DateTime _date = DateTime.now();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final presenter = CaptureReviewPresenter(
      mode: widget.mode,
      result: widget.result,
    );
    final viewModel = presenter.buildViewModel();

    // Initialize controllers with suggested values from capture
    _titleController = TextEditingController(
      text: _inferTitle(viewModel),
    );
    _notesController = TextEditingController(
      text: viewModel.details,
    );
    _tagsController = TextEditingController(
      text: viewModel.tagsDescription,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  String _inferTitle(CaptureReviewViewModel viewModel) {
    // Generate a default title based on capture mode and date
    final modeName = widget.mode.displayName;
    final dateStr = DateFormat.yMd().format(_date);
    return '$modeName - $dateStr';
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

    final newRecord = RecordEntity(
      id: null,
      type: _type,
      date: _date,
      title: _titleController.text.trim(),
      text: cleanedNotes.isEmpty ? null : cleanedNotes,
      tags: tags,
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
    );

    final state = context.read<RecordsHomeState>();
    try {
      // Save the record first to get the ID
      final savedRecord = await state.saveRecord(newRecord);

      // Save attachments linked to the record
      if (widget.result.artifacts.isNotEmpty) {
        await _saveAttachments(savedRecord.id!, widget.result.artifacts);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Record saved with ${widget.result.artifacts.length} attachment(s)',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save record: $e')),
      );
      setState(() => _submitting = false);
    }
  }

  Future<void> _saveAttachments(
    int recordId,
    List<CaptureArtifact> artifacts,
  ) async {
    final state = context.read<RecordsHomeState>();
    final attachments = artifacts.map((artifact) {
      return Attachment()
        ..recordId = recordId
        ..path = artifact.relativePath
        ..kind = _mapArtifactTypeToKind(artifact.type)
        ..mimeType = artifact.mimeType
        ..sizeBytes = artifact.sizeBytes
        ..durationMs = artifact.durationMs
        ..pageCount = artifact.pageCount
        ..capturedAt = artifact.createdAt
        ..source = widget.mode.id
        ..metadataJson =
            artifact.metadata.isNotEmpty ? jsonEncode(artifact.metadata) : null
        ..createdAt = DateTime.now();
    }).toList();

    await state.saveAttachments(attachments);
  }

  String _mapArtifactTypeToKind(CaptureArtifactType type) {
    switch (type) {
      case CaptureArtifactType.photo:
        return 'image';
      case CaptureArtifactType.documentScan:
        return 'pdf';
      case CaptureArtifactType.audio:
        return 'audio';
      case CaptureArtifactType.file:
        return 'file';
      case CaptureArtifactType.email:
        return 'email';
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
    final presenter = CaptureReviewPresenter(
      mode: widget.mode,
      result: widget.result,
    );
    final viewModel = presenter.buildViewModel();
    final artifacts = viewModel.artifacts;
    final dateLabel = DateFormat.yMMMMd().format(_date);

    return Scaffold(
      appBar: AppBar(
        title: Text(viewModel.title),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Record type and date
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
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Editable fields
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
                helperText: 'Edit the suggested summary or add your own notes',
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
            const Divider(height: 32),

            // Captured artifacts (read-only display)
            Text(
              'Captured Artefacts (${artifacts.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...artifacts.map(
              (artifact) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    artifact.kindLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(artifact.pathLabel),
                      if (artifact.hasMetadata) ...[
                        const SizedBox(height: 4),
                        Text(artifact.metadataLabel),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
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
                        : const Text('Save'),
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
