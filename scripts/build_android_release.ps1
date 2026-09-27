param(
  [Parameter(Mandatory = $true)][string]$BackendUrl,
  [string]$AgoraAppId = "fa41476c6813471eb45c059bcb4a0e19"
)

$ErrorActionPreference = "Stop"
$parsed = $null
if (-not [uri]::TryCreate($BackendUrl, [System.UriKind]::Absolute, [ref]$parsed) -or
    $parsed.Scheme -ne "https" -or
    $parsed.Host -in @("localhost", "127.0.0.1", "10.0.2.2") -or
    $parsed.UserInfo -or $parsed.Query -or $parsed.Fragment) {
  throw "A deployed HTTPS backend URL is required; never build a release against local 127.0.0.1."
}
if ($AgoraAppId -notmatch '^[a-fA-F0-9]{32}$') {
  throw "Invalid public Agora App ID."
}
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
flutter pub get
if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed" }
flutter analyze
if ($LASTEXITCODE -ne 0) { throw "flutter analyze failed" }
flutter build apk --release "--dart-define=AGORA_APP_ID=$AgoraAppId" "--dart-define=WORLDVOICE_ROOM_BACKEND_URL=$($parsed.AbsoluteUri.TrimEnd('/'))"
if ($LASTEXITCODE -ne 0) { throw "flutter build apk failed" }
Write-Host "Release APK created at build/app/outputs/flutter-apk/app-release.apk"
