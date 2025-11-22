# Requirements Document: Universal Spaces System

## Introduction

The Universal Spaces System transforms the Patient App from a health-focused application into a flexible personal information system. Users can organize different areas of their life (health, education, home, business, etc.) in separate "spaces," each with its own categories, visual identity, and records.

## Glossary

- **Space**: A distinct life area or domain (e.g., Health, Education, Business) with its own categories, icon, and color scheme
- **Default Space**: Pre-configured space templates provided by the system (8 total)
- **Custom Space**: User-created space with personalized settings
- **Active Space**: A space that the user has enabled and can use
- **Current Space**: The space currently being viewed/used
- **Space ID**: Unique identifier for a space (e.g., 'health', 'education')
- **Information Item**: Universal term for any record, regardless of space (replaces "health record")
- **Category**: Type classification within a space (e.g., 'Checkup' in Health, 'Recipe' in Home)

## Requirements

### Requirement 1: Default Spaces

**User Story:** As a user, I want to choose from pre-defined life areas so that I can quickly start organizing information relevant to me.

#### Acceptance Criteria

1. THE System SHALL provide eight default space templates
2. WHEN a user views available spaces, THE System SHALL display Health, Education, Home & Life, Business, Finance, Travel, Family, and Creative spaces
3. THE System SHALL assign each default space a unique identifier, name, icon, gradient color, description, and category list
4. THE Health space SHALL include categories: Checkup, Dental, Vision, Lab, Medication, Vaccine, Therapy, Other
5. THE Education space SHALL include categories: Course, Assignment, Research, Notes, Project, Reading, Certification, Other
6. THE Home & Life space SHALL include categories: Recipe, DIY, Maintenance, Hobby, Garden, Pet, Shopping, Other
7. THE Business space SHALL include categories: Meeting, Contact, Contract, Idea, Project, Goal, Review, Other
8. THE Finance space SHALL include categories: Expense, Income, Investment, Receipt, Bill, Tax, Budget, Other
9. THE Travel space SHALL include categories: Trip, Booking, Itinerary, Accommodation, Activity, Transport, Memory, Other
10. THE Family space SHALL include categories: Event, Milestone, Memory, Document, Photo, Genealogy, Contact, Other
11. THE Creative space SHALL include categories: Art, Writing, Music, Photography, Design, Craft, Performance, Other

### Requirement 2: Space Selection

**User Story:** As a new user, I want to select which life areas matter to me so that I only see relevant spaces.

#### Acceptance Criteria

1. WHEN a user completes authentication for the first time, THE System SHALL present a space selection screen
2. THE System SHALL display all eight default spaces with their icons, names, and descriptions
3. WHEN a user taps a space card, THE System SHALL toggle its selection state
4. THE System SHALL visually indicate selected spaces with a checkmark and highlight
5. THE System SHALL require at least one space to be selected
6. WHEN a user attempts to deselect the only selected space, THE System SHALL prevent the action
7. WHEN a user confirms their selection, THE System SHALL save the selected spaces to local storage
8. THE System SHALL mark the first selected space as the current active space
9. THE System SHALL persist space selections across app restarts

### Requirement 3: Space Management

**User Story:** As a user, I want to add or remove spaces at any time so that my app adapts to my changing needs.

#### Acceptance Criteria

1. THE System SHALL provide a space management screen accessible from the main navigation
2. WHEN a user opens space management, THE System SHALL display all active spaces
3. THE System SHALL provide an option to add more spaces from the default templates
4. WHEN a user adds a new space, THE System SHALL append it to their active spaces list
5. THE System SHALL allow users to remove spaces from their active list
6. THE System SHALL prevent removal of the last remaining space
7. WHEN a user removes the currently active space, THE System SHALL switch to the first remaining space
8. THE System SHALL save space management changes to local storage immediately

### Requirement 4: Space Switching

**User Story:** As a user, I want to easily switch between my active spaces so that I can view different areas of my life.

#### Acceptance Criteria

1. WHEN a user has multiple active spaces, THE System SHALL display a space switcher button in the app bar
2. WHEN a user taps the space switcher, THE System SHALL show all active spaces
3. THE System SHALL visually indicate the currently active space
4. WHEN a user selects a different space, THE System SHALL switch to that space and update the UI
5. THE System SHALL filter displayed records to show only those belonging to the current space
6. THE System SHALL update the header gradient to match the current space's color
7. THE System SHALL update the header icon to match the current space's icon
8. THE System SHALL persist the current space selection across app sessions

### Requirement 5: Information Item Model

**User Story:** As a developer, I want a universal data model that supports any space so that records can belong to different life areas.

#### Acceptance Criteria

1. THE System SHALL extend the record model to include a spaceId field
2. WHEN a record is created, THE System SHALL associate it with the current active space
3. THE System SHALL default spaceId to 'health' for existing records without a spaceId
4. THE System SHALL allow querying records by spaceId
5. THE System SHALL support filtering, searching, and sorting within a specific space
6. THE System SHALL maintain backward compatibility with existing health records
7. THE System SHALL migrate existing records to include spaceId='health' during database upgrade

### Requirement 6: Space Visual Identity

**User Story:** As a user, I want each space to have a distinct visual appearance so that I can quickly identify which area I'm viewing.

#### Acceptance Criteria

1. THE System SHALL assign each space a unique gradient color scheme
2. THE System SHALL display the space's gradient in the header background
3. THE System SHALL show the space's icon in the header
4. THE System SHALL use the space's name as the header title
5. THE System SHALL display the space's description as the header subtitle
6. THE System SHALL apply consistent visual styling across all space-related UI elements
7. THE System SHALL use Lucide icons for space icons

### Requirement 7: Custom Space Creation

**User Story:** As a user, I want to create my own custom spaces so that I can organize unique areas of my life.

#### Acceptance Criteria

1. THE System SHALL provide a "Create Custom Space" option in space management
2. WHEN a user creates a custom space, THE System SHALL prompt for name, description, icon, color, and categories
3. THE System SHALL validate that the space name is not empty and is unique
4. THE System SHALL allow users to select from available Lucide icons
5. THE System SHALL allow users to choose from predefined gradient color schemes
6. THE System SHALL allow users to define custom categories (comma-separated list)
7. WHEN a user saves a custom space, THE System SHALL generate a unique ID
8. THE System SHALL mark custom spaces with an isCustom flag
9. THE System SHALL save custom spaces to local storage
10. THE System SHALL automatically add newly created custom spaces to active spaces

### Requirement 8: Space-Specific Categories

**User Story:** As a user, I want to see categories relevant to the current space so that I can properly classify my records.

#### Acceptance Criteria

1. WHEN a user adds a record, THE System SHALL display categories for the current space
2. THE System SHALL populate the category dropdown with space-specific categories
3. THE System SHALL include an "Other" category in every space
4. THE System SHALL allow records to use any category from their associated space
5. THE System SHALL display the category in record cards with appropriate styling

### Requirement 9: Space Statistics

**User Story:** As a user, I want to see statistics for the current space so that I understand my information at a glance.

#### Acceptance Criteria

1. THE System SHALL display three statistics cards for the current space
2. THE System SHALL show total record count for the current space
3. THE System SHALL show total attachment count for records in the current space
4. THE System SHALL show number of unique categories used in the current space
5. THE System SHALL update statistics in real-time when records are added or removed
6. THE System SHALL animate statistics cards on screen load with staggered timing

### Requirement 10: Onboarding Experience

**User Story:** As a new user, I want a guided onboarding experience so that I understand how to use spaces.

#### Acceptance Criteria

1. THE System SHALL present a 3-step onboarding flow for first-time users
2. Step 1 SHALL introduce the universal spaces concept with value propositions
3. Step 2 SHALL allow users to select their initial spaces
4. Step 3 SHALL explain key features (multi-modal input, AI assistance, security)
5. THE System SHALL show progress indicators (dots) at the top of the onboarding screen
6. THE System SHALL allow users to skip to the final step
7. WHEN onboarding is complete, THE System SHALL save a completion flag to local storage
8. THE System SHALL not show onboarding again after completion
9. THE System SHALL navigate to the records list after onboarding completion

### Requirement 11: Space Persistence

**User Story:** As a user, I want my space selections and custom spaces to persist so that I don't lose my configuration.

#### Acceptance Criteria

1. THE System SHALL store active space IDs in local storage
2. THE System SHALL store custom space definitions in local storage
3. THE System SHALL store the current space ID in local storage
4. THE System SHALL restore space configuration on app launch
5. THE System SHALL handle missing or corrupted space data gracefully
6. IF stored space data is invalid, THE System SHALL reset to default (Health space only)
7. THE System SHALL include space data in backup archives
8. THE System SHALL restore space data from backup archives

### Requirement 12: Migration Strategy

**User Story:** As a developer, I want a safe migration path so that existing users don't lose data.

#### Acceptance Criteria

1. THE System SHALL detect records without a spaceId field
2. WHEN migrating existing records, THE System SHALL set spaceId to 'health'
3. THE System SHALL perform migration automatically on first launch after update
4. THE System SHALL log migration progress and results
5. THE System SHALL not modify records that already have a spaceId
6. THE System SHALL maintain all existing record data during migration
7. THE System SHALL verify migration success before proceeding
8. IF migration fails, THE System SHALL rollback changes and log the error

### Requirement 13: Search and Filter

**User Story:** As a user, I want to search within the current space so that I can find relevant information quickly.

#### Acceptance Criteria

1. THE System SHALL scope search results to the current space
2. WHEN a user enters a search query, THE System SHALL filter records by title, description, and category within the current space
3. THE System SHALL display search results in real-time as the user types
4. THE System SHALL show a "no results" message when no records match in the current space
5. THE System SHALL clear search results when the user switches spaces
6. THE System SHALL maintain search functionality across all spaces

### Requirement 14: Cross-Space Features (Future)

**User Story:** As a user, I want to search across all my spaces so that I can find information regardless of where I stored it.

#### Acceptance Criteria

1. THE System SHALL provide an option to search across all active spaces
2. WHEN searching across spaces, THE System SHALL group results by space
3. THE System SHALL indicate which space each result belongs to
4. THE System SHALL allow filtering results by specific spaces
5. THE System SHALL support linking records across different spaces

### Requirement 15: Accessibility

**User Story:** As a user with accessibility needs, I want spaces to be fully accessible so that I can use all features.

#### Acceptance Criteria

1. THE System SHALL provide screen reader labels for all space UI elements
2. THE System SHALL ensure sufficient color contrast for space gradients and text
3. THE System SHALL support keyboard navigation for space selection and switching
4. THE System SHALL announce space changes to screen readers
5. THE System SHALL provide alternative text for space icons
6. THE System SHALL ensure touch targets for space buttons are at least 44x44 logical pixels
