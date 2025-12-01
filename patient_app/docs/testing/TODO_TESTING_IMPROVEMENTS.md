# Testing Improvements TODO

## High Priority

### 1. Bulk Test Data Import Feature
**Status:** Not Started  
**Priority:** High  
**Estimated Effort:** 2-3 hours

**Description:**
Create a JSON-based bulk data import feature to easily populate the app with test records instead of manually adding them one by one.

**Requirements:**
- Create JSON schema for test records
- Support importing 50-100+ records at once
- **Support multiple space categories:**
  - **Health:** blood pressure, weight, medications, doctor visits, lab results, symptoms, exercise logs
  - **Business:** meetings, proposals, client notes, project updates, invoices, contracts, tasks
  - **Education:** assignments, courses, study notes, exams, research, lectures, grades
- Support different date ranges (last 7 days, 14 days, 30 days, older)
- Include records with varying viewCounts for relevance testing
- Add import functionality accessible from Settings or Debug menu
- Support importing to specific spaces or all spaces at once

**Use Cases:**
- Stage 4 manual testing (needs 50+ records)
- Token budget testing (needs 100+ records)
- Performance testing with large datasets
- Relevance scoring validation
- Context truncation testing
- Multi-space testing (Health, Business, Education)
- Space isolation validation
- Cross-space context testing

**Proposed Implementation:**

1. **JSON Schema:**
```json
{
  "records": [
    {
      "title": "Blood Pressure Reading",
      "type": "vital_signs",
      "date": "2025-11-28T10:00:00Z",
      "content": "120/80 mmHg",
      "spaceId": "health",
      "viewCount": 5,
      "tags": ["blood_pressure", "vitals"]
    },
    {
      "title": "Weight Measurement",
      "type": "vital_signs",
      "date": "2025-11-27T08:00:00Z",
      "content": "75 kg",
      "spaceId": "health",
      "viewCount": 2,
      "tags": ["weight", "vitals"]
    },
    {
      "title": "Project Kickoff Meeting",
      "type": "meeting",
      "date": "2025-11-28T14:00:00Z",
      "content": "Discussed Q1 goals and deliverables",
      "spaceId": "business",
      "viewCount": 3,
      "tags": ["meeting", "project", "planning"]
    },
    {
      "title": "Client Proposal Draft",
      "type": "document",
      "date": "2025-11-27T16:30:00Z",
      "content": "Initial proposal for ABC Corp project",
      "spaceId": "business",
      "viewCount": 8,
      "tags": ["proposal", "client", "document"]
    },
    {
      "title": "React Hooks Tutorial",
      "type": "learning",
      "date": "2025-11-26T20:00:00Z",
      "content": "Completed advanced hooks course on Udemy",
      "spaceId": "education",
      "viewCount": 4,
      "tags": ["react", "programming", "course"]
    },
    {
      "title": "Math Assignment 5",
      "type": "assignment",
      "date": "2025-11-25T18:00:00Z",
      "content": "Calculus problems - derivatives and integrals",
      "spaceId": "education",
      "viewCount": 6,
      "tags": ["math", "calculus", "homework"]
    }
  ]
}
```

2. **Features:**
   - Import from JSON file (file picker)
   - Import from assets (pre-packaged test data)
   - Clear all test data option
   - Generate random test data option
   - Preview before import
   - Validation of JSON structure

3. **UI Location:**
   - Settings → Developer Options → Import Test Data
   - Or: Debug menu (if exists)
   - Or: Hidden gesture (long press on app logo)

4. **Sample Data Sets:**
   - `test_data_small.json` - 20 records (mixed spaces)
   - `test_data_medium.json` - 50 records (mixed spaces)
   - `test_data_large.json` - 100 records (mixed spaces)
   - `test_data_stage4.json` - Optimized for Stage 4 testing
   - `test_data_health.json` - Health-specific records
   - `test_data_business.json` - Business-specific records
   - `test_data_education.json` - Education-specific records

**Benefits:**
- ✅ Faster testing workflow
- ✅ Consistent test data across test runs
- ✅ Easy to test edge cases
- ✅ Reproducible test scenarios
- ✅ Can test with realistic data volumes
- ✅ Saves hours of manual data entry

**Files to Create:**
- `lib/features/testing/bulk_import_service.dart`
- `lib/features/testing/ui/bulk_import_screen.dart`
- `assets/test_data/test_data_small.json` (mixed spaces)
- `assets/test_data/test_data_medium.json` (mixed spaces)
- `assets/test_data/test_data_large.json` (mixed spaces)
- `assets/test_data/test_data_stage4.json` (optimized for Stage 4)
- `assets/test_data/health/test_data_health_small.json`
- `assets/test_data/health/test_data_health_large.json`
- `assets/test_data/business/test_data_business_small.json`
- `assets/test_data/business/test_data_business_large.json`
- `assets/test_data/education/test_data_education_small.json`
- `assets/test_data/education/test_data_education_large.json`

**Related:**
- Manual Testing Guide needs update to reference this feature
- Add to developer documentation

---

## Medium Priority

### 2. Automated Test Data Generator
**Status:** Not Started  
**Priority:** Medium  
**Estimated Effort:** 1-2 hours

**Description:**
Add a feature to generate random test data programmatically with configurable parameters.

**Features:**
- Generate N records with random dates
- Configurable date range
- Random record types
- Random viewCounts (with distribution)
- Random content based on templates

**UI:**
```
Generate Test Data
- Number of records: [slider 10-200]
- Date range: [dropdown: 7/14/30/90 days]
- Include old records: [checkbox]
- ViewCount distribution: [dropdown: uniform/normal/skewed]
[Generate] [Cancel]
```

---

## Low Priority

### 3. Test Data Profiles
**Status:** Not Started  
**Priority:** Low  
**Estimated Effort:** 1 hour

**Description:**
Pre-defined test data profiles for common testing scenarios.

**Profiles:**
- "Stage 4 Testing" - Optimized for token optimization testing
- "Performance Testing" - Large dataset with 500+ records
- "Relevance Testing" - Records with varied viewCounts
- "Edge Cases" - Empty records, very long content, special characters
- "Minimal" - Just enough data to test basic functionality

---

## Notes

- This feature should be **debug/development only** (not in production builds)
- Consider adding a "Test Mode" flag in app settings
- Add clear warnings that imported data is for testing only
- Provide easy way to clear all test data
- Consider adding export functionality to save current data as JSON

---

**Created:** November 29, 2024  
**Last Updated:** November 29, 2024  
**Status:** Pending Implementation
