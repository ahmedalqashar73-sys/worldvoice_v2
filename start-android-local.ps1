# Run from the root of the green WorldVoice test checkout.
# Start backend/start-local.ps1 in a SECOND PowerShell window first.
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
if (-not (Test-Path -LiteralPath $adb)) {
    throw "ADB is missing at $adb. Use flutter doctor -v to locate the Android SDK."
}

$connected = (& $adb devices) -join [Environment]::NewLine
Write-Host $connected
if ($connected -notmatch '(?m)^\S+\s+device\s*$') {
    throw 'No authorized Android device. Connect USB and approve USB debugging on the phone.'
}

try {
    $health = Invoke-RestMethod -Uri 'http://127.0.0.1:8080/health' -TimeoutSec 7
} catch {
    throw 'WorldVoice backend is not reachable. Start backend\start-local.ps1 in its own window first.'
}
if ($health.ok -ne $true) {
    throw 'Backend responded, but /health did not return ok: true.'
}

& $adb reverse tcp:8080 tcp:8080
if ($LASTEXITCODE -ne 0) {
    throw 'ADB reverse failed. Reconnect the phone and check adb devices.'
}
Write-Host 'ADB reverse is active. The Android app can reach the backend at 127.0.0.1:8080.'
& flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'Flutter dependency resolution failed.' }

& flutter run --dart-define=AGORA_APP_ID=fa41476c6813471eb45c059bcb4a0e19 --dart-define=WORLDVOICE_ROOM_BACKEND_URL=http://127.0.0.1:8080
if ($LASTEXITCODE -ne 0) {
    throw "Flutter run terminated with exit code $LASTEXITCODE"
}
