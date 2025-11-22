# UI Performance Optimization Requirements

## Introduction

Optimize the RecordsHomeModern screen for low-end devices while maintaining visual appeal. The current implementation uses expensive UI elements (multiple shadows, animations, large cards) that cause frame drops on less powerful phones. We need to reduce resource consumption without sacrificing the modern, beautiful design.

## Glossary

- **RecordsHomeModern**: The main screen showing list of records with gradient header and stats
- **GradientHeader**: Custom widget with gradient background, search, and action buttons
- **StatsCard**: Individual card showing statistics (Records, Attachments, Categories)
- **ModernRecordCard**: Card displaying individual record with animations and shadows
- **Frame Drop**: When UI rendering takes too long, causing visible stuttering
- **Repaint**: When Flutter redraws a widget on screen

## Requirements

### Requirement 1: Optimize Header Performance

**User Story:** As a user with a low-end phone, I want the header to load quickly so that I can start viewing my records without delay.

#### Acceptance Criteria

1. WHEN the RecordsHomeModern screen loads, THE header SHALL render in less than 100ms
2. WHEN the user toggles search, THE search field SHALL animate smoothly at 60fps
3. THE header gradient SHALL use cached LinearGradient to avoid recreation on every build
4. THE header padding SHALL be reduced from 24px to 16px to minimize render area
5. THE search field SHALL be hidden by default and only shown when user taps search icon

### Requirement 2: Simplify Stats Display

**User Story:** As a user, I want to see statistics at a glance without waiting for multiple cards to render.

#### Acceptance Criteria

1. THE stats SHALL be displayed in a single horizontal row instead of 3 separate cards
2. EACH stat chip SHALL have minimal decoration (no shadows, simple background)
3. THE stats SHALL use dot separators (·) between items
4. THE stats row SHALL render in less than 50ms
5. THE stats SHALL use AppTextStyles.bodySmall for consistent, lightweight text rendering

### Requirement 3: Compact Record Cards

**User Story:** As a user, I want to see more records on screen without scrolling while maintaining readability.

#### Acceptance Criteria

1. EACH record card SHALL have maximum 2 lines of content (Tag+Title, Date+Description)
2. THE card padding SHALL be reduced from 20px to 12px
3. THE card SHALL have NO border and NO shadow for maximum lightness
4. THE card spacing SHALL be reduced from 16px to 12px between items
5. THE card SHALL NOT use AnimatedContainer or ScaleTransition animations
6. THE card SHALL use simple Container with GestureDetector for tap handling
7. THE title SHALL truncate with ellipsis if longer than available width
8. THE description SHALL be limited to ~50 characters with ellipsis
9. THE card SHALL NOT display tags/attachments line (only 2 lines total)

### Requirement 4: Progressive Disclosure for Search

**User Story:** As a user, I want search to be available when I need it without taking permanent screen space.

#### Acceptance Criteria

1. THE search field SHALL be hidden by default
2. WHEN user taps search icon, THE search field SHALL slide down smoothly
3. WHEN search is visible, THE search icon SHALL remain visible (no icon change)
4. WHEN user taps search icon again OR clears search, THE search field SHALL slide up and hide
5. THE search animation SHALL use AnimatedSize with 200ms duration
6. THE search field SHALL auto-focus when opened
7. THE search field SHALL take zero vertical space when closed
8. THE header SHALL include back arrow, favorite icon, filter icon, search icon, and grid icon

### Requirement 5: Maintain Visual Appeal

**User Story:** As a user, I want the app to look modern and beautiful even with performance optimizations.

#### Acceptance Criteria

1. THE gradient header SHALL maintain smooth color transitions
2. THE record cards SHALL maintain rounded corners (12px radius)
3. THE category tags SHALL maintain color-coded backgrounds
4. THE overall design SHALL maintain clean, modern aesthetic
5. THE color scheme SHALL follow existing AppColors palette
6. THE typography SHALL follow existing AppTextStyles
7. THE spacing SHALL maintain visual hierarchy and breathing room

### Requirement 6: Performance Targets

**User Story:** As a user with a low-end phone, I want the app to run smoothly without stuttering.

#### Acceptance Criteria

1. THE initial screen render SHALL complete in less than 500ms
2. THE frame drops during scrolling SHALL be less than 5 frames per scroll
3. THE list SHALL maintain 60fps scrolling on devices with 2GB RAM
4. THE memory usage SHALL not increase by more than 10MB during normal usage
5. THE widget rebuild count SHALL be minimized through proper use of const constructors

### Requirement 7: Preserve Existing Functionality

**User Story:** As a user, I want all existing features to continue working after optimization.

#### Acceptance Criteria

1. THE search functionality SHALL continue to filter records by title and text
2. THE space switching SHALL continue to work via grid icon
3. THE record tap SHALL continue to navigate to detail screen
4. THE pull-to-refresh SHALL continue to reload records
5. THE load more functionality SHALL continue to work for pagination
6. THE empty state SHALL continue to display when no records exist
7. THE error state SHALL continue to display when loading fails

## Non-Functional Requirements

### Performance
- Screen render time: < 500ms
- Scroll performance: 60fps on 2GB RAM devices
- Memory overhead: < 10MB increase

### Compatibility
- Must work on Android devices with 2GB RAM
- Must work on Small_Phone emulator
- Must maintain existing functionality

### Maintainability
- Follow Clean Architecture principles
- Use existing AppColors and AppTextStyles
- Maintain separation of concerns
- Add performance logging where appropriate

## Out of Scope

- Redesigning the entire app UI
- Changing the navigation structure
- Modifying the data layer or business logic
- Adding new features or functionality
- Changing color schemes or branding
