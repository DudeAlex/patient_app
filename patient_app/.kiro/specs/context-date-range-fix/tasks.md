# Implementation Plan

- [x] 1. Update DateRange model to support custom ranges




  - Add `DateRange.lastNDays(int days)` factory method with validation (1-1095 days)
  - Update existing factory methods to delegate to `lastNDays()` for consistency
  - Add assertion to ensure days are between 1 and 1095
  - _Requirements: 1.2, 6.6, 8.4_

- [x] 2. Update ContextConfigRepository validation





  - Modify `getDateRangeDays()` to accept any value between 1-1095 (not just 7/14/30)
  - Modify `setDateRangeDays()` to validate 1-1095 range
  - Update error messages to mention "up to 3 years"
  - _Requirements: 3.4, 3.5, 8.4, 8.5_

- [x] 3. Register ContextConfigRepository in dependency container




  - Register `ContextConfigRepository` in `AppContainer` during app initialization
  - Ensure registration happens early in startup sequence
  - Add logging to confirm successful registration
  - _Requirements: 1.1_

- [x] 4. Update spaceContextBuilderProvider to read date range setting





  - Change `spaceContextBuilderProvider` from `Provider` to `FutureProvider`
  - Read date range setting from `ContextConfigRepository`
  - Create `DateRange` using `lastNDays()` method
  - Pass configured date range to `SpaceContextBuilderImpl` constructor
  - Add logging for date range value and whether it's custom
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 5. Update spaceContextProvider to handle FutureProvider




  - Modify `spaceContextProvider` to await `spaceContextBuilderProvider.future`
  - Ensure proper error handling for provider initialization
  - _Requirements: 1.1_

- [x] 6. Add custom date range UI to Settings screen




  - Add state variables: `_isCustomDateRange`, `_customDaysController`, `_customDaysError`
  - Add "Custom" choice chip alongside preset options (7, 14, 30 days)
  - Show text input field when custom mode is selected
  - Add helper text: "Up to 3 years"
  - Add informational text about token limits and record prioritization
  - _Requirements: 8.1, 8.2, 8.3, 8.9_

- [ ] 7. Implement custom date range validation in UI

  - Validate input is a valid integer
  - Validate input is between 1 and 1095
  - Show error messages for invalid input
  - Prevent saving invalid values
  - _Requirements: 8.4, 8.5_

- [ ] 8. Update Settings screen to detect and display custom values
  - Modify `_loadContextConfig()` to detect custom values (not 7/14/30)
  - Set `_isCustomDateRange` flag appropriately
  - Populate text field with custom value when loading
  - Allow switching between preset and custom modes
  - _Requirements: 8.7, 8.8_

- [ ] 9. Add comprehensive logging for date range operations
  - Log when date range setting is read (include value and whether custom)
  - Log when default is used (include reason)
  - Log when DateRange is created (include start/end dates)
  - Log when user sets custom value (include previous value)
  - Log truncation events with large date ranges
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [ ] 10. Add confirmation messages for setting changes
  - Show snackbar when date range is updated
  - Include the new value in the message
  - Distinguish between preset and custom values in message
  - _Requirements: 7.2_

- [ ] 11. Write unit tests for DateRange.lastNDays()
  - Test that `lastNDays(7)` creates 7-day range
  - Test that `lastNDays(14)` creates 14-day range
  - Test that `lastNDays(30)` creates 30-day range
  - Test that `lastNDays(45)` creates 45-day range (custom)
  - Test that `lastNDays(1095)` creates 1095-day range (boundary)
  - Test that `lastNDays(1)` creates 1-day range (boundary)
  - Test that end date is always "now"
  - Test that start date is exactly N days before end
  - _Requirements: 5.1, 5.2, 5.4, 5.6_

- [ ] 12. Write unit tests for ContextConfigRepository validation
  - Test that values 1-1095 are accepted
  - Test that 0 is rejected
  - Test that negative values are rejected
  - Test that values > 1095 are rejected
  - Test that invalid stored values return default (14)
  - Test that missing setting returns default (14)
  - _Requirements: 5.1, 5.2, 5.4, 5.7_

- [ ] 13. Write unit tests for custom date range UI validation
  - Test that valid input (1-1095) is accepted
  - Test that invalid input shows error message
  - Test that non-numeric input shows error message
  - Test that error messages are cleared when valid input is entered
  - Test that preset and custom modes can be switched
  - _Requirements: 5.1, 5.4_

- [ ] 14. Write property test for date range setting round-trip
  - **Property 1: Date range setting is read from repository**
  - Generate random date range values (1-1095)
  - Set via `setDateRangeDays()`
  - Read via `getDateRangeDays()`
  - Assert returned value equals set value
  - _Requirements: 5.5, 1.1_

- [ ] 15. Write property test for date range calculation correctness
  - **Property 2: Date range calculation matches setting**
  - Generate random date range values (1-1095)
  - Create `DateRange` using `lastNDays(n)`
  - Assert `end.difference(start).inDays` equals input value
  - _Requirements: 5.5, 1.2_

- [ ] 16. Write property test for invalid values using default
  - **Property 4: Default fallback is consistent**
  - Generate random invalid integers (< 1 or > 1095)
  - Attempt to set via `setDateRangeDays()` (should throw)
  - OR: Store invalid value in SharedPreferences
  - Read via `getDateRangeDays()`
  - Assert returned value is 14 (default)
  - _Requirements: 5.5, 3.1, 3.2, 3.3_

- [ ] 17. Write property test for token budget enforcement
  - **Property 7: Token budget enforcement with large date ranges**
  - Generate random date ranges (including 1095)
  - Create 50-200 test records
  - Build space context
  - Assert token usage never exceeds 2000 tokens
  - Assert records are truncated if necessary
  - _Requirements: 5.5, 3.1, 3.2, 3.3_

- [ ] 18. Write integration test for end-to-end date range application
  - Set date range to 7 days in Settings
  - Send AI chat message
  - Verify context assembly log shows 7-day range
  - Verify AI response mentions "last 7 days"
  - Repeat for 30 days and custom value (e.g., 45 days)
  - _Requirements: 5.3, 5.4, 1.1, 1.2, 1.3, 4.1, 4.2_

- [ ] 19. Write integration test for setting persistence
  - Set date range to custom value (e.g., 90 days)
  - Restart app (simulate by recreating provider)
  - Send AI chat message
  - Verify 90-day range is used
  - _Requirements: 5.3, 7.5_

- [ ] 20. Write integration test for setting changes
  - Set date range to 7 days
  - Send AI chat message (verify 7 days in logs)
  - Change to 1095 days
  - Send another message (verify 1095 days in logs)
  - Verify AI responses mention correct ranges
  - _Requirements: 5.3, 1.3, 7.3_

- [ ] 21. Write integration test for large date ranges with many records
  - Create 100 test records spanning 3 years
  - Set date range to 1095 days
  - Build space context
  - Verify only top 20 records are considered (maxRecords limit)
  - Verify token budget is not exceeded
  - Verify most recent records are prioritized
  - Verify truncation logging is present
  - _Requirements: 5.3, 3.1, 3.2, 3.3_

- [ ] 22. Manual testing and verification
  - Test preset options (7, 14, 30 days) in Settings UI
  - Test custom input with valid values (1, 45, 90, 365, 1095)
  - Test custom input with invalid values (0, -1, 1096, "abc")
  - Verify error messages are clear and helpful
  - Verify confirmation messages appear when setting is changed
  - Send AI chat messages with different date ranges
  - Verify AI responses mention correct date ranges
  - Verify logs show correct date range values
  - Test with large date range (1095 days) and many records
  - Verify performance is acceptable (< 200ms context assembly)
  - Verify token budget is enforced
  - _Requirements: All_

- [ ] 23. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
