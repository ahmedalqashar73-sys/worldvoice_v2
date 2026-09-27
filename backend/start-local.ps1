# WorldVoice local backend startup for Windows PowerShell.
# The private Agora certificate is saved encrypted for this Windows user.
# Firebase credentials stay OUTSIDE the repository, under $HOME\firebase-keys.
param([switch]$ResetCertificate)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$firebaseProjectId = 'worldvoice-37896'
$agoraAppId = 'fa41476c6813471eb45c059bcb4a0e19'
$keyDirectory = Join-Path $HOME 'firebase-keys'
$privateDirectory = Join-Path $env:LOCALAPPDATA 'WorldVoice'
$encryptedCertPath = Join-Path $privateDirectory 'agora-certificate.clixml'

# Select the correct project by reading JSON metadata without printing secrets.
# On a first run, securely MOVE a downloaded service-account file out of Downloads.
if (-not (Test-Path -LiteralPath $keyDirectory)) {
    New-Item -Path $keyDirectory -ItemType Directory -Force | Out-Null
}
$findMatchingKey = {
    param([string]$directory)
    if (-not (Test-Path -LiteralPath $directory)) { return $null }
    Get-ChildItem -LiteralPath $directory -Filter '*firebase-adminsdk-*.json' -File |
        Where-Object {
            try {
                (Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json).project_id -eq $firebaseProjectId
            } catch {
                $false
            }
        } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}
$key = & $findMatchingKey $keyDirectory
if ($null -eq $key) {
    $downloaded = & $findMatchingKey (Join-Path $HOME 'Downloads')
    if ($null -ne $downloaded) {
        $newPath = Join-Path $keyDirectory $downloaded.Name
        Move-Item -LiteralPath $downloaded.FullName -Destination $newPath
        $key = Get-Item -LiteralPath $newPath
        Write-Host 'Moved Firebase JSON from Downloads into the private firebase-keys folder.'
    }
}
if ($null -eq $key) {
    throw "No Firebase service-account JSON for $firebaseProjectId found. Save it in $keyDirectory, outside the project."
}
$env:FIREBASE_PROJECT_ID = $firebaseProjectId
$env:GOOGLE_CLOUD_PROJECT = $firebaseProjectId
$env:GOOGLE_APPLICATION_CREDENTIALS = $key.FullName
$env:AGORA_APP_ID = $agoraAppId

if (-not (Test-Path -LiteralPath $privateDirectory)) {
    New-Item -Path $privateDirectory -ItemType Directory -Force | Out-Null
}
if ($ResetCertificate -and (Test-Path -LiteralPath $encryptedCertPath)) {
    Remove-Item -LiteralPath $encryptedCertPath
}
if (Test-Path -LiteralPath $encryptedCertPath) {
    try {
        $certificate = Import-Clixml -LiteralPath $encryptedCertPath
        if ($certificate -isnot [System.Security.SecureString]) {
            throw 'Encrypted certificate file is not a SecureString.'
        }
    } catch {
        throw 'Could not read the saved certificate. Rerun with: .\start-local.ps1 -ResetCertificate'
    }
} else {
    Write-Host 'First run: paste the Agora Primary Certificate. Input will be hidden.'
    $certificate = Read-Host 'Agora Primary Certificate' -AsSecureString
}
$plainCertificate = [System.Net.NetworkCredential]::new('', $certificate).Password.Trim()
if ($plainCertificate -notmatch '^[0-9a-fA-F]{32}$') {
    $plainCertificate = $null
    throw 'Agora certificate must be 32 hexadecimal characters. Use -ResetCertificate to replace a saved certificate.'
}
$env:AGORA_APP_CERTIFICATE = $plainCertificate
$plainCertificate = $null

if (-not (Test-Path -LiteralPath $encryptedCertPath)) {
    $certificate | Export-Clixml -LiteralPath $encryptedCertPath
    Write-Host 'Certificate saved securely for this Windows account outside the repository.'
}
Remove-Variable certificate -ErrorAction SilentlyContinue

# Worktrees are separate folders: Flutter pub get does not install Node deps.
# Restore any missing modules before starting the server.
$needInstall = -not (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'node_modules\agora-token\package.json'))
if (-not $needInstall) {
    & npm.cmd ls --depth=0 --silent *> $null
    $needInstall = ($LASTEXITCODE -ne 0)
}
if ($needInstall) {
    Write-Host 'Installing missing backend Node.js packages. This is normally needed once per worktree.'
    if (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'package-lock.json')) {
        & npm.cmd ci --no-audit --no-fund
    } else {
        & npm.cmd install --no-audit --no-fund
    }
    if ($LASTEXITCODE -ne 0) {
        throw 'npm dependency installation failed. Check internet connectivity and the npm output.'
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'node_modules\agora-token\package.json'))) {
    throw 'Backend is still missing agora-token. npm install did not finish successfully.'
}
# Catch accidentally leaving an older backend running in a separate window.
# Otherwise Flutter might reach that old process and show the previous errors.
$existingBackend = $null
try {
    $existingBackend = Invoke-RestMethod -Uri 'http://127.0.0.1:8080/health' -TimeoutSec 2
} catch {
    # No healthy HTTP backend currently listening.
}
if ($null -ne $existingBackend) {
    throw 'Port 8080 is already occupied. Stop the OLD backend (Ctrl+C) before launching this one.'
}

Write-Host 'Firebase project and certificate configured. Starting WorldVoice on localhost:8080.'
& npm.cmd start
if ($LASTEXITCODE -ne 0) {
    throw "WorldVoice backend terminated with exit code $LASTEXITCODE"
}
