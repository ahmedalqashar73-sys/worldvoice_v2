# Deploys the EXISTING Cloudflare Worker, never a new Worker or a new app.
# Run from the original Windows WorldVoice checkout on branch main:
# powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\deploy_live_agora_worker.ps1
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
    $branch = (& git branch --show-current).Trim()
    if ($LASTEXITCODE -ne 0 -or $branch -ne 'main') {
        throw 'Open the ORIGINAL WorldVoice repo on the main branch. No branches were changed.'
    }

    $changes = @(& git status --porcelain)
    if ($LASTEXITCODE -ne 0 -or $changes.Count -gt 0) {
        throw 'Local changes exist. Save them before deployment; nothing was overwritten.'
    }

    & git pull --ff-only origin main
    if ($LASTEXITCODE -ne 0) { throw 'Git main could not fast-forward. No Worker was deployed.' }

    Push-Location (Join-Path $root 'services\agora-token-worker')
    try {
        & npm.cmd install --no-package-lock --no-audit --no-fund
        if ($LASTEXITCODE -ne 0) { throw 'Worker dependencies failed to install.' }

        & npm.cmd test
        if ($LASTEXITCODE -ne 0) { throw 'Worker tests failed. Deployment cancelled.' }

        # Owner signs in via the browser; no API token or certificate is
        # pasted into the repository or printed in the terminal.
        & npx.cmd wrangler login
        if ($LASTEXITCODE -ne 0) { throw 'Cloudflare login failed. Deployment cancelled.' }

        & npx.cmd wrangler whoami
        if ($LASTEXITCODE -ne 0) { throw 'Cloudflare account could not be verified.' }

        Write-Host 'Deploying existing Worker: worldvoice-agora-token'
        & npx.cmd wrangler deploy
        if ($LASTEXITCODE -ne 0) { throw 'Cloudflare deployment failed.' }

        $health = Invoke-RestMethod -Method Get -Uri 'https://worldvoice-agora-token.worldvoice.workers.dev/health' -TimeoutSec 30
        if ($health.tokenApiRevision -ne '2026-10-30.1' -or
            $health.liveHostBootstrapSupported -ne $true -or
            $health.ok -ne $true) {
            throw 'Worker is not yet serving revision 2026-10-30.1. Check Cloudflare deployment.'
        }

        Write-Host 'SUCCESS: Existing Agora Worker is serving revision 2026-10-30.1.' -ForegroundColor Green
        Write-Host 'Now run the full WorldVoice flutter run command on main.' -ForegroundColor Green
    } finally {
        Pop-Location
    }
} finally {
    Pop-Location
}
