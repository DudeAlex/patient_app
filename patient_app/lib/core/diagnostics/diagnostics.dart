/// Public API for the diagnostic system.
/// 
/// Import this file to access logging functionality throughout the app.
library diagnostics;

// Main API
export 'app_logger.dart';
export 'diagnostic_system.dart';

// Models (for advanced usage)
export 'models/log_level.dart';
export 'models/log_entry.dart';
export 'models/log_config.dart';
export 'models/environment_context.dart';
export 'models/crash_info.dart';

// Services (for advanced usage)
export 'services/crash_detector.dart';
export 'services/global_error_handler.dart';
