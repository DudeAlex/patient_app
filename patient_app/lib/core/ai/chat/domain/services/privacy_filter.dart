import 'package:patient_app/features/records/domain/entities/record.dart';

/// Filters records based on privacy settings and deletion status.
/// 
/// This service implements privacy filtering for Stage 6 intent-driven retrieval:
/// - Excludes records marked as deleted
/// - Excludes records marked as private
/// - Excludes records from other spaces (unless cross-space retrieval is allowed)
/// - Provides helper methods for individual record checks
class PrivacyFilter {
  /// Filters a list of records based on privacy settings.
  ///
  /// [records] The list of records to filter
  /// [activeSpaceId] The current active space ID to determine space access
  ///
  /// Returns a list of records that pass all privacy checks
  /// 
  /// Requirements: 6.1, 6.2, 6.3, 6.5
  List<RecordEntity> filter(List<RecordEntity> records, String activeSpaceId) {
    return records.where((record) => isAllowed(record, activeSpaceId)).toList();
  }

  /// Checks if a single record is allowed based on privacy settings.
  /// 
  /// [record] The record to check
  /// [activeSpaceId] The current active space ID to determine space access
  /// 
  /// Returns true if the record passes all privacy checks, false otherwise
  /// 
  /// Requirements: 6.1, 6.2, 6.3
  bool isAllowed(RecordEntity record, String activeSpaceId) {
    // Exclude if record is marked as deleted
    if (record.deletedAt != null) {
      return false;
    }
    
    // Exclude if record is marked as private
    if (_isPrivate(record)) {
      return false;
    }
    
    // Exclude if record is from a different space (unless cross-space allowed)
    // For now, we'll enforce space isolation by default
    if (record.spaceId != activeSpaceId) {
      return false;
    }
    
    return true;
  }
  
  /// Helper method to determine if a record is private.
  /// 
  /// Currently uses a simple heuristic - in a real implementation,
  /// this might check for specific private tags or metadata.
  /// 
  /// Requirements: 6.1
  bool _isPrivate(RecordEntity record) {
    // In the current RecordEntity implementation, there's no explicit 'isPrivate' field
    // This could be extended in the future to check for privacy indicators
    // For now, we can check for sensitive content indicators or specific tags
    
    // Check if the record has any privacy-related tags
    final privateTags = {'private', 'confidential', 'sensitive', 'personal'};
    for (final tag in record.tags) {
      if (privateTags.contains(tag.toLowerCase())) {
        return true;
      }
    }
    
    // Additional checks could be added here in the future
    // For example, checking specific types, content patterns, etc.
    
    return false;
 }
}