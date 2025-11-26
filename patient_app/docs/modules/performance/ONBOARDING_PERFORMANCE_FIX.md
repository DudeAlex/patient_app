Status: LEGACY

# Onboarding Performance Fix

- Issue: OnboardingScreen build ~476ms, 68+ frame drops due to heavy work in `build` (fetching default spaces each rebuild).
- Fix (2024-11-18):
  - Cache default spaces in `initState`.
  - Added performance logging (build durations, page changes, completion flow timings).
- Result: build time reduced to ~69ms (85% improvement); jank minimized.
- Guidance: keep heavy prep out of `build`, profile with DevTools + AppLogger before optimizing further.
