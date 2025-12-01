Status: LEGACY

# Figma Design Implementation Guide

- Source: Mobile Health App Figma concepts; adapt to Flutter with gradients, rounded cards, clear hierarchy.
- Core patterns: gradient headers, compact cards with icons/title/date, search bar with shadow, category badges, stats cards, large FABs, generous spacing.
- Use `AppColors/AppTextStyles` equivalents; avoid hard-coded prose; ensure accessibility (contrast, touch sizes).
- Reference implementation: `lib/features/records/ui/records_home_modern.dart`.
- Keep performance in mind: lazy lists, minimal rebuilds, limited animations.
