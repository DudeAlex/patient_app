/// Information about a detected crash.
/// 
/// Stores crash timestamp and context to help with debugging.
class CrashInfo {
  final DateTime crashTime;
  final DateTime detectedTime;
  final String? lastLogFile;
  final Map<String, dynamic> context;

  CrashInfo({
    required this.crashTime,
    required this.detectedTime,
    this.lastLogFile,
    Map<String, dynamic>? context,
  }) : context = context ?? {};

  /// Create from JSON
  factory CrashInfo.fromJson(Map<String, dynamic> json) {
    return CrashInfo(
      crashTime: DateTime.parse(json['crashTime'] as String),
      detectedTime: DateTime.parse(json['detectedTime'] as String),
      lastLogFile: json['lastLogFile'] as String?,
      context: Map<String, dynamic>.from(json['context'] as Map? ?? {}),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'crashTime': crashTime.toIso8601String(),
      'detectedTime': detectedTime.toIso8601String(),
      'lastLogFile': lastLogFile,
      'context': context,
    };
  }

  /// Get a human-readable description
  String get description {
    final duration = detectedTime.difference(crashTime);
    return 'App crashed at ${_formatTime(crashTime)}, '
        'detected ${duration.inSeconds}s later at ${_formatTime(detectedTime)}';
  }

  String _formatTime(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-'
        '${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }
}
