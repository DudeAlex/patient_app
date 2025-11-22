import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

/// Environment and device context included in every log entry.
/// 
/// Provides information about the app version, device, OS, and session.
class EnvironmentContext {
  final String appVersion;
  final String buildNumber;
  final String environment;
  final String deviceType;
  final String osVersion;
  final String platform;
  final String sessionId;
  final String deviceId;

  EnvironmentContext({
    required this.appVersion,
    required this.buildNumber,
    required this.environment,
    required this.deviceType,
    required this.osVersion,
    required this.platform,
    required this.sessionId,
    required this.deviceId,
  });

  /// Cached instance to avoid repeated expensive operations
  static EnvironmentContext? _cached;

  /// Create environment context (cached after first call)
  static Future<EnvironmentContext> create() async {
    if (_cached != null) return _cached!;

    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();
    
    String deviceType = 'unknown';
    String osVersion = 'unknown';
    String deviceId = 'unknown';
    String platform = 'unknown';

    try {
      if (kIsWeb) {
        platform = 'web';
        final webInfo = await deviceInfo.webBrowserInfo;
        deviceType = 'browser';
        osVersion = '${webInfo.browserName} ${webInfo.appVersion}';
        deviceId = 'web-${webInfo.vendor}';
      } else if (Platform.isAndroid) {
        platform = 'android';
        final androidInfo = await deviceInfo.androidInfo;
        deviceType = androidInfo.isPhysicalDevice ? 'physical' : 'emulator';
        osVersion = 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        platform = 'ios';
        final iosInfo = await deviceInfo.iosInfo;
        deviceType = iosInfo.isPhysicalDevice ? 'physical' : 'simulator';
        osVersion = '${iosInfo.systemName} ${iosInfo.systemVersion}';
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
      } else if (Platform.isWindows) {
        platform = 'windows';
        final windowsInfo = await deviceInfo.windowsInfo;
        deviceType = 'desktop';
        osVersion = 'Windows ${windowsInfo.majorVersion}.${windowsInfo.minorVersion}';
        deviceId = windowsInfo.deviceId;
      } else if (Platform.isMacOS) {
        platform = 'macos';
        final macInfo = await deviceInfo.macOsInfo;
        deviceType = 'desktop';
        osVersion = 'macOS ${macInfo.osRelease}';
        deviceId = macInfo.systemGUID ?? 'unknown';
      } else if (Platform.isLinux) {
        platform = 'linux';
        final linuxInfo = await deviceInfo.linuxInfo;
        deviceType = 'desktop';
        osVersion = '${linuxInfo.name} ${linuxInfo.version}';
        deviceId = linuxInfo.machineId ?? 'unknown';
      }
    } catch (e) {
      // Fallback if device info fails
      debugPrint('[EnvironmentContext] Failed to get device info: $e');
    }

    // Determine environment (default to dev)
    const environment = String.fromEnvironment('ENV', defaultValue: 'dev');

    // Generate session ID
    final sessionId = const Uuid().v4();

    _cached = EnvironmentContext(
      appVersion: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      environment: environment,
      deviceType: deviceType,
      osVersion: osVersion,
      platform: platform,
      sessionId: sessionId,
      deviceId: deviceId,
    );

    return _cached!;
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() => {
        'appVersion': appVersion,
        'buildNumber': buildNumber,
        'environment': environment,
        'deviceType': deviceType,
        'osVersion': osVersion,
        'platform': platform,
        'sessionId': sessionId,
        'deviceId': deviceId,
      };

  @override
  String toString() =>
      '$platform/$deviceType v$appVersion ($buildNumber) - $osVersion';
}
