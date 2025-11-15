# Figma Design Implementation Guide for Flutter

## Quick Start: Adapting the Design to Flutter

This guide provides concrete code examples for implementing the Figma design patterns in our Flutter patient app.

## 1. Theme Setup

### Create App Colors
```dart
// lib/ui/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary Gradient Colors
  static const gradientBlue = Color(0xFF3B82F6);    // blue-500
  static const gradientPurple = Color(0xFF8B5CF6);  // purple-500
  static const gradientPink = Color(0xFFEC4899);    // pink-500
  
  // Category Colors
  static const checkupLight = Color(0xFFDBEAFE);    // blue-100
  static const checkupDark = Color(0xFF1D4ED8);     // blue-700
  
  static const dentalLight = Color(0xFFF3E8FF);     // purple-100
  static const dentalDark = Color(0xFF7C3AED);      // purple-700
  
  static const visionLight = Color(0xFFFCE7F3);     // pink-100
  static const visionDark = Color(0xFFDB2777);      // pink-700
  
  static const labLight = Color(0xFFD1FAE5);        // green-100
  static const labDark = Color(0xFF059669);         // green-700
  
  static const medicationLight = Color(0xFFFFEDD5); // orange-100
  static const medicationDark = Color(0xFFEA580C);  // orange-700
  
  // Neutral Colors
  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray300 = Color(0xFFD1D5DB);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF6B7280);
  static const gray600 = Color(0xFF4B5563);
  static const gray700 = Color(0xFF374151);
  static const gray800 = Color(0xFF1F2937);
  static const gray900 = Color(0xFF111827);
  
  // Semantic Colors
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const error = Color(0xFFEF4444);
  static const success = Color(0xFF10B981);
  
  // Gradients
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientBlue, gradientPurple, gradientPink],
  );
  
  static const buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [gradientBlue, gradientPurple],
  );
}
```

### Create Text Styles
```dart
// lib/ui/theme/app_text_styles.dart
import 'package:flutter/material.dart';

class AppTextStyles {
  static const String fontFamily = 'Inter'; // or your preferred font
  
  // Headings
  static const h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: -0.5,
  );
  
  static const h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: -0.3,
  );
  
  static const h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
  
  static const h4 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
  
  // Body Text
  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  
  // Labels
  static const labelLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
  
  static const labelMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
  
  static const labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
}
```

### Create App Theme
```dart
// lib/ui/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextStyles.fontFamily,
      
      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: AppColors.gradientPurple,
        secondary: AppColors.gradientBlue,
        surface: AppColors.white,
        background: AppColors.gray50,
        error: AppColors.error,
      ),
      
      // Scaffold
      scaffoldBackgroundColor: AppColors.gray50,
      
      // App Bar
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.white,
      ),
      
      // Card
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: AppColors.white,
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.gradientPurple,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      
      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.labelMedium,
        ),
      ),
    );
  }
}
```

## 2. Core Components

### Gradient Header
```dart
// lib/ui/widgets/common/gradient_header.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class GradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Widget? child;
  final double bottomPadding;
  
  const GradientHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.onBackPressed,
    this.actions,
    this.child,
    this.bottomPadding = 32,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  if (onBackPressed != null)
                    _BackButton(onPressed: onBackPressed!),
                  if (onBackPressed != null) const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
              // Optional Child Content
              if (child != null) ...[
                const SizedBox(height: 24),
                child!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

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
```

### Record Card
```dart
// lib/ui/widgets/cards/record_card.dart
import 'package:flutter/material.dart';
import '../../../features/records/domain/entities/health_record.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class RecordCard extends StatelessWidget {
  final HealthRecord record;
  final VoidCallback onTap;
  
  const RecordCard({
    Key? key,
    required this.record,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(
                color: _getCategoryColor(record.category),
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Category
              Row(
                children: [
                  Expanded(
                    child: Text(
                      record.title,
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.gray900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _CategoryBadge(category: record.category),
                ],
              ),
              const SizedBox(height: 12),
              
              // Date
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.gray500,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(record.date),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Description Preview
              Text(
                record.description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.gray600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Attachments
              if (record.attachments.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                _AttachmentChips(attachments: record.attachments),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'checkup':
        return AppColors.checkupDark;
      case 'dental':
        return AppColors.dentalDark;
      case 'vision':
        return AppColors.visionDark;
      case 'lab':
        return AppColors.labDark;
      case 'medication':
        return AppColors.medicationDark;
      default:
        return AppColors.gray500;
    }
  }
  
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  
  const _CategoryBadge({required this.category});
  
  @override
  Widget build(BuildContext context) {
    final colors = _getCategoryColors(category);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors['light'],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category,
        style: AppTextStyles.labelSmall.copyWith(
          color: colors['dark'],
        ),
      ),
    );
  }
  
  Map<String, Color> _getCategoryColors(String category) {
    switch (category.toLowerCase()) {
      case 'checkup':
        return {'light': AppColors.checkupLight, 'dark': AppColors.checkupDark};
      case 'dental':
        return {'light': AppColors.dentalLight, 'dark': AppColors.dentalDark};
      case 'vision':
        return {'light': AppColors.visionLight, 'dark': AppColors.visionDark};
      case 'lab':
        return {'light': AppColors.labLight, 'dark': AppColors.labDark};
      case 'medication':
        return {'light': AppColors.medicationLight, 'dark': AppColors.medicationDark};
      default:
        return {'light': AppColors.gray100, 'dark': AppColors.gray700};
    }
  }
}

class _AttachmentChips extends StatelessWidget {
  final List<Attachment> attachments;
  
  const _AttachmentChips({required this.attachments});
  
  @override
  Widget build(BuildContext context) {
    final displayAttachments = attachments.take(3).toList();
    final remainingCount = attachments.length - 3;
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...displayAttachments.map((attachment) => _AttachmentChip(
          attachment: attachment,
        )),
        if (remainingCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+$remainingCount more',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.gray500,
              ),
            ),
          ),
      ],
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  final Attachment attachment;
  
  const _AttachmentChip({required this.attachment});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getAttachmentIcon(attachment.type),
            size: 12,
            color: AppColors.gray600,
          ),
          const SizedBox(width: 4),
          Text(
            attachment.name.length > 15
                ? '${attachment.name.substring(0, 12)}...'
                : attachment.name,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.gray600,
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getAttachmentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'photo':
        return Icons.image;
      case 'scan':
        return Icons.description;
      case 'voice':
        return Icons.mic;
      case 'file':
        return Icons.attach_file;
      default:
        return Icons.insert_drive_file;
    }
  }
}
```

### Stats Card
```dart
// lib/ui/widgets/cards/stats_card.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class StatsCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  
  const StatsCard({
    Key? key,
    required this.value,
    required this.label,
    required this.color,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTextStyles.h2.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.gray600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Gradient Button
```dart
// lib/ui/widgets/common/gradient_button.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;
  
  const GradientButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.buttonGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientPurple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.white,
                      ),
                    ),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(icon, color: AppColors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### Bottom Navigation Bar
```dart
// lib/ui/widgets/navigation/custom_bottom_nav_bar.dart
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  
  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Records',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.add_circle_rounded,
                label: 'Add',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive ? AppColors.primaryGradient : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.white : AppColors.gray400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isActive ? AppColors.white : AppColors.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 3. Usage Examples

### Records List Screen
```dart
// lib/ui/screens/records/records_list_screen.dart
import 'package:flutter/material.dart';
import '../../widgets/common/gradient_header.dart';
import '../../widgets/cards/record_card.dart';
import '../../widgets/cards/stats_card.dart';
import '../../theme/app_colors.dart';

class RecordsListScreen extends StatelessWidget {
  const RecordsListScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            title: 'My Health Records',
            subtitle: 'Manage your personal health data',
            bottomPadding: 32,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search records...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {},
                ),
              ),
            ),
          ),
          
          // Stats Cards
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: const [
                Expanded(
                  child: StatsCard(
                    value: '12',
                    label: 'Total Records',
                    color: AppColors.gradientBlue,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: StatsCard(
                    value: '24',
                    label: 'Attachments',
                    color: AppColors.gradientPurple,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: StatsCard(
                    value: '5',
                    label: 'Categories',
                    color: AppColors.gradientPink,
                  ),
                ),
              ],
            ),
          ),
          
          // Records List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: 10, // Replace with actual data
              itemBuilder: (context, index) {
                return RecordCard(
                  record: /* your record */,
                  onTap: () {
                    // Navigate to detail
                  },
                );
              },
            ),
          ),
        ],
      ),
      
      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
        backgroundColor: AppColors.gradientPurple,
      ),
    );
  }
}
```

## 4. Animation Examples

### Staggered List Animation
```dart
import 'package:flutter/material.dart';

class StaggeredListView extends StatelessWidget {
  final List<Widget> children;
  
  const StaggeredListView({Key? key, required this.children}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: children.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 100)),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: children[index],
        );
      },
    );
  }
}
```

## Next Steps

1. **Install Dependencies**: Add required packages to `pubspec.yaml`
2. **Create Theme Files**: Implement the color and text style files
3. **Build Components**: Create the reusable widget library
4. **Update Screens**: Refactor existing screens to use new components
5. **Add Animations**: Implement smooth transitions and micro-interactions
6. **Test on Devices**: Verify design on different screen sizes

## Resources

- Flutter Animation Documentation: https://flutter.dev/docs/development/ui/animations
- Material Design 3: https://m3.material.io/
- Figma Design Reference: `Mobile Health App Design/` folder
