# Requirements Document

## Introduction

When users take a photo or scan a document, there is a delay while the system performs quality analysis (clarity check, OCR extraction). During this delay, the capture launcher screen remains visible in the background, creating a confusing user experience where users can see and potentially interact with the launcher while processing is happening. The system needs to display a processing indicator immediately after capture to provide clear feedback and prevent interaction during analysis.

## Glossary

- **Photo Capture Service**: The service that handles camera photo capture, file storage, clarity analysis, and OCR extraction
- **Processing Indicator**: A visual overlay showing a loading spinner and "Checking clarity..." message
- **Clarity Analysis**: The process of analyzing photo sharpness/blur after capture
- **OCR Extraction**: Optical Character Recognition text extraction from captured images
- **Capture Context**: The context object passed to capture modes containing callbacks including `onProcessing`
- **Processing Overlay**: The UI component that blocks interaction and shows processing status

## Requirements

### Requirement 1

**User Story:** As a user taking a photo, I want to see a processing indicator immediately after capture, so that I understand the app is working and don't try to interact with the launcher screen.

#### Acceptance Criteria

1. WHEN the user captures a photo, THE System SHALL display the processing overlay immediately after the camera closes
2. WHILE the photo is being stored to disk, THE System SHALL keep the processing overlay visible
3. WHILE clarity analysis is running, THE System SHALL keep the processing overlay visible with "Checking clarity..." message
4. WHILE OCR extraction is running, THE System SHALL keep the processing overlay visible
5. WHEN all processing completes, THE System SHALL hide the processing overlay before showing any quality prompts

### Requirement 2

**User Story:** As a user, I want the capture launcher screen to be blocked during processing, so that I cannot accidentally trigger another capture while analysis is happening.

#### Acceptance Criteria

1. WHEN the processing overlay is visible, THE System SHALL prevent all touch interactions with the capture launcher
2. WHEN the processing overlay is visible, THE System SHALL prevent navigation away from the capture launcher
3. THE processing overlay SHALL use a semi-transparent black background to clearly indicate the launcher is blocked
4. THE processing overlay SHALL display a centered loading spinner
5. THE processing overlay SHALL display the text "Checking clarity..." below the spinner

### Requirement 3

**User Story:** As a developer, I want the photo capture service to use the same processing indicator pattern as document scan and voice capture, so that all capture modes provide consistent user experience.

#### Acceptance Criteria

1. THE Photo Capture Service SHALL call `context.onProcessing?.call(true)` before starting clarity analysis
2. THE Photo Capture Service SHALL call `context.onProcessing?.call(false)` after completing all analysis
3. THE Photo Capture Service SHALL call `context.onProcessing?.call(false)` in a finally block to ensure it's called even if analysis fails
4. THE Photo Capture Service SHALL follow the same pattern used by Document Scan Service and Voice Capture Service
5. THE processing indicator SHALL be controlled by the same `onProcessing` callback mechanism used by other capture modes

### Requirement 4

**User Story:** As a user, I want the processing indicator to appear for the appropriate duration, so that I see feedback for long operations but don't see unnecessary delays for fast operations.

#### Acceptance Criteria

1. WHEN clarity analysis takes less than 100 milliseconds, THE System SHALL still show the processing indicator for the full duration
2. WHEN clarity analysis takes more than 100 milliseconds, THE System SHALL show the processing indicator for the actual duration
3. THE System SHALL NOT add artificial delays to the processing indicator
4. THE System SHALL hide the processing indicator immediately when processing completes
5. THE System SHALL show the processing indicator even if clarity analyzer is null or disabled

### Requirement 5

**User Story:** As a user experiencing an error during photo processing, I want the processing indicator to be hidden, so that I can see and interact with error messages.

#### Acceptance Criteria

1. WHEN photo capture fails with an exception, THE System SHALL hide the processing indicator
2. WHEN clarity analysis fails with an exception, THE System SHALL hide the processing indicator
3. WHEN OCR extraction fails with an exception, THE System SHALL hide the processing indicator
4. THE System SHALL ensure `onProcessing(false)` is called in the finally block regardless of success or failure
5. THE System SHALL allow error dialogs and snackbars to be displayed after hiding the processing indicator
