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

    # Flutter generates platform registration files during flutter run.
    # They do not affect the token Worker and must never be discarded.
    # Refuse only if the actual Worker source/config has local edits.
    $workerChanges = @(& git status --porcelain -- services/agora-token-worker)
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not inspect local Agora Worker changes. No deployment attempted.'
    }
    if ($workerChanges.Count -gt 0) {
        Write-Host ($workerChanges -join [Environment]::NewLine)
        throw 'The Agora Worker has local edits. Save or review those changes before deployment. Nothing was overwritten.'
    }

    $otherChanges = @(& git status --porcelain)
    if ($LASTEXITCODE -ne 0) {
        throw 'Could not inspect Git working tree. No deployment attempted.'
    }
    if ($otherChanges.Count -gt 0) {
        Write-Host 'Unrelated local files were modified (for example Flutter generated registrants); preserving them.' -ForegroundColor Yellow
    }

    & git pull --ff-only origin main
    if ($LASTEXITCODE -ne 0) {
        throw 'Git main could not fast-forward safely. Save conflicting local files; nothing was overwritten.'
    }

    # Confirm the Worker itself is still clean after synchronizing main.
    $workerChanges = @(& git status --porcelain -- services/agora-token-worker)
    if ($LASTEXITCODE -ne 0 -or $workerChanges.Count -gt 0) {
        throw 'Agora Worker has uncommitted edits after update. No deployment attempted.'
    }

    Push-Location (Join-Path $root 'services\agora-token-worker')
    try {
        & npm.cmd install --no-package-lock --no-audit --no-fund
        if ($LASTEXITCODE -ne 0) { throw 'Worker dependencies failed to install.' }

        & npm.cmd test
        if ($LASTEXITCODE -ne 0) { throw 'Worker tests failed. Deployment cancelled.' }

        # A Cloudflare dashboard browser session alone does not authenticate
        # Wrangler. Reuse a valid CLI OAuth session instead of needlessly
        # opening another authorization window on every deployment.
        & npx.cmd wrangler whoami
        if ($LASTEXITCODE -ne 0) {
            Write-Host 'Wrangler is not authenticated yet. Sign in to the existing Cloudflare account.' -ForegroundColor Yellow
            # Device OAuth is supported by Wrangler >=4.119.0 and avoids
            # the localhost callback timeout seen on this Windows PC.
            # The console shows a URL and a one-time code. Approve in Chrome;
            # never post the code or access credentials to chat.
            Write-Host 'Use Chrome to open https://dash.cloudflare.com/oauth2/device and enter the one-time code shown below.' -ForegroundColor Cyan
            & npx.cmd wrangler login --device --browser=false
            if ($LASTEXITCODE -ne 0) {
                throw 'Cloudflare device authorization failed or expired. Nothing was deployed. Re-run to request a new code.'
            }
            & npx.cmd wrangler whoami
            if ($LASTEXITCODE -ne 0) {
                throw 'Cloudflare authorization did not reach Wrangler. Nothing was deployed.'
            }
        }

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
