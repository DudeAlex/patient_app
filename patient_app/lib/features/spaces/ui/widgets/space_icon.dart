import 'package:flutter/material.dart';
import '../../../../core/domain/value_objects/space_gradient.dart';
import '../../../../ui/theme/app_colors.dart';

/// A widget that displays a space icon with optional gradient background.
/// 
/// Maps icon names (like 'Heart', 'GraduationCap') to Material Icons.
/// Supports gradient background for selected state and white background for default state.
/// 
/// Example:
/// ```dart
/// SpaceIcon(
///   iconName: 'Heart',
///   gradient: healthGradient,
///   size: 48,
///   isSelected: true,
/// )
/// ```
class SpaceIcon extends StatelessWidget {
  /// The name of the icon (e.g., 'Heart', 'GraduationCap')
  final String iconName;
  
  /// The gradient to use for the background
  final SpaceGradient gradient;
  
  /// The size of the icon container
  final double size;
  
  /// Whether the icon is in selected state (affects background)
  final bool isSelected;

  const SpaceIcon({
    Key? key,
    required this.iconName,
    required this.gradient,
    this.size = 48,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconData = _getIconData(iconName);
    final iconSize = size * 0.5; // Icon is 50% of container size

    // PERFORMANCE: Use solid color instead of gradient for better performance on low-end devices
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // Use solid color from gradient start instead of full gradient
        color: isSelected 
            ? AppColors.white.withOpacity(0.2) 
            : gradient.startColor,
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Icon(
        iconData,
        size: iconSize,
        color: AppColors.white,
      ),
    );
  }

  /// Maps icon names to Material Icons
  /// 
  /// Supports common icon names used in the space system.
  /// Falls back to Icons.circle if icon name is not recognized.
  IconData _getIconData(String name) {
    switch (name.toLowerCase()) {
      // Health
      case 'heart':
        return Icons.favorite;
      case 'health':
        return Icons.health_and_safety;
      
      // Education
      case 'graduationcap':
      case 'graduation_cap':
      case 'education':
        return Icons.school;
      case 'book':
        return Icons.menu_book;
      
      // Home & Life
      case 'home':
        return Icons.home;
      case 'house':
        return Icons.house;
      case 'coffee':
        return Icons.coffee;
      
      // Business
      case 'briefcase':
        return Icons.work;
      case 'business':
        return Icons.business;
      case 'building':
        return Icons.business_center;
      
      // Finance
      case 'dollarsign':
      case 'dollar_sign':
      case 'money':
        return Icons.attach_money;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'piggybank':
      case 'piggy_bank':
        return Icons.savings;
      
      // Travel
      case 'plane':
      case 'airplane':
        return Icons.flight;
      case 'map':
        return Icons.map;
      case 'compass':
        return Icons.explore;
      case 'luggage':
        return Icons.luggage;
      
      // Family
      case 'users':
      case 'people':
        return Icons.people;
      case 'family':
        return Icons.family_restroom;
      case 'user':
      case 'person':
        return Icons.person;
      
      // Creative
      case 'palette':
        return Icons.palette;
      case 'brush':
        return Icons.brush;
      case 'camera':
        return Icons.camera_alt;
      case 'music':
        return Icons.music_note;
      case 'pen':
      case 'edit':
        return Icons.edit;
      
      // Generic
      case 'star':
        return Icons.star;
      case 'sparkles':
        return Icons.auto_awesome;
      case 'circle':
        return Icons.circle;
      case 'square':
        return Icons.square;
      
      // Default fallback
      default:
        return Icons.circle;
    }
  }
}
