param(
  [Parameter(Mandatory = $true)][string]$Testers
)

$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$apk = Join-Path (Get-Location) "build/app/outputs/flutter-apk/app-release.apk"
if (-not (Test-Path $apk)) {
  throw "First build the release APK using the deployed HTTPS backend."
}
# This is a non-secret Firebase app ID from firebase.json. If you change
# the Android Firebase app, update the ID for the matching package.
$appId = "1:149108991969:android:f9000a8165a8a38166d4a0"
firebase appdistribution:distribute $apk `
  --project "worldvoice-37896" `
  --app $appId `
  --release-notes "WorldVoice FRIEND TEST: emerald/gold gifts, 30 art designs, free cross-device demo animations only after reviewed Firestore rules are deployed. No real payments or coin gifts are enabled." `
  --testers $Testers
if ($LASTEXITCODE -ne 0) { throw "Firebase App Distribution upload failed" }
Write-Host "Release sent to Firebase App Distribution testers."
