# Design System Documentation

## Overview

The Patient App uses a modern design system inspired by the Figma Mobile Health App Design, featuring gradient colors, rounded corners, and a clean, professional aesthetic.

## Quick Start

### Viewing the Design System

1. **Run the app**: `flutter run`
2. **Navigate to Settings**: Tap the settings icon (⚙️)
3. **View Design Showcase**: Scroll to "Diagnostics" and tap "View Design Showcase"

### Using in Your Code

```dart
import 'package:patient_app/ui/theme/app_colors.dart';
import 'package:patient_app/ui/theme/app_text_styles.dart';
import 'package:patient_app/ui/widgets/common/gradient_header.dart';
import 'package:patient_app/ui/widgets/common/gradient_button.dart';
```

## Color Palette

### Primary Colors
```dart
AppColors.blue    // #3B82F6 - Primary blue
AppColors.purple  // #8B5CF6 - Primary purple  
AppColors.pink    // #EC4899 - Accent pink
```

### Gradients
```dart
AppColors.primaryGradient  // Blue → Purple → Pink
AppColors.buttonGradient   // Blue → Purple
```

### Category Colors
Each health record category has its own color scheme:

| Category   | Light Background | Dark Text | Usage |
|------------|------------------|-----------|-------|
| Checkup    | #DBEAFE         | #1D4ED8   | General visits |
| Dental     | #F3E8FF         | #7C3AED   | Dental records |
| Vision     | #FCE7F3         | #DB2777   | Eye exams |
| Lab        | #D1FAE5         | #059669   | Lab results |
| Medication | #FFEDD5         | #EA580C   | Prescriptions |

### Neutral Colors
```dart
AppColors.gray50   // #F9FAFB - Lightest
AppColors.gray100  // #F3F4F6
AppColors.gray200  // #E5E7EB
AppColors.gray300  // #D1D5DB
AppColors.gray400  // #9CA3AF
AppColors.gray500  // #6B7280
AppColors.gray600  // #4B5563
AppColors.gray700  // #374151
AppColors.gray800  // #1F2937
AppColors.gray900  // #111827 - Darkest
```

## Typography

### Heading Styles
```dart
AppTextStyles.h1  // 24px, medium weight - Page titles
AppTextStyles.h2  // 20px, medium weight - Section headers
AppTextStyles.h3  // 18px, medium weight - Card titles
AppTextStyles.h4  // 16px, medium weight - Subsections
```

### Body Styles
```dart
AppTextStyles.bodyLarge   // 16px - Main content
AppTextStyles.bodyMedium  // 14px - Secondary content
AppTextStyles.bodySmall   // 12px - Captions, hints
```

### Label Styles
```dart
AppTextStyles.labelLarge   // 16px - Button text
AppTextStyles.labelMedium  // 14px - Form labels
AppTextStyles.labelSmall   // 12px - Small labels
```

## Components

### Gradient Header

Modern header with gradient background and rounded bottom corners.

```dart
GradientHeader(
  title: 'My Records',
  subtitle: 'View and manage your health records',
  showBackButton: true,
  actions: [
    IconButton(
      icon: Icon(Icons.add),
      onPressed: () {},
    ),
  ],
)
```

**Features:**
- Gradient background (blue → purple → pink)
- Rounded bottom corners (24px)
- Optional back button with frosted glass effect
- Title and subtitle support
- Custom action buttons
- Safe area support

### Gradient Button

Primary action button with gradient background.

```dart
GradientButton(
  text: 'Save Changes',
  onPressed: () {},
  icon: Icons.save,
  isLoading: false,
)
```

**Features:**
- Blue-to-purple gradient
- Rounded corners (16px)
- Optional icon
- Loading state with spinner
- Disabled state support

### Secondary Button

Outline button for secondary actions.

```dart
GradientButton.secondary(
  text: 'Cancel',
  onPressed: () {},
)
```

### Category Badge

Colored badge for health record categories.

```dart
CategoryBadge(
  category: 'Checkup',
  size: CategoryBadgeSize.medium,
)
```

**Sizes:**
- `small` - Compact badge
- `medium` - Default size
- `large` - Prominent badge

## Layout Patterns

### Spacing System
Use consistent spacing based on 8px grid:

```dart
4px   // Tight spacing (between related items)
8px   // Small spacing (within cards)
12px  // Medium spacing (between sections)
16px  // Large spacing (card padding)
24px  // Extra large (screen padding)
32px  // Section spacing
```

### Border Radius
```dart
8px   // Small elements (badges, chips)
12px  // Medium elements (buttons, inputs)
16px  // Large elements (cards)
20px  // Extra large (special cards)
24px  // Headers, modals
```

### Shadows
```dart
elevation: 2  // Subtle (inputs, chips)
elevation: 4  // Medium (cards, buttons)
elevation: 8  // Prominent (dialogs, menus)
elevation: 16 // Floating (FABs, snackbars)
```

## Common Patterns

### Record Card with 3D Effect

```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border(
      left: BorderSide(
        color: AppColors.getCategoryColor('Checkup'),
        width: 4,
      ),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: Padding(
    padding: EdgeInsets.all(20),
    child: // Your content
  ),
)
```

### Stats Card

```dart
Card(
  elevation: 4,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        Text('24', style: AppTextStyles.h2),
        SizedBox(height: 4),
        Text('Total Records', style: AppTextStyles.bodySmall),
      ],
    ),
  ),
)
```

### Touch Feedback

Add scale animation for premium mobile feel:

```dart
GestureDetector(
  onTapDown: (_) => _controller.forward(),
  onTapUp: (_) => _controller.reverse(),
  onTapCancel: () => _controller.reverse(),
  child: ScaleTransition(
    scale: Tween<double>(begin: 1.0, end: 0.95).animate(_controller),
    child: // Your widget
  ),
)
```

## File Structure

```
lib/ui/
├── theme/
│   ├── app_colors.dart          # Color constants
│   ├── app_text_styles.dart     # Typography
│   └── app_theme.dart           # Theme configuration
├── widgets/
│   └── common/
│       ├── gradient_header.dart
│       ├── gradient_button.dart
│       └── category_badge.dart
└── screens/
    └── design_showcase_screen.dart  # Component showcase
```

## Implementation Status

### ✅ Completed
- Color palette and gradients
- Typography system
- Material Design 3 theme
- Gradient header component
- Gradient button component
- Category badge component
- Design showcase screen
- Modern records UI with 3D effects

### 🎯 Ready to Use
- All components are production-ready
- No breaking changes to existing code
- Compatible with authentication module
- Ready for new screen development

## Design Principles

1. **Consistency** - Use the same spacing, colors, and patterns throughout
2. **Hierarchy** - Use size, weight, and color to establish importance
3. **Feedback** - Provide visual feedback for all interactions
4. **Simplicity** - Keep interfaces clean and uncluttered
5. **Accessibility** - Ensure sufficient contrast and touch targets
6. **Performance** - Optimize animations and gradients

## Accessibility Guidelines

### Color Contrast
- Text on gradient backgrounds: Use white (#FFFFFF)
- Body text: Use gray-900 (#111827)
- Secondary text: Use gray-600 (#4B5563)
- Disabled text: Use gray-400 (#9CA3AF)

### Touch Targets
- Minimum size: 44x44 logical pixels
- Recommended: 48x48 logical pixels
- Spacing between targets: 8px minimum

### Focus States
- Visible outline: 2px solid purple
- Offset: 2px from element
- Border radius: Match element

## Testing Checklist

When implementing new screens:

- [ ] Colors match the design system
- [ ] Spacing follows 8px grid
- [ ] Border radius is consistent
- [ ] Shadows are appropriate
- [ ] Text is readable (contrast check)
- [ ] Touch targets are large enough (44px+)
- [ ] Animations are smooth (60fps)
- [ ] Works on different screen sizes
- [ ] Safe areas respected (notches, etc.)

## Examples

See `lib/features/records/ui/records_home_modern.dart` for a complete example of the design system in action, featuring:
- Gradient header with integrated search
- 3D card effects with colored borders
- Touch animations and ripple effects
- Category badges
- Stats cards
- Proper spacing and shadows

## Support

For questions or issues with the design system:
1. Check the Design Showcase screen for component examples
2. Review this documentation
3. Look at `records_home_modern.dart` for implementation patterns
4. Refer to Figma design files in `Mobile Health App Design/` folder
