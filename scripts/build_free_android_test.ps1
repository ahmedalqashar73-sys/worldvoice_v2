param(
  [Parameter(Mandatory = $true)][string]$WorkerUrl,
  [string]$AuxBackendUrl
)
$ErrorActionPreference = "Stop"
$worker = $null
if (-not [uri]::TryCreate($WorkerUrl, [System.UriKind]::Absolute, [ref]$worker) -or
    $worker.Scheme -ne "https" -or
    $worker.Host -in @("localhost", "127.0.0.1", "10.0.2.2") -or
    $worker.UserInfo -or $worker.Query -or $worker.Fragment) {
  throw "Cloudflare Worker URL must be a deployed HTTPS service."
}
$backend = $WorkerUrl.TrimEnd("/")
if ($AuxBackendUrl) {
  $backend = $AuxBackendUrl.TrimEnd("/")
} else {
  Write-Warning "Audio + Firestore board test only: Teacher AI/quiz/store backend endpoints need a separately deployed full backend."
}
Set-Location (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
& (Join-Path $PSScriptRoot "build_android_release.ps1") -BackendUrl $backend -TokenEndpoint ($WorkerUrl.TrimEnd("/") + "/agora/token")
if (-not $?) { throw "Release build failed" }
