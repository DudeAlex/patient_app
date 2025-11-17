import 'dart:convert';

import '../../application/ports/space_repository.dart';
import '../../domain/entities/space.dart';

/// SharedPreferences-based implementation of SpaceRepository.
/// Stores space configuration in local device preferences.
/// 
/// Note: This is a placeholder implementation that stores data in memory.
/// In a real implementation, this would use the shared_preferences package.
/// For now, we use in-memory storage to avoid adding the dependency.
class SpacePreferences implements SpaceRepository {
  SpacePreferences();

  // In-memory storage (placeholder until shared_preferences is added)
  final Map<String, dynamic> _storage = {};

  // Keys for SharedPreferences storage
  static const String _keyActiveSpaces = 'spaces.active';
  static const String _keyCurrentSpace = 'spaces.current';
  static const String _keyCustomSpaces = 'spaces.custom';
  static const String _keyOnboardingComplete = 'spaces.onboarding_complete';

  // Default values
  static const String _defaultSpaceId = 'health';
  static const List<String> _defaultActiveSpaces = ['health'];

  @override
  Future<List<String>> getActiveSpaceIds() async {
    final stored = _storage[_keyActiveSpaces] as List<String>?;
    return stored ?? List<String>.from(_defaultActiveSpaces);
  }

  @override
  Future<void> setActiveSpaceIds(List<String> spaceIds) async {
    _storage[_keyActiveSpaces] = List<String>.from(spaceIds);
  }

  @override
  Future<String> getCurrentSpaceId() async {
    final stored = _storage[_keyCurrentSpace] as String?;
    return stored ?? _defaultSpaceId;
  }

  @override
  Future<void> setCurrentSpaceId(String spaceId) async {
    _storage[_keyCurrentSpace] = spaceId;
  }

  @override
  Future<Map<String, Space>> getCustomSpaces() async {
    final stored = _storage[_keyCustomSpaces] as String?;
    if (stored == null || stored.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(stored) as Map<String, dynamic>;
      final spaces = <String, Space>{};

      for (final entry in decoded.entries) {
        final spaceData = entry.value as Map<String, dynamic>;
        spaces[entry.key] = Space.fromJson(spaceData);
      }

      return spaces;
    } catch (e) {
      // If deserialization fails, return empty map
      return {};
    }
  }

  @override
  Future<void> saveCustomSpace(Space space) async {
    final customSpaces = await getCustomSpaces();
    customSpaces[space.id] = space;

    final serialized = <String, dynamic>{};
    for (final entry in customSpaces.entries) {
      serialized[entry.key] = entry.value.toJson();
    }

    _storage[_keyCustomSpaces] = jsonEncode(serialized);
  }

  @override
  Future<void> deleteCustomSpace(String spaceId) async {
    final customSpaces = await getCustomSpaces();
    customSpaces.remove(spaceId);

    final serialized = <String, dynamic>{};
    for (final entry in customSpaces.entries) {
      serialized[entry.key] = entry.value.toJson();
    }

    _storage[_keyCustomSpaces] = jsonEncode(serialized);
  }

  @override
  Future<bool> spaceExists(String spaceId) async {
    // Check if it's a custom space
    final customSpaces = await getCustomSpaces();
    if (customSpaces.containsKey(spaceId)) {
      return true;
    }

    // Check if it's in active spaces (which includes built-in spaces)
    final activeSpaces = await getActiveSpaceIds();
    return activeSpaces.contains(spaceId);
  }

  @override
  Future<bool> hasCompletedOnboarding() async {
    final stored = _storage[_keyOnboardingComplete] as bool?;
    return stored ?? false;
  }

  @override
  Future<void> setOnboardingComplete() async {
    _storage[_keyOnboardingComplete] = true;
  }

}
