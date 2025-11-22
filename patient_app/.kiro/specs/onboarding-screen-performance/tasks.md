# Implementation Plan

- [x] 1. Add performance logging to OnboardingScreen





  - Add operation tracking for `onboarding_screen_build` in `initState()`
  - Use `addPostFrameCallback` to log completion after first frame renders
  - Log warning if initial build exceeds 100ms threshold
  - Include context with duration and frame metrics
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [x] 2. Optimize SpaceGradient value object with caching





  - Add `_cachedLinearGradient` field to `SpaceGradient` class
  - Modify `toLinearGradient()` method to return cached gradient or create and cache it
  - Ensure gradient caching works with const constructor
  - _Requirements: 2.3, 4.3_

- [x] 3. Optimize SpaceRegistry to return cached list





  - Add `_cachedDefaultSpaces` field to cache the list of default spaces
  - Initialize cached list using `late final` for lazy initialization
  - Modify `getAllDefaultSpaces()` to return cached list
  - _Requirements: 2.3, 4.3_

- [x] 4. Optimize SpaceCard widget for performance





  - Remove `AnimatedContainer` and replace with regular `Container`
  - Wrap entire card in `RepaintBoundary` to isolate repaints
  - Add `late final _cachedGradient` field to cache gradient object
  - Use cached gradient in decoration instead of calling `toLinearGradient()` repeatedly
  - Add const constructors where possible for child widgets
  - Extract `_buildDecoration()` and `_buildContent()` methods for clarity
  - _Requirements: 1.1, 1.4, 2.1, 2.2, 2.3, 2.4, 4.1_

- [x] 5. Convert OnboardingScreen PageView to lazy loading





  - Replace `PageView` with `PageView.builder` in `build()` method
  - Implement `itemCount: 3` and `itemBuilder` callback
  - Create `_buildPage(int index)` method that returns the appropriate page widget
  - Wrap each page in `RepaintBoundary` within the builder
  - Remove pre-built children array from PageView
  - _Requirements: 1.1, 1.2, 1.4, 4.2_
-

- [x] 6. Add const constructors to onboarding page widgets



  - Review `_buildWelcomeStep()`, `_buildSpaceSelectionStep()`, and `_buildFeaturesOverviewStep()`
  - Add const constructors to static widgets (icons, text styles, padding)
  - Use `const` keyword for `SizedBox`, `EdgeInsets`, and other immutable widgets
  - _Requirements: 4.3_

- [x] 7. Verify performance improvements and update documentation





  - Clear app data and launch app on Small_Phone emulator
  - Verify frames skipped during OnboardingScreen render are < 5
  - Test page transitions are smooth (60fps)
  - Test space list scrolling is smooth (60fps)
  - Verify build duration is < 100ms in logs
  - Update `PERFORMANCE_OPTIMIZATION_SUMMARY.md` with the new optimization
  - Update `KNOWN_ISSUES_AND_FIXES.md` if the frame drop issue is resolved
  - _Requirements: 1.1, 1.3, 2.1, 3.2, 3.3, 4.1_

- [x] 8. Fix nested scrolling crash by disabling PageView scrolling on page 2


  - Add conditional `physics` parameter to `PageView.builder` based on `_currentPage`
  - Use `NeverScrollableScrollPhysics()` when `_currentPage == 1` (page 2)
  - Use `PageScrollPhysics()` for other pages (pages 1 and 3)
  - Ensure state updates properly when page changes
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_




- [ ] 9. Add ClampingScrollPhysics to ListView in space selection step
  - Add `physics: const ClampingScrollPhysics()` to `ListView.separated` in `_buildSpaceSelectionStep()`
  - This prevents over-scroll bounce that can trigger PageView gestures
  - Test that list scrolling feels natural without bounce
  - _Requirements: 5.4, 5.5_

- [x] 10. Test crash fix and verify stability


  - Clear app data and launch app on Small_Phone emulator
  - Navigate to page 2 (space selection)
  - Scroll up and down through the space list multiple times
  - Verify no crashes occur during scrolling
  - Test diagonal gestures on the list
  - Verify PageView cannot be swiped while on page 2
  - Verify "Continue" and "Skip" buttons work for navigation
  - Test on pages 1 and 3 that horizontal swiping still works
  - Update `KNOWN_ISSUES_AND_FIXES.md` with crash fix details
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_
