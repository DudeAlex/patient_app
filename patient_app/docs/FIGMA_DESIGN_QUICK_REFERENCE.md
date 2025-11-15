# Figma Design Quick Reference

## Color Palette Cheat Sheet

### Primary Colors
```
Blue:    #3B82F6  (rgb(59, 130, 246))
Purple:  #8B5CF6  (rgb(139, 92, 246))
Pink:    #EC4899  (rgb(236, 72, 153))
```

### Category Colors
| Category   | Light Background | Dark Text |
|------------|------------------|-----------|
| Checkup    | #DBEAFE         | #1D4ED8   |
| Dental     | #F3E8FF         | #7C3AED   |
| Vision     | #FCE7F3         | #DB2777   |
| Lab        | #D1FAE5         | #059669   |
| Medication | #FFEDD5         | #EA580C   |

## Spacing System

```
xs:  4px   (0.25rem)
sm:  8px   (0.5rem)
md:  12px  (0.75rem)
lg:  16px  (1rem)
xl:  24px  (1.5rem)
2xl: 32px  (2rem)
3xl: 48px  (3rem)
```

## Border Radius

```
sm:  8px   (small chips, badges)
md:  12px  (buttons, inputs)
lg:  16px  (cards, containers)
xl:  20px  (large cards)
2xl: 24px  (headers, modals)
3xl: 32px  (special containers)
full: 50%  (circular buttons)
```

## Typography Scale

```
h1:    24px / 500 weight / -0.5 letter-spacing
h2:    20px / 500 weight / -0.3 letter-spacing
h3:    18px / 500 weight
h4:    16px / 500 weight
body:  16px / 400 weight
small: 14px / 400 weight
tiny:  12px / 400 weight
```

## Shadow Levels

```
sm:  0 1px 2px rgba(0,0,0,0.05)
md:  0 4px 6px rgba(0,0,0,0.1)
lg:  0 10px 15px rgba(0,0,0,0.1)
xl:  0 20px 25px rgba(0,0,0,0.1)
2xl: 0 25px 50px rgba(0,0,0,0.15)
```

## Component Patterns

### Card Structure
```
- White background
- 16px border radius
- md shadow (4px blur)
- 20px padding
- 4px colored left border (for records)
```

### Button Structure
```
Primary:
- Gradient background (blue → purple)
- 16px border radius
- 16px vertical padding
- 24px horizontal padding
- White text
- md shadow

Secondary:
- White background
- Gray border
- Same padding as primary
```

### Input Structure
```
- White background
- 16px border radius
- 16px padding
- No border (or subtle gray)
- Focus: 2px purple border
```

### Header Structure
```
- Gradient background (blue → purple → pink)
- 24px bottom border radius
- 24px horizontal padding
- 16px top padding
- 32px bottom padding (default)
- White text
```

## Icon Sizes

```
Small:  16px (inline with text)
Medium: 20px (buttons)
Large:  24px (navigation)
XLarge: 32px (feature icons)
Hero:   48px+ (onboarding)
```

## Animation Timings

```
Fast:   150ms (hover states)
Normal: 200ms (transitions)
Slow:   300ms (page transitions)
Stagger: +100ms per item (list animations)
```

## Common Gradients

### Primary Gradient (Headers, Backgrounds)
```css
linear-gradient(135deg, #3B82F6 0%, #8B5CF6 50%, #EC4899 100%)
```

### Button Gradient
```css
linear-gradient(90deg, #3B82F6 0%, #8B5CF6 100%)
```

### Subtle Background
```css
linear-gradient(135deg, #F9FAFB 0%, #F3E8FF 50%, #FCE7F3 100%)
```

## Layout Breakpoints

```
Mobile:  < 640px  (default)
Tablet:  640px - 1024px
Desktop: > 1024px

Max Content Width: 448px (md breakpoint)
```

## Accessibility Guidelines

### Color Contrast
- Text on gradient: Use white (#FFFFFF)
- Body text: Use gray-900 (#111827)
- Secondary text: Use gray-600 (#4B5563)
- Disabled text: Use gray-400 (#9CA3AF)

### Touch Targets
- Minimum: 44x44 logical pixels
- Recommended: 48x48 logical pixels
- Spacing between: 8px minimum

### Focus States
- Visible outline: 2px solid purple
- Offset: 2px from element
- Border radius: Match element

## Common Component Combinations

### Record Card
```
Card
├── Left Border (4px, category color)
├── Padding (20px)
├── Row
│   ├── Title (h3, gray-900)
│   └── Category Badge
├── Date Row (icon + text, gray-500)
├── Description (body, gray-600, 2 lines)
└── Attachment Chips (if any)
```

### Stats Card
```
Card
├── Padding (16px)
├── Value (h2, colored)
└── Label (small, gray-600)
```

### Header with Search
```
Gradient Header
├── Title Row
│   ├── Back Button (optional)
│   ├── Title + Subtitle
│   └── Actions (optional)
└── Search Input
    ├── Search Icon (prefix)
    ├── Input Field
    └── Filter Icon (suffix)
```

## File Organization

```
lib/
  ui/
    theme/
      app_colors.dart       # Color constants
      app_text_styles.dart  # Typography
      app_theme.dart        # Theme configuration
    widgets/
      common/
        gradient_header.dart
        gradient_button.dart
        search_bar.dart
      cards/
        record_card.dart
        stats_card.dart
      navigation/
        bottom_nav_bar.dart
    screens/
      [feature]/
        [screen]_screen.dart
```

## Quick Copy-Paste Snippets

### Gradient Container
```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF3B82F6),
        Color(0xFF8B5CF6),
        Color(0xFFEC4899),
      ],
    ),
    borderRadius: BorderRadius.circular(24),
  ),
)
```

### Card with Shadow
```dart
Card(
  elevation: 4,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  child: Padding(
    padding: EdgeInsets.all(20),
    child: // Your content
  ),
)
```

### Frosted Glass Button
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.2),
    borderRadius: BorderRadius.circular(20),
  ),
  child: IconButton(
    icon: Icon(Icons.arrow_back),
    color: Colors.white,
    onPressed: () {},
  ),
)
```

## Design Principles Summary

1. **Consistency**: Use the same spacing, colors, and patterns throughout
2. **Hierarchy**: Use size, weight, and color to establish importance
3. **Feedback**: Provide visual feedback for all interactions
4. **Simplicity**: Keep interfaces clean and uncluttered
5. **Accessibility**: Ensure sufficient contrast and touch targets
6. **Performance**: Optimize animations and gradients
7. **Responsiveness**: Design for different screen sizes

## Common Mistakes to Avoid

❌ Using different border radius values inconsistently
❌ Mixing gradient directions
❌ Inconsistent spacing between elements
❌ Too many colors (stick to the palette)
❌ Small touch targets (< 44px)
❌ Low contrast text on gradients
❌ Overusing animations
❌ Ignoring safe areas on mobile

## Testing Checklist

- [ ] Colors match the design system
- [ ] Spacing is consistent (8px grid)
- [ ] Border radius matches patterns
- [ ] Shadows are appropriate for elevation
- [ ] Text is readable (contrast check)
- [ ] Touch targets are large enough
- [ ] Animations are smooth (60fps)
- [ ] Works on different screen sizes
- [ ] Safe areas respected (notches, etc.)
- [ ] Dark mode considered (if applicable)
