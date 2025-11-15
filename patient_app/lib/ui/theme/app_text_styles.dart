import 'package:flutter/material.dart';

/// Typography system for the Patient App based on Figma design.
/// 
/// Provides consistent text styles throughout the app with proper
/// hierarchy, readability, and accessibility.
class AppTextStyles {
  // Prevent instantiation
  AppTextStyles._();

  /// Base font family - can be customized
  static const String fontFamily = 'Roboto'; // Default Flutter font
  
  // Headings - Used for titles and section headers
  
  /// Large heading (24px) - Used for screen titles
  static const h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: -0.5,
    fontFamily: fontFamily,
  );
  
  /// Medium heading (20px) - Used for section titles
  static const h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: -0.3,
    fontFamily: fontFamily,
  );
  
  /// Small heading (18px) - Used for card titles
  static const h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.5,
    fontFamily: fontFamily,
  );
  
  /// Extra small heading (16px) - Used for subsection titles
  static const h4 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    fontFamily: fontFamily,
  );
  
  // Body Text - Used for main content
  
  /// Large body text (16px) - Used for primary content
  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    fontFamily: fontFamily,
  );
  
  /// Medium body text (14px) - Used for secondary content
  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    fontFamily: fontFamily,
  );
  
  /// Small body text (12px) - Used for captions and metadata
  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    fontFamily: fontFamily,
  );
  
  // Labels - Used for buttons, form labels, and UI elements
  
  /// Large label (16px) - Used for primary buttons
  static const labelLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    fontFamily: fontFamily,
  );
  
  /// Medium label (14px) - Used for secondary buttons and form labels
  static const labelMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    fontFamily: fontFamily,
  );
  
  /// Small label (12px) - Used for chips and small UI elements
  static const labelSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5,
    fontFamily: fontFamily,
  );
  
  // Special Text Styles
  
  /// Button text style
  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.5,
    fontFamily: fontFamily,
  );
  
  /// Input text style
  static const input = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    fontFamily: fontFamily,
  );
  
  /// Hint text style
  static const hint = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    fontFamily: fontFamily,
  );
  
  /// Error text style
  static const error = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    fontFamily: fontFamily,
  );
}
