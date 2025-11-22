import 'package:flutter/material.dart';

/// Shows a dialog describing how AI assistance uses Information Item data.
Future<bool> showAiConsentDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => const _AiConsentDialog(),
  );
  return result ?? false;
}

class _AiConsentDialog extends StatelessWidget {
  const _AiConsentDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enable AI Assistance?'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'AI can summarize your Information Items with a compassionate tone. '
              'To do that, the following fields are sent securely when you request a summary:',
            ),
            SizedBox(height: 12),
            _Bullet(text: 'Space name and category'),
            _Bullet(text: 'Title or subject'),
            _Bullet(text: 'Tags and labels'),
            _Bullet(text: 'Notes / body text'),
            _Bullet(text: 'Attachment descriptors (type + filename only)'),
            SizedBox(height: 12),
            Text(
              'What stays on your device:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            _Bullet(text: 'Record IDs and internal identifiers'),
            _Bullet(text: 'Attachment files (photos, PDFs, audio)'),
            _Bullet(text: 'Secure encryption keys and account info'),
            SizedBox(height: 12),
            Text(
              'You can turn AI off anytime in Settings. Summaries are suggestions—'
              'always verify important details before taking action.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Enable AI'),
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
