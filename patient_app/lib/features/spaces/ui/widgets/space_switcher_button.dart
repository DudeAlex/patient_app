import 'package:flutter/material.dart';
import '../../../../ui/theme/app_colors.dart';

/// A frosted glass button that displays a grid icon for switching between spaces.
/// 
/// This button should only be shown when the user has multiple active spaces.
/// When tapped, it navigates to the space selector screen.
/// 
/// Designed to be used in the app bar or gradient header actions.
/// 
/// Example:
/// ```dart
/// GradientHeader(
///   title: 'Health',
///   actions: [
///     SpaceSwitcherButton(
///       onPressed: () => Navigator.pushNamed(context, '/space-selector'),
///     ),
///   ],
/// )
/// ```
class SpaceSwitcherButton extends StatelessWidget {
  /// Callback when the button is pressed
  final VoidCallback onPressed;
  
  /// Optional tooltip text (defaults to "Switch Space")
  final String? tooltip;

  const SpaceSwitcherButton({
    Key? key,
    required this.onPressed,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: IconButton(
        icon: const Icon(Icons.grid_view, size: 20),
        color: AppColors.white,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        tooltip: '', // Empty to prevent default tooltip
      ),
    );

    // Wrap with Tooltip if tooltip text is provided
    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    // Default tooltip
    return Tooltip(
      message: 'Switch Space',
      child: button,
    );
  }
}
