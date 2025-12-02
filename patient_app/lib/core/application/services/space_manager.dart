import '../../domain/entities/space.dart';
import '../../domain/value_objects/space_gradient.dart';
import '../ports/space_repository.dart';
import '../../../features/spaces/domain/space_registry.dart';

/// Core service for managing spaces.
/// 
/// Orchestrates space operations including:
/// - Retrieving active and current spaces
/// - Switching between spaces
/// - Activating/deactivating spaces
/// - Creating custom spaces
/// 
/// This service acts as the application layer coordinator between
/// the domain (Space entities, SpaceRegistry) and infrastructure (SpaceRepository).
class SpaceManager {
  final SpaceRepository _repository;
  final SpaceRegistry _registry;

  SpaceManager(this._repository, this._registry);

  /// Retrieves all active spaces for the current user.
  /// 
  /// Returns a list of Space objects representing spaces the user has enabled.
  /// If no spaces are active, defaults to the Health space.
  /// 
  /// The method:
  /// 1. Fetches active space IDs from storage
  /// 2. Maps each ID to a Space object (checking custom spaces first, then defaults)
  /// 3. Returns the list of resolved spaces
  Future<List<Space>> getActiveSpaces() async {
    var activeIds = await _repository.getActiveSpaceIds();
    
    // Default to all built-in spaces if none selected or only the legacy default is present.
    final defaultIds = _registry.getAllDefaultSpaceIds();
    if (activeIds.isEmpty ||
        (activeIds.length == 1 &&
            activeIds.first == 'health' &&
            defaultIds.length > 1)) {
      activeIds = defaultIds;
    }

    // Map IDs to Space objects
    final spaces = <Space>[];
    for (final id in activeIds) {
      final space = await _getSpaceById(id);
      if (space != null) {
        spaces.add(space);
      }
    }

    return spaces;
  }

  /// Retrieves the current active space.
  /// 
  /// Returns the Space object for the space the user is currently viewing.
  /// Falls back to the first active space if the stored current space is invalid.
  /// Ultimately defaults to Health space if no valid spaces are found.
  Future<Space> getCurrentSpace() async {
    // Try to get the stored current space ID
    final currentId = await _repository.getCurrentSpaceId();
    final space = await _getSpaceById(currentId);
    
    if (space != null) {
      return space;
    }

    // Fallback to first active space
    final activeSpaces = await getActiveSpaces();
    if (activeSpaces.isNotEmpty) {
      return activeSpaces.first;
    }

    // Ultimate fallback to Health space
    final healthSpace = _registry.getDefaultSpace('health');
    if (healthSpace != null) {
      return healthSpace;
    }

    // This should never happen, but throw if it does
    throw StateError('No valid spaces available');
  }

  /// Sets the current active space.
  /// 
  /// Validates that the space ID exists in the user's active spaces
  /// before persisting the selection.
  /// 
  /// Throws [ArgumentError] if the space ID is not in the active spaces list.
  Future<void> setCurrentSpace(String spaceId) async {
    // Validate that the space exists and is active
    final activeSpaces = await getActiveSpaces();
    final isActive = activeSpaces.any((space) => space.id == spaceId);

    if (!isActive) {
      throw ArgumentError(
        'Cannot set current space to "$spaceId": space is not active. '
        'Activate the space first using activateSpace().'
      );
    }

    // Save to storage
    await _repository.setCurrentSpaceId(spaceId);
  }

  /// Activates a space, adding it to the user's active spaces list.
  /// 
  /// Validates that the space exists (either as a default or custom space)
  /// before adding it. Prevents duplicate activations.
  /// 
  /// Throws [ArgumentError] if the space ID doesn't exist.
  Future<void> activateSpace(String spaceId) async {
    // Validate that the space exists
    final space = await _getSpaceById(spaceId);
    if (space == null) {
      throw ArgumentError(
        'Cannot activate space "$spaceId": space does not exist. '
        'Create a custom space first or use a valid default space ID.'
      );
    }

    // Get current active space IDs
    final activeIds = await _repository.getActiveSpaceIds();

    // Prevent duplicates
    if (activeIds.contains(spaceId)) {
      return; // Already active, nothing to do
    }

    // Add to active list and save
    activeIds.add(spaceId);
    await _repository.setActiveSpaceIds(activeIds);
  }

  /// Deactivates a space, removing it from the user's active spaces list.
  /// 
  /// Prevents removing the last active space (at least one must remain).
  /// If the deactivated space is the current space, automatically switches
  /// to the first remaining active space.
  /// 
  /// Throws [StateError] if attempting to deactivate the last space.
  Future<void> deactivateSpace(String spaceId) async {
    // Get current active space IDs
    final activeIds = await _repository.getActiveSpaceIds();

    // Prevent removing the last space
    if (activeIds.length <= 1) {
      throw StateError(
        'Cannot deactivate space "$spaceId": at least one space must remain active.'
      );
    }

    // Remove from active list
    final wasRemoved = activeIds.remove(spaceId);
    
    if (!wasRemoved) {
      return; // Space wasn't active, nothing to do
    }

    // Save updated active list
    await _repository.setActiveSpaceIds(activeIds);

    // If deactivating current space, switch to first remaining space
    final currentId = await _repository.getCurrentSpaceId();
    if (currentId == spaceId) {
      await _repository.setCurrentSpaceId(activeIds.first);
    }
  }

  /// Creates a custom space with user-defined properties.
  /// 
  /// Generates a unique space ID from the name, creates the Space entity,
  /// saves it to storage, and automatically activates it.
  /// 
  /// Returns the created Space entity.
  /// 
  /// Throws [ArgumentError] if a space with the generated ID already exists.
  Future<Space> createCustomSpace({
    required String name,
    required String icon,
    required SpaceGradient gradient,
    required String description,
    required List<String> categories,
  }) async {
    // Generate unique space ID from name
    final id = _generateSpaceId(name);

    // Check if space ID already exists
    final existingSpace = await _getSpaceById(id);
    if (existingSpace != null) {
      throw ArgumentError(
        'Cannot create custom space: a space with ID "$id" already exists. '
        'Try a different name.'
      );
    }

    // Create Space entity with isCustom=true
    final space = Space(
      id: id,
      name: name,
      icon: icon,
      gradient: gradient,
      description: description,
      categories: categories,
      isCustom: true,
    );

    // Save to custom spaces storage
    await _repository.saveCustomSpace(space);

    // Automatically activate the new space
    await activateSpace(id);

    return space;
  }

  /// Generates a space ID from a name.
  /// 
  /// Converts the name to lowercase, replaces non-alphanumeric characters
  /// with underscores, and removes leading/trailing underscores.
  /// 
  /// Examples:
  /// - "My Projects" -> "my_projects"
  /// - "Work & Career" -> "work_career"
  /// - "Fitness 2024!" -> "fitness_2024"
  String _generateSpaceId(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  /// Checks if the user has completed onboarding.
  /// 
  /// Returns true if the user has gone through the onboarding flow,
  /// false if this is their first time using the app.
  Future<bool> hasCompletedOnboarding() async {
    return await _repository.hasCompletedOnboarding();
  }

  /// Marks onboarding as complete.
  /// 
  /// Should be called after the user completes the onboarding flow.
  /// This ensures they won't see the onboarding screen again.
  Future<void> setOnboardingComplete() async {
    await _repository.setOnboardingComplete();
  }

  /// Internal helper to retrieve a space by ID.
  /// 
  /// Checks custom spaces first, then falls back to default spaces.
  /// Returns null if the space ID is not found.
  Future<Space?> _getSpaceById(String id) async {
    // Check custom spaces first
    final customSpaces = await _repository.getCustomSpaces();
    if (customSpaces.containsKey(id)) {
      return customSpaces[id];
    }

    // Fall back to default spaces
    return _registry.getDefaultSpace(id);
  }
}
