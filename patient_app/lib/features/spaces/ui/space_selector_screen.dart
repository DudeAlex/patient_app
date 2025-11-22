import 'package:flutter/material.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_text_styles.dart';
import '../providers/space_provider.dart';
import '../domain/space_registry.dart';
import 'widgets/space_card.dart';
import 'create_space_screen.dart';

/// Space selector screen with two modes: view and manage.
/// 
/// View mode: Displays active spaces, allows switching between them
/// Manage mode: Shows all default spaces, allows activating/deactivating
/// 
/// Requirements: 3.1-3.8, 4.1-4.8
class SpaceSelectorScreen extends StatefulWidget {
  final SpaceProvider spaceProvider;

  const SpaceSelectorScreen({
    super.key,
    required this.spaceProvider,
  });

  @override
  State<SpaceSelectorScreen> createState() => _SpaceSelectorScreenState();
}

class _SpaceSelectorScreenState extends State<SpaceSelectorScreen> {
  final SpaceRegistry _spaceRegistry = SpaceRegistry();
  
  // Track which mode we're in: view or manage
  bool _isManageMode = false;
  
  // Track selected spaces in manage mode (space IDs)
  Set<String> _selectedSpaceIds = {};
  
  // Track if we're saving changes
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize selected spaces with current active spaces
    _selectedSpaceIds = widget.spaceProvider.activeSpaces
        .map((space) => space.id)
        .toSet();
  }

  /// Toggle between view and manage modes
  void _toggleMode() {
    setState(() {
      if (_isManageMode) {
        // Exiting manage mode - reset selections to current active spaces
        _selectedSpaceIds = widget.spaceProvider.activeSpaces
            .map((space) => space.id)
            .toSet();
      }
      _isManageMode = !_isManageMode;
    });
  }

  /// Toggle space selection in manage mode
  void _toggleSpaceSelection(String spaceId) {
    setState(() {
      if (_selectedSpaceIds.contains(spaceId)) {
        // Prevent deselecting the last space
        if (_selectedSpaceIds.length > 1) {
          _selectedSpaceIds.remove(spaceId);
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must have at least one active space'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } else {
        _selectedSpaceIds.add(spaceId);
      }
    });
  }

  /// Save changes in manage mode
  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Get current active space IDs
      final currentActiveIds = widget.spaceProvider.activeSpaces
          .map((space) => space.id)
          .toSet();

      // Find spaces to add (in selected but not in current active)
      final spacesToAdd = _selectedSpaceIds.difference(currentActiveIds);
      
      // Find spaces to remove (in current active but not in selected)
      final spacesToRemove = currentActiveIds.difference(_selectedSpaceIds);

      // Add new spaces
      for (final spaceId in spacesToAdd) {
        await widget.spaceProvider.addSpace(spaceId);
      }

      // Remove deactivated spaces
      for (final spaceId in spacesToRemove) {
        await widget.spaceProvider.removeSpace(spaceId);
      }

      // Exit manage mode
      setState(() {
        _isManageMode = false;
        _isSaving = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Spaces updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update spaces: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Cancel changes in manage mode
  void _cancelChanges() {
    setState(() {
      // Reset selections to current active spaces
      _selectedSpaceIds = widget.spaceProvider.activeSpaces
          .map((space) => space.id)
          .toSet();
      _isManageMode = false;
    });
  }

  /// Switch to a different space (view mode only)
  Future<void> _switchToSpace(String spaceId) async {
    try {
      await widget.spaceProvider.switchSpace(spaceId);
      
      // Navigate back after switching
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch space: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Navigate to create custom space screen
  void _navigateToCreateSpace() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateSpaceScreen(
          spaceProvider: widget.spaceProvider,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isManageMode ? 'Manage Spaces' : 'Select Space',
          style: AppTextStyles.h2.copyWith(
            color: AppColors.gray900,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray900),
          onPressed: _isManageMode ? _cancelChanges : () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!_isManageMode)
            // "Manage" button in view mode
            TextButton(
              onPressed: _toggleMode,
              child: Text(
                'Manage',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.gradientPurple,
                ),
              ),
            ),
        ],
      ),
      body: _isManageMode ? _buildManageMode() : _buildViewMode(),
    );
  }

  /// Build view mode UI
  /// Requirements: 3.2, 4.1-4.4
  Widget _buildViewMode() {
    final activeSpaces = widget.spaceProvider.activeSpaces;
    final currentSpace = widget.spaceProvider.currentSpace;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Spaces',
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap a space to switch to it',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.gray600,
                ),
              ),
            ],
          ),
        ),

        // Active spaces list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: activeSpaces.length + 1, // +1 for "Add More Spaces" button
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              // Last item is "Add More Spaces" button
              if (index == activeSpaces.length) {
                return _buildAddMoreSpacesButton();
              }

              final space = activeSpaces[index];
              final isCurrent = currentSpace?.id == space.id;

              return SpaceCard(
                space: space,
                isSelected: isCurrent,
                isCurrent: isCurrent,
                onTap: () => _switchToSpace(space.id),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build "Add More Spaces" button
  Widget _buildAddMoreSpacesButton() {
    return GestureDetector(
      onTap: _toggleMode,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.gradientPurple,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              color: AppColors.gradientPurple,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Add More Spaces',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.gradientPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build manage mode UI
  /// Requirements: 3.3-3.7
  Widget _buildManageMode() {
    final allDefaultSpaces = _spaceRegistry.getAllDefaultSpaces();

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Your Spaces',
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose which spaces you want to use',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.gray600,
                ),
              ),
              const SizedBox(height: 16),
              // Selection count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_selectedSpaceIds.length} ${_selectedSpaceIds.length == 1 ? 'space' : 'spaces'} selected',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.gray700,
                  ),
                ),
              ),
            ],
          ),
        ),

        // All default spaces list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: allDefaultSpaces.length + 1, // +1 for "Create Custom Space" button
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              // Last item is "Create Custom Space" button
              if (index == allDefaultSpaces.length) {
                return _buildCreateCustomSpaceButton();
              }

              final space = allDefaultSpaces[index];
              final isSelected = _selectedSpaceIds.contains(space.id);

              return SpaceCard(
                space: space,
                isSelected: isSelected,
                isCurrent: false,
                onTap: () => _toggleSpaceSelection(space.id),
              );
            },
          ),
        ),

        // Save/Cancel buttons
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.gray900.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Cancel button
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _cancelChanges,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(
                      color: AppColors.gray300,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.gray700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Save button
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : Text(
                          'Save',
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build "Create Custom Space" button
  /// Requirements: 7.1
  Widget _buildCreateCustomSpaceButton() {
    return GestureDetector(
      onTap: _navigateToCreateSpace,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.gray300,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.gray600,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Custom Space',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Design your own space with custom categories',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
