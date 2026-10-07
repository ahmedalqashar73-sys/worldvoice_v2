param(
  [string]$ZipPath = "$env:USERPROFILE\Downloads\WorldVoice_Gifts_Ready_For_Project.zip"
)

$ErrorActionPreference = "Stop"
$project = Split-Path -Parent $PSScriptRoot
$target = Join-Path $project "assets\gifts\catalog"

if (-not (Test-Path $ZipPath)) {
  throw "Gift asset pack not found: $ZipPath"
}

$temp = Join-Path $env:TEMP ("worldvoice-gifts-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $temp -Force | Out-Null

try {
  Expand-Archive -Path $ZipPath -DestinationPath $temp -Force
  $source = Join-Path $temp "assets\gifts\catalog"
  $parts = Get-ChildItem $source -Filter "atlas_*.b64" | Sort-Object Name
  if ($parts.Count -ne 18) {
    throw "Expected 18 approved atlas parts, found $($parts.Count)."
  }

  New-Item -ItemType Directory -Path $target -Force | Out-Null
  Remove-Item (Join-Path $target "atlas_*.b64") -Force -ErrorAction SilentlyContinue
  Copy-Item (Join-Path $source "atlas_*.b64") -Destination $target -Force

  Write-Host "Installed 18 WorldVoice gift atlas parts." -ForegroundColor Green
  Set-Location $project
  flutter clean
  flutter pub get
  flutter analyze
}
finally {
  Remove-Item $temp -Recurse -Force -ErrorAction SilentlyContinue
}
