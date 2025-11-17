import 'package:flutter/material.dart';

import 'core/di/bootstrap.dart';
import 'core/diagnostics/diagnostic_system.dart';
import 'core/diagnostics/app_logger.dart';
import 'core/diagnostics/services/global_error_handler.dart';
import 'ui/app.dart';

void main() {
  // Run app in guarded zone to catch all errors
  GlobalErrorHandler.runGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize diagnostic system first
    await DiagnosticSystem.initialize();
    await AppLogger.info('App starting');
    await AppLogger.info('Global error handler active');
    
    // Bootstrap dependency injection
    await bootstrapAppContainer();
    
    // Log app launch
    await AppLogger.logAppLifecycle('launched');
    
    runApp(const PatientApp());
  });
}
