import 'package:flutter/material.dart';
import '../../../../core/domain/entities/space.dart';
import '../../../../ui/theme/app_colors.dart';
import '../../../../ui/theme/app_text_styles.dart';
import 'space_icon.dart';

/// A card widget that displays a space with its icon, name, and description.
/// 
/// Supports three visual states:
/// - Default: White background with gray border
/// - Selected: Space gradient background with shadow
/// - Current: Shows "Current" badge
/// 
/// Example:
/// ```dart
/// SpaceCard(
///   space: healthSpace,
///   isSelected: true,
///   isCurrent: false,
///   onTap: () => selectSpace(healthSpace),
/// )
/// ```
class SpaceCard extends StatelessWidget {
  /// The space to display
  final Space space;
  
  /// Whether this space is selected (active)
  final bool isSelected;
  
  /// Whether this is the currently active space
  final bool isCurrent;
  
  /// Callback when the card is tapped
  final VoidCallback onTap;

  const SpaceCard({
    Key? key,
    required this.space,
    required this.isSelected,
    required this.isCurrent,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    try {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isSelected ? space.gradient.toLinearGradient() : null,
            color: isSelected ? null : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.transparent : AppColors.gray300,
              width: 2,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: space.gradient.startColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
        child: Row(
          children: [
            // Space icon
            SpaceIcon(
              iconName: space.icon,
              gradient: space.gradient,
              size: 48,
              isSelected: isSelected,
            ),
            const SizedBox(width: 16),
            // Space name and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          space.name,
                          style: AppTextStyles.h3.copyWith(
                            color: isSelected ? AppColors.white : AppColors.gray900,
                          ),
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.white.withOpacity(0.3)
                                : AppColors.gradientPurple,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Current',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    space.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected
                          ? AppColors.white.withOpacity(0.9)
                          : AppColors.gray600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Checkmark for selected state
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.white,
                size: 24,
              ),
          ],
        ),
      ),
    );
    } catch (e, stackTrace) {
      // Fallback UI if card fails to render
      debugPrint('Error building SpaceCard for ${space.id}: $e');
      debugPrint('Stack trace: $stackTrace');
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Error loading ${space.name}',
          style: TextStyle(color: AppColors.gray600),
        ),
      );
    }
  }
}
