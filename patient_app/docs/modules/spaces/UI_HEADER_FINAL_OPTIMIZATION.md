Status: LEGACY

# UI Header Final Optimization (2024-11-20)

## Summary
- Removed redundant AppBar title; rely on compact `GradientHeader`.
- Settings button moved into header actions; space switcher always visible; search toggle retained.
- Combined with header compaction (no subtitle, smaller icon/text/padding) to maximize list space (~126px saved).

## Files
- `lib/ui/app.dart` (AppBar removed)
- `lib/features/records/ui/records_home_modern.dart` (header actions + padding)
- `lib/ui/widgets/common/gradient_header.dart` (size/padding/title tweaks)

## Result
- More records visible, cleaner design, consistent header across spaces; navigation (search/switcher/settings) still accessible.

## Testing
- Verified on Pixel_4a emulator: header compact, actions accessible, search works, more list space.
