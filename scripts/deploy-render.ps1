# Deploy automatique sur Render (config + clear cache + deploy)
# Usage:
#   $env:RENDER_API_KEY = "rnd_xxxxxxxx"
#   .\scripts\deploy-render.ps1

$ErrorActionPreference = "Stop"

$ServiceId = "srv-d8ffajbeo5us73brqj2g"
$RootDir = "trig_essalama"
$DockerfilePath = "trig_essalama/Dockerfile"

if (-not $env:RENDER_API_KEY) {
    Write-Host "ERREUR: definissez RENDER_API_KEY avant de lancer ce script." -ForegroundColor Red
    Write-Host ""
    Write-Host "1. Render Dashboard -> Account Settings -> API Keys -> Create API Key"
    Write-Host "2. PowerShell:"
    Write-Host '   $env:RENDER_API_KEY = "rnd_votre_cle"'
    Write-Host "   .\scripts\deploy-render.ps1"
    exit 1
}

$headers = @{
    Authorization = "Bearer $env:RENDER_API_KEY"
    "Content-Type"  = "application/json"
    Accept          = "application/json"
}

Write-Host "==> Mise a jour du service Render ($ServiceId)..." -ForegroundColor Cyan

$patchBody = @{
    rootDir = $RootDir
    serviceDetails = @{
        env = "docker"
        envSpecificDetails = @{
            dockerfilePath = $DockerfilePath
        }
    }
} | ConvertTo-Json -Depth 5

try {
    $update = Invoke-RestMethod `
        -Method Patch `
        -Uri "https://api.render.com/v1/services/$ServiceId" `
        -Headers $headers `
        -Body $patchBody
    Write-Host "OK: Root Directory = $RootDir, Dockerfile = $DockerfilePath" -ForegroundColor Green
}
catch {
    Write-Host "AVERTISSEMENT: mise a jour des settings echouee (deploy quand meme)." -ForegroundColor Yellow
    Write-Host $_.Exception.Message
}

Write-Host ""
Write-Host "==> Deploiement avec vidage du cache build..." -ForegroundColor Cyan

$deployBody = @{
    clearCache = "clear"
} | ConvertTo-Json

try {
    $deploy = Invoke-RestMethod `
        -Method Post `
        -Uri "https://api.render.com/v1/services/$ServiceId/deploys" `
        -Headers $headers `
        -Body $deployBody

    $deployId = $deploy.id
    Write-Host "OK: deploy lance (id: $deployId)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Suivre les logs:"
    Write-Host "https://dashboard.render.com/web/$ServiceId"
    Write-Host ""
    Write-Host "Site:"
    Write-Host "https://grand-projet-pfe.onrender.com"
}
catch {
    Write-Host "ERREUR deploy:" -ForegroundColor Red
    if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message }
    else { Write-Host $_.Exception.Message }
    exit 1
}
