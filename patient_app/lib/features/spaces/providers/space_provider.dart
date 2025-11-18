import 'package:flutter/foundation.dart';
import '../../../core/diagnostics/app_logger.dart';
import '../../../core/domain/entities/space.dart';
import '../../../core/domain/value_objects/space_gradient.dart';
import '../../../core/application/services/space_manager.dart';

/// State management provider for spaces using ChangeNotifier.
/// 
/// Manages the current space, active spaces list, and provides methods
/// for space switching and management. Notifies listeners when state changes.
/// 
/// This provider acts as the presentation layer coordinator, exposing
/// space state to UI components and delegating operations to SpaceManager.
class SpaceProvider extends ChangeNotifier {
  final SpaceManager _spaceManager;

  // State properties
  Space? _currentSpace;
  List<Space> _activeSpaces = [];
  bool _isLoading = false;
  String? _error;
  bool? _onboardingComplete; // Cached onboarding status (null = not loaded)

  SpaceProvider(this._spaceManager);

  // Getters for state properties
  
  /// The currently active space being viewed by the user.
  /// Null during initialization or if an error occurred.
  Space? get currentSpace => _currentSpace;

  /// List of all spaces the user has activated.
  /// Empty during initialization or if an error occurred.
  List<Space> get activeSpaces => List.unmodifiable(_activeSpaces);

  /// Whether the provider is currently loading data.
  bool get isLoading => _isLoading;

  /// Error message if an operation failed, null otherwise.
  String? get error => _error;

  /// Whether the provider has been initialized with data.
  bool get isInitialized => _currentSpace != null && _activeSpaces.isNotEmpty;

  /// Whether the user has completed onboarding.
  /// Returns null if onboarding status hasn't been loaded yet.
  /// This value is cached during initialization to avoid additional async calls.
  bool? get onboardingComplete => _onboardingComplete;

  // Initialization

  /// Initializes the provider by loading active spaces, current space, and onboarding status.
  /// 
  /// This method should be called once when the provider is created,
  /// typically in the app initialization flow.
  /// 
  /// Optimized to batch all data loading before notifying listeners, reducing
  /// UI rebuilds from multiple notifications to a single notification.
  /// 
  /// Handles errors gracefully by setting the error state and logging.
  /// If initialization fails, the provider will have empty state but won't crash.
  /// 
  /// Performance metrics are logged, with warnings if initialization exceeds 500ms.
  Future<void> initialize() async {
    // Start operation tracking and record start time for performance metrics
    final initOp = AppLogger.startOperation('initialize_space_provider');
    final startTime = DateTime.now();
    
    await AppLogger.info('Starting SpaceProvider initialization');
    
    try {
      // Load all data without notifying listeners (batch operation)
      
      // Load active spaces first
      final loadSpacesOp = AppLogger.startOperation('load_active_spaces', parentId: initOp);
      _activeSpaces = await _spaceManager.getActiveSpaces();
      await AppLogger.endOperation(loadSpacesOp);

      // Load current space
      final loadCurrentOp = AppLogger.startOperation('load_current_space', parentId: initOp);
      _currentSpace = await _spaceManager.getCurrentSpace();
      await AppLogger.endOperation(loadCurrentOp);

      // Load onboarding status
      final loadOnboardingOp = AppLogger.startOperation('load_onboarding_status', parentId: initOp);
      _onboardingComplete = await _spaceManager.hasCompletedOnboarding();
      await AppLogger.endOperation(loadOnboardingOp);

      // Clear any previous errors
      _error = null;
      
      // Calculate duration and log completion with performance metrics
      final endTime = DateTime.now();
      final durationMs = endTime.difference(startTime).inMilliseconds;
      
      await AppLogger.endOperation(initOp);
      
      // Log completion with performance context
      final performanceContext = {
        'durationMs': durationMs,
        'activeSpacesCount': _activeSpaces.length,
        'currentSpaceId': _currentSpace?.id,
        'onboardingComplete': _onboardingComplete,
      };
      
      // Warn if initialization took longer than 500ms (performance threshold)
      if (durationMs > 500) {
        await AppLogger.warning(
          'SpaceProvider initialization completed but exceeded performance threshold',
          context: {
            ...performanceContext,
            'thresholdMs': 500,
            'exceededBy': durationMs - 500,
          },
        );
      } else {
        await AppLogger.info(
          'SpaceProvider initialization completed successfully',
          context: performanceContext,
        );
      }
    } catch (e, stackTrace) {
      // Calculate duration even on error for performance tracking
      final endTime = DateTime.now();
      final durationMs = endTime.difference(startTime).inMilliseconds;
      
      // Handle errors gracefully - set all fields before notifying
      _error = 'Failed to load spaces: ${e.toString()}';
      _activeSpaces = [];
      _currentSpace = null;
      _onboardingComplete = false;
      
      // Log error with performance context
      await AppLogger.error(
        'SpaceProvider initialization failed',
        error: e,
        stackTrace: stackTrace,
        context: {
          'durationMs': durationMs,
        },
      );
      await AppLogger.endOperation(initOp);
    } finally {
      // Set loading to false and notify listeners once with all data loaded
      _isLoading = false;
      notifyListeners();
    }
  }

  // Space switching

  /// Switches to a different space.
  /// 
  /// Validates that the space ID exists in active spaces, then updates
  /// the current space and persists the selection.
  /// 
  /// Throws [ArgumentError] if the space ID is not in the active spaces list.
  /// Sets error state if the operation fails.
  Future<void> switchSpace(String spaceId) async {
    // Clear any previous errors
    _error = null;

    try {
      // Validate that the space exists in active spaces
      final targetSpace = _activeSpaces.firstWhere(
        (space) => space.id == spaceId,
        orElse: () => throw ArgumentError(
          'Cannot switch to space "$spaceId": space is not active'
        ),
      );

      // Call SpaceManager to persist the selection
      await _spaceManager.setCurrentSpace(spaceId);

      // Update local state
      _currentSpace = targetSpace;

      // Notify listeners of the change
      notifyListeners();
    } catch (e, stackTrace) {
      // Set error state
      _error = 'Failed to switch space: ${e.toString()}';
      
      // Log error for debugging
      debugPrint('SpaceProvider switchSpace error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Notify listeners of error state
      notifyListeners();
      
      // Re-throw to allow caller to handle if needed
      rethrow;
    }
  }

  // Space management

  /// Adds a space to the active spaces list.
  /// 
  /// Activates the space using SpaceManager, then refreshes the active spaces list.
  /// The space must exist (either as a default or custom space).
  /// 
  /// Throws [ArgumentError] if the space ID doesn't exist.
  /// Sets error state if the operation fails.
  Future<void> addSpace(String spaceId) async {
    // Clear any previous errors
    _error = null;

    try {
      // Call SpaceManager to activate the space
      await _spaceManager.activateSpace(spaceId);

      // Refresh active spaces list
      _activeSpaces = await _spaceManager.getActiveSpaces();

      // Notify listeners of the change
      notifyListeners();
    } catch (e, stackTrace) {
      // Set error state
      _error = 'Failed to add space: ${e.toString()}';
      
      // Log error for debugging
      debugPrint('SpaceProvider addSpace error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Notify listeners of error state
      notifyListeners();
      
      // Re-throw to allow caller to handle if needed
      rethrow;
    }
  }

  /// Removes a space from the active spaces list.
  /// 
  /// Deactivates the space using SpaceManager, then refreshes the active spaces list.
  /// If the removed space is the current space, the current space will be automatically
  /// switched to the first remaining active space.
  /// 
  /// Throws [StateError] if attempting to remove the last active space.
  /// Sets error state if the operation fails.
  Future<void> removeSpace(String spaceId) async {
    // Clear any previous errors
    _error = null;

    try {
      // Call SpaceManager to deactivate the space
      await _spaceManager.deactivateSpace(spaceId);

      // Refresh active spaces list
      _activeSpaces = await _spaceManager.getActiveSpaces();

      // Refresh current space (may have changed if we removed the current space)
      _currentSpace = await _spaceManager.getCurrentSpace();

      // Notify listeners of the change
      notifyListeners();
    } catch (e, stackTrace) {
      // Set error state
      _error = 'Failed to remove space: ${e.toString()}';
      
      // Log error for debugging
      debugPrint('SpaceProvider removeSpace error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Notify listeners of error state
      notifyListeners();
      
      // Re-throw to allow caller to handle if needed
      rethrow;
    }
  }

  /// Creates a custom space with user-defined properties.
  /// 
  /// Creates the space using SpaceManager, then refreshes the active spaces list.
  /// The new space is automatically activated and added to the active spaces.
  /// 
  /// Throws [ArgumentError] if a space with the generated ID already exists.
  /// Sets error state if the operation fails.
  Future<void> createCustomSpace({
    required String name,
    required String icon,
    required SpaceGradient gradient,
    required String description,
    required List<String> categories,
  }) async {
    // Clear any previous errors
    _error = null;

    try {
      // Call SpaceManager to create the custom space
      await _spaceManager.createCustomSpace(
        name: name,
        icon: icon,
        gradient: gradient,
        description: description,
        categories: categories,
      );

      // Refresh active spaces list (new space is automatically activated)
      _activeSpaces = await _spaceManager.getActiveSpaces();

      // Notify listeners of the change
      notifyListeners();
    } catch (e, stackTrace) {
      // Set error state
      _error = 'Failed to create custom space: ${e.toString()}';
      
      // Log error for debugging
      debugPrint('SpaceProvider createCustomSpace error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Notify listeners of error state
      notifyListeners();
      
      // Re-throw to allow caller to handle if needed
      rethrow;
    }
  }

  // Onboarding

  /// Checks if the user has completed onboarding.
  /// 
  /// Returns true if the user has gone through the onboarding flow.
  Future<bool> hasCompletedOnboarding() async {
    return await _spaceManager.hasCompletedOnboarding();
  }

  /// Marks onboarding as complete.
  /// 
  /// Should be called after the user completes the onboarding flow.
  Future<void> setOnboardingComplete() async {
    await _spaceManager.setOnboardingComplete();
  }
}
