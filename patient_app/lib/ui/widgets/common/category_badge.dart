import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// A colored badge for displaying health record categories.
/// 
/// Automatically applies the appropriate color scheme based on the category.
/// 
/// Example:
/// ```dart
/// CategoryBadge(category: 'Checkup')
/// ```
class CategoryBadge extends StatelessWidget {
  /// The category name (e.g., 'Checkup', 'Dental', 'Vision')
  final String category;
  
  /// Optional custom size (default: medium)
  final CategoryBadgeSize size;

  const CategoryBadge({
    Key? key,
    required this.category,
    this.size = CategoryBadgeSize.medium,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.getCategoryColors(category);
    final padding = _getPadding();
    final textStyle = _getTextStyle();

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors['light'],
        borderRadius: BorderRadius.circular(_getBorderRadius()),
      ),
      child: Text(
        category,
        style: textStyle.copyWith(
          color: colors['dark'],
        ),
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case CategoryBadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case CategoryBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case CategoryBadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case CategoryBadgeSize.small:
        return AppTextStyles.bodySmall;
      case CategoryBadgeSize.medium:
        return AppTextStyles.labelSmall;
      case CategoryBadgeSize.large:
        return AppTextStyles.labelMedium;
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case CategoryBadgeSize.small:
        return 8;
      case CategoryBadgeSize.medium:
        return 12;
      case CategoryBadgeSize.large:
        return 16;
    }
  }
}

/// Size variants for category badges
enum CategoryBadgeSize {
  small,
  medium,
  large,
}
