# Local fallback ONLY (USB + adb reverse). Production requires Cloud Run.
# -SaveCertificate encrypts a fresh Agora primary certificate with the
# current Windows user's DPAPI. Never commit it to source control.
param([switch]$SaveCertificate)
$ErrorActionPreference = "Stop"
$project = "worldvoice-37896"
$appId = "fa41476c6813471eb45c059bcb4a0e19"
$folder = Join-Path $env:LOCALAPPDATA "WorldVoice"
$encrypted = Join-Path $folder "agora-cert.dpapi"
$backend = Join-Path (Split-Path -Parent $PSScriptRoot) "backend"
New-Item -ItemType Directory -Force -Path $folder | Out-Null

if ($SaveCertificate) {
  $secret = Read-Host "Enter a newly rotated Agora Primary Certificate" -AsSecureString
  $secret | ConvertFrom-SecureString | Set-Content -Path $encrypted
  Remove-Variable secret
  Write-Host "Encrypted for this Windows user (outside project source)."
  Write-Host "Run again WITHOUT -SaveCertificate to start."
  exit
}
if (-not (Test-Path $encrypted)) {
  throw "Run scripts/start-local-green.ps1 -SaveCertificate once first."
}
$key = Get-ChildItem (Join-Path $HOME "firebase-keys") -Filter "worldvoice-37896-firebase-adminsdk-*.json" -File -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $key -or -not (Test-Path $key.FullName)) {
  throw "Firebase private JSON not found in your firebase-keys folder."
}
$projectInKey = (Get-Content $key.FullName -Raw | ConvertFrom-Json).project_id
if ($projectInKey -ne $project) {
  throw "Firebase key is for the wrong project. Do not mix Firebase projects."
}
$encryptedCert = Get-Content $encrypted -Raw | ConvertTo-SecureString
$cert = [System.Net.NetworkCredential]::new("", $encryptedCert).Password
if ($cert.Length -ne 32) {
  throw "Saved Agora certificate is not 32 characters. Repeat -SaveCertificate."
}
$env:GOOGLE_APPLICATION_CREDENTIALS = $key.FullName
$env:FIREBASE_PROJECT_ID = $project
$env:AGORA_APP_ID = $appId
$env:AGORA_APP_CERTIFICATE = $cert
Remove-Variable cert, encryptedCert

Push-Location $backend
try {
  if (-not (Test-Path "node_modules/agora-token")) {
    & npm install
    if ($LASTEXITCODE -ne 0) { throw "npm install failed." }
  }
  Write-Host "Local backend on port 8080. Keep this PowerShell window open."
  Write-Host "On another window, connect USB and run adb reverse tcp:8080 tcp:8080"
  & npm start
} finally {
  Pop-Location
}
