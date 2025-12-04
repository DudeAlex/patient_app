import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/gradient_header.dart';
import '../widgets/common/gradient_button.dart';
import '../widgets/common/category_badge.dart';

/// A screen showcasing the new design system components.
/// 
/// This screen demonstrates all the design elements from the Figma design
/// including colors, typography, buttons, badges, and layouts.
class DesignShowcaseScreen extends StatelessWidget {
  const DesignShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Gradient Header Example
          GradientHeader(
            title: 'Design Showcase',
            subtitle: 'Explore the new design system',
            onBackPressed: () => Navigator.pop(context),
            actions: [
              GradientHeaderActionButton(
                icon: Icons.info_outline,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('This is the new design system!'),
                    ),
                  );
                },
                tooltip: 'Info',
              ),
            ],
          ),
          
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Typography Section
                _Section(
                  title: 'Typography',
                  children: [
                    Text('Heading 1', style: AppTextStyles.h1),
                    const SizedBox(height: 8),
                    Text('Heading 2', style: AppTextStyles.h2),
                    const SizedBox(height: 8),
                    Text('Heading 3', style: AppTextStyles.h3),
                    const SizedBox(height: 8),
                    Text('Body Large', style: AppTextStyles.bodyLarge),
                    const SizedBox(height: 8),
                    Text('Body Medium', style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 8),
                    Text('Body Small', style: AppTextStyles.bodySmall),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Buttons Section
                _Section(
                  title: 'Buttons',
                  children: [
                    GradientButton(
                      text: 'Primary Button',
                      onPressed: () {},
                      icon: Icons.check,
                    ),
                    const SizedBox(height: 12),
                    SecondaryButton(
                      text: 'Secondary Button',
                      onPressed: () {},
                      icon: Icons.cancel,
                    ),
                    const SizedBox(height: 12),
                    GradientButton(
                      text: 'Loading...',
                      onPressed: () {},
                      isLoading: true,
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Category Badges Section
                _Section(
                  title: 'Category Badges',
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        CategoryBadge(category: 'Checkup'),
                        CategoryBadge(category: 'Dental'),
                        CategoryBadge(category: 'Vision'),
                        CategoryBadge(category: 'Lab'),
                        CategoryBadge(category: 'Medication'),
                        CategoryBadge(category: 'Other'),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Colors Section
                _Section(
                  title: 'Colors',
                  children: [
                    Row(
                      children: [
                        _ColorSwatch(
                          color: AppColors.gradientBlue,
                          label: 'Blue',
                        ),
                        const SizedBox(width: 12),
                        _ColorSwatch(
                          color: AppColors.gradientPurple,
                          label: 'Purple',
                        ),
                        const SizedBox(width: 12),
                        _ColorSwatch(
                          color: AppColors.gradientTeal,
                          label: 'Teal',
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Card Example
                _Section(
                  title: 'Cards',
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Sample Health Record',
                                    style: AppTextStyles.h3,
                                  ),
                                ),
                                const CategoryBadge(category: 'Checkup'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: AppColors.gray500,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Nov 14, 2025',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.gray500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'This is a sample health record card demonstrating the new design system with proper spacing, typography, and colors.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.gray600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Form Elements
                _Section(
                  title: 'Form Elements',
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: Icon(Icons.visibility),
                      ),
                      obscureText: true,
                    ),
                  ],
                ),
                
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.h2.copyWith(
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final String label;

  const _ColorSwatch({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.gray600,
            ),
          ),
        ],
      ),
    );
  }
}
