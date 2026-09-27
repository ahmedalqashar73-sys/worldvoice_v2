# Deploys the EXISTING WorldVoice room API to managed HTTPS.
# Prerequisites: Firebase/Google Cloud billing enabled, Google Cloud CLI,
# a NEW Agora primary certificate saved as a Secret Manager secret named
# worldvoice-agora-certificate (never store the certificate in this repo).
param(
  [string]$ProjectId = "worldvoice-37896",
  [string]$Region = "me-central2",
  [Parameter(Mandatory = $true)]
  [ValidatePattern('^[0-9a-fA-F]{32}$')]
  [string]$AgoraAppId
)
$ErrorActionPreference = "Stop"
$serviceName = "worldvoice-room-api"
$secretName = "worldvoice-agora-certificate"
$saName = "worldvoice-room-api"
$serviceAccount = "${saName}@${ProjectId}.iam.gserviceaccount.com"
$root = Split-Path -Parent $PSScriptRoot
$backend = Join-Path $root "backend"

function Invoke-Gcloud {
  param([Parameter(Mandatory=$true)][string[]]$CliArgs)
  & gcloud @CliArgs
  if ($LASTEXITCODE -ne 0) {
    throw "Google Cloud command failed. Check the error printed above."
  }
}

if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
  throw "Google Cloud CLI is not installed. Install it and run: gcloud auth login"
}
if (-not (Test-Path (Join-Path $backend "Dockerfile"))) {
  throw "This script must run from the green WorldVoice production branch."
}

Write-Host "Project: $ProjectId, region: $Region"
Write-Host "Required: Google Cloud billing and a rotated Agora certificate in Secret Manager."
Write-Host "The service will allow HTTP invocation, but app endpoints verify Firebase ID tokens."
$confirmation = Read-Host "Type DEPLOY if billing is enabled and you approve Cloud Run deployment"
if ($confirmation -cne "DEPLOY") {
  throw "Deployment cancelled. No cloud resources changed."
}

# Verify secret exists before enabling APIs or creating billable resources.
& gcloud secrets describe $secretName "--project=$ProjectId" "--format=value(name)" 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
  throw "Create a secret named $secretName containing a freshly rotated Agora PRIMARY certificate in Google Cloud Secret Manager first. Never commit or send it."
}
$versions = & gcloud secrets versions list $secretName "--project=$ProjectId" "--filter=state:ENABLED" "--format=value(name)"
if ($LASTEXITCODE -ne 0 -or -not $versions) {
  throw "The Secret Manager secret has no enabled versions. Add the new Agora primary certificate before deploying."
}

Invoke-Gcloud -CliArgs @("services", "enable",
  "run.googleapis.com",
  "cloudbuild.googleapis.com",
  "artifactregistry.googleapis.com",
  "secretmanager.googleapis.com",
  "--project=$ProjectId")

& gcloud iam service-accounts describe $serviceAccount "--project=$ProjectId" "--format=value(email)" 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
  Invoke-Gcloud -CliArgs @("iam","service-accounts","create",$saName,
    "--display-name=WorldVoice room backend","--project=$ProjectId")
}

$identity = "serviceAccount:$serviceAccount"
Invoke-Gcloud -CliArgs @("projects","add-iam-policy-binding",$ProjectId,
  "--member=$identity","--role=roles/firebaseauth.viewer","--quiet")
Invoke-Gcloud -CliArgs @("projects","add-iam-policy-binding",$ProjectId,
  "--member=$identity","--role=roles/datastore.user","--quiet")
Invoke-Gcloud -CliArgs @("secrets","add-iam-policy-binding",$secretName,
  "--project=$ProjectId","--member=$identity",
  "--role=roles/secretmanager.secretAccessor","--quiet")

# Min instances 0 avoids idle-instance charges but can incur cold starts.
# Firebase bearer authentication is enforced by the Express API itself.
Invoke-Gcloud -CliArgs @("run","deploy",$serviceName,
  "--source=$backend",
  "--region=$Region",
  "--project=$ProjectId",
  "--service-account=$serviceAccount",
  "--set-env-vars=FIREBASE_PROJECT_ID=$ProjectId,AGORA_APP_ID=$AgoraAppId",
  "--set-secrets=AGORA_APP_CERTIFICATE=${secretName}:latest",
  "--allow-unauthenticated",
  "--min-instances=0",
  "--max-instances=3",
  "--memory=1Gi",
  "--quiet")

$url = (& gcloud run services describe $serviceName
  "--region=$Region" "--project=$ProjectId" "--format=value(status.url)").Trim()
if ($LASTEXITCODE -ne 0 -or -not $url -or -not $url.StartsWith("https://")) {
  throw "Deployment might have succeeded, but no HTTPS service URL was returned."
}

Write-Host "SERVICE URL: $url"
Write-Host "Checking: $url/ready"
$ready = Invoke-RestMethod -Uri "$url/ready" -TimeoutSec 50
if (-not $ready.ok -or -not $ready.configured) {
  throw "Cloud Run is deployed, but token server configuration is incomplete."
}
Write-Host "READY: the API can start with configured Agora credentials."
Write-Host "NEXT: run scripts/build-green-tester.ps1 -BackendUrl '$url' -AgoraAppId '$AgoraAppId'"
Write-Host "NOTE: /ready checks configuration, not a real signed-in Agora join."
