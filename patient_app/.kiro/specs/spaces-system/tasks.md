# Implementation Plan: Universal Spaces System

## Overview

This plan breaks down the implementation of the Universal Spaces System into discrete, manageable tasks. Each task builds incrementally on previous work, ensuring the system remains functional throughout development.

---

- [x] 1. Foundation: Core Domain Models





  - Create Space entity with validation
  - Create SpaceGradient value object
  - Create SpaceRegistry with 8 default spaces
  - Create space-related error classes
  - _Requirements: 1.1-1.11, 5.1-5.7_

- [x] 1.1 Create Space entity


  - Define Space class in `lib/core/domain/entities/space.dart`
  - Implement validation logic (non-empty ID, name, categories)
  - Add copyWith method for immutability
  - Implement toJson/fromJson for serialization
  - _Requirements: 1.1, 1.2, 1.3_


- [x] 1.2 Create SpaceGradient value object

  - Define SpaceGradient in `lib/core/domain/value_objects/space_gradient.dart`
  - Implement toLinearGradient() method
  - Add JSON serialization support
  - _Requirements: 6.1, 6.2_

- [x] 1.3 Create SpaceRegistry


  - Define SpaceRegistry in `lib/features/spaces/domain/space_registry.dart`
  - Add all 8 default space definitions
  - Implement getDefaultSpace() and getAllDefaultSpaces()
  - _Requirements: 1.1-1.11_

- [ ]* 1.4 Create space error classes
  - Define SpaceError, SpaceNotFoundError, InvalidSpaceError, LastSpaceError
  - Add error messages and context
  - _Requirements: Error handling_

- [x] 2. Infrastructure: Storage Layer





  - Update Isar schema with spaceId field
  - Create database migration for existing records
  - Implement SpaceRepository interface
  - Create SharedPreferences-based space storage
  - _Requirements: 5.1-5.7, 11.1-11.8, 12.1-12.8_

- [x] 2.1 Update Isar schema



  - Add spaceId field to Item collection
  - Add composite index for space-category-date queries
  - Update existing RecordEntity mapping
  - _Requirements: 5.1, 5.2_

- [x] 2.2 Create database migration


  - Implement SpaceMigration class
  - Set spaceId='health' for all existing records
  - Add migration verification
  - Log migration progress
  - _Requirements: 5.3, 12.1-12.8_

- [x] 2.3 Create SpaceRepository interface


  - Define interface in `lib/core/application/ports/space_repository.dart`
  - Methods: getActiveSpaceIds, setActiveSpaceIds, getCurrentSpaceId, etc.
  - _Requirements: 11.1-11.8_

- [x] 2.4 Implement space storage


  - Create SpacePreferences in `lib/core/infrastructure/storage/space_preferences.dart`
  - Implement SharedPreferences wrapper for space config
  - Add methods for active spaces, current space, custom spaces
  - Handle JSON serialization of custom spaces
  - _Requirements: 11.1-11.8_

- [x] 3. Application Layer: Space Management





  - Create SpaceManager service
  - Implement space activation/deactivation logic
  - Add custom space creation
  - Handle current space switching
  - _Requirements: 2.1-2.9, 3.1-3.8, 4.1-4.8, 7.1-7.10_

- [x] 3.1 Create SpaceManager service


  - Implement in `lib/core/application/services/space_manager.dart`
  - Inject SpaceRepository and SpaceRegistry dependencies
  - _Requirements: 2.1, 3.1, 4.1_

- [x] 3.2 Implement getActiveSpaces()


  - Retrieve active space IDs from storage
  - Map IDs to Space objects (custom + default)
  - Default to Health space if none selected
  - _Requirements: 2.1, 3.1_

- [x] 3.3 Implement getCurrentSpace()


  - Retrieve current space ID from storage
  - Return Space object
  - Fallback to first active space
  - _Requirements: 4.1, 4.2_

- [x] 3.4 Implement setCurrentSpace()


  - Validate space ID exists in active spaces
  - Save to storage
  - _Requirements: 4.3, 4.4_

- [x] 3.5 Implement activateSpace()


  - Add space ID to active list
  - Prevent duplicates
  - Save to storage
  - _Requirements: 3.3, 3.4_

- [x] 3.6 Implement deactivateSpace()


  - Remove space ID from active list
  - Prevent removing last space
  - Switch current space if needed
  - Save to storage
  - _Requirements: 3.5, 3.6, 3.7_

- [x] 3.7 Implement createCustomSpace()


  - Generate unique space ID from name
  - Create Space entity with isCustom=true
  - Save to custom spaces storage
  - Automatically activate new space
  - _Requirements: 7.1-7.10_

- [x] 4. State Management: Space Provider





  - Create SpaceProvider with ChangeNotifier
  - Expose current space and active spaces
  - Handle space switching
  - Notify listeners on changes
  - _Requirements: 4.1-4.8_


- [x] 4.1 Create SpaceProvider

  - Implement in `lib/features/spaces/providers/space_provider.dart`
  - Extend ChangeNotifier
  - Inject SpaceManager dependency
  - _Requirements: 4.1_

- [x] 4.2 Add state properties

  - currentSpace (Space?)
  - activeSpaces (List<Space>)
  - isLoading (bool)
  - error (String?)
  - _Requirements: 4.1, 4.2_


- [x] 4.3 Implement initialization

  - Load active spaces on init
  - Load current space on init
  - Handle errors gracefully
  - _Requirements: 4.1, 11.4_


- [x] 4.4 Implement switchSpace()

  - Call SpaceManager.setCurrentSpace()
  - Update currentSpace property
  - Notify listeners
  - _Requirements: 4.3, 4.4, 4.5_



- [x] 4.5 Implement addSpace() and removeSpace()
  - Call SpaceManager methods
  - Update activeSpaces list
  - Notify listeners
  - _Requirements: 3.3-3.7_

- [x] 5. UI Components: Reusable Widgets





  - Create SpaceCard widget
  - Create SpaceIcon widget
  - Create space-specific gradient header
  - Add space switcher button
  - _Requirements: 6.1-6.7_

- [x] 5.1 Create SpaceCard widget


  - Implement in `lib/features/spaces/ui/widgets/space_card.dart`
  - Show space icon, name, description
  - Visual states: default, selected, current
  - Tap handling
  - _Requirements: 2.2, 6.1-6.6_

- [x] 5.2 Create SpaceIcon widget


  - Implement in `lib/features/spaces/ui/widgets/space_icon.dart`
  - Map icon name to Lucide icon
  - Support gradient background
  - Configurable size
  - _Requirements: 6.3, 6.7_

- [x] 5.3 Update GradientHeader for spaces


  - Accept Space parameter
  - Use space gradient for background
  - Show space icon
  - Display space name and description
  - _Requirements: 6.1-6.6_

- [x] 5.4 Create space switcher button


  - Grid icon button in app bar
  - Only show when multiple active spaces
  - Navigate to space selector
  - _Requirements: 4.1, 4.2_

- [x] 6. Onboarding Flow



  - Create onboarding screen with 3 steps
  - Implement space selection step
  - Add progress indicators
  - Handle onboarding completion
  - _Requirements: 10.1-10.9_


- [x] 6.1 Create OnboardingScreen

  - Implement in `lib/features/spaces/ui/onboarding_screen.dart`
  - PageView for 3 steps
  - Progress dots indicator
  - _Requirements: 10.1, 10.2, 10.5_


- [x] 6.2 Implement Step 1: Welcome
  - Title: "Welcome to Your Personal Space"
  - Description of universal system
  - Value propositions (flexible, AI-powered, secure)
  - Continue button
  - _Requirements: 10.2_


- [x] 6.3 Implement Step 2: Space Selection
  - Display all 8 default spaces
  - Multi-select with visual feedback
  - Minimum 1 space required
  - Selection count display
  - _Requirements: 2.1-2.9, 10.3_


- [x] 6.4 Implement Step 3: Features Overview
  - Explain multi-modal input
  - Mention AI assistance
  - Highlight security
  - "Get Started" button

  - _Requirements: 10.4_

- [x] 6.5 Handle onboarding completion
  - Save selected spaces to storage
  - Set first space as current
  - Mark onboarding complete
  - Navigate to records list
  - _Requirements: 10.7, 10.8, 10.9_


- [x] 6.6 Add skip functionality

  - Skip button on steps 1-2
  - Jump to final step
  - _Requirements: 10.6_

- [x] 7. Space Selector Screen



  - Create space selector UI
  - Display active spaces
  - Show current space indicator
  - Add space management mode

  - _Requirements: 3.1-3.8, 4.1-4.8_


- [x] 7.1 Create SpaceSelectorScreen
  - Implement in `lib/features/spaces/ui/space_selector_screen.dart`
  - Two modes: view and manage
  - Back button navigation
  - _Requirements: 3.1, 4.1_


- [x] 7.2 Implement view mode
  - List all active spaces
  - Highlight current space
  - Tap to switch space
  - "Add More Spaces" button

  - _Requirements: 3.2, 4.1-4.4_

- [x] 7.3 Implement manage mode
  - Show all default spaces
  - Toggle selection state
  - Prevent deselecting last space
  - Save/Cancel buttons
  - _Requirements: 3.3-3.7_


- [x] 7.4 Add "Create Custom Space" button

  - Dashed border card
  - Navigate to create space screen
  - _Requirements: 7.1_

- [x] 8. Create Custom Space Screen




  - Build custom space creation form
  - Icon picker
  - Color picker
  - Category input
  - Validation and save
  - _Requirements: 7.1-7.10_

- [x] 8.1 Create CreateSpaceScreen


  - Implement in `lib/features/spaces/ui/create_space_screen.dart`
  - Form with TextFields and pickers
  - _Requirements: 7.1, 7.2_

- [x] 8.2 Implement name and description inputs


  - Name TextField with validation
  - Description TextField (optional)
  - _Requirements: 7.2, 7.3_

- [x] 8.3 Implement icon picker


  - Grid of Lucide icons
  - Search/filter functionality
  - Visual selection
  - _Requirements: 7.4_

- [x] 8.4 Implement color picker


  - Predefined gradient options
  - Visual preview
  - _Requirements: 7.5_

- [x] 8.5 Implement category input


  - Comma-separated TextField
  - Chip display of categories
  - Validation (at least one category)
  - _Requirements: 7.6_

- [x] 8.6 Handle save


  - Validate all fields
  - Call SpaceManager.createCustomSpace()
  - Show success message
  - Navigate back
  - _Requirements: 7.7-7.10_

- [x] 9. Update Records List




  - Filter records by current space
  - Update header with space identity
  - Show space-specific stats
  - Add space switcher button
  - _Requirements: 4.5, 4.6, 6.1-6.7, 9.1-9.4_

- [x] 9.1 Update RecordsListScreen


  - Inject SpaceProvider
  - Listen to current space changes
  - _Requirements: 4.5_

- [x] 9.2 Filter records by space


  - Query items where spaceId = currentSpace.id
  - Update list when space changes
  - _Requirements: 4.5, 5.4_

- [x] 9.3 Update header


  - Use space gradient
  - Show space icon
  - Display space name and description
  - Add space switcher button (if multiple spaces)
  - _Requirements: 4.1, 4.2, 6.1-6.7_

- [x] 9.4 Update stats cards


  - Count records in current space
  - Count attachments in current space
  - Count categories used in current space
  - _Requirements: 9.1-9.4_



- [x] 10. Update Add Record Flow



  - Associate new records with current space
  - Show space-specific categories
  - Update category dropdown
  - _Requirements: 5.1, 8.1-8.5_

- [x] 10.1 Update AddRecordScreen


  - Inject SpaceProvider
  - Get current space
  - _Requirements: 5.1_

- [x] 10.2 Set spaceId on new records

  - Use currentSpace.id when creating record
  - _Requirements: 5.2_

- [x] 10.3 Update category dropdown

  - Populate with currentSpace.categories
  - _Requirements: 8.1, 8.2_

- [x] 10.4 Update UI labels

  - "Add [Space Name] Record" title
  - Space-specific hints
  - _Requirements: 6.4, 6.5_

- [x] 11. Search and Filter Updates





  - Scope search to current space
  - Clear search on space switch
  - Update search placeholder
  - _Requirements: 13.1-13.6_

- [x] 11.1 Update search logic


  - Filter by spaceId in query
  - _Requirements: 13.1, 13.2_



- [x] 11.2 Handle space switching

  - Clear search query when space changes
  - Reset filters
  - _Requirements: 13.5_


- [x] 11.3 Update search placeholder

  - "Search in [Space Name]..."
  - _Requirements: 13.2_

- [x] 12. Navigation Updates





  - Add space selector to navigation
  - Update app initialization flow
  - Handle onboarding check
  - _Requirements: 10.1-10.9_

- [x] 12.1 Update app initialization


  - Check onboarding completion
  - Show onboarding if first time
  - Load spaces if onboarding complete
  - _Requirements: 10.7, 10.8_

- [x] 12.2 Add space selector route


  - Register route in app router
  - Handle navigation from records list
  - _Requirements: 3.1_

- [x] 13. Migration Execution





  - Run database migration on app start
  - Run user data migration
  - Add migration version tracking
  - _Requirements: 12.1-12.8_

- [x] 13.1 Implement migration check


  - Track migration version in SharedPreferences
  - Run migration if needed
  - _Requirements: 12.3_

- [x] 13.2 Execute database migration


  - Call SpaceMigration.migrate()
  - Log progress and results
  - Handle errors gracefully
  - _Requirements: 12.1-12.8_

- [x] 13.3 Execute user data migration


  - Set default space for existing users
  - Mark onboarding complete for existing users
  - _Requirements: 12.1_

- [x] 13.4 Update migration version


  - Save new version after successful migration
  - _Requirements: 12.3_

- [ ]* 14. Testing
  - Write unit tests for domain entities
  - Write unit tests for SpaceManager
  - Write integration tests for storage
  - Write widget tests for UI components
  - _Requirements: All_

- [ ]* 14.1 Unit tests for Space entity
  - Test validation logic
  - Test copyWith
  - Test JSON serialization
  - _Requirements: 1.1-1.3_

- [ ]* 14.2 Unit tests for SpaceManager
  - Test getActiveSpaces with various scenarios
  - Test space activation/deactivation
  - Test custom space creation
  - Test error cases (last space, invalid IDs)
  - _Requirements: 2.1-2.9, 3.1-3.8_

- [ ]* 14.3 Integration tests for storage
  - Test space persistence
  - Test migration
  - Test data integrity
  - _Requirements: 11.1-11.8, 12.1-12.8_

- [ ]* 14.4 Widget tests for onboarding
  - Test step navigation
  - Test space selection
  - Test completion flow
  - _Requirements: 10.1-10.9_

- [ ]* 14.5 Widget tests for space selector
  - Test space switching
  - Test space management
  - Test custom space creation
  - _Requirements: 3.1-3.8, 7.1-7.10_

- [x] 15. Documentation and Polish





  - Update README with spaces feature
  - Add spaces section to ARCHITECTURE.md
  - Update user guide
  - Add inline code documentation
  - _Requirements: All_

- [x] 15.1 Update README


  - Add Spaces System to features list
  - Explain universal information concept
  - _Requirements: All_

- [x] 15.2 Update ARCHITECTURE.md


  - Document spaces module structure
  - Explain data model changes
  - Add migration notes
  - _Requirements: All_

- [x] 15.3 Add code documentation


  - Document all public APIs
  - Add usage examples
  - Explain design decisions
  - _Requirements: All_

---

## Implementation Notes

### Task Execution Order
1. Start with Foundation (tasks 1.x) - establishes core models
2. Build Infrastructure (tasks 2.x) - enables data persistence
3. Create Application Layer (tasks 3.x-4.x) - business logic
4. Build UI Components (tasks 5.x) - reusable widgets
5. Implement Screens (tasks 6.x-8.x) - user-facing features
6. Update Existing Features (tasks 9.x-11.x) - integration
7. Handle Migration (task 13.x) - data migration
8. Test and Document (tasks 14.x-15.x) - quality assurance

### Dependencies
- Tasks 2.x depend on 1.x (need domain models)
- Tasks 3.x depend on 2.x (need storage)
- Tasks 4.x depend on 3.x (need services)
- Tasks 5.x-8.x depend on 4.x (need state management)
- Tasks 9.x-11.x depend on 5.x-8.x (need UI components)
- Task 13.x should run early in testing phase

### Testing Strategy
- Unit test each component as it's built
- Integration test after completing each major section
- Widget test UI components before moving to next screen
- Manual test full flow after completing all tasks

### Backward Compatibility
- All existing health records continue to work
- Migration is automatic and transparent
- RecordEntity remains as adapter layer
- No breaking changes to existing APIs

---

**Total Tasks**: 15 major tasks, ~60 subtasks
**Estimated Effort**: 6-8 weeks for full implementation
**Priority**: High - Foundation for universal system
