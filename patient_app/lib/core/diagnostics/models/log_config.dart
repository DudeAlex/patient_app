import 'dart:convert';
import 'package:flutter/services.dart';
import 'log_level.dart';

/// Configuration for the logging system.
/// 
/// Controls log levels, output destinations, file rotation, and filtering.
class LogConfig {
  final LogLevel minLevel;
  final bool consoleEnabled;
  final bool fileEnabled;
  final int maxFileSize;
  final int maxFiles;
  final List<String> moduleFilters;
  final List<String> moduleExcludes;
  final int performanceThreshold;

  const LogConfig({
    required this.minLevel,
    required this.consoleEnabled,
    required this.fileEnabled,
    required this.maxFileSize,
    required this.maxFiles,
    required this.moduleFilters,
    required this.moduleExcludes,
    required this.performanceThreshold,
  });

  /// Default configuration for development
  static const LogConfig defaultConfig = LogConfig(
    minLevel: LogLevel.debug,
    consoleEnabled: true,
    fileEnabled: true,
    maxFileSize: 5 * 1024 * 1024, // 5MB
    maxFiles: 5,
    moduleFilters: ['*'],
    moduleExcludes: [],
    performanceThreshold: 1000, // 1 second
  );

  /// Load configuration from JSON asset file
  static Future<LogConfig> load() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/config/logging_config.json');
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return LogConfig.fromJson(json);
    } catch (e) {
      // If config file doesn't exist or is invalid, use default
      print('[LogConfig] Failed to load config, using defaults: $e');
      return defaultConfig;
    }
  }

  /// Create from JSON
  factory LogConfig.fromJson(Map<String, dynamic> json) {
    return LogConfig(
      minLevel: LogLevel.fromString(json['minLevel'] as String? ?? 'debug'),
      consoleEnabled: json['consoleEnabled'] as bool? ?? true,
      fileEnabled: json['fileEnabled'] as bool? ?? true,
      maxFileSize: json['maxFileSize'] as int? ?? 5242880,
      maxFiles: json['maxFiles'] as int? ?? 5,
      moduleFilters: (json['moduleFilters'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['*'],
      moduleExcludes: (json['moduleExcludes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      performanceThreshold: json['performanceThreshold'] as int? ?? 1000,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'minLevel': minLevel.name,
        'consoleEnabled': consoleEnabled,
        'fileEnabled': fileEnabled,
        'maxFileSize': maxFileSize,
        'maxFiles': maxFiles,
        'moduleFilters': moduleFilters,
        'moduleExcludes': moduleExcludes,
        'performanceThreshold': performanceThreshold,
      };

  /// Check if a module should be logged based on filters
  bool shouldLogModule(String module) {
    // Check excludes first
    if (moduleExcludes.any((pattern) => _matchesPattern(module, pattern))) {
      return false;
    }

    // Check includes
    if (moduleFilters.isEmpty || moduleFilters.contains('*')) {
      return true;
    }

    return moduleFilters.any((pattern) => _matchesPattern(module, pattern));
  }

  /// Simple pattern matching (supports * wildcard)
  bool _matchesPattern(String value, String pattern) {
    if (pattern == '*') return true;
    if (pattern == value) return true;

    // Convert pattern to regex
    final regexPattern = pattern
        .replaceAll('.', r'\.')
        .replaceAll('*', '.*')
        .replaceAll('?', '.');

    return RegExp('^$regexPattern\$', caseSensitive: false).hasMatch(value);
  }

  /// Create a copy with updated fields
  LogConfig copyWith({
    LogLevel? minLevel,
    bool? consoleEnabled,
    bool? fileEnabled,
    int? maxFileSize,
    int? maxFiles,
    List<String>? moduleFilters,
    List<String>? moduleExcludes,
    int? performanceThreshold,
  }) {
    return LogConfig(
      minLevel: minLevel ?? this.minLevel,
      consoleEnabled: consoleEnabled ?? this.consoleEnabled,
      fileEnabled: fileEnabled ?? this.fileEnabled,
      maxFileSize: maxFileSize ?? this.maxFileSize,
      maxFiles: maxFiles ?? this.maxFiles,
      moduleFilters: moduleFilters ?? this.moduleFilters,
      moduleExcludes: moduleExcludes ?? this.moduleExcludes,
      performanceThreshold: performanceThreshold ?? this.performanceThreshold,
    );
  }
}
