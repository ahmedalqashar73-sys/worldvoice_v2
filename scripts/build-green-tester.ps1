# Build the unchanged original GREEN room and improved board for testers.
# This script never ships a localhost-dependent APK. Firebase upload is
# optional and always requires the caller's explicit -UploadToFirebase flag.
param(
  [Parameter(Mandatory = $true)]
  [string]$BackendUrl,
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^[0-9a-fA-F]{32}$')]
  [string]$AgoraAppId,
  [switch]$UploadToFirebase,
  [string]$Testers = ""
)
$ErrorActionPreference = "Stop"
$BackendUrl = $BackendUrl.TrimEnd("/")
if (
  -not $BackendUrl.StartsWith("https://") -or
  $BackendUrl -match "(?i)(127\\.0\\.0\\.1|localhost|192\\.168\\.|10\\.0\\.)"
) {
  throw "An HTTPS public token server is REQUIRED for the tester APK. Do not build with a USB or local network address."
}
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw "Flutter was not found on PATH."
}
$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
  & flutter pub get
  if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed." }
  & flutter analyze
  if ($LASTEXITCODE -ne 0) { throw "Flutter analysis failed. Fix reported errors before distributing." }

  # The current project signs release builds with a DEBUG key. This APK is
  # for invite-only Firebase App Distribution testers, NOT a public store.
  & flutter build apk --release `
    "--dart-define=AGORA_APP_ID=$AgoraAppId" `
    "--dart-define=WORLDVOICE_ROOM_BACKEND_URL=$BackendUrl"
  if ($LASTEXITCODE -ne 0) { throw "APK build failed." }

  $apk = Join-Path $root "build/app/outputs/flutter-apk/app-release.apk"
  if (-not (Test-Path $apk)) { throw "Built APK was not found: $apk" }
  Write-Host "Tester APK is ready: $apk"

  if ($UploadToFirebase) {
    if ([string]::IsNullOrWhiteSpace($Testers)) {
      throw "Provide -Testers 'address@example.com' to send invitations explicitly."
    }
    if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
      throw "Firebase CLI is not installed. The APK is built; upload it manually in Firebase App Distribution or install firebase-tools."
    }
    # Android package com.worldvoice.app as configured in build.gradle.kts
    $firebaseAppId = "1:149108991969:android:b09d15308f8f5d9266d4a0"
    & firebase appdistribution:distribute $apk `
      --project worldvoice-37896 `
      --app $firebaseAppId `
      --testers $Testers `
      --release-notes "Green room with remotely hosted Agora token service and local board media improvements."
    if ($LASTEXITCODE -ne 0) {
      throw "APK built, but Firebase App Distribution upload failed."
    }
    Write-Host "Firebase App Distribution command completed. Verify testers in the console."
  }
} finally {
  Pop-Location
}
