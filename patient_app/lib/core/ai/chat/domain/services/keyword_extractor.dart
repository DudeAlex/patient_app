import 'dart:math' as math;

/// Extracts keywords from text using a language-agnostic approach.
/// 
/// This implementation avoids language-specific processing like stop word removal
/// or stemming to work universally across languages (English, Russian, Uzbek, etc.).
/// 
/// The approach:
/// 1. Split on whitespace and punctuation
/// 2. Convert to lowercase for case-insensitive matching
/// 3. Remove very short words (< 2 characters)
/// 4. NO stop word removal (language-agnostic)
/// 5. NO stemming (language-agnostic)
class KeywordExtractor {
  /// Extracts keywords from the provided text.
  /// 
  /// Returns a list of keywords after processing:
  /// - Splitting on whitespace and punctuation
  /// - Converting to lowercase
  /// - Removing words shorter than 2 characters
  /// 
  /// Example:
  /// ```dart
  /// final extractor = KeywordExtractor();
  /// final keywords = extractor.extract("What is my blood pressure?");
  /// // Returns: ["what", "is", "my", "blood", "pressure"]
  /// ```
  List<String> extract(String text) {
    if (text.isEmpty) {
      return [];
    }

    // Split on any character that is not a Unicode letter or number
    // Using unicode: true enables Unicode support for the \p{L} and \p{N} patterns
    final words = text.split(RegExp(r'[^\p{L}\p{N}]+', unicode: true));
    
    // Remove empty strings, convert to lowercase, and filter short words
    final keywords = <String>[];
    for (final word in words) {
      final cleanedWord = word.toLowerCase().trim();
      if (cleanedWord.isNotEmpty && cleanedWord.length >= 2) {
        keywords.add(cleanedWord);
      }
    }
    
    return keywords;
  }
}