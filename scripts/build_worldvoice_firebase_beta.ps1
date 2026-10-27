# WorldVoice original Android beta - Windows PowerShell
# Builds the complete EXISTING Flutter app, not a separate Stories demo.
# Does not modify room, gift, live or backend source files.
[CmdletBinding()]
param(
    [switch]$SkipGitUpdate
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $root
$expectedBranch = 'feature/scalable-progress-foundation'

function Confirm-LastExitCode([string]$operation) {
    if ($LASTEXITCODE -ne 0) {
        throw "$operation failed with exit code $LASTEXITCODE. Nothing was uploaded."
    }
}

if (-not (Test-Path (Join-Path $root 'pubspec.yaml')) -or
    -not (Test-Path (Join-Path $root 'android/app/google-services.json'))) {
    throw 'Open the original worldvoice_v2 checkout. Firebase config or pubspec.yaml not found.'
}
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'Git is not on PATH.'
}
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Flutter is not on PATH. Configure Flutter SDK on this laptop first.'
}

$branch = (& git branch --show-current).Trim()
Confirm-LastExitCode 'Checking the current branch'
if ($branch -ne $expectedBranch) {
    throw "Current branch is '$branch', not '$expectedBranch'. Stopping to protect the original local project."
}
$changes = @(& git status --porcelain)
Confirm-LastExitCode 'Checking local modifications'
if ($changes.Count -gt 0) {
    Write-Host 'Local edits detected (your room/gift changes may be among them):' -ForegroundColor Yellow
    $changes | ForEach-Object { Write-Host $_ }
    throw 'Save/commit or safely back up and reconcile local changes before updating/building. This script will not discard them.'
}

if (-not $SkipGitUpdate) {
    Write-Host 'Fetching newest WorldVoice source from GitHub...' -ForegroundColor Cyan
    & git fetch origin $expectedBranch
    Confirm-LastExitCode 'Git fetch'
    & git merge --ff-only 'FETCH_HEAD'
    Confirm-LastExitCode 'Fast-forward only merge'
}

$commit = (& git rev-parse --short HEAD).Trim()
Confirm-LastExitCode 'Reading commit'
Write-Host "Building full WorldVoice app at commit $commit" -ForegroundColor Cyan

& flutter pub get
Confirm-LastExitCode 'Flutter pub get'

# The next revision code increases across real-world builds (Android int-safe).
# Existing test APK may use code 1. Do not change the Android package name.
$buildNumber = [int][Math]::Floor(([DateTime]::UtcNow - [DateTime]'2020-01-01').TotalMinutes)
$arguments = @(
    'build', 'apk', '--release',
    "--build-number=$buildNumber",
    '--dart-define=AGORA_APP_ID=fa41476c6813471eb45c059bcb4a0e19',
    '--dart-define=WORLDVOICE_ROOM_BACKEND_URL=https://worldvoice-v2.onrender.com',
    '--dart-define=AGORA_TOKEN_ENDPOINT=https://worldvoice-agora-token.worldvoice.workers.dev/agora/token',
    '--dart-define=WORLDVOICE_ECONOMY_ENDPOINT=https://worldvoice-v2.onrender.com',
    '--dart-define=WORLDVOICE_FRIEND_GIFT_PREVIEW=true',
    '--dart-define=WORLDVOICE_STORY_BACKEND_URL=https://worldvoice-stories.onrender.com'
)
& flutter @arguments
Confirm-LastExitCode 'Flutter Android release build'

$apk = Join-Path $root 'build/app/outputs/flutter-apk/app-release.apk'
if (-not (Test-Path $apk)) {
    throw 'Flutter finished but build/app/outputs/flutter-apk/app-release.apk does not exist.'
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$desktop = [Environment]::GetFolderPath('Desktop')
if ([string]::IsNullOrWhiteSpace($desktop) -or -not (Test-Path $desktop)) {
    $desktop = $root
}
$destination = Join-Path $desktop "WorldVoice-Beta-$stamp.apk"
Copy-Item -LiteralPath $apk -Destination $destination -ErrorAction Stop

Write-Host ''
Write-Host "SUCCESS: Complete WorldVoice APK is on your laptop." -ForegroundColor Green
Write-Host "APK: $destination"
Write-Host "Git commit: $commit"
Write-Host "Android versionCode: $buildNumber"
Write-Host "SHA-256: $((Get-FileHash $destination -Algorithm SHA256).Hash)"
Write-Host ''
Write-Host 'Next: Firebase Console > worldvoice-37896 > App Distribution > Android com.worldvoice.app > Upload APK.'
Write-Host 'Keep this laptop debug signing key stable for beta upgrades. Do not publish this debug-signed APK to Google Play.'
