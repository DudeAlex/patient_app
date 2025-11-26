Status: LEGACY

# Header Space Optimization (2024-11-20)

## Summary
- Goal: compact `GradientHeader` across all spaces to show more records.
- Changes:
  - Removed subtitle/description; title uses h2.
  - Icon size 40 -> 32.
  - Padding: top/sides 16->12, bottom 32->16, spacing 24->16.
  - Reduced bottom padding in `records_home_modern.dart`.
- Result: ~70-80px vertical space saved; better performance/visibility on small screens.

## Files
- `lib/ui/widgets/common/gradient_header.dart`
- `lib/features/records/ui/records_home_modern.dart`

## Testing
- Pixel_4a emulator; multiple spaces; with/without search; single/multi spaces.

## Future
- Optional: make top bar a space selector or show record count; current choice is minimal header.
