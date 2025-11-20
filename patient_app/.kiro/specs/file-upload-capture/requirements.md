# Requirements Document

## Introduction

The File Upload Capture feature enables patients to add health records by uploading existing digital files (PDFs and images) from their device storage. This capability complements other multi-modal capture methods (photo, scan, voice) and provides a pathway for patients to import lab results, medical reports, prescriptions, and other health documents they have received electronically or downloaded from patient portals.

The feature integrates into the existing multi-modal capture launcher and follows the unified review-and-save flow established for other capture modes. All uploaded files are stored locally with full metadata preservation, supporting the app's local-first, privacy-focused architecture.

## Glossary

- **File Upload System**: The capture mode that allows patients to select and import files from device storage into the app
- **Patient**: The end user of the application who manages their personal health records
- **Capture Launcher**: The multi-modal entry screen that presents available capture modes to the patient
- **Session Directory**: The temporary storage location where captured artifacts are stored before being linked to a saved record
- **Attachment**: A file artifact linked to a health record, stored with metadata including path, MIME type, size, and capture timestamp
- **Review Screen**: The unified interface where patients can edit metadata and confirm captured content before saving
- **File Picker**: The platform-native interface for browsing and selecting files from device storage
- **MIME Type**: A standard identifier for file formats (e.g., application/pdf, image/jpeg)

## Requirements

### Requirement 1

**User Story:** As a patient, I want to upload PDF documents from my device, so that I can add lab results and medical reports I received electronically to my health records.

#### Acceptance Criteria

1. WHERE the File Upload mode is available, THE File Upload System SHALL display "Upload File" as an option in the Capture Launcher with an upload icon
2. WHEN the patient selects the File Upload option, THE File Upload System SHALL present the platform-native file picker filtered to PDF and image formats
3. WHEN the patient selects a valid PDF file, THE File Upload System SHALL copy the file to the Session Directory with a timestamped filename
4. WHEN the file copy completes successfully, THE File Upload System SHALL create an Attachment artifact with the file path, MIME type, size in bytes, and capture timestamp
5. WHEN the Attachment artifact is created, THE File Upload System SHALL navigate the patient to the Review Screen with the uploaded file metadata pre-populated

### Requirement 2

**User Story:** As a patient, I want to upload image files (JPEG, PNG) from my device, so that I can add photos of prescriptions, insurance cards, and other health documents I have saved.

#### Acceptance Criteria

1. WHEN the patient selects the File Upload option, THE File Upload System SHALL accept JPEG and PNG image formats in addition to PDF
2. WHEN the patient selects a valid image file, THE File Upload System SHALL determine the correct MIME type (image/jpeg or image/png) based on the file extension
3. WHEN an image file is uploaded, THE File Upload System SHALL create an Attachment artifact with type "photo" for display consistency with camera-captured images
4. WHEN a PDF file is uploaded, THE File Upload System SHALL create an Attachment artifact with type "documentScan" for display consistency with scanned documents

### Requirement 3

**User Story:** As a patient, I want to be prevented from uploading excessively large files, so that the app remains responsive and my device storage is not exhausted.

#### Acceptance Criteria

1. THE File Upload System SHALL enforce a maximum file size limit of 50 megabytes per upload
2. WHEN the patient selects a file exceeding 50 megabytes, THE File Upload System SHALL display an error message stating the file size and the maximum allowed size
3. WHEN a file size error occurs, THE File Upload System SHALL return the patient to the file picker to select a different file
4. WHEN the patient cancels the file picker, THE File Upload System SHALL return to the Capture Launcher without creating any artifacts

### Requirement 4

**User Story:** As a patient, I want clear feedback when file upload fails, so that I understand what went wrong and can try again.

#### Acceptance Criteria

1. WHEN the file picker cannot access the selected file, THE File Upload System SHALL display an error message "Could not access selected file"
2. WHEN the file copy operation fails, THE File Upload System SHALL display an error message including the failure reason
3. WHEN any error occurs during upload, THE File Upload System SHALL preserve the original file and not create partial or corrupted artifacts
4. WHEN an error is displayed, THE File Upload System SHALL provide the patient an option to retry or return to the Capture Launcher

### Requirement 5

**User Story:** As a patient, I want uploaded files to be stored securely on my device, so that my health information remains private and accessible offline.

#### Acceptance Criteria

1. THE File Upload System SHALL store uploaded files in the Session Directory within the app's private storage area
2. WHEN a file is copied to the Session Directory, THE File Upload System SHALL preserve the original file in its source location
3. THE File Upload System SHALL generate a unique timestamped filename to prevent naming conflicts
4. WHEN the patient saves the record from the Review Screen, THE File Upload System SHALL link the uploaded file as an Attachment to the saved record with the recordId populated

### Requirement 6

**User Story:** As a patient, I want the file upload feature to work consistently across Android and web platforms, so that I can manage my records regardless of which device I use.

#### Acceptance Criteria

1. THE File Upload System SHALL be available on Android devices with access to device storage
2. THE File Upload System SHALL be available on web browsers with support for the File API
3. WHEN the platform does not support file upload, THE File Upload System SHALL not display the Upload File option in the Capture Launcher
4. THE File Upload System SHALL use platform-appropriate file picker interfaces (native on Android, browser file input on web)
