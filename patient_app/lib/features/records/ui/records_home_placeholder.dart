import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../model/record.dart';
import '../repo/records_repo.dart';
import 'record_detail_screen.dart';
import 'records_home_state.dart';

/// Temporary widget that will evolve into the records home list. For now it
/// simply fetches recent records and shows an empty-state placeholder.
class RecordsHomePlaceholder extends StatelessWidget {
  const RecordsHomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const _RecordsHomeBody();
}

class _RecordsHomeBody extends StatelessWidget {
  const _RecordsHomeBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<RecordsHomeState>(
      builder: (context, state, _) {
        if (state.isLoading && !state.hasData && state.error == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Unable to load records.\n${state.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => state.load(force: true),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => state.load(force: true),
          child: state.hasData
              ? _RecordsList(
                  records: state.records,
                  repository: state.repository,
                )
              : const _EmptyRecordsList(),
        );
      },
    );
  }
}

class _RecordListTile extends StatelessWidget {
  const _RecordListTile({required this.record, required this.repository});

  final Record record;
  final RecordsRepository repository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle =
        '${_formatType(record.type)} - ${_formatDate(record.date)}';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Text(record.title, style: theme.textTheme.titleMedium),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        final state = context.read<RecordsHomeState>();
        Navigator.of(context)
            .push<bool>(
              MaterialPageRoute(
                builder: (_) =>
                    RecordDetailScreen(record: record, repository: repository),
              ),
            )
            .then((wasDeleted) {
              if (wasDeleted == true) {
                state.load(force: true);
              }
            });
      },
    );
  }

  String _formatType(String type) {
    switch (type) {
      case 'visit':
        return 'Visit';
      case 'lab':
        return 'Lab';
      case 'med':
        return 'Medication';
      case 'note':
        return 'Note';
      default:
        return type;
    }
  }

  String _formatDate(DateTime date) => DateFormat.yMMMd().format(date);
}

class _RecordsList extends StatelessWidget {
  const _RecordsList({required this.records, required this.repository});

  final List<Record> records;
  final RecordsRepository repository;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      itemCount: records.length,
      separatorBuilder: (context, _) => const Divider(height: 24),
      itemBuilder: (context, index) {
        final record = records[index];
        return _RecordListTile(record: record, repository: repository);
      },
    );
  }
}

class _EmptyRecordsList extends StatelessWidget {
  const _EmptyRecordsList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 80),
      children: const [
        Icon(Icons.folder_open, size: 48, color: Colors.grey),
        SizedBox(height: 12),
        Text(
          'No records yet.\nUse the Add Record flow to get started.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
