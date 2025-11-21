import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/diagnostics/app_logger.dart';
import '../model/attachment.dart';
import '../model/record_types.dart';
import '../domain/entities/record.dart';
import 'add_record_screen.dart';
import 'records_home_state.dart';
import '../../spaces/providers/space_provider.dart';

/// Temporary detail screen that shows the core fields for the selected record.
/// This keeps navigation wiring incremental while the full detail design is
/// still in progress (see M2 plan).
class RecordDetailScreen extends StatefulWidget {
  const RecordDetailScreen({super.key, required this.recordId});

  final int recordId;

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
  RecordEntity? _record;
  List<Attachment>? _attachments;
  bool _loadingAttachments = false;

  @override
  void initState() {
    super.initState();
    AppLogger.info('RecordDetailScreen initialized', context: {
      'recordId': widget.recordId,
    });
    final state = context.read<RecordsHomeState>();
    _record = state.recordById(widget.recordId);
    _loadAttachments();
  }

  Future<void> _loadAttachments() async {
    final opId = AppLogger.startOperation('load_attachments');
    setState(() => _loadingAttachments = true);
    try {
      final state = context.read<RecordsHomeState>();
      final attachments =
          await state.getAttachmentsByRecordId(widget.recordId);
      if (mounted) {
        setState(() {
          _attachments = attachments;
          _loadingAttachments = false;
        });
      }
      AppLogger.info('Attachments loaded', context: {
        'recordId': widget.recordId,
        'count': attachments.length,
      });
      AppLogger.endOperation(opId);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to load attachments', 
        error: e, 
        stackTrace: stackTrace,
        context: {'recordId': widget.recordId}
      );
      AppLogger.endOperation(opId);
      if (mounted) {
        setState(() => _loadingAttachments = false);
      }
    }
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
            if (_loadingAttachments)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_attachments == null || _attachments!.isEmpty)
              Card(
                color: containerColor,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No attachments for this record.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              )
            else
              ..._attachments!.map(
                (attachment) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(
                      _getIconForKind(attachment.kind),
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(_getAttachmentTitle(attachment)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_formatFileSize(attachment.sizeBytes)),
                        if (attachment.capturedAt != null)
                          Text(
                            'Captured: ${dateTimeFormatter.format(attachment.capturedAt!)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        if (attachment.durationMs != null)
                          Text(
                            'Duration: ${_formatDuration(attachment.durationMs!)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        if (attachment.pageCount != null)
                          Text(
                            'Pages: ${attachment.pageCount}',
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Open attachment viewer
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Attachment viewer coming soon'),
                        ),
                      );
                    },
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

  IconData _getIconForKind(String kind) {
    switch (kind.toLowerCase()) {
      case 'image':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'audio':
        return Icons.audiotrack;
      case 'file':
        return Icons.insert_drive_file;
      case 'email':
        return Icons.email;
      default:
        return Icons.attach_file;
    }
  }

  String _getAttachmentTitle(Attachment attachment) {
    final fileName = attachment.path.split('/').last;
    return fileName;
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return 'Unknown size';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDuration(int milliseconds) {
    final seconds = milliseconds ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    }
    return '${seconds}s';
  }

  Future<void> _editRecord(BuildContext context, RecordEntity record) async {
    AppLogger.logNavigation('RecordDetailScreen', 'AddRecordScreen', context: {
      'action': 'edit',
      'recordId': record.id,
    });
    
    final spaceProvider = context.read<SpaceProvider>();
    final state = context.read<RecordsHomeState>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: state),
            ChangeNotifierProvider.value(value: spaceProvider),
          ],
          child: AddRecordScreen(existing: record),
        ),
      ),
    );
    await _refreshRecord();
    AppLogger.info('Returned from edit screen', context: {
      'recordId': record.id,
    });
  }

  Future<void> _confirmDelete(BuildContext context, RecordEntity record) async {
    AppLogger.info('Delete confirmation dialog opened', context: {
      'recordId': record.id,
    });
    
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
    
    if (!confirmed) {
      AppLogger.info('Delete cancelled by user', context: {
        'recordId': record.id,
      });
      return;
    }

    final opId = AppLogger.startOperation('delete_record');
    try {
      await context.read<RecordsHomeState>().deleteRecord(record.id!);
      AppLogger.info('Record deleted successfully', context: {
        'recordId': record.id,
      });
      AppLogger.endOperation(opId);
      
      if (!context.mounted) return;
      Navigator.of(context).pop();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete record', 
        error: e, 
        stackTrace: stackTrace,
        context: {'recordId': record.id}
      );
      AppLogger.endOperation(opId);
      
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
