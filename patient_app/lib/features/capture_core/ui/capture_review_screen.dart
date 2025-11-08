import 'package:flutter/material.dart';

import '../adapters/presenters/capture_review_presenter.dart';
import '../api/capture_mode.dart';
import '../api/capture_result.dart';

class CaptureReviewScreen extends StatelessWidget {
  const CaptureReviewScreen({
    super.key,
    required this.mode,
    required this.result,
  });

  final CaptureMode mode;
  final CaptureResult result;

  @override
  Widget build(BuildContext context) {
    final presenter = CaptureReviewPresenter(mode: mode, result: result);
    final viewModel = presenter.buildViewModel();
    final artifacts = viewModel.artifacts;
    return Scaffold(
      appBar: AppBar(
        title: Text(viewModel.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (viewModel.hasDraft) ...[
            Text(
              'Suggested Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _ReadOnlyField(
              label: 'Details',
              value: viewModel.details,
            ),
            const SizedBox(height: 8),
            _ReadOnlyField(
              label: 'Tags',
              value: viewModel.tagsDescription,
            ),
            const Divider(height: 32),
          ],
          Text(
            'Captured Artefacts (${artifacts.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...artifacts.map((artifact) => Card(
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
              )),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Saving from review coming soon.'),
                ),
              );
            },
            child: const Text('Save (coming soon)'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      maxLines: null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
    );
  }
}
