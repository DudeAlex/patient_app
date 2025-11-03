import 'package:flutter/material.dart';

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
    final draft = result.draft;
    final artifacts = result.artifacts;
    return Scaffold(
      appBar: AppBar(
        title: Text('Review ${mode.displayName}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (draft != null) ...[
            Text(
              'Suggested Summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _ReadOnlyField(
              label: 'Details',
              value: draft.suggestedDetails ?? 'No details suggested yet.',
            ),
            const SizedBox(height: 8),
            _ReadOnlyField(
              label: 'Tags',
              value: draft.suggestedTags.isEmpty
                  ? 'No tags suggested yet.'
                  : draft.suggestedTags.join(', '),
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
                    artifact.type.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Stored at: ${artifact.relativePath}'),
                      if (artifact.metadata.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Metadata: ${artifact.metadata}'),
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
