Status: LEGACY

# Performance Optimization Summary

- Focus: reduce frame drops and build times on key screens (RecordsHome, onboarding).
- Actions taken:
  - Removed heavy animations/decorations; simplified card layouts; added `RepaintBoundary`.
  - Cached expensive data/precomputation outside build; split widgets to limit rebuild scope.
  - Instrumented build durations and scroll performance via AppLogger + DevTools.
  - Adjusted onboarding to cache default spaces in `initState`, cutting build time.
- Results: smoother scrolling and reduced frame drops (see logs/metrics from 2024-11-18 efforts).
- Next ideas: continue profiling before optimizing; avoid work in build; prefer lazy lists and cached formatters.
