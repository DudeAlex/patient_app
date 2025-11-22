import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// A button with gradient background matching the app's design system.
/// 
/// This button provides a polished look with gradient colors and shadow.
/// It supports loading states and optional icons.
/// 
/// Example:
/// ```dart
/// GradientButton(
///   text: 'Sign In',
///   onPressed: () => _handleSignIn(),
///   icon: Icons.login,
/// )
/// ```
class GradientButton extends StatelessWidget {
  /// The text displayed on the button
  final String text;
  
  /// Callback when the button is pressed
  final VoidCallback? onPressed;
  
  /// Whether the button is in loading state
  final bool isLoading;
  
  /// Optional icon displayed before the text
  final IconData? icon;
  
  /// Whether the button should expand to fill available width
  final bool expanded;
  
  /// Custom gradient (if null, uses default button gradient)
  final Gradient? gradient;

  const GradientButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.expanded = true,
    this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonContent = Container(
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.buttonGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.gradientPurple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (isLoading || onPressed == null) ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.white,
                      ),
                    ),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(icon, color: AppColors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (expanded) {
      return SizedBox(
        width: double.infinity,
        child: buttonContent,
      );
    }

    return buttonContent;
  }
}

/// A secondary button with outline style
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool expanded;

  const SecondaryButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.expanded = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonContent = OutlinedButton(
      onPressed: (isLoading || onPressed == null) ? null : onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        side: const BorderSide(
          color: AppColors.gray300,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.gray700,
                ),
              ),
            )
          else ...[
            if (icon != null) ...[
              Icon(icon, color: AppColors.gray700, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: AppTextStyles.button.copyWith(
                color: AppColors.gray700,
              ),
            ),
          ],
        ],
      ),
    );

    if (expanded) {
      return SizedBox(
        width: double.infinity,
        child: buttonContent,
      );
    }

    return buttonContent;
  }
}
