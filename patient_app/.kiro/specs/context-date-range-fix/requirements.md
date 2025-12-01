# Requirements Document

## Introduction

The AI chat system currently has a date range setting in the Settings UI that allows users to choose 7, 14, or 30 days for context filtering. However, the setting is not being properly applied when building the space context for AI chat requests. The system consistently uses a 14-day range regardless of the user's selected setting. This specification defines the fix to ensure the user's date range preference is correctly read and applied during context assembly.

## Glossary

- **Date Range Setting**: User-configurable preference for how many days of records to include in AI context (preset options: 7, 14, 30 days, or custom value)
- **Custom Date Range**: User-specified number of days (1-1095, approximately 3 years) for context filtering
- **Preset Date Range**: Quick-select options (7, 14, or 30 days) for common use cases
- **Space Context Assembly**: Process of gathering and filtering user records to provide to the AI
- **Context Date Range**: The actual start and end dates calculated based on the date range setting
- **Settings Repository**: Data access layer for reading and writing user preferences
- **AI Chat Service**: Service responsible for sending chat messages and building context

## Requirements

### Requirement 1

**User Story:** As a user, I want my selected date range setting to be applied when the AI builds context, so that the AI only sees records from my chosen time period.

#### Acceptance Criteria

1. WHEN the System builds space context for AI chat, THE System SHALL read the current date range setting from Settings
2. WHEN calculating the context date range, THE System SHALL use the user's selected value (preset or custom)
3. WHEN the user changes the date range setting, THE System SHALL apply the new value to subsequent AI chat requests
4. THE System SHALL never use a hardcoded default date range when a user setting exists
5. WHEN the AI responds, THE System SHALL mention the correct date range in its response (e.g., "from the last 7 days" or "from the last 45 days")

### Requirement 2

**User Story:** As a developer, I want comprehensive logging of date range application, so that I can verify the setting is being used correctly.

#### Acceptance Criteria

1. WHEN building space context, THE System SHALL log the date range setting value read from Settings
2. WHEN building space context, THE System SHALL log the calculated start and end dates
3. WHEN building space context, THE System SHALL log the number of days in the date range
4. THE System SHALL log any errors reading the date range setting
5. THE System SHALL log when the default date range is used due to missing setting

### Requirement 3

**User Story:** As a developer, I want the date range setting to have a sensible default, so that the system works correctly for new users.

#### Acceptance Criteria

1. WHEN a user has not set a date range preference, THE System SHALL use 14 days as the default
2. WHEN the date range setting is invalid or corrupted, THE System SHALL fall back to 14 days
3. WHEN using the default date range, THE System SHALL log that the default is being used
4. THE System SHALL validate that the date range setting is between 1 and 1095 days (approximately 3 years)
5. THE System SHALL reject invalid date range values (less than 1 or greater than 1095) and use the default instead

### Requirement 4

**User Story:** As a user, I want the AI to accurately describe the time period it's looking at, so that I understand what information it has access to.

#### Acceptance Criteria

1. WHEN the AI responds with record information, THE System SHALL include the actual date range used in the system prompt
2. WHEN the date range is any valid value, THE System SHALL instruct the AI to say "from the last N days" where N is the configured value
3. THE System SHALL include the specific start and end dates in the system prompt for AI reference
4. WHEN the date range is a custom value, THE System SHALL format it the same way as preset values
5. THE System SHALL never hardcode specific day values in the AI prompt logic

### Requirement 5

**User Story:** As a developer, I want to test that the date range setting is correctly applied, so that I can prevent regressions.

#### Acceptance Criteria

1. THE System SHALL have unit tests verifying date range setting is read from Settings
2. THE System SHALL have unit tests verifying date range calculation uses the setting value
3. THE System SHALL have integration tests verifying end-to-end date range application
4. THE System SHALL have tests for preset values (7, 14, 30 days) and custom values
5. THE System SHALL have tests for default fallback behavior when setting is missing
6. THE System SHALL have tests for boundary values (1 day, 1095 days)
7. THE System SHALL have tests for invalid values (0, negative, > 1095)

### Requirement 6

**User Story:** As a developer, I want to identify where the date range is currently hardcoded, so that I can fix all instances.

#### Acceptance Criteria

1. THE System SHALL identify all code locations where date range is calculated
2. THE System SHALL identify all code locations where Duration(days: 14) or similar hardcoded values exist
3. THE System SHALL replace hardcoded date ranges with setting-based values
4. THE System SHALL ensure no other hardcoded date ranges remain in the codebase
5. THE System SHALL document the correct pattern for reading date range settings
6. THE System SHALL support any integer value between 1 and 1095 days (approximately 3 years)

### Requirement 7

**User Story:** As a user, I want immediate feedback when I change the date range setting, so that I know my preference has been saved.

#### Acceptance Criteria

1. WHEN the user changes the date range setting in Settings UI, THE System SHALL save the new value immediately
2. WHEN the user changes the date range setting, THE System SHALL show a confirmation message
3. WHEN the user returns to the AI chat after changing the setting, THE System SHALL use the new date range
4. THE System SHALL not require app restart for date range changes to take effect
5. THE System SHALL persist the date range setting across app restarts

### Requirement 8

**User Story:** As a user, I want to enter a custom date range value, so that I can control exactly how much history the AI sees.

#### Acceptance Criteria

1. THE System SHALL provide preset options (7, 14, 30 days) as quick-select buttons
2. THE System SHALL provide a "Custom" option that allows entering any number of days
3. WHEN the user selects "Custom", THE System SHALL show a text input field for entering days
4. WHEN the user enters a custom value, THE System SHALL validate it is between 1 and 1095 (approximately 3 years)
5. WHEN the user enters an invalid value, THE System SHALL show an error message and not save the value
6. WHEN the user enters a valid custom value, THE System SHALL save it and use it for AI context
7. THE System SHALL display the current custom value when the user returns to Settings
8. THE System SHALL allow switching between preset and custom values at any time
9. THE System SHALL provide helpful hints about the maximum range (e.g., "Up to 3 years")

