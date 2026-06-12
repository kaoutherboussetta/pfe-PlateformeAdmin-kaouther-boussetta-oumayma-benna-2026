# Script pour mettre à jour le mot de passe MongoDB dans .env
# Usage: .\update-mongodb-password.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Mise à jour du mot de passe MongoDB" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Demander le mot de passe
$password = Read-Host "Entrez votre mot de passe MongoDB Atlas" -AsSecureString
$passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
)

# Encoder le mot de passe pour URL
Add-Type -AssemblyName System.Web
$encodedPassword = [System.Web.HttpUtility]::UrlEncode($passwordPlain)

Write-Host ""
Write-Host "Mot de passe encodé : $encodedPassword" -ForegroundColor Yellow
Write-Host ""

# Lire le fichier .env
$envPath = Join-Path $PSScriptRoot ".env"
if (-not (Test-Path $envPath)) {
    Write-Host "Erreur: Fichier .env introuvable!" -ForegroundColor Red
    exit 1
}

$content = Get-Content $envPath -Raw

# Mettre à jour DB_URI
$oldPattern = 'DB_URI="mongodb\+srv://oumaymabenna2_db_user:[^@]+@trigessalama\.sw3x05v\.mongodb\.net/trig_essalama\?retryWrites=true&w=majority"'
$newUri = "DB_URI=`"mongodb+srv://oumaymabenna2_db_user:$encodedPassword@trigessalama.sw3x05v.mongodb.net/trig_essalama?retryWrites=true&w=majority`""

if ($content -match $oldPattern) {
    $content = $content -replace $oldPattern, $newUri
    Write-Host "✅ DB_URI mis à jour" -ForegroundColor Green
} else {
    # Si le pattern n'est pas trouvé, chercher et remplacer manuellement
    if ($content -match 'DB_URI="[^"]+"') {
        $content = $content -replace 'DB_URI="[^"]+"', $newUri
        Write-Host "✅ DB_URI mis à jour (pattern alternatif)" -ForegroundColor Green
    } else {
        Write-Host "⚠️  DB_URI non trouvé, ajout de la ligne..." -ForegroundColor Yellow
        # Ajouter après DB_CONNECTION
        $content = $content -replace '(DB_CONNECTION=mongodb)', "`$1`n$newUri"
    }
}

# Sauvegarder
$content | Set-Content $envPath -NoNewline

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "✅ Fichier .env mis à jour avec succès!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Prochaines étapes:" -ForegroundColor Cyan
Write-Host "1. Exécutez: php artisan config:clear" -ForegroundColor White
Write-Host "2. Exécutez: php artisan cache:clear" -ForegroundColor White
Write-Host "3. Testez la connexion avec: php artisan tinker" -ForegroundColor White
Write-Host ""
