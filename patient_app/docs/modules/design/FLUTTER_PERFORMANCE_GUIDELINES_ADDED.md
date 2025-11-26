Status: LEGACY

# Flutter Performance Guidelines Added

- Added steering doc for UI performance: avoid heavy work in `build`, use lazy lists, minimize rebuilds, reduce deep nesting/animations, size images, cache formatters, profile with DevTools.
- Goal: keep 60fps and prevent crashes; apply to all Flutter UI work (see `.kiro/steering/flutter-ui-performance.md` for full rules).
