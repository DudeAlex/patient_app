# Design Document: Universal Spaces System

## Overview

The Universal Spaces System transforms the Patient App into a flexible personal information platform by introducing "spaces" - distinct life areas that users can organize independently. This design maintains backward compatibility with existing health records while enabling expansion into education, home life, business, finance, travel, family, and creative domains.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Onboarding  │  │Space Selector│  │ Records List │     │
│  │    Screen    │  │    Screen    │  │  (Filtered)  │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                   Application Layer                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │Space Manager │  │  Item Repo   │  │Space Storage │     │
│  │   Service    │  │  (Filtered)  │  │   Service    │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                     Domain Layer                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │Space Entity  │  │  Item Entity │  │Space Registry│     │
│  │  (8 default) │  │ (with spaceId)│ │  (Templates) │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                   Infrastructure Layer                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Isar Storage │  │SharedPrefs   │  │  Migration   │     │
│  │ (Items+Meta) │  │(Space Config)│  │   Service    │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

### Module Structure

```
lib/
├── core/
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── space.dart              # Space entity
│   │   │   └── information_item.dart   # Universal item entity
│   │   └── value_objects/
│   │       └── space_id.dart           # Space ID value object
│   ├── application/
│   │   ├── services/
│   │   │   ├── space_manager.dart      # Space management logic
│   │   │   └── space_storage.dart      # Space persistence
│   │   └── ports/
│   │       └── space_repository.dart   # Space repo interface
│   └── infrastructure/
│       ├── repositories/
│       │   └── space_repository_impl.dart
│       └── storage/
│           └── space_preferences.dart  # SharedPreferences wrapper
├── features/
│   ├── spaces/
│   │   ├── domain/
│   │   │   └── space_registry.dart     # Default space templates
│   │   ├── ui/
│   │   │   ├── onboarding_screen.dart
│   │   │   ├── space_selector_screen.dart
│   │   │   ├── create_space_screen.dart
│   │   │   └── widgets/
│   │   │       ├── space_card.dart
│   │   │       └── space_icon.dart
│   │   └── providers/
│   │       └── space_provider.dart     # State management
│   └── records/
│       ├── domain/
│       │   └── entities/
│       │       └── record.dart         # Updated with spaceId
│       └── ui/
│           └── records_list_screen.dart # Filtered by space
└── ui/
    └── theme/
        └── space_gradients.dart        # Space-specific gradients
```

## Data Models

### Space Entity

```dart
/// Domain entity representing a life area or domain
class Space {
  final String id;              // Unique identifier (e.g., 'health', 'education')
  final String name;            // Display name (e.g., 'Health', 'Education')
  final String icon;            // Lucide icon name (e.g., 'Heart', 'GraduationCap')
  final SpaceGradient gradient; // Gradient color scheme
  final String description;     // Brief description of the space
  final List<String> categories; // Space-specific categories
  final bool isDefault;         // True for pre-defined spaces
  final bool isCustom;          // True for user-created spaces
  final DateTime createdAt;     // Creation timestamp
  
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
  
  factory Space.fromJson(Map<String, dynamic> json) {
    return Space(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      gradient: SpaceGradient.fromJson(json['gradient']),
      description: json['description'],
      categories: List<String>.from(json['categories']),
      isDefault: json['isDefault'] ?? false,
      isCustom: json['isCustom'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
```

### Space Gradient

```dart
/// Value object for space gradient colors
class SpaceGradient {
  final Color startColor;
  final Color endColor;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  
  const SpaceGradient({
    required this.startColor,
    required this.endColor,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });
  
  LinearGradient toLinearGradient() {
    return LinearGradient(
      begin: begin,
      end: end,
      colors: [startColor, endColor],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'startColor': startColor.value,
      'endColor': endColor.value,
    };
  }
  
  factory SpaceGradient.fromJson(Map<String, dynamic> json) {
    return SpaceGradient(
      startColor: Color(json['startColor']),
      endColor: Color(json['endColor']),
    );
  }
}
```

### Information Item (Updated Record)

```dart
/// Universal information item (replaces HealthRecord)
/// Maintains backward compatibility while supporting multiple spaces
class InformationItem {
  final int? id;
  final String spaceId;         // NEW: Associates item with a space
  final String category;        // Space-specific category
  final DateTime date;
  final String title;
  final String? content;
  final List<String> tags;
  final List<Attachment> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  
  InformationItem({
    this.id,
    required this.spaceId,
    required this.category,
    required this.date,
    required this.title,
    this.content,
    List<String>? tags,
    List<Attachment>? attachments,
    required this.createdAt,
    required DateTime updatedAt,
    this.deletedAt,
  }) : tags = List<String>.unmodifiable(tags ?? const []),
       attachments = List<Attachment>.unmodifiable(attachments ?? const []),
       updatedAt = _validateUpdatedAt(createdAt, updatedAt) {
    _validate();
  }
  
  void _validate() {
    if (spaceId.trim().isEmpty) {
      throw ArgumentError('Space ID cannot be empty');
    }
    if (category.trim().isEmpty) {
      throw ArgumentError('Category cannot be empty');
    }
    if (title.trim().isEmpty) {
      throw ArgumentError('Title cannot be empty');
    }
  }
  
  static DateTime _validateUpdatedAt(DateTime createdAt, DateTime updatedAt) {
    if (updatedAt.isBefore(createdAt)) {
      throw ArgumentError('updatedAt cannot be before createdAt');
    }
    return updatedAt;
  }
}
```

### Isar Schema (Migration)

```dart
@collection
class Item {
  Id id = Isar.autoIncrement;
  
  late String spaceId;          // NEW: Space association
  late String category;         // Was 'type'
  late DateTime date;
  late String title;
  String? content;              // Was 'text'
  List<String> tags = [];
  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? deletedAt;
  
  // Composite index for efficient space-based queries
  @Index(composite: [CompositeIndex('category'), CompositeIndex('date')])
  String get spaceCategoryDateIndex => '$spaceId-$category';
  
  // Backward compatibility: default to 'health' for old records
  @ignore
  String get effectiveSpaceId => spaceId.isEmpty ? 'health' : spaceId;
}
```

## Components and Interfaces

### Space Manager Service

```dart
/// Core service for managing spaces
class SpaceManager {
  final SpaceRepository _repository;
  final SpaceRegistry _registry;
  
  SpaceManager(this._repository, this._registry);
  
  /// Get all active spaces for the current user
  Future<List<Space>> getActiveSpaces() async {
    final activeIds = await _repository.getActiveSpaceIds();
    if (activeIds.isEmpty) {
      // Default to Health space if none selected
      return [_registry.getDefaultSpace('health')];
    }
    
    final spaces = <Space>[];
    for (final id in activeIds) {
      final space = await _getSpaceById(id);
      if (space != null) spaces.add(space);
    }
    return spaces;
  }
  
  /// Get space by ID (checks custom spaces first, then defaults)
  Future<Space?> _getSpaceById(String id) async {
    // Check custom spaces
    final customSpaces = await _repository.getCustomSpaces();
    final custom = customSpaces.firstWhere(
      (s) => s.id == id,
      orElse: () => null,
    );
    if (custom != null) return custom;
    
    // Check default spaces
    return _registry.getDefaultSpace(id);
  }
  
  /// Get current active space
  Future<Space> getCurrentSpace() async {
    final currentId = await _repository.getCurrentSpaceId();
    if (currentId != null) {
      final space = await _getSpaceById(currentId);
      if (space != null) return space;
    }
    
    // Fallback to first active space or Health
    final activeSpaces = await getActiveSpaces();
    return activeSpaces.first;
  }
  
  /// Set current active space
  Future<void> setCurrentSpace(String spaceId) async {
    await _repository.setCurrentSpaceId(spaceId);
  }
  
  /// Add space to active list
  Future<void> activateSpace(String spaceId) async {
    final activeIds = await _repository.getActiveSpaceIds();
    if (!activeIds.contains(spaceId)) {
      activeIds.add(spaceId);
      await _repository.setActiveSpaceIds(activeIds);
    }
  }
  
  /// Remove space from active list (must keep at least one)
  Future<void> deactivateSpace(String spaceId) async {
    final activeIds = await _repository.getActiveSpaceIds();
    if (activeIds.length <= 1) {
      throw StateError('Cannot deactivate the last space');
    }
    
    activeIds.remove(spaceId);
    await _repository.setActiveSpaceIds(activeIds);
    
    // If deactivating current space, switch to first remaining
    final currentId = await _repository.getCurrentSpaceId();
    if (currentId == spaceId) {
      await _repository.setCurrentSpaceId(activeIds.first);
    }
  }
  
  /// Create custom space
  Future<Space> createCustomSpace({
    required String name,
    required String icon,
    required SpaceGradient gradient,
    required String description,
    required List<String> categories,
  }) async {
    final id = _generateSpaceId(name);
    final space = Space(
      id: id,
      name: name,
      icon: icon,
      gradient: gradient,
      description: description,
      categories: categories,
      isCustom: true,
    );
    
    await _repository.saveCustomSpace(space);
    await activateSpace(id);
    
    return space;
  }
  
  String _generateSpaceId(String name) {
    return name.toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
```

### Space Registry

```dart
/// Registry of default space templates
class SpaceRegistry {
  static final Map<String, Space> _defaultSpaces = {
    'health': Space(
      id: 'health',
      name: 'Health',
      icon: 'Heart',
      gradient: SpaceGradient(
        startColor: Color(0xFFEF4444),
        endColor: Color(0xFFEC4899),
      ),
      description: 'Medical records, appointments, medications, and wellness',
      categories: ['Checkup', 'Dental', 'Vision', 'Lab', 'Medication', 'Vaccine', 'Therapy', 'Other'],
      isDefault: true,
    ),
    'education': Space(
      id: 'education',
      name: 'Education',
      icon: 'GraduationCap',
      gradient: SpaceGradient(
        startColor: Color(0xFF3B82F6),
        endColor: Color(0xFF06B6D4),
      ),
      description: 'Courses, notes, assignments, research, and learning materials',
      categories: ['Course', 'Assignment', 'Research', 'Notes', 'Project', 'Reading', 'Certification', 'Other'],
      isDefault: true,
    ),
    // ... other 6 default spaces
  };
  
  Space? getDefaultSpace(String id) => _defaultSpaces[id];
  
  List<Space> getAllDefaultSpaces() => _defaultSpaces.values.toList();
  
  bool isDefaultSpace(String id) => _defaultSpaces.containsKey(id);
}
```

### Space Repository Interface

```dart
abstract class SpaceRepository {
  Future<List<String>> getActiveSpaceIds();
  Future<void> setActiveSpaceIds(List<String> ids);
  
  Future<String?> getCurrentSpaceId();
  Future<void> setCurrentSpaceId(String id);
  
  Future<List<Space>> getCustomSpaces();
  Future<void> saveCustomSpace(Space space);
  Future<void> deleteCustomSpace(String id);
  
  Future<bool> hasCompletedOnboarding();
  Future<void> setOnboardingComplete();
}
```

## Error Handling

### Space-Related Errors

```dart
class SpaceError extends Error {
  final String message;
  SpaceError(this.message);
}

class SpaceNotFoundError extends SpaceError {
  SpaceNotFoundError(String spaceId) 
    : super('Space not found: $spaceId');
}

class InvalidSpaceError extends SpaceError {
  InvalidSpaceError(String reason) 
    : super('Invalid space: $reason');
}

class LastSpaceError extends SpaceError {
  LastSpaceError() 
    : super('Cannot remove the last active space');
}
```

## Testing Strategy

### Unit Tests

1. **Space Entity Tests**
   - Validation logic
   - Copy with functionality
   - JSON serialization/deserialization

2. **Space Manager Tests**
   - Get active spaces
   - Switch current space
   - Activate/deactivate spaces
   - Create custom spaces
   - Handle edge cases (last space, invalid IDs)

3. **Space Registry Tests**
   - Default space retrieval
   - All default spaces present
   - Correct categories per space

### Integration Tests

1. **Space Persistence Tests**
   - Save and retrieve active spaces
   - Save and retrieve custom spaces
   - Persist current space selection

2. **Migration Tests**
   - Existing records get spaceId='health'
   - No data loss during migration
   - Backward compatibility maintained

### Widget Tests

1. **Onboarding Screen Tests**
   - Step navigation
   - Space selection
   - Minimum one space required
   - Completion saves configuration

2. **Space Selector Tests**
   - Display active spaces
   - Switch between spaces
   - Add/remove spaces
   - Create custom space flow

## Migration Strategy

### Database Migration

```dart
class SpaceMigration {
  final Isar _isar;
  
  Future<void> migrate() async {
    print('[Migration] Starting space system migration...');
    
    await _isar.writeTxn(() async {
      // Get all items without spaceId
      final items = await _isar.items
          .filter()
          .spaceIdIsEmpty()
          .findAll();
      
      print('[Migration] Found ${items.length} items to migrate');
      
      // Set spaceId to 'health' for all existing records
      for (final item in items) {
        item.spaceId = 'health';
      }
      
      // Save updated items
      await _isar.items.putAll(items);
      
      print('[Migration] Migration complete');
    });
    
    // Verify migration
    final unmigrated = await _isar.items
        .filter()
        .spaceIdIsEmpty()
        .count();
    
    if (unmigrated > 0) {
      throw StateError('Migration failed: $unmigrated items still without spaceId');
    }
  }
}
```

### User Data Migration

```dart
class UserSpaceMigration {
  final SpaceRepository _repository;
  
  Future<void> migrate() async {
    // Check if user has completed old onboarding
    final hasOldOnboarding = await _checkOldOnboarding();
    
    if (hasOldOnboarding) {
      // Existing user: activate Health space by default
      await _repository.setActiveSpaceIds(['health']);
      await _repository.setCurrentSpaceId('health');
      await _repository.setOnboardingComplete();
    }
    // New users will go through new onboarding
  }
  
  Future<bool> _checkOldOnboarding() async {
    // Check for any existing records
    final hasRecords = await _hasAnyRecords();
    return hasRecords;
  }
}
```

## Performance Considerations

### Indexing Strategy

```dart
// Composite index for efficient space-based queries
@Index(composite: [CompositeIndex('category'), CompositeIndex('date')])
String get spaceCategoryDateIndex => '$spaceId-$category';

// Query examples:
// 1. All items in a space
final items = await isar.items
    .filter()
    .spaceIdEqualTo('health')
    .findAll();

// 2. Items in space by category
final checkups = await isar.items
    .filter()
    .spaceIdEqualTo('health')
    .and()
    .categoryEqualTo('Checkup')
    .findAll();

// 3. Items in space by date range
final recent = await isar.items
    .filter()
    .spaceIdEqualTo('health')
    .and()
    .dateBetween(startDate, endDate)
    .findAll();
```

### Caching Strategy

```dart
class SpaceCache {
  Space? _currentSpace;
  List<Space>? _activeSpaces;
  DateTime? _lastRefresh;
  
  static const _cacheDuration = Duration(minutes: 5);
  
  bool get isValid {
    if (_lastRefresh == null) return false;
    return DateTime.now().difference(_lastRefresh!) < _cacheDuration;
  }
  
  void invalidate() {
    _currentSpace = null;
    _activeSpaces = null;
    _lastRefresh = null;
  }
}
```

## UI Components

### Space Card Widget

```dart
class SpaceCard extends StatelessWidget {
  final Space space;
  final bool isSelected;
  final bool isCurrent;
  final VoidCallback onTap;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected ? space.gradient.toLinearGradient() : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: space.gradient.startColor.withOpacity(0.3),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            SpaceIcon(
              icon: space.icon,
              gradient: space.gradient,
              size: 48,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        space.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                      if (isCurrent) ...[
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white.withOpacity(0.3) : Colors.purple,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Current',
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    space.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
```

## Security Considerations

1. **Space ID Validation**: Prevent injection attacks by validating space IDs
2. **Custom Space Limits**: Limit number of custom spaces per user (e.g., 10)
3. **Category Validation**: Sanitize user-provided category names
4. **Storage Encryption**: Custom spaces stored in encrypted SharedPreferences
5. **Backup Inclusion**: Space configuration included in encrypted backups

## Accessibility

1. **Screen Reader Support**: All space elements have semantic labels
2. **Color Contrast**: Ensure text on gradients meets WCAG AA standards
3. **Touch Targets**: Minimum 44x44 logical pixels for all interactive elements
4. **Keyboard Navigation**: Full keyboard support for space selection
5. **Announcements**: Space changes announced to screen readers

## Future Enhancements

1. **Space Templates Marketplace**: Community-contributed space templates
2. **Cross-Space Linking**: Link related items across different spaces
3. **Space Analytics**: Usage patterns and insights per space
4. **Collaborative Spaces**: Share spaces with family/team members
5. **Space-Specific AI Models**: Trained models per space domain
6. **Space Export/Import**: Share space configurations
7. **Space Themes**: Custom visual themes per space
8. **Space Widgets**: Home screen widgets per space

---

This design provides a solid foundation for implementing the Universal Spaces System while maintaining backward compatibility and setting up for future enhancements.
