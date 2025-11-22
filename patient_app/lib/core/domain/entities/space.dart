import '../value_objects/space_gradient.dart';

/// Domain entity representing a life area or domain (e.g., Health, Education, Business)
/// 
/// Each space has its own visual identity (icon, gradient), categories, and description.
/// Spaces can be default (pre-configured) or custom (user-created).
class Space {
  /// Unique identifier (e.g., 'health', 'education')
  final String id;
  
  /// Display name (e.g., 'Health', 'Education')
  final String name;
  
  /// Lucide icon name (e.g., 'Heart', 'GraduationCap')
  final String icon;
  
  /// Gradient color scheme for visual identity
  final SpaceGradient gradient;
  
  /// Brief description of the space
  final String description;
  
  /// Space-specific categories (e.g., ['Checkup', 'Dental', 'Vision'] for Health)
  final List<String> categories;
  
  /// True for pre-defined spaces
  final bool isDefault;
  
  /// True for user-created spaces
  final bool isCustom;
  
  /// Creation timestamp
  final DateTime createdAt;

  Space({
    required this.id,
    required this.name,
    required this.icon,
    required this.gradient,
    required this.description,
    required this.categories,
    this.isDefault = false,
    this.isCustom = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now() {
    _validate();
  }

  /// Validates space properties
  /// Throws ArgumentError if validation fails
  void _validate() {
    if (id.trim().isEmpty) {
      throw ArgumentError('Space ID cannot be empty');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError('Space name cannot be empty');
    }
    if (categories.isEmpty) {
      throw ArgumentError('Space must have at least one category');
    }
  }

  /// Creates a copy of this space with updated fields
  Space copyWith({
    String? id,
    String? name,
    String? icon,
    SpaceGradient? gradient,
    String? description,
    List<String>? categories,
    bool? isDefault,
    bool? isCustom,
  }) {
    return Space(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      gradient: gradient ?? this.gradient,
      description: description ?? this.description,
      categories: categories ?? this.categories,
      isDefault: isDefault ?? this.isDefault,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt,
    );
  }

  /// Converts space to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'gradient': gradient.toJson(),
      'description': description,
      'categories': categories,
      'isDefault': isDefault,
      'isCustom': isCustom,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Creates space from JSON
  factory Space.fromJson(Map<String, dynamic> json) {
    return Space(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      gradient: SpaceGradient.fromJson(json['gradient'] as Map<String, dynamic>),
      description: json['description'] as String,
      categories: List<String>.from(json['categories'] as List),
      isDefault: json['isDefault'] as bool? ?? false,
      isCustom: json['isCustom'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Space &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Space(id: $id, name: $name)';
}
