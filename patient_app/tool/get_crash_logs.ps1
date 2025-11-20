param(
  [string]$OutputDir = "retrieved_logs"
)

$ErrorActionPreference = 'Stop'

function Write-Step($msg) { Write-Host "[get_crash_logs] $msg" -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host "[get_crash_logs] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "[get_crash_logs] $msg" -ForegroundColor Yellow }
function Write-Err($msg) { Write-Host "[get_crash_logs] $msg" -ForegroundColor Red }

# Ensure we run from the script directory (project root)
Set-Location -Path $PSScriptRoot

# Determine adb path
$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
if (-not (Test-Path $adb)) { 
  $adb = 'adb'
  Write-Step "Using adb from PATH"
} else {
  Write-Step "Using adb from Android SDK"
}

# Check if device is connected
Write-Step "Checking for connected devices"
$devices = & $adb devices | Select-String -Pattern 'emulator-\d+|device'
if (-not $devices) {
  Write-Err "No Android device/emulator found. Please start your emulator first."
  exit 1
}

# App package name
$packageName = "com.example.patient_app"

# Create output directory
if (-not (Test-Path $OutputDir)) {
  New-Item -ItemType Directory -Path $OutputDir | Out-Null
  Write-Step "Created output directory: $OutputDir"
}

# Get app's data directory path
Write-Step "Retrieving app data directory path"
$appDataPath = "/data/data/$packageName/files"

# Check if crash logs directory exists
Write-Step "Checking for crash logs"
$crashLogsExist = & $adb shell "run-as $packageName test -d $appDataPath/crash_logs && echo 'exists' || echo 'not_found'" 2>$null
if ($crashLogsExist -match 'not_found') {
  Write-Warn "No crash_logs directory found. Either no crashes occurred or app hasn't run yet."
} else {
  Write-Success "Found crash_logs directory"
  
  # List crash log files
  Write-Step "Listing crash log files"
  $crashLogFiles = & $adb shell "run-as $packageName ls $appDataPath/crash_logs" 2>$null
  
  if ($crashLogFiles) {
    Write-Success "Found crash log files:"
    $crashLogFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    
    # Pull each crash log file
    foreach ($logFile in $crashLogFiles) {
      $logFile = $logFile.Trim()
      if ($logFile) {
        Write-Step "Pulling $logFile"
        $remotePath = "$appDataPath/crash_logs/$logFile"
        $localPath = Join-Path $OutputDir $logFile
        
        # Use run-as to read the file and save locally
        & $adb shell "run-as $packageName cat $remotePath" | Out-File -FilePath $localPath -Encoding UTF8
        Write-Success "Saved to $localPath"
      }
    }
  } else {
    Write-Warn "No crash log files found in crash_logs directory"
  }
}

# Check for last_crash.json
Write-Step "Checking for last_crash.json"
$crashInfoExists = & $adb shell "run-as $packageName test -f $appDataPath/last_crash.json && echo 'exists' || echo 'not_found'" 2>$null
if ($crashInfoExists -match 'exists') {
  Write-Success "Found last_crash.json"
  $localCrashInfo = Join-Path $OutputDir "last_crash.json"
  & $adb shell "run-as $packageName cat $appDataPath/last_crash.json" | Out-File -FilePath $localCrashInfo -Encoding UTF8
  Write-Success "Saved to $localCrashInfo"
  
  # Display crash info
  Write-Step "Last crash information:"
  Get-Content $localCrashInfo | ConvertFrom-Json | Format-List
} else {
  Write-Warn "No last_crash.json found"
}

# Check for regular log files
Write-Step "Checking for regular log files"
$logsExist = & $adb shell "run-as $packageName test -d $appDataPath/logs && echo 'exists' || echo 'not_found'" 2>$null
if ($logsExist -match 'exists') {
  Write-Success "Found logs directory"
  
  # List log files
  $logFiles = & $adb shell "run-as $packageName ls -t $appDataPath/logs" 2>$null | Select-Object -First 5
  
  if ($logFiles) {
    Write-Success "Found recent log files (showing last 5):"
    $logFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    
    # Pull the most recent log files
    foreach ($logFile in $logFiles) {
      $logFile = $logFile.Trim()
      if ($logFile) {
        Write-Step "Pulling $logFile"
        $remotePath = "$appDataPath/logs/$logFile"
        $localPath = Join-Path $OutputDir $logFile
        
        & $adb shell "run-as $packageName cat $remotePath" | Out-File -FilePath $localPath -Encoding UTF8
        Write-Success "Saved to $localPath"
      }
    }
  } else {
    Write-Warn "No log files found in logs directory"
  }
} else {
  Write-Warn "No logs directory found"
}

# Check for .app_running marker (indicates if app is currently running or crashed)
Write-Step "Checking for crash marker file"
$markerExists = & $adb shell "run-as $packageName test -f $appDataPath/.app_running && echo 'exists' || echo 'not_found'" 2>$null
if ($markerExists -match 'exists') {
  Write-Warn "Marker file .app_running exists - app may have crashed or is still running"
  $markerContent = & $adb shell "run-as $packageName cat $appDataPath/.app_running" 2>$null
  Write-Host "  Marker timestamp: $markerContent" -ForegroundColor Yellow
} else {
  Write-Success "No marker file found - app shut down gracefully last time"
}

# Also capture logcat for recent errors
Write-Step "Capturing recent logcat errors"
$logcatFile = Join-Path $OutputDir "logcat_errors.txt"
& $adb logcat -d -s "flutter:E" "*:F" | Out-File -FilePath $logcatFile -Encoding UTF8
Write-Success "Saved logcat errors to $logcatFile"

Write-Success "`nLog retrieval complete! Check the '$OutputDir' directory for all logs."
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "  1. Review crash logs in $OutputDir" -ForegroundColor White
Write-Host "  2. Check last_crash.json for crash details" -ForegroundColor White
Write-Host "  3. Examine logcat_errors.txt for system-level errors" -ForegroundColor White
