import 'package:flutter/foundation.dart';

/// Universal entity representing any item of information in the system.
/// 
/// This is the core entity for the "Universal Personal Information System".
/// It replaces the domain-specific [RecordEntity] as the primary unit of storage.
/// 
/// Each item belongs to a [spaceId] (e.g., 'health', 'finance') and has a
/// specific [domainId] (e.g., 'medical_record', 'expense_entry') that determines
/// how its [data] should be interpreted.
@immutable
class InformationItem {
  /// Unique identifier (null before persistence)
  final int? id;
  
  /// The space this item belongs to (e.g., 'health', 'finance', 'career')
  final String spaceId;
  
  /// The specific domain type of this item (e.g., 'medical_visit', 'receipt')
  /// This maps to a registered DomainDefinition.
  final String domainId;
  
  /// Version of the schema used for the [data] map.
  /// Allows for schema evolution within a domain.
  final int schemaVersion;
  
  /// The actual content of the item, structured according to [domainId] and [schemaVersion].
  /// For a medical record, this might contain 'doctor', 'diagnosis', etc.
  final Map<String, dynamic> data;
  
  /// When this item was created
  final DateTime createdAt;
  
  /// When this item was last updated
  final DateTime updatedAt;
  
  /// When this item was deleted (soft delete)
  final DateTime? deletedAt;

  const InformationItem({
    this.id,
    required this.spaceId,
    required this.domainId,
    this.schemaVersion = 1,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  /// Creates a copy of this item with updated fields
  InformationItem copyWith({
    int? id,
    String? spaceId,
    String? domainId,
    int? schemaVersion,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return InformationItem(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      domainId: domainId ?? this.domainId,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is InformationItem &&
      other.id == id &&
      other.spaceId == spaceId &&
      other.domainId == domainId &&
      other.schemaVersion == schemaVersion &&
      mapEquals(other.data, data) &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.deletedAt == deletedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      spaceId.hashCode ^
      domainId.hashCode ^
      schemaVersion.hashCode ^
      data.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode ^
      deletedAt.hashCode;
  }

  @override
  String toString() {
    return 'InformationItem(id: $id, spaceId: $spaceId, domainId: $domainId, schemaVersion: $schemaVersion, createdAt: $createdAt)';
  }
}
