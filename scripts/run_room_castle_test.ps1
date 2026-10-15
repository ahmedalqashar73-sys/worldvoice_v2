param(
  [string]$DeviceId = "",
  [switch]$SkipAnalyze
)

$ErrorActionPreference = "Stop"
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

$branch = (& git branch --show-current).Trim()
if ($LASTEXITCODE -ne 0 -or $branch -ne "feature/scalable-progress-foundation") {
  throw "Switch to feature/scalable-progress-foundation before running this script. Current: $branch"
}

for ($i = 1; $i -le 10; $i++) {
  $start = ($i - 1) * 5 + 1
  $end = $i * 5
  $filename = "castle_{0:D2}_lv{1:D2}-{2:D2}.webp" -f $i, $start, $end
  $path = Join-Path "assets/castles" $filename
  if (-not (Test-Path $path)) {
    throw "Castle image is missing: $path. Run git pull --ff-only origin feature/scalable-progress-foundation"
  }
}
Write-Host "All ten premium castle images are present." -ForegroundColor Green

& flutter pub get
if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed." }

if (-not $SkipAnalyze) {
  & flutter analyze
  if ($LASTEXITCODE -ne 0) { throw "flutter analyze failed. Fix this before device testing." }
}

Write-Host "Connected Flutter devices:" -ForegroundColor Cyan
& flutter devices
if ($LASTEXITCODE -ne 0) { throw "flutter devices failed." }

$argsRun = @(
  "run",
  "--dart-define=AGORA_APP_ID=fa41476c6813471eb45c059bcb4a0e19",
  "--dart-define=WORLDVOICE_ROOM_BACKEND_URL=https://worldvoice-v2.onrender.com",
  "--dart-define=AGORA_TOKEN_ENDPOINT=https://worldvoice-agora-token.worldvoice.workers.dev/agora/token",
  "--dart-define=WORLDVOICE_ECONOMY_ENDPOINT=https://worldvoice-v2.onrender.com",
  "--dart-define=WORLDVOICE_FRIEND_GIFT_PREVIEW=true"
)
if ($DeviceId.Trim()) { $argsRun += "-d"; $argsRun += $DeviceId.Trim() }

Write-Host "Starting WorldVoice Flutter on your Android device..." -ForegroundColor Green
Write-Warning "This test uses the existing production backend; newer XP task endpoints may require a separate backend rollout."
& flutter @argsRun
if ($LASTEXITCODE -ne 0) { throw "flutter run failed with code $LASTEXITCODE" }
