import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_text_styles.dart';
import '../../../ui/widgets/common/gradient_header.dart';
import '../domain/entities/record.dart';
import 'record_detail_screen.dart';
import 'records_home_state.dart';

/// Modern redesigned records list with gradient header and card-based layout.
/// 
/// This is an alternative to RecordsHomePlaceholder with a more modern,
/// visually appealing design using the new design system.
class RecordsHomeModern extends StatelessWidget {
  const RecordsHomeModern({super.key});

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
  
  int _countTags(List<RecordEntity> records) {
    final allTags = <String>{};
    for (final record in records) {
      allTags.addAll(record.tags);
    }
    return allTags.length;
  }
  
  int _countTypes(List<RecordEntity> records) {
    return records.map((r) => r.type).toSet().length;
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
            // Modern gradient header with search
            GradientHeader(
              title: 'My Health Records',
              subtitle: 'Manage your personal health data',
              bottomPadding: 32,
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onSubmitted: _submitSearch,
                style: const TextStyle(color: AppColors.gray900),
                decoration: InputDecoration(
                  hintText: 'Search records...',
                  hintStyle: TextStyle(color: AppColors.gray400),
                  prefixIcon: const Icon(Icons.search, color: AppColors.gray400),
                  suffixIcon: _searchController.text.isEmpty
                      ? IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.filter_list, color: AppColors.gray400),
                          tooltip: 'Filter',
                        )
                      : IconButton(
                          onPressed: _clearSearch,
                          icon: const Icon(Icons.clear, color: AppColors.gray400),
                          tooltip: 'Clear search',
                        ),
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            
            // Stats Cards
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Transform.translate(
                offset: const Offset(0, -16),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatsCard(
                        value: '${state.records.length}',
                        label: 'Total Records',
                        color: AppColors.gradientBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatsCard(
                        value: '${_countTags(state.records)}',
                        label: 'Tags',
                        color: AppColors.gradientPurple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatsCard(
                        value: '${_countTypes(state.records)}',
                        label: 'Categories',
                        color: AppColors.gradientTeal,
                      ),
                    ),
                  ],
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

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: AppTextStyles.h2.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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

    final itemCount = records.length + 1 + (hasMore ? 1 : 0); // +1 for header
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Section header
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Recent Records',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.gray900,
              ),
            ),
          );
        }
        
        final recordIndex = index - 1;
        if (recordIndex >= records.length) {
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
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          );
        }

        final record = records[recordIndex];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _ModernRecordCard(record: record),
        );
      },
    );
  }
}

class _ModernRecordCard extends StatefulWidget {
  const _ModernRecordCard({required this.record});

  final RecordEntity record;

  @override
  State<_ModernRecordCard> createState() => _ModernRecordCardState();
}

class _ModernRecordCardState extends State<_ModernRecordCard> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final typeInfo = _getTypeInfo(widget.record.type);
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: typeInfo['color'] as Color,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: (typeInfo['color'] as Color).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: AppColors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final state = context.read<RecordsHomeState>();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: state,
                    child: RecordDetailScreen(recordId: widget.record.id!),
                  ),
                ),
              );
            },
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            borderRadius: BorderRadius.circular(16),
            splashColor: (typeInfo['color'] as Color).withOpacity(0.1),
            highlightColor: (typeInfo['color'] as Color).withOpacity(0.05),
            child: Padding(
            padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Type Badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.record.title,
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.gray900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (typeInfo['lightColor'] as Color),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      typeInfo['label'] as String,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: typeInfo['color'] as Color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.gray500,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(widget.record.date),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
              
              // Text preview if available
              if (widget.record.text != null && widget.record.text!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  widget.record.text!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.gray600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              // Tags indicator
              if (widget.record.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.record.tags.take(3).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getTypeInfo(String type) {
    switch (type) {
      case 'visit':
        return {
          'label': 'Visit',
          'color': AppColors.checkupDark,
          'lightColor': AppColors.checkupLight,
        };
      case 'lab':
        return {
          'label': 'Lab',
          'color': AppColors.labDark,
          'lightColor': AppColors.labLight,
        };
      case 'med':
        return {
          'label': 'Medication',
          'color': AppColors.medicationDark,
          'lightColor': AppColors.medicationLight,
        };
      case 'note':
        return {
          'label': 'Note',
          'color': AppColors.visionDark,
          'lightColor': AppColors.visionLight,
        };
      default:
        return {
          'label': type,
          'color': AppColors.gray700,
          'lightColor': AppColors.gray100,
        };
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(40),
          ),
          child: const Icon(
            Icons.folder_open,
            size: 40,
            color: AppColors.gray400,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'No records yet',
          style: AppTextStyles.h2.copyWith(
            color: AppColors.gray900,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Use the Add Record button to get started',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.gray600,
          ),
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.gray700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
