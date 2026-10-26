param(
  [Parameter(Mandatory = $true)][string]$ServiceAccount,
  [string]$Project = "worldvoice-37896",
  [string]$Region = "me-central1",
  [string]$AgoraAppId = "fa41476c6813471eb45c059bcb4a0e19",
  [string]$CertificateSecret = "worldvoice-agora-cert"
)

$ErrorActionPreference = "Stop"
if ($ServiceAccount -notmatch '^[^@\s]+@[^@\s]+\.iam\.gserviceaccount\.com$') {
  throw "Provide a pre-created, least-privilege service account in the Firebase project."
}
Write-Host "Before deploying: verify billing is enabled, grant the service account Firebase Auth/Firestore permissions and Secret Manager Secret Accessor on the certificate secret."
gcloud config set project $Project
if ($LASTEXITCODE -ne 0) { throw "gcloud project selection failed" }
gcloud secrets describe $CertificateSecret --project $Project
if ($LASTEXITCODE -ne 0) { throw "Create Agora certificate in Secret Manager first; never paste it into command flags or Git." }
$backend = (Resolve-Path (Join-Path $PSScriptRoot "../backend")).Path
gcloud run deploy worldvoice-room-backend `
  --source $backend `
  --project $Project `
  --region $Region `
  --service-account $ServiceAccount `
  --allow-unauthenticated `
  --min-instances 0 `
  --max-instances 2 `
  --set-env-vars "FIREBASE_PROJECT_ID=$Project,AGORA_APP_ID=$AgoraAppId" `
  --set-secrets "AGORA_APP_CERTIFICATE=$($CertificateSecret):latest"
if ($LASTEXITCODE -ne 0) { throw "Cloud Run deployment failed" }
$backendUrl = gcloud run services describe worldvoice-room-backend --project $Project --region $Region --format "value(status.url)"
if ($LASTEXITCODE -ne 0 -or -not $backendUrl) { throw "Could not read service URL" }
Write-Host "Verify your HTTPS backend:" $backendUrl
Write-Host "Build your Android release with: .\scripts\build_android_release.ps1 -BackendUrl $backendUrl"
