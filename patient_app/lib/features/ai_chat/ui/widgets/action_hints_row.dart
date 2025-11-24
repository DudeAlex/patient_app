import 'package:flutter/material.dart';

/// Displays AI action hints as tappable chips.
class ActionHintsRow extends StatelessWidget {
  const ActionHintsRow({
    super.key,
    required this.hints,
    this.onHintTapped,
  });

  /// List of hint labels to render as chips.
  final List<String> hints;

  /// Called when a chip is tapped, passing the hint text.
  final ValueChanged<String>? onHintTapped;

  @override
  Widget build(BuildContext context) {
    if (hints.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: hints
          .map(
            (hint) => ActionChip(
              label: Text(hint),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: colors.secondaryContainer,
              labelStyle: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: colors.onSecondaryContainer),
              onPressed: onHintTapped != null ? () => onHintTapped!(hint) : null,
            ),
          )
          .toList(),
    );
  }
}
