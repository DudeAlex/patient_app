import '../../domain/entities/space.dart';

/// Port (interface) for space configuration persistence.
/// Defines operations for managing active spaces, current space selection,
/// and custom space definitions.
abstract class SpaceRepository {
  /// Retrieves the list of active space IDs.
  /// Returns the IDs of spaces currently enabled by the user.
  Future<List<String>> getActiveSpaceIds();

  /// Updates the list of active space IDs.
  /// Persists which spaces are currently enabled.
  Future<void> setActiveSpaceIds(List<String> spaceIds);

  /// Retrieves the currently selected space ID.
  /// Returns the ID of the space the user is currently viewing.
  Future<String> getCurrentSpaceId();

  /// Updates the currently selected space ID.
  /// Persists which space the user is currently viewing.
  Future<void> setCurrentSpaceId(String spaceId);

  /// Retrieves all custom space definitions created by the user.
  /// Returns a map of space ID to Space entity.
  Future<Map<String, Space>> getCustomSpaces();

  /// Saves a custom space definition.
  /// Persists a user-created space configuration.
  Future<void> saveCustomSpace(Space space);

  /// Deletes a custom space definition.
  /// Removes a user-created space by its ID.
  Future<void> deleteCustomSpace(String spaceId);

  /// Checks if a space ID exists (either built-in or custom).
  /// Returns true if the space is available.
  Future<bool> spaceExists(String spaceId);

  /// Checks if the user has completed onboarding.
  /// Returns true if onboarding has been completed.
  Future<bool> hasCompletedOnboarding();

  /// Marks onboarding as complete.
  /// Persists the onboarding completion flag.
  Future<void> setOnboardingComplete();
}
