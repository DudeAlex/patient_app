import 'package:flutter/material.dart';

/// Value object representing a gradient color scheme for a space
/// 
/// Encapsulates the visual identity colors used in space headers and cards.
/// Immutable and serializable for persistence.
class SpaceGradient {
  /// Starting color of the gradient
  final Color startColor;
  
  /// Ending color of the gradient
  final Color endColor;
  
  /// Gradient begin alignment (default: top-left)
  final AlignmentGeometry begin;
  
  /// Gradient end alignment (default: bottom-right)
  final AlignmentGeometry end;

  /// Cached LinearGradient to avoid recreating on every call
  /// Initialized lazily on first access to toLinearGradient()
  LinearGradient? _cachedLinearGradient;

  SpaceGradient({
    required this.startColor,
    required this.endColor,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  /// Converts this gradient to a Flutter LinearGradient
  /// Used for rendering in UI components
  /// Returns cached gradient if available, otherwise creates and caches it
  LinearGradient toLinearGradient() {
    // Return cached gradient or create and cache it
    return _cachedLinearGradient ??= LinearGradient(
      begin: begin,
      end: end,
      colors: [startColor, endColor],
    );
  }

  /// Converts gradient to JSON for serialization
  /// Only stores color values; alignment uses defaults on deserialization
  Map<String, dynamic> toJson() {
    return {
      'startColor': startColor.value,
      'endColor': endColor.value,
    };
  }

  /// Creates gradient from JSON
  /// Uses default alignment values
  factory SpaceGradient.fromJson(Map<String, dynamic> json) {
    return SpaceGradient(
      startColor: Color(json['startColor'] as int),
      endColor: Color(json['endColor'] as int),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpaceGradient &&
          runtimeType == other.runtimeType &&
          startColor == other.startColor &&
          endColor == other.endColor;

  @override
  int get hashCode => startColor.hashCode ^ endColor.hashCode;

  @override
  String toString() => 'SpaceGradient(start: $startColor, end: $endColor)';
}
