import 'package:flutter/material.dart';
import '../../../core/diagnostics/app_logger.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_text_styles.dart';
import '../../../core/domain/value_objects/space_gradient.dart';
import '../providers/space_provider.dart';

/// Screen for creating custom spaces with user-defined properties.
/// 
/// Allows users to:
/// - Enter space name and description
/// - Select an icon from a grid
/// - Choose a gradient color scheme
/// - Define custom categories
/// 
/// Requirements: 7.1-7.10
class CreateSpaceScreen extends StatefulWidget {
  final SpaceProvider spaceProvider;

  const CreateSpaceScreen({
    super.key,
    required this.spaceProvider,
  });

  @override
  State<CreateSpaceScreen> createState() => _CreateSpaceScreenState();
}

class _CreateSpaceScreenState extends State<CreateSpaceScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();
  
  // Text controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  
  // Selected values
  String? _selectedIcon;
  SpaceGradient? _selectedGradient;
  List<String> _categories = [];
  
  // UI state
  bool _isSaving = false;
  
  // Available gradient options for selection
  static final List<SpaceGradient> _availableGradients = [
    const SpaceGradient(
      startColor: Color(0xFFEF4444), // red-500
      endColor: Color(0xFFEC4899),   // pink-500
    ),
    const SpaceGradient(
      startColor: Color(0xFF3B82F6), // blue-500
      endColor: Color(0xFF06B6D4),   // cyan-500
    ),
    const SpaceGradient(
      startColor: Color(0xFF10B981), // green-500
      endColor: Color(0xFF14B8A6),   // teal-500
    ),
    const SpaceGradient(
      startColor: Color(0xFF8B5CF6), // violet-500
      endColor: Color(0xFFA855F7),   // purple-500
    ),
    const SpaceGradient(
      startColor: Color(0xFFF59E0B), // amber-500
      endColor: Color(0xFFEAB308),   // yellow-500
    ),
    const SpaceGradient(
      startColor: Color(0xFF06B6D4), // cyan-500
      endColor: Color(0xFF0EA5E9),   // sky-500
    ),
    const SpaceGradient(
      startColor: Color(0xFFF43F5E), // rose-500
      endColor: Color(0xFFEC4899),   // pink-500
    ),
    const SpaceGradient(
      startColor: Color(0xFFEC4899), // pink-500
      endColor: Color(0xFFA855F7),   // purple-500
    ),
    const SpaceGradient(
      startColor: Color(0xFF6366F1), // indigo-500
      endColor: Color(0xFF8B5CF6),   // violet-500
    ),
    const SpaceGradient(
      startColor: Color(0xFF14B8A6), // teal-500
      endColor: Color(0xFF10B981),   // green-500
    ),
  ];
  
  // Available icons for selection
  static const List<Map<String, String>> _availableIcons = [
    {'name': 'Heart', 'label': 'Heart'},
    {'name': 'GraduationCap', 'label': 'Education'},
    {'name': 'Home', 'label': 'Home'},
    {'name': 'Briefcase', 'label': 'Work'},
    {'name': 'DollarSign', 'label': 'Money'},
    {'name': 'Plane', 'label': 'Travel'},
    {'name': 'Users', 'label': 'People'},
    {'name': 'Palette', 'label': 'Art'},
    {'name': 'Book', 'label': 'Book'},
    {'name': 'Camera', 'label': 'Camera'},
    {'name': 'Music', 'label': 'Music'},
    {'name': 'Star', 'label': 'Star'},
    {'name': 'Coffee', 'label': 'Coffee'},
    {'name': 'Pen', 'label': 'Writing'},
    {'name': 'Sparkles', 'label': 'Magic'},
    {'name': 'Map', 'label': 'Map'},
  ];

  @override
  void initState() {
    super.initState();
    AppLogger.info('CreateSpaceScreen initialized');
  }

  @override
  void dispose() {
    AppLogger.info('CreateSpaceScreen disposing');
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Custom Space',
          style: AppTextStyles.h2.copyWith(
            color: AppColors.gray900,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray900),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Scrollable form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header text
                    Text(
                      'Design Your Space',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.gray900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a custom space tailored to your needs',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Name input
                    _buildNameInput(),
                    const SizedBox(height: 24),
                    
                    // Description input
                    _buildDescriptionInput(),
                    const SizedBox(height: 32),
                    
                    // Icon picker
                    _buildIconPicker(),
                    const SizedBox(height: 32),
                    
                    // Color picker
                    _buildColorPicker(),
                    const SizedBox(height: 32),
                    
                    // Category input
                    _buildCategoryInput()
                  ],
                ),
              ),
            ),
            
            // Save button at bottom
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  /// Builds the name input field with validation
  /// Requirements: 7.2, 7.3
  Widget _buildNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Space Name',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'e.g., My Projects, Work Notes',
            hintStyle: AppTextStyles.hint.copyWith(
              color: AppColors.gray400,
            ),
            filled: true,
            fillColor: AppColors.gray50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.gray300,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.gray300,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.gradientPurple,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: AppTextStyles.input.copyWith(
            color: AppColors.gray900,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a space name';
            }
            if (value.trim().length < 2) {
              return 'Space name must be at least 2 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Builds the description input field (optional)
  /// Requirements: 7.2, 7.3
  Widget _buildDescriptionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description (Optional)',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: 'Describe what you\'ll track in this space',
            hintStyle: AppTextStyles.hint.copyWith(
              color: AppColors.gray400,
            ),
            filled: true,
            fillColor: AppColors.gray50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.gray300,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.gray300,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.gradientPurple,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: AppTextStyles.input.copyWith(
            color: AppColors.gray900,
          ),
          maxLines: 3,
          maxLength: 200,
        ),
      ],
    );
  }

  /// Builds the icon picker grid
  /// Requirements: 7.4
  Widget _buildIconPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Icon',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedIcon == null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.error.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please select an icon for your space',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        // Icon grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: _availableIcons.length,
          itemBuilder: (context, index) {
            final icon = _availableIcons[index];
            final iconName = icon['name']!;
            final isSelected = _selectedIcon == iconName;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIcon = iconName;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.gradientPurple : AppColors.gray100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.gradientPurple : AppColors.gray300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getIconData(iconName),
                      size: 32,
                      color: isSelected ? AppColors.white : AppColors.gray700,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      icon['label']!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected ? AppColors.white : AppColors.gray600,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Maps icon names to Material Icons (same as SpaceIcon widget)
  IconData _getIconData(String name) {
    switch (name.toLowerCase()) {
      case 'heart':
        return Icons.favorite;
      case 'graduationcap':
      case 'graduation_cap':
        return Icons.school;
      case 'home':
        return Icons.home;
      case 'briefcase':
        return Icons.work;
      case 'dollarsign':
      case 'dollar_sign':
        return Icons.attach_money;
      case 'plane':
        return Icons.flight;
      case 'users':
        return Icons.people;
      case 'palette':
        return Icons.palette;
      case 'book':
        return Icons.menu_book;
      case 'camera':
        return Icons.camera_alt;
      case 'music':
        return Icons.music_note;
      case 'star':
        return Icons.star;
      case 'coffee':
        return Icons.coffee;
      case 'pen':
        return Icons.edit;
      case 'sparkles':
        return Icons.auto_awesome;
      case 'map':
        return Icons.map;
      default:
        return Icons.circle;
    }
  }

  /// Builds the color picker with gradient options
  /// Requirements: 7.5
  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Color Scheme',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedGradient == null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.error.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please select a color scheme for your space',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        // Preview of selected gradient
        if (_selectedGradient != null) ...[
          Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: _selectedGradient!.toLinearGradient(),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'Preview',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Gradient grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: _availableGradients.length,
          itemBuilder: (context, index) {
            final gradient = _availableGradients[index];
            final isSelected = _selectedGradient == gradient;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGradient = gradient;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: gradient.toLinearGradient(),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.gray900 : Colors.transparent,
                    width: isSelected ? 3 : 0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.gray900.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Center(
                        child: Icon(
                          Icons.check,
                          color: AppColors.white,
                          size: 24,
                        ),
                      )
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }

  /// Builds the category input with chip display
  /// Requirements: 7.6
  Widget _buildCategoryInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Categories',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Enter categories separated by commas (e.g., Notes, Ideas, Tasks)',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.gray600,
          ),
        ),
        const SizedBox(height: 12),
        // Category chips display
        if (_categories.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((category) {
              return Chip(
                label: Text(
                  category,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.gray900,
                  ),
                ),
                backgroundColor: AppColors.gray100,
                deleteIcon: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.gray600,
                ),
                onDeleted: () {
                  setState(() {
                    _categories.remove(category);
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(
                    color: AppColors.gray300,
                    width: 1,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        if (_categories.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.error.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please add at least one category',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        // Category input field
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  hintText: 'Type category and press Add',
                  hintStyle: AppTextStyles.hint.copyWith(
                    color: AppColors.gray400,
                  ),
                  filled: true,
                  fillColor: AppColors.gray50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.gray300,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.gray300,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.gradientPurple,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                style: AppTextStyles.input.copyWith(
                  color: AppColors.gray900,
                ),
                onFieldSubmitted: (_) => _addCategory(),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _addCategory,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Add',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Adds a category from the input field
  void _addCategory() {
    final text = _categoryController.text.trim();
    if (text.isEmpty) return;

    // Split by comma and add each category
    final newCategories = text
        .split(',')
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty && !_categories.contains(c))
        .toList();

    if (newCategories.isNotEmpty) {
      setState(() {
        _categories.addAll(newCategories);
        _categoryController.clear();
      });
    }
  }

  /// Builds the save button at the bottom
  /// Requirements: 7.7-7.10
  Widget _buildSaveButton() {
    return Container(
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
      child: ElevatedButton(
        onPressed: _isSaving ? null : _handleSave,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: AppColors.gray300,
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
                'Create Space',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.white,
                ),
              ),
      ),
    );
  }

  /// Handles the save action
  /// Validates all fields and creates the custom space
  /// Requirements: 7.7-7.10
  Future<void> _handleSave() async {
    // Validate form fields
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate icon selection
    if (_selectedIcon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an icon for your space'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate gradient selection
    if (_selectedGradient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a color scheme for your space'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate categories
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one category'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // All validations passed, proceed with creation
    setState(() {
      _isSaving = true;
    });

    try {
      // Add "Other" category if not already present
      final categories = List<String>.from(_categories);
      if (!categories.contains('Other')) {
        categories.add('Other');
      }

      // Call SpaceProvider to create the custom space
      await widget.spaceProvider.createCustomSpace(
        name: _nameController.text.trim(),
        icon: _selectedIcon!,
        gradient: _selectedGradient!,
        description: _descriptionController.text.trim().isEmpty
            ? 'Custom space for ${_nameController.text.trim()}'
            : _descriptionController.text.trim(),
        categories: categories,
      );

      // Generate space ID (same logic as SpaceManager)
      final spaceId = _nameController.text.trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Space "${_nameController.text.trim()}" created successfully!',
            ),
            backgroundColor: AppColors.success,
          ),
        );

        // Navigate back and return the space ID
        Navigator.of(context).pop(spaceId);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create space: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
