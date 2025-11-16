import 'package:flutter/material.dart';

/// Color palette for the Patient App based on Figma design.
/// 
/// Uses a modern gradient-based color system with blue, purple, and pink
/// as primary colors, along with category-specific colors for health records.
class AppColors {
  // Prevent instantiation
  AppColors._();

  // Primary Gradient Colors
  static const gradientBlue = Color(0xFF3B82F6);    // blue-500
  static const gradientPurple = Color(0xFF8B5CF6);  // purple-500
  static const gradientTeal = Color(0xFF14B8A6);    // teal-500 (softer than pink)
  
  // Category Colors - Light backgrounds
  static const checkupLight = Color(0xFFDBEAFE);    // blue-100
  static const dentalLight = Color(0xFFF3E8FF);     // purple-100
  static const visionLight = Color(0xFFCCFBF1);     // teal-100 (softer than pink)
  static const labLight = Color(0xFFD1FAE5);        // green-100
  static const medicationLight = Color(0xFFFFEDD5); // orange-100
  
  // Category Colors - Dark text
  static const checkupDark = Color(0xFF1D4ED8);     // blue-700
  static const dentalDark = Color(0xFF7C3AED);      // purple-700
  static const visionDark = Color(0xFF0F766E);      // teal-700 (softer than pink)
  static const labDark = Color(0xFF059669);         // green-700
  static const medicationDark = Color(0xFFEA580C);  // orange-700
  
  // Neutral Colors - Gray scale
  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray300 = Color(0xFFD1D5DB);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF6B7280);
  static const gray600 = Color(0xFF4B5563);
  static const gray700 = Color(0xFF374151);
  static const gray800 = Color(0xFF1F2937);
  static const gray900 = Color(0xFF111827);
  
  // Semantic Colors
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const error = Color(0xFFEF4444);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);
  
  // Gradients
  /// Primary gradient used for headers and important UI elements
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientBlue, gradientPurple, gradientTeal],
  );
  
  /// Button gradient for primary action buttons
  static const buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [gradientBlue, gradientPurple],
  );
  
  /// Subtle background gradient for screens
  static const backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gray50, Color(0xFFF3E8FF), Color(0xFFFCE7F3)],
  );
  
  // Helper method to get category colors
  static Map<String, Color> getCategoryColors(String category) {
    switch (category.toLowerCase()) {
      case 'checkup':
        return {'light': checkupLight, 'dark': checkupDark};
      case 'dental':
        return {'light': dentalLight, 'dark': dentalDark};
      case 'vision':
        return {'light': visionLight, 'dark': visionDark};
      case 'lab':
        return {'light': labLight, 'dark': labDark};
      case 'medication':
        return {'light': medicationLight, 'dark': medicationDark};
      default:
        return {'light': gray100, 'dark': gray700};
    }
  }
  
  // Helper method to get category border color
  static Color getCategoryBorderColor(String category) {
    switch (category.toLowerCase()) {
      case 'checkup':
        return checkupDark;
      case 'dental':
        return dentalDark;
      case 'vision':
        return visionDark;
      case 'lab':
        return labDark;
      case 'medication':
        return medicationDark;
      default:
        return gray500;
    }
  }
}
