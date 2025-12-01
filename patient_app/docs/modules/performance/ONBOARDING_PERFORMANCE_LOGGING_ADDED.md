Status: LEGACY

# Onboarding Performance Logging

- Added AppLogger instrumentation to OnboardingScreen:
  - Screen build start/end with duration + pageIndex + isInitialBuild.
  - Page change events with from/to.
  - `_completeOnboarding` start/end + duration + selected spaces count.
  - Each `addSpace` call timing and `markOnboardingComplete` timing.
- Goal: detect synchronous hotspots vs normal async I/O; targets <100ms initial build, <150ms rebuilds.
- Use logs + DevTools rebuild stats to correlate jank; optimize only with data.
