# Flutter UI Performance Guidelines - Added November 18, 2024

## Summary

Created comprehensive Flutter UI performance steering file based on expert analysis and ChatGPT recommendations. This establishes mandatory performance standards for all Flutter UI code in the Patient App.

## What Was Created

### New Steering File
**Location**: `.kiro/steering/flutter-ui-performance.md`
**Status**: Active - Mandatory for all UI development
**Inclusion**: Always (automatically included in all AI agent contexts)

### Content Overview

The steering file includes 10 comprehensive sections:

1. **Build Functions** - No heavy work in build methods
2. **Rebuilds and State** - Minimize rebuild scope
3. **Lists and Collections** - Always use lazy rendering
4. **Images** - Proper sizing and caching
5. **Widget Tree and Layout** - Avoid deep nesting
6. **Animations** - Use sparingly and wisely
7. **Performance Diagnostics** - Profile before optimizing
8. **Caching and Data Usage** - Cache expensive operations
9. **Avoid Common Anti-Patterns** - Known pitfalls to avoid
10. **Mandatory Checklist** - Verification for all UI code

## Key Rules Established

### Critical Rules (Must Follow)

1. **No heavy work in build** - Move to ViewModel/Controller
2. **Lazy lists for > 20 items** - Use ListView.builder
3. **Minimize rebuilds** - Only rebuild what changed
4. **Split large widgets** - Keep under 100 lines
5. **Profile before optimizing** - Use DevTools

### Success Story Documented

Included RecordsHomeModern optimization as a success story:
- Before: 400+ frame drops
- After: < 5 frame drops
- Key: Removed animations, added RepaintBoundary, simplified decorations

### Known Issues Documented

Included OnboardingScreen performance problem:
- 476ms build time (should be < 100ms)
- 68+ frame drops
- Likely violations of multiple rules
- Marked for future optimization

## Integration

### Updated Files

1. **AI_AGENT_START_HERE.md**
   - Added reference to new steering file
   - Now part of mandatory reading for all agents

2. **.kiro/steering/flutter-ui-performance.md**
   - New steering file with `inclusion: always`
   - Automatically included in all AI contexts

## Benefits

### For Development

1. **Prevents common mistakes** - Clear rules to follow
2. **Faster code reviews** - Checklist for reviewers
3. **Better performance** - Proactive optimization
4. **Easier debugging** - Predictable, simple code

### For AI Agents

1. **Clear guidelines** - Know what to do and what to avoid
2. **Consistent quality** - All UI code follows same standards
3. **Performance-first** - Build with performance in mind
4. **Examples included** - Good vs bad code patterns

### For Users

1. **Smoother UI** - No frame drops or jank
2. **Faster app** - Optimized from the start
3. **Stable experience** - No crashes from performance issues
4. **Better battery life** - Efficient rendering

## Enforcement

### Code Review Checklist

All Flutter UI code must be reviewed against the checklist:
- [ ] No heavy logic in build
- [ ] Lazy lists for large collections
- [ ] Minimal rebuild scope
- [ ] No deep nesting
- [ ] Performance risks documented

### AI Agent Requirements

When building/refactoring UI, agents must:
1. Follow all rules in steering file
2. Add performance comments
3. Propose lighter alternatives
4. Profile if screen feels laggy
5. Document performance decisions

## Examples Included

### Good vs Bad Patterns

The steering file includes multiple examples:
- ✅ Good: Data preparation before build
- ❌ Bad: Heavy work in build
- ✅ Good: ListView.builder for lists
- ❌ Bad: Column with large children list
- ✅ Good: Small, focused widgets
- ❌ Bad: Deep nesting and large widgets

## Future Impact

### Immediate

- All new UI code follows guidelines
- Existing issues (OnboardingScreen) identified
- Performance-first mindset established

### Long-term

- Fewer performance regressions
- Easier maintenance
- Better user experience
- Reduced debugging time

## Related Documentation

- **Steering File**: `.kiro/steering/flutter-ui-performance.md`
- **Logging Guidelines**: `.kiro/steering/logging-guidelines.md`
- **RecordsHomeModern Optimization**: `.kiro/specs/ui-performance-optimization/`
- **Known Issues**: `KNOWN_ISSUES_AND_FIXES.md`
- **AI Agent Start**: `AI_AGENT_START_HERE.md`

## Acknowledgments

Guidelines based on:
- ChatGPT expert recommendations
- Flutter official best practices
- RecordsHomeModern optimization learnings
- Real-world performance issues encountered

## Next Steps

### Immediate

1. ✅ Steering file created and active
2. ✅ AI_AGENT_START_HERE.md updated
3. ✅ Documentation complete

### Future

1. Apply guidelines to OnboardingScreen optimization
2. Audit existing screens against checklist
3. Update as new patterns emerge
4. Share learnings in documentation

---

**Created**: November 18, 2024
**Status**: ✅ Complete and Active
**Impact**: All future Flutter UI development
**Enforcement**: Mandatory for all UI code
