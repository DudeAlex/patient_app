param(
  [string]$EmulatorId = "Pixel",
  [string]$ServerClientId = "",
  [switch]$SkipBuildRunner
)

$ErrorActionPreference = 'Stop'

function Write-Step($msg) { Write-Host "[run_pixel] $msg" -ForegroundColor Cyan }
function Write-Warn($msg) { Write-Host "[run_pixel] $msg" -ForegroundColor Yellow }

# Ensure we run from the script directory (project root)
Set-Location -Path $PSScriptRoot

# Quick checks
Write-Step "Checking Flutter availability"
try {
  flutter --version | Out-Null
} catch {
  throw "Flutter not found in PATH. Install Flutter and reopen PowerShell."
}

# Resolve Server Client ID if not provided.
# This avoids needing to copy a long command each run.
if (-not $ServerClientId -or $ServerClientId.Trim().Length -eq 0) {
  # 1) Try env var set in the shell/session
  if ($env:GOOGLE_ANDROID_SERVER_CLIENT_ID) {
    $ServerClientId = $env:GOOGLE_ANDROID_SERVER_CLIENT_ID
    Write-Step "Using GOOGLE_ANDROID_SERVER_CLIENT_ID from environment."
  }
}
if (-not $ServerClientId -or $ServerClientId.Trim().Length -eq 0) {
  # 2) Try a local file to persist the ID between runs
  $cidPath = Join-Path $PSScriptRoot 'GOOGLE_CLIENT_ID.txt'
  if (Test-Path $cidPath) {
    try {
      $ServerClientId = (Get-Content -Raw $cidPath).Trim()
      if ($ServerClientId) { Write-Step "Using Client ID from GOOGLE_CLIENT_ID.txt" }
    } catch { }
  }
}
if (-not $ServerClientId -or $ServerClientId.Trim().Length -eq 0) {
  # 3) Prompt user interactively
  Write-Warn "ServerClientId not provided. Enter your Web Client ID (.apps.googleusercontent.com)."
  $ServerClientId = Read-Host 'Web Client ID'
  if ($ServerClientId -and $ServerClientId.Trim().Length -gt 0) {
    # Save for future runs
    $cidPath = Join-Path $PSScriptRoot 'GOOGLE_CLIENT_ID.txt'
    Set-Content -Path $cidPath -Value $ServerClientId
    Write-Step "Saved Client ID to GOOGLE_CLIENT_ID.txt for future runs."
  } else {
    Write-Warn "Proceeding without Client ID (Google sign-in will fail on Android)."
  }
}

# Launch emulator
Write-Step "Launching emulator '$EmulatorId'"
flutter emulators --launch $EmulatorId | Out-Null
Start-Sleep -Seconds 5

# Determine adb path and wait for boot
$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
if (-not (Test-Path $adb)) { $adb = 'adb' }

Write-Step "Waiting for Android emulator to boot (timeout ~120s)"
$booted = $false
for ($i = 0; $i -lt 120; $i++) {
  try {
    $out = & $adb shell getprop sys.boot_completed 2>$null
    if ($out -match '1') { $booted = $true; break }
  } catch { }
  Start-Sleep -Seconds 1
}
if (-not $booted) { Write-Warn "Boot not confirmed, proceeding anyway." }

# Resolve device id from flutter
Write-Step "Resolving device id"
$deviceLine = flutter devices | Select-String -Pattern 'emulator-\d+'
$deviceId = $deviceLine.Matches.Value | Select-Object -First 1
if (-not $deviceId) { throw "No running Android emulator device found." }
Write-Step "Using device id: $deviceId"

# Dependencies
Write-Step "Running flutter pub get"
flutter pub get

if (-not $SkipBuildRunner) {
  Write-Step "Running build_runner (code generation)"
  dart run build_runner build --delete-conflicting-outputs
} else {
  Write-Warn "Skipping build_runner per flag"
}

# Compose run command
$runArgs = @('run', '-d', $deviceId)
if ($ServerClientId -and $ServerClientId.Trim().Length -gt 0) {
  $runArgs += "--dart-define=GOOGLE_ANDROID_SERVER_CLIENT_ID=$ServerClientId"
}

Write-Step "Starting app on $deviceId"
flutter @runArgs
