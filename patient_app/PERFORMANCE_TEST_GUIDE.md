# Performance Testing Guide for RecordsHomeModern

This guide provides instructions for manually testing the performance optimizations implemented in RecordsHomeModern.

## Prerequisites

- Flutter development environment set up
- Android emulator or physical device (preferably low-end device with 2GB RAM)
- Small_Phone emulator configured (optional but recommended)

## Test Setup

1. **Start the app in profile mode** (for accurate performance measurements):
   ```bash
   flutter run --profile
   ```

2. **Enable performance overlay** (optional, for visual frame rate monitoring):
   - In the app, open the debug menu
   - Enable "Performance Overlay"

## Test Cases

### 7.1 Initial Render Time Test

**Objective**: Verify that the RecordsHomeModern screen renders in < 500ms

**Steps**:
1. Start the app in profile mode
2. Navigate to the RecordsHomeModern screen
3. Check the logs for the operation timing:
   ```
   Operation completed: records_home_initial_render (XXXms)
   ```
4. **Expected Result**: Duration should be < 500ms

**Log Location**: Check console output or log files in `logs/` directory

### 7.2 Scroll Performance Test

**Objective**: Verify < 5 frame drops during scrolling

**Steps**:
1. Navigate to RecordsHomeModern with at least 20 records
2. Perform a fast scroll from top to bottom
3. Observe the performance overlay (if enabled) for frame drops
4. Check logs for scroll operation timing:
   ```
   Operation completed: records_list_scroll (XXXms)
   ```
5. Repeat 3-5 times to get consistent results

**Expected Results**:
- Smooth scrolling at 60fps
- < 5 frame drops per scroll
- No janky animations or stuttering
- Scroll operation completes quickly (< 1000ms for warning threshold)

**Test on Small_Phone Emulator**:
```bash
flutter emulators --launch Small_Phone
flutter run --profile
```

### 7.3 Memory Usage Test

**Objective**: Verify < 10MB memory increase during normal usage

**Steps**:
1. Start the app and navigate to RecordsHomeModern
2. Check logs for initial memory usage:
   ```
   Memory usage check: phase=before_init
   Memory usage check: phase=after_init
   ```
3. Perform normal operations:
   - Scroll through records
   - Toggle search
   - Navigate to record details and back
   - Switch spaces (if multiple)
4. Use Flutter DevTools to monitor memory:
   ```bash
   flutter pub global activate devtools
   flutter pub global run devtools
   ```
5. Take memory snapshots before and after operations

**Expected Results**:
- Memory increase < 10MB during normal usage
- No memory leaks (memory returns to baseline after operations)
- Stable memory usage during scrolling

### 7.4 Visual Verification Test

**Objective**: Verify layout matches design requirements on different screen sizes

**Test Screens**:
- Small phone (< 360dp width)
- Medium phone (360-400dp width)
- Large phone (> 400dp width)
- Tablet (if applicable)

**Visual Checklist**:

#### Header
- [ ] Gradient background displays correctly
- [ ] Header padding is 16px (reduced from 24px)
- [ ] Search field is hidden by default
- [ ] Search field slides down smoothly when toggled
- [ ] Search field auto-focuses when opened
- [ ] All action buttons are visible and functional

#### Stats Row
- [ ] Stats displayed in single horizontal row
- [ ] Dot separators (·) between stats
- [ ] White background on stat chips
- [ ] Minimal padding (12px horizontal, 4px vertical)
- [ ] Uses AppTextStyles.bodySmall

#### Record Cards
- [ ] Card margin is 8px (reduced from 16px)
- [ ] Card padding is 12px (reduced from 20px)
- [ ] Border radius is 12px
- [ ] Single subtle shadow (no multiple shadows)
- [ ] Subtle border (gray200, 1px)
- [ ] No animations on tap or scroll
- [ ] 3-line layout:
  - Line 1: Category tag + Title (truncated)
  - Line 2: Calendar icon + Date + · + Description (truncated)
  - Line 3: Tags (max 3, "+X more" if needed)
- [ ] Line spacing is 6px
- [ ] Title truncates with ellipsis
- [ ] Description limited to ~50 characters
- [ ] Tags display correctly with color-coded backgrounds

#### Colors (verify against AppColors)
- [ ] Header gradient matches space gradient
- [ ] Card background is white
- [ ] Border is gray200
- [ ] Text colors match AppTextStyles
- [ ] Category tags use correct color scheme

#### Typography (verify against AppTextStyles)
- [ ] Header title uses h2
- [ ] Record title uses h4
- [ ] Body text uses bodySmall
- [ ] Labels use labelSmall

#### Spacing and Alignment
- [ ] Consistent spacing throughout
- [ ] Proper alignment of elements
- [ ] No layout overflow errors
- [ ] Responsive on different screen sizes

## Performance Logging

All performance metrics are automatically logged using AppLogger. To view logs:

1. **Console Output**: Check the terminal where you ran `flutter run`

2. **Log Files**: Check the `logs/` directory for detailed log files

3. **Key Log Messages to Look For**:
   ```
   Operation started: records_home_initial_render
   Operation completed: records_home_initial_render (XXXms)
   RecordsHomeModern rendered (recordCount: X, screenWidth: X, screenHeight: X)
   Operation started: records_list_scroll
   Operation completed: records_list_scroll (XXXms)
   Memory usage check (phase: before_init/after_init)
   RecordCard visual verification (debug mode only)
   ```

## Troubleshooting

### High Initial Render Time
- Check if there are too many records being loaded initially
- Verify that RepaintBoundary is working correctly
- Check for unnecessary rebuilds in logs

### Frame Drops During Scroll
- Verify that animations are removed from cards
- Check that RepaintBoundary is wrapping each card
- Monitor memory usage during scroll

### Memory Issues
- Use Flutter DevTools Memory profiler
- Check for memory leaks in logs
- Verify that widgets are properly disposed

### Visual Issues
- Check that AppColors and AppTextStyles are imported correctly
- Verify that const constructors are used where possible
- Check for layout overflow errors in logs

## Success Criteria

All tests pass with the following metrics:
- ✅ Initial render time < 500ms
- ✅ Frame drops during scroll < 5 frames
- ✅ Memory increase < 10MB
- ✅ Visual layout matches design requirements
- ✅ All functionality preserved (search, navigation, pagination)

## Next Steps

After completing these tests:
1. Document results in PERFORMANCE_OPTIMIZATION_SUMMARY.md
2. Update KNOWN_ISSUES_AND_FIXES.md if any issues found
3. Remove backup file if all tests pass
4. Proceed to task 8: Documentation and cleanup


---

## Quick Reference

### Log Messages to Monitor

**Initial Render Time**
```
Operation started: records_home_initial_render
Operation completed: records_home_initial_render (XXXms)
Target: < 500ms
```

**Scroll Performance**
```
Operation started: records_list_scroll
Operation completed: records_list_scroll (XXXms)
Target: < 5 frame drops, smooth 60fps
```

**Memory Usage**
```
Memory usage check (phase: before_init, screen: RecordsHomeModern)
Memory usage check (phase: after_init, screen: RecordsHomeModern)
Target: < 10MB increase
```

**Screen Render**
```
RecordsHomeModern rendered (recordCount: X, screenWidth: X, screenHeight: X)
```

**Visual Verification (Debug Mode)**
```
RecordCard visual verification (cardMargin: 8.0, cardPadding: 12.0, ...)
```

### Quick Test Commands

```bash
# Profile mode (recommended)
flutter run --profile

# With performance overlay
flutter run --profile --enable-software-rendering

# Small phone emulator
flutter emulators --launch Small_Phone
flutter run --profile

# Pixel 4a emulator
flutter emulators --launch Pixel_4a
flutter run --profile
```

### Success Criteria Summary

- ✅ Initial render: < 500ms
- ✅ Scroll: < 5 frame drops
- ✅ Memory: < 10MB increase
- ✅ Visual: Matches design specs
