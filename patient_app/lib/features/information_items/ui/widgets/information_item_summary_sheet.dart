import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ai/ai_providers.dart';
import '../../../../core/ai/models/ai_summary_result.dart';
import '../../../../core/domain/entities/information_item.dart';
import '../../../records/domain/entities/record.dart';
import '../../application/use_cases/summarize_information_item_use_case.dart';

/// Bottom sheet that displays AI-generated summaries for an Information Item.
class InformationItemSummarySheet extends ConsumerStatefulWidget {
  const InformationItemSummarySheet({super.key, required this.record});

  final RecordEntity record;

  @override
  ConsumerState<InformationItemSummarySheet> createState() =>
      _InformationItemSummarySheetState();
}

class _InformationItemSummarySheetState
    extends ConsumerState<InformationItemSummarySheet> {
  bool _loading = true;
  AiSummaryResult? _result;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _summarize();
  }

  Future<void> _summarize() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final aiService = ref.read(aiServiceProvider);
      final consentRepo = ref.read(aiConsentRepositoryProvider);
      final useCase = SummarizeInformationItemUseCase(
        aiService: aiService,
        consentRepository: consentRepo,
      );
      final item = widget.record.toItem;
      final result = await useCase.execute(item as InformationItem);
      if (!mounted) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'AI Summary',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Regenerate summary',
                  onPressed: _loading ? null : _summarize,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              _ErrorState(
                error: _error!,
                onRetry: _summarize,
              )
            else if (_result != null)
              _SummaryContent(result: _result!),
          ],
        ),
      ),
    );
  }
}

class _SummaryContent extends StatelessWidget {
  const _SummaryContent({required this.result});

  final AiSummaryResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(result.summaryText, style: theme.textTheme.bodyLarge),
        if (result.actionHints.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Suggested next steps', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...result.actionHints.map((hint) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_outline),
                title: Text(hint),
              )),
        ],
        const SizedBox(height: 16),
        Text(
          'Powered by ${result.provider}. Confidence ${(result.confidence * 100).toStringAsFixed(0)}%.',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Unable to generate a summary right now.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Text(
          error.toString(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      ],
    );
  }
}
