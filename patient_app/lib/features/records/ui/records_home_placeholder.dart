import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../domain/entities/record.dart';
import 'record_detail_screen.dart';
import 'records_home_state.dart';

/// Records list with simple title/notes search and load-more pagination.
class RecordsHomePlaceholder extends StatelessWidget {
  const RecordsHomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const _RecordsHomeBody();
}

class _RecordsHomeBody extends StatefulWidget {
  const _RecordsHomeBody();

  @override
  State<_RecordsHomeBody> createState() => _RecordsHomeBodyState();
}

class _RecordsHomeBodyState extends State<_RecordsHomeBody> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecordsHomeState>().load(force: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch(String query) {
    context.read<RecordsHomeState>().load(query: query, force: true);
  }

  void _clearSearch() {
    _searchController.clear();
    _submitSearch('');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecordsHomeState>(
      builder: (context, state, _) {
        if (_searchController.text != state.searchQuery) {
          _searchController.value = _searchController.value.copyWith(
            text: state.searchQuery,
            selection: TextSelection.collapsed(
              offset: state.searchQuery.length,
            ),
          );
        }

        Widget body;
        if (state.isLoading && !state.hasData && state.error == null) {
          body = const Center(child: CircularProgressIndicator());
        } else if (state.error != null && !state.hasData) {
          body = _ErrorView(
            message: 'Unable to load records.\n${state.error}',
            onRetry: () => state.load(force: true),
          );
        } else {
          body = RefreshIndicator(
            onRefresh: () => state.load(force: true),
            child: _RecordsList(
              records: state.records,
              hasMore: state.hasMore,
              isLoadingMore: state.isLoadingMore,
              onLoadMore: state.loadMore,
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: _submitSearch,
                decoration: InputDecoration(
                  labelText: 'Search records',
                  hintText: 'Search title or notes',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _clearSearch,
                          icon: const Icon(Icons.clear),
                          tooltip: 'Clear search',
                        ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(child: body),
          ],
        );
      },
    );
  }
}

class _RecordsList extends StatelessWidget {
  const _RecordsList({
    required this.records,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  final List<RecordEntity> records;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const _EmptyRecordsList();
    }

    final itemCount = records.length + (hasMore ? 1 : 0);
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      itemCount: itemCount,
      separatorBuilder: (context, index) {
        if (index >= records.length) {
          return const SizedBox.shrink();
        }
        return const Divider(height: 24);
      },
      itemBuilder: (context, index) {
        if (index >= records.length) {
          if (isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: OutlinedButton.icon(
                onPressed: onLoadMore,
                icon: const Icon(Icons.expand_more),
                label: const Text('Load more records'),
              ),
            ),
          );
        }

        final record = records[index];
        return _RecordListTile(record: record);
      },
    );
  }
}

class _RecordListTile extends StatelessWidget {
  const _RecordListTile({required this.record});

  final RecordEntity record;

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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: state,
              child: RecordDetailScreen(recordId: record.id!),
            ),
          ),
        );
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
