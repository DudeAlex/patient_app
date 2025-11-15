import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// A gradient header component with optional back button, title, subtitle, and actions.
/// 
/// This component provides a consistent header design across the app with
/// a gradient background and rounded bottom corners.
/// 
/// Example:
/// ```dart
/// GradientHeader(
///   title: 'My Health Records',
///   subtitle: 'Manage your personal health data',
///   onBackPressed: () => Navigator.pop(context),
///   actions: [
///     IconButton(
///       icon: Icon(Icons.settings),
///       onPressed: () {},
///     ),
///   ],
///   child: SearchBar(...),
/// )
/// ```
class GradientHeader extends StatelessWidget {
  /// The main title text displayed in the header
  final String title;
  
  /// Optional subtitle text displayed below the title
  final String? subtitle;
  
  /// Callback when the back button is pressed (if null, no back button shown)
  final VoidCallback? onBackPressed;
  
  /// Optional action widgets displayed in the top-right corner
  final List<Widget>? actions;
  
  /// Optional child widget displayed below the title/subtitle
  final Widget? child;
  
  /// Bottom padding of the header (default: 32)
  final double bottomPadding;
  
  /// Whether to apply safe area padding at the top
  final bool useSafeArea;

  const GradientHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.onBackPressed,
    this.actions,
    this.child,
    this.bottomPadding = 32,
    this.useSafeArea = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row with back button, title, and actions
          Row(
            children: [
              if (onBackPressed != null) ...[
                _BackButton(onPressed: onBackPressed!),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.h1.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
          // Optional child content
          if (child != null) ...[
            const SizedBox(height: 24),
            child!,
          ],
        ],
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: useSafeArea
          ? SafeArea(
              bottom: false,
              child: content,
            )
          : content,
    );
  }
}

/// Frosted glass back button used in the gradient header
class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back, size: 20),
        color: AppColors.white,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

/// Frosted glass action button for use in gradient header
class GradientHeaderActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const GradientHeaderActionButton({
    Key? key,
    required this.icon,
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
        icon: Icon(icon, size: 20),
        color: AppColors.white,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}
