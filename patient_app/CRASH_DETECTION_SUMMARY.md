# Crash Detection Summary

## ✅ Phase 6 Complete: Crash Detection System

The app now automatically detects crashes and preserves crash logs for debugging!

### How It Works

**Marker File System:**
1. On app start: Creates `.app_running` marker file
2. On graceful shutdown: Removes the marker file
3. On next start: If marker exists → crash detected!

**Crash Detection Flow:**
```
App Start
  ↓
Check for .app_running marker
  ↓
Marker exists? → CRASH DETECTED
  ├─ Log crash event
  ├─ Preserve last log file
  ├─ Save crash info
  └─ Create new marker
  ↓
Marker doesn't exist? → Clean start
  └─ Create new marker
  ↓
App Running...
  ↓
Graceful Shutdown
  └─ Remove marker
```

### What Gets Logged

**On Crash Detection:**
```
[ERROR] Previous crash detected
Context:
  - crashTime: 2025-11-16T10:30:45.123Z
  - detectedTime: 2025-11-16T10:35:12.456Z
  - lastLogFile: /path/to/app_log_2025-11-16_10-30-00.log
  - description: App crashed at 2025-11-16 10:30:45, detected 267s later
```

**On Normal Start:**
```
[INFO] Crash detection active
```

### Crash Log Preservation

**Automatic Preservation:**
- When a crash is detected, the most recent log file is copied to `crash_logs/`
- Filename format: `crash_2025-11-16_10-30-45.log`
- Original logs remain in `logs/` directory
- Crash logs are preserved separately for analysis

**File Locations:**
```
/data/data/com.example.patient_app/files/
├── logs/                          # Regular rotating logs
│   ├── app_log_2025-11-16_10-30-00.log
│   ├── app_log_2025-11-16_10-35-00.log
│   └── ...
├── crash_logs/                    # Preserved crash logs
│   ├── crash_2025-11-16_10-30-45.log
│   ├── crash_2025-11-15_14-22-10.log
│   └── ...
├── last_crash.json                # Most recent crash info
└── .app_running                   # Marker file (present while running)
```

### CrashInfo Model

**Stored Information:**
```dart
class CrashInfo {
  final DateTime crashTime;        // When the crash occurred
  final DateTime detectedTime;     // When we detected it
  final String? lastLogFile;       // Path to the log file
  final Map<String, dynamic> context;  // Additional context
}
```

**JSON Format:**
```json
{
  "crashTime": "2025-11-16T10:30:45.123Z",
  "detectedTime": "2025-11-16T10:35:12.456Z",
  "lastLogFile": "/path/to/logs/app_log_2025-11-16_10-30-00.log",
  "context": {
    "markerFileModified": "2025-11-16T10:30:45.123Z",
    "detectionTime": "2025-11-16T10:35:12.456Z"
  }
}
```

### API Usage

**Get Last Crash Info:**
```dart
final crashInfo = await DiagnosticSystem.getLastCrashInfo();
if (crashInfo != null) {
  print('Last crash: ${crashInfo.description}');
  print('Log file: ${crashInfo.lastLogFile}');
}
```

**Get All Crash Logs:**
```dart
final crashLogs = await DiagnosticSystem.getCrashLogFiles();
for (final logPath in crashLogs) {
  print('Crash log: $logPath');
}
```

**Clear Crash Logs:**
```dart
await DiagnosticSystem.clearCrashLogs();
```

**Direct CrashDetector Access:**
```dart
final detector = DiagnosticSystem.crashDetector;
if (detector != null) {
  await detector.markAppStarted();
  await detector.markAppStopped();
}
```

### Graceful Shutdown Handling

**Lifecycle Integration:**
```dart
class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // App is being terminated - mark graceful shutdown
      DiagnosticSystem.shutdown();
    }
  }
}
```

**What Happens on Shutdown:**
1. Log "Diagnostic system shutting down"
2. Remove crash marker file (`.app_running`)
3. Flush all log writers
4. Close all resources

### Benefits for Emulator Debugging

**Crash vs Disconnect:**
- If emulator disconnects and crash is detected → **App crashed**
- If emulator disconnects and no crash detected → **External issue** (emulator, ADB, etc.)

**Crash Analysis:**
1. Run app until emulator disconnects
2. Restart app
3. Check logs for "Previous crash detected"
4. Examine preserved crash log in `crash_logs/`
5. See exactly what was happening before the crash

**Example Investigation:**
```bash
# Check if crash was detected
adb logcat | grep "Previous crash detected"

# Get the preserved crash log
adb shell run-as com.example.patient_app ls -la files/crash_logs/

# Pull the crash log
adb shell run-as com.example.patient_app cat files/crash_logs/crash_2025-11-16_10-30-45.log > crash_log.json

# Analyze the log
cat crash_log.json | jq '.message' | tail -20
```

### Testing Crash Detection

**Simulate a Crash:**
```dart
// In your code, force an exception
throw Exception('Test crash');

// Or use assert
assert(false, 'Test crash');

// Or exit without cleanup
import 'dart:io';
exit(1);
```

**Verify Detection:**
1. Force crash
2. Restart app
3. Look for "Previous crash detected" in logs
4. Check `crash_logs/` directory for preserved log

### Configuration

**No configuration needed!**
- Crash detection is automatic
- Marker file is managed automatically
- Crash logs are preserved automatically
- Works on all platforms (Android, iOS, Windows, etc.)

### Platform-Specific Notes

**Android:**
- Marker file: `/data/data/com.example.patient_app/files/.app_running`
- Crash logs: `/data/data/com.example.patient_app/files/crash_logs/`
- Access via: `adb shell run-as com.example.patient_app`

**iOS:**
- Marker file: `~/Library/Developer/CoreSimulator/.../Documents/.app_running`
- Crash logs: `~/Library/Developer/CoreSimulator/.../Documents/crash_logs/`

**Windows:**
- Marker file: `C:\Users\[USER]\AppData\Roaming\[APP]\.app_running`
- Crash logs: `C:\Users\[USER]\AppData\Roaming\[APP]\crash_logs\`

### Limitations

**What's NOT Detected:**
- **Instant kills** - If the OS kills the app instantly (OOM, force stop), the marker file may not be created
- **Power loss** - If device loses power, marker file remains but it's not a crash
- **External termination** - If ADB kills the process, it looks like a crash

**Workarounds:**
- Check crash context for clues
- Compare crash time with device logs
- Look for patterns in crash logs

### Future Enhancements (Phase 10)

**Diagnostics UI will add:**
- View crash history in-app
- See crash count and frequency
- Export crash logs via share dialog
- Clear crash logs with confirmation
- Crash analytics and trends

## 🎯 Impact on Emulator Debugging

**Before Crash Detection:**
- Emulator disconnects → No idea if it was a crash
- No preserved logs → Hard to debug
- Manual investigation required

**After Crash Detection:**
- Emulator disconnects → Automatic crash detection on restart
- Preserved crash logs → Easy to analyze
- Clear indication of crash vs external issue
- Full context of what was happening before crash

**Next Steps:**
1. Run the app and let it hit the emulator disconnect issue
2. Restart the app
3. Check for "Previous crash detected" message
4. If detected → It's a crash! Examine the preserved log
5. If not detected → It's an external issue (emulator, ADB, etc.)

## 📊 Current Status

**Overall Progress:** ~65% complete

**Completed Phases:**
- ✅ Phase 1: Core Models
- ✅ Phase 2: Configuration & Privacy
- ✅ Phase 3: Log Writers
- ✅ Phase 4: Core Logging Service
- ✅ Phase 5: Performance Tracking
- ✅ Phase 6: Crash Detection ⭐ **JUST COMPLETED**
- ✅ Phase 11: Main App Integration (partial)

**Next Priority:**
- Phase 7: Global Error Handling - Catch ALL uncaught exceptions and log them

The crash detection system is now active! Every app start checks for previous crashes and preserves the logs for analysis.
