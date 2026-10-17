$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$downloads = Join-Path $HOME "Downloads"
$dest = Join-Path $root "assets\gifts\models"
New-Item -ItemType Directory -Force -Path $dest | Out-Null

$jobs = @(
  @{ Pattern = "Meshy_AI_*0930113835_texture.zip"; Out = "golden_muse.glb" },
  @{ Pattern = "Meshy_AI_Gilded_Clockwork_Owl_0930112631_texture.zip"; Out = "royal_clockwork_owl.glb" }
)

foreach ($job in $jobs) {
  $zip = Get-ChildItem -Path $downloads -Filter $job.Pattern |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-not $zip) { throw "Missing ZIP in Downloads: $($job.Pattern)" }

  $tmp = Join-Path $env:TEMP ("worldvoice3d_" + [guid]::NewGuid())
  New-Item -ItemType Directory -Force -Path $tmp | Out-Null
  try {
    Expand-Archive -LiteralPath $zip.FullName -DestinationPath $tmp -Force
    $glb = Get-ChildItem -Path $tmp -Recurse -Filter "*.glb" |
      Sort-Object Length -Descending | Select-Object -First 1
    if (-not $glb) { throw "No GLB inside $($zip.Name)" }
    Copy-Item -LiteralPath $glb.FullName -Destination (Join-Path $dest $job.Out) -Force
    Write-Host "Installed $($job.Out) ($([math]::Round($glb.Length / 1MB, 1)) MB)"
  } finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
  }
}

Write-Host "WorldVoice test 3D gifts installed."
Write-Host "Next: flutter pub get; flutter run --dart-define=WORLDVOICE_FRIEND_GIFT_PREVIEW=true"
