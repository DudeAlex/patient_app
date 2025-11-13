# UI Design Samples

Visual mockups and design references for the Patient App interface.

Last Updated: 2025-11-12

## Contents

### Main Page (`main+page.png`)
- Dashboard/home screen design
- Shows health metrics overview
- Navigation structure
- Visual style and color scheme

### Records Page (`records_page.png`)
- Records list view design
- Search and filter UI
- Record card layout
- Empty states

### Add Records Menu (`add_records_menu.png`)
- Multi-modal capture launcher
- Photo, Scan, Voice, Keyboard, File, Email options
- Modal/bottom sheet design
- Button layout and iconography

## Design Principles

Based on these mockups and `Health_Tracker_Advisor_UX_Documentation.md`:

- **Style:** Modern, minimal, calm
- **Primary Accent:** Gradient Blue (#60A5FA → #2563EB)
- **Background:** Soft off-white gradient
- **Typography:** Inter (legible, digital-first)
- **Accessibility:** Large touch targets (48pt+), high contrast

## For AI Agents

When implementing UI features:

1. **Reference these mockups** for visual guidance
2. **Follow Material 3** design system (Flutter default)
3. **Check accessibility** - large fonts, high contrast, screen reader support
4. **Use semantic colors** from theme, not hard-coded hex values
5. **Prepare strings for localization** - no hard-coded text

### Key UI Components to Match

From the mockups:
- **Circular metric cards** (dashboard)
- **Large, clear list items** (records page)
- **Bottom sheet modal** (add records menu)
- **Gradient blue FAB** (floating action button)
- **Clean, spacious layouts** (avoid clutter)

### Current Implementation Status

- ✅ Records list (M2) - basic implementation
- ✅ Add record form (M2) - keyboard entry only
- ✅ Multi-modal launcher (M5) - in progress
- ⏳ Dashboard metrics - planned
- ⏳ Gradient styling - planned

## Related Documentation

- `Health_Tracker_Advisor_UX_Documentation.md` - Detailed UX vision
- `SPEC.md` section 9 - Accessibility requirements
- `M5_MULTI_MODAL_PLAN.md` - Multi-modal capture implementation
- `GLOSSARY.md` - UI terminology (Patient, Record, Capture, etc.)

## Usage Notes

- These are **reference designs**, not pixel-perfect specs
- Adapt to Material 3 guidelines and Flutter best practices
- Prioritize accessibility over exact visual match
- Test with large fonts and screen readers
- Ensure designs work in both light and dark themes
