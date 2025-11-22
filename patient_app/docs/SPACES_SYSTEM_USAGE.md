# Spaces System Usage Guide

## Overview

The Spaces System transforms the app into a universal personal information platform by allowing users to organize different life areas (Health, Education, Business, etc.) in separate "spaces". This guide explains how to use the Spaces System in your code.

## Core Concepts

### Space Entity

A `Space` represents a distinct life area with its own visual identity and categories:

```dart
final space = Space(
  id: 'health',
  name: 'Health',
  icon: 'Heart',
  gradient: SpaceGradient(
    startColor: Color(0xFFEF4444),
    endColor: Color(0xFFEC4899),
  ),
  description: 'Medical records, appointments, medications',
  categories: ['Checkup', 'Dental', 'Vision', 'Lab'],
  isDefault: true,
);
```

### Default Spaces

The system provides 8 pre-configured spaces:
- **Health**: Medical records, appointments, medications
- **Education**: Courses, assignments, research, notes
- **Home & Life**: Recipes, DIY, maintenance, hobbies
- **Business**: Meetings, contacts, contracts, projects
- **Finance**: Expenses, income, investments, receipts
- **Travel**: Trips, bookings, itineraries, memories
- **Family**: Events, milestones, photos, genealogy
- **Creative**: Art, writing, music, photography

## Using SpaceManager

`SpaceManager` is the main service for managing spaces. It's available through dependency injection.

### Getting Active Spaces

```dart
final spaceManager = context.read<SpaceManager>();
final activeSpaces = await spaceManager.getActiveSpaces();

// activeSpaces is a List<Space> containing all spaces the user has enabled
for (final space in activeSpaces) {
  print('${space.name}: ${space.description}');
}
```

### Getting Current Space

```dart
final currentSpace = await spaceManager.getCurrentSpace();
print('Currently viewing: ${currentSpace.name}');
```

### Switching Spaces

```dart
// Switch to Education space
await spaceManager.setCurrentSpace('education');

// The current space is now Education
final newCurrent = await spaceManager.getCurrentSpace();
print('Switched to: ${newCurrent.name}');
```

### Activating/Deactivating Spaces

```dart
// Activate a space (add to user's active list)
await spaceManager.activateSpace('finance');

// Deactivate a space (remove from active list)
// Note: Cannot deactivate the last remaining space
try {
  await spaceManager.deactivateSpace('health');
} catch (e) {
  // Will throw StateError if it's the last space
  print('Error: $e');
}
```

### Creating Custom Spaces

```dart
final customSpace = await spaceManager.createCustomSpace(
  name: 'Fitness',
  icon: 'Dumbbell',
  gradient: SpaceGradient(
    startColor: Color(0xFF10B981),
    endColor: Color(0xFF14B8A6),
  ),
  description: 'Workouts, nutrition, and fitness goals',
  categories: ['Workout', 'Nutrition', 'Goal', 'Progress'],
);

// The custom space is automatically activated
print('Created custom space: ${customSpace.name}');
```

## Using SpaceProvider

`SpaceProvider` is a `ChangeNotifier` that manages space state for the UI layer.

### Accessing SpaceProvider

```dart
// In a widget
final spaceProvider = context.watch<SpaceProvider>();

// Or for one-time access without rebuilding
final spaceProvider = context.read<SpaceProvider>();
```

### Initializing SpaceProvider

```dart
// Initialize when the app starts (typically in main.dart or app.dart)
final spaceProvider = SpaceProvider(spaceManager);
await spaceProvider.initialize();
```

### Watching Current Space

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spaceProvider = context.watch<SpaceProvider>();
    final currentSpace = spaceProvider.currentSpace;
    
    if (currentSpace == null) {
      return CircularProgressIndicator();
    }
    
    return Text('Current space: ${currentSpace.name}');
  }
}
```

### Switching Spaces in UI

```dart
// In a button or list tile
onTap: () async {
  final spaceProvider = context.read<SpaceProvider>();
  await spaceProvider.switchSpace('education');
  
  // UI will automatically rebuild due to notifyListeners()
}
```

### Handling Errors

```dart
final spaceProvider = context.watch<SpaceProvider>();

if (spaceProvider.error != null) {
  return Text('Error: ${spaceProvider.error}');
}

if (spaceProvider.isLoading) {
  return CircularProgressIndicator();
}

// Normal UI
return MySpacesList(spaces: spaceProvider.activeSpaces);
```

## Filtering Records by Space

Records are associated with spaces via the `spaceId` field.

### Querying Records for Current Space

```dart
final currentSpace = await spaceManager.getCurrentSpace();

// Query all records in the current space
final records = await isar.records
    .filter()
    .spaceIdEqualTo(currentSpace.id)
    .sortByDateDesc()
    .findAll();
```

### Querying Records by Category within Space

```dart
// Get all Checkup records in Health space
final checkups = await isar.records
    .filter()
    .spaceIdEqualTo('health')
    .and()
    .typeEqualTo('Checkup')
    .sortByDateDesc()
    .findAll();
```

### Creating Records in Current Space

```dart
final currentSpace = await spaceManager.getCurrentSpace();

final record = Record()
  ..spaceId = currentSpace.id  // Associate with current space
  ..type = 'Checkup'
  ..date = DateTime.now()
  ..title = 'Annual Physical'
  ..text = 'Everything looks good';

await isar.writeTxn(() async {
  await isar.records.put(record);
});
```

## Using Space UI Components

### SpaceCard Widget

Displays a space with its icon, name, and description:

```dart
SpaceCard(
  space: space,
  isSelected: selectedSpaceIds.contains(space.id),
  isCurrent: space.id == currentSpace?.id,
  onTap: () {
    // Handle tap
    setState(() {
      if (selectedSpaceIds.contains(space.id)) {
        selectedSpaceIds.remove(space.id);
      } else {
        selectedSpaceIds.add(space.id);
      }
    });
  },
)
```

### SpaceIcon Widget

Displays a space's icon with gradient background:

```dart
SpaceIcon(
  icon: space.icon,
  gradient: space.gradient,
  size: 48,
)
```

### GradientHeader with Space

Display a header with space-specific gradient:

```dart
GradientHeader(
  space: currentSpace,
  title: currentSpace.name,
  subtitle: currentSpace.description,
  showBackButton: true,
)
```

## Onboarding Flow

### Checking Onboarding Status

```dart
final spaceManager = context.read<SpaceManager>();
final hasCompleted = await spaceManager.hasCompletedOnboarding();

if (!hasCompleted) {
  // Show onboarding screen
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => OnboardingScreen()),
  );
}
```

### Completing Onboarding

```dart
// After user selects spaces in onboarding
final selectedSpaceIds = ['health', 'education', 'business'];

// Activate selected spaces
for (final spaceId in selectedSpaceIds) {
  await spaceManager.activateSpace(spaceId);
}

// Set first space as current
await spaceManager.setCurrentSpace(selectedSpaceIds.first);

// Mark onboarding complete
await spaceManager.setOnboardingComplete();

// Navigate to main app
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (_) => RecordsHomeModern()),
);
```

## Migration

The Spaces System includes automatic migration for existing records.

### How Migration Works

1. **Database Migration**: All existing records without `spaceId` are assigned `spaceId='health'`
2. **User Data Migration**: Existing users are automatically set up with Health space active
3. **Onboarding**: Existing users skip onboarding; new users go through space selection

### Migration is Automatic

Migration happens automatically on first launch after updating to the Spaces System:

```dart
// In app initialization (main.dart or app.dart)
final migrationService = MigrationService(
  db: isar,
  spaceRepository: spacePreferences,
);

final migrationSuccess = await migrationService.checkAndMigrate();
if (!migrationSuccess) {
  print('Warning: Migration failed, but app will continue');
}
```

### Verifying Migration

```dart
// Check if any records lack spaceId
final unmigrated = await isar.records
    .filter()
    .spaceIdIsEmpty()
    .count();

if (unmigrated > 0) {
  print('Warning: $unmigrated records still need migration');
}
```

## Best Practices

### 1. Always Use Current Space for New Records

```dart
// ✅ Good: Use current space
final currentSpace = await spaceManager.getCurrentSpace();
record.spaceId = currentSpace.id;

// ❌ Bad: Hardcode space ID
record.spaceId = 'health';
```

### 2. Filter Queries by Space

```dart
// ✅ Good: Filter by current space
final records = await isar.records
    .filter()
    .spaceIdEqualTo(currentSpace.id)
    .findAll();

// ❌ Bad: Query all records across all spaces
final records = await isar.records.where().findAll();
```

### 3. Handle Space Switching

```dart
// ✅ Good: Clear search/filters when space changes
void _onSpaceChanged() {
  setState(() {
    searchQuery = '';
    selectedCategory = null;
    // Reload records for new space
    _loadRecords();
  });
}

// Listen to space changes
spaceProvider.addListener(_onSpaceChanged);
```

### 4. Validate Space Operations

```dart
// ✅ Good: Handle errors gracefully
try {
  await spaceManager.deactivateSpace(spaceId);
} catch (e) {
  if (e is StateError) {
    // Show user-friendly message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cannot remove the last space')),
    );
  }
}
```

### 5. Use Space-Specific Categories

```dart
// ✅ Good: Show categories for current space
final categories = currentSpace.categories;
DropdownButton<String>(
  items: categories.map((cat) => 
    DropdownMenuItem(value: cat, child: Text(cat))
  ).toList(),
  onChanged: (value) => setState(() => selectedCategory = value),
);

// ❌ Bad: Hardcode categories
final categories = ['Checkup', 'Dental', 'Vision'];
```

## Common Patterns

### Space Switcher Button

```dart
// Show space switcher only if multiple spaces are active
if (spaceProvider.activeSpaces.length > 1) {
  IconButton(
    icon: Icon(Icons.grid_view),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SpaceSelectorScreen()),
      );
    },
  )
}
```

### Space-Specific Statistics

```dart
// Count records in current space
final recordCount = await isar.records
    .filter()
    .spaceIdEqualTo(currentSpace.id)
    .count();

// Count attachments in current space
final records = await isar.records
    .filter()
    .spaceIdEqualTo(currentSpace.id)
    .findAll();
final attachmentCount = records.fold<int>(
  0, 
  (sum, record) => sum + record.attachments.length,
);

// Count unique categories used
final categories = records
    .map((r) => r.type)
    .toSet()
    .length;
```

### Custom Space Creation Flow

```dart
// In CreateSpaceScreen
final space = await spaceProvider.createCustomSpace(
  name: nameController.text,
  icon: selectedIcon,
  gradient: selectedGradient,
  description: descriptionController.text,
  categories: categoryController.text.split(',').map((s) => s.trim()).toList(),
);

// Show success message
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Created space: ${space.name}')),
);

// Navigate back
Navigator.pop(context);
```

## Troubleshooting

### Space Not Found Error

```dart
// Error: "Cannot switch to space 'xyz': space is not active"
// Solution: Activate the space first
await spaceManager.activateSpace('xyz');
await spaceManager.setCurrentSpace('xyz');
```

### Last Space Error

```dart
// Error: "Cannot deactivate the last space"
// Solution: Activate another space before deactivating
await spaceManager.activateSpace('education');
await spaceManager.deactivateSpace('health');
```

### Records Not Showing

```dart
// Problem: Records not appearing after space switch
// Solution: Ensure query filters by current space
final currentSpace = await spaceManager.getCurrentSpace();
final records = await isar.records
    .filter()
    .spaceIdEqualTo(currentSpace.id)  // ← Add this filter
    .findAll();
```

### Migration Issues

```dart
// Problem: Old records not showing in Health space
// Solution: Run migration manually
final migrationService = MigrationService(db: isar, spaceRepository: repo);
await migrationService.checkAndMigrate();
```

## Further Reading

- See `ARCHITECTURE.md` for system architecture details
- See `.kiro/specs/spaces-system/design.md` for complete design documentation
- See `.kiro/specs/spaces-system/requirements.md` for detailed requirements
