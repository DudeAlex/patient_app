import 'package:flutter/material.dart';
import '../../../core/diagnostics/app_logger.dart';
import '../../../ui/theme/app_colors.dart';
import '../../../ui/theme/app_text_styles.dart';
import '../../spaces/domain/space_registry.dart';
import '../../spaces/providers/space_provider.dart';
import 'create_space_screen.dart';
import 'widgets/space_card.dart';

/// Onboarding screen with 3 steps to introduce the Universal Spaces System.
/// 
/// Step 1: Welcome - Introduces the universal spaces concept
/// Step 2: Space Selection - Allows users to select their initial spaces
/// Step 3: Features Overview - Explains key features
/// 
/// Requirements: 10.1-10.9
class OnboardingScreen extends StatefulWidget {
  final SpaceProvider spaceProvider;
  final VoidCallback onComplete;

  const OnboardingScreen({
    super.key,
    required this.spaceProvider,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final SpaceRegistry _spaceRegistry = SpaceRegistry();
  
  // Track selected spaces (initially empty, user must select at least one)
  final Set<String> _selectedSpaceIds = {};

  @override
  void initState() {
    super.initState();
    AppLogger.info('OnboardingScreen initialized');
  }

  @override
  void dispose() {
    AppLogger.info('OnboardingScreen disposing');
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    AppLogger.info('Onboarding page changed', context: {'page': page});
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToFinal() {
    _pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _toggleSpaceSelection(String spaceId) {
    setState(() {
      if (_selectedSpaceIds.contains(spaceId)) {
        // Allow deselecting - user can have 0 spaces selected
        _selectedSpaceIds.remove(spaceId);
      } else {
        _selectedSpaceIds.add(spaceId);
      }
    });
  }

  Future<void> _completeOnboarding() async {
    try {
      AppLogger.info('Completing onboarding', context: {'selectedSpaces': _selectedSpaceIds.length});
      
      // Save selected spaces to storage
      for (final spaceId in _selectedSpaceIds) {
        await widget.spaceProvider.addSpace(spaceId);
      }

      // Set first space as current
      if (_selectedSpaceIds.isNotEmpty) {
        await widget.spaceProvider.switchSpace(_selectedSpaceIds.first);
      }

      // Mark onboarding complete (Requirements: 10.7)
      await widget.spaceProvider.setOnboardingComplete();

      AppLogger.info('Onboarding completed successfully');
      
      // Navigate to main app
      widget.onComplete();
    } catch (e, stackTrace) {
      AppLogger.error('Error completing onboarding', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicators (dots)
            _buildProgressIndicator(),
            
            // PageView for 3 steps
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  _buildWelcomeStep(),
                  _buildSpaceSelectionStep(),
                  _buildFeaturesOverviewStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Progress dots indicator at the top
  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          final isActive = index == _currentPage;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? AppColors.gradientPurple : AppColors.gray300,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  /// "Create Your Own Space" button for space selection step
  Widget _buildCreateCustomSpaceButton() {
    return InkWell(
      onTap: () async {
        try {
          AppLogger.info('Navigating to CreateSpaceScreen');
          
          // Navigate to create space screen
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateSpaceScreen(
                spaceProvider: widget.spaceProvider,
              ),
            ),
          );
          
          AppLogger.info('Returned from CreateSpaceScreen', context: {'result': result?.toString()});
          
          // If a custom space was created, add it to selected spaces
          if (result != null && result is String) {
            setState(() {
              _selectedSpaceIds.add(result);
            });
          }
        } catch (e, stackTrace) {
          AppLogger.error('Error navigating to CreateSpaceScreen', error: e, stackTrace: stackTrace);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.gradientPurple,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Plus icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Your Own Space',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.gradientPurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Design a custom space for your unique needs',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.gray600,
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.gradientPurple,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Step 1: Welcome
  /// Requirements: 10.2
  Widget _buildWelcomeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.grid_view_rounded,
              size: 64,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 32),
          
          // Title
          Text(
            'Welcome to Your Personal Space',
            style: AppTextStyles.h1.copyWith(
              color: AppColors.gray900,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Description
          Text(
            'Organize every area of your life in one secure place. From health to education, business to creative projects.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.gray600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Value propositions
          _buildValueProposition(
            Icons.tune,
            'Flexible',
            'Choose the spaces that matter to you',
          ),
          const SizedBox(height: 16),
          _buildValueProposition(
            Icons.auto_awesome,
            'AI-Powered',
            'Smart assistance for capturing and organizing',
          ),
          const SizedBox(height: 16),
          _buildValueProposition(
            Icons.lock,
            'Secure',
            'Your data stays private and encrypted',
          ),
          const SizedBox(height: 48),
          
          // Continue button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Continue',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Skip button (Requirements: 10.6)
          TextButton(
            onPressed: _skipToFinal,
            child: Text(
              'Skip',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.gray600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueProposition(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.gradientPurple,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.h4.copyWith(
                  color: AppColors.gray900,
                ),
              ),
              Text(
                description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.gray600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Step 2: Space Selection
  /// Requirements: 2.1-2.9, 10.3
  Widget _buildSpaceSelectionStep() {
    try {
      // Don't log in build methods - too noisy and causes performance issues
      final allSpaces = _spaceRegistry.getAllDefaultSpaces();
      
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Title
            Text(
              'Choose Your Spaces',
              style: AppTextStyles.h1.copyWith(
                color: AppColors.gray900,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Description
            Text(
              'Select the areas of life you want to organize. You can always add more later.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Selection count display
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
            const SizedBox(height: 24),
            
            // Space cards list
            Expanded(
              child: ListView.separated(
                itemCount: allSpaces.length + 1, // +1 for "Create Your Own" button
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  try {
                    // Show "Create Your Own Space" button as last item
                    if (index == allSpaces.length) {
                      return _buildCreateCustomSpaceButton();
                    }
                    
                    final space = allSpaces[index];
                    final isSelected = _selectedSpaceIds.contains(space.id);
                    
                    // Don't log in build methods - causes performance issues
                    return SpaceCard(
                      space: space,
                      isSelected: isSelected,
                      isCurrent: false,
                      onTap: () => _toggleSpaceSelection(space.id),
                    );
                  } catch (e, stackTrace) {
                    AppLogger.error('Error building space card at index $index', error: e, stackTrace: stackTrace);
                    return Container(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error loading space', style: TextStyle(color: Colors.red)),
                    );
                  }
                },
              ),
            ),
          const SizedBox(height: 24),
          
          // Continue button (disabled if no spaces selected)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedSpaceIds.isEmpty ? null : _nextPage,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Continue',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Skip button (Requirements: 10.6)
          TextButton(
            onPressed: _skipToFinal,
            child: Text(
              'Skip',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.gray600,
              ),
            ),
          ),
        ],
      ),
    );
    } catch (e, stackTrace) {
      AppLogger.error('Error building space selection step', error: e, stackTrace: stackTrace);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Error loading spaces. Please try again.',
            style: TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }

  /// Step 3: Features Overview
  /// Requirements: 10.4
  Widget _buildFeaturesOverviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.rocket_launch,
              size: 64,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 32),
          
          // Title
          Text(
            'Everything You Need',
            style: AppTextStyles.h1.copyWith(
              color: AppColors.gray900,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Description
          Text(
            'Powerful features to help you capture, organize, and find your information.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.gray600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Features
          _buildFeature(
            Icons.mic,
            'Multi-Modal Input',
            'Capture information through voice, camera, or keyboard',
          ),
          const SizedBox(height: 20),
          _buildFeature(
            Icons.auto_awesome,
            'AI Assistance',
            'Smart suggestions and automatic organization',
          ),
          const SizedBox(height: 20),
          _buildFeature(
            Icons.shield,
            'Privacy & Security',
            'Your data is encrypted and stays on your device',
          ),
          const SizedBox(height: 48),
          
          // Get Started button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _completeOnboarding,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Get Started',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: AppColors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.gray600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
