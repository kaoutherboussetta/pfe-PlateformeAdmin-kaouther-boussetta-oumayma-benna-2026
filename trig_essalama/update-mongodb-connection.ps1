# Script pour mettre à jour la connexion MongoDB dans le fichier .env
# Usage: .\update-mongodb-connection.ps1

$envFile = ".env"
$backupFile = ".env.backup"

# Vérifier si le fichier .env existe
if (-not (Test-Path $envFile)) {
    Write-Host "❌ Le fichier .env n'existe pas!" -ForegroundColor Red
    Write-Host "💡 Créez d'abord un fichier .env à partir de .env.example" -ForegroundColor Yellow
    exit 1
}

# Créer une sauvegarde
Copy-Item $envFile $backupFile
Write-Host "✅ Sauvegarde créée: $backupFile" -ForegroundColor Green

# Demander le mot de passe MongoDB
Write-Host ""
Write-Host "🔐 Entrez le mot de passe MongoDB pour l'utilisateur 'oumaymabenna2_db_user':" -ForegroundColor Cyan
$password = Read-Host -AsSecureString
$passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))

# Encoder le mot de passe pour l'URL (si nécessaire)
$encodedPassword = [System.Web.HttpUtility]::UrlEncode($passwordPlain)

# Lire le contenu du fichier .env
$content = Get-Content $envFile -Raw

# Nouveau DSN MongoDB avec appName
$newDsn = "mongodb+srv://oumaymabenna2_db_user:$encodedPassword@trigessalama.sw3x05v.mongodb.net/?appName=trigEssalama"

# Mettre à jour ou ajouter les variables MongoDB
$lines = Get-Content $envFile

$updated = $false
$newLines = @()

foreach ($line in $lines) {
    if ($line -match "^DB_CONNECTION=") {
        $newLines += "DB_CONNECTION=mongodb"
        $updated = $true
    }
    elseif ($line -match "^MONGODB_DSN=") {
        $newLines += "MONGODB_DSN=$newDsn"
        $updated = $true
    }
    elseif ($line -match "^MONGODB_DATABASE=") {
        $newLines += "MONGODB_DATABASE=trig_essalama"
        $updated = $true
    }
    elseif ($line -match "^MONGODB_AUTHENTICATION_DATABASE=") {
        $newLines += "MONGODB_AUTHENTICATION_DATABASE=admin"
        $updated = $true
    }
    elseif ($line -match "^MONGODB_HOST=" -or $line -match "^MONGODB_PORT=" -or $line -match "^MONGODB_USERNAME=" -or $line -match "^MONGODB_PASSWORD=") {
        # Ignorer les anciennes configurations individuelles si on utilise DSN
        continue
    }
    else {
        $newLines += $line
    }
}

# Ajouter les configurations si elles n'existent pas
$hasDbConnection = $newLines | Where-Object { $_ -match "^DB_CONNECTION=" }
$hasMongodbDsn = $newLines | Where-Object { $_ -match "^MONGODB_DSN=" }
$hasMongodbDatabase = $newLines | Where-Object { $_ -match "^MONGODB_DATABASE=" }
$hasMongodbAuthDb = $newLines | Where-Object { $_ -match "^MONGODB_AUTHENTICATION_DATABASE=" }

if (-not $hasDbConnection) {
    $newLines += "DB_CONNECTION=mongodb"
}

if (-not $hasMongodbDsn) {
    $newLines += "MONGODB_DSN=$newDsn"
}

if (-not $hasMongodbDatabase) {
    $newLines += "MONGODB_DATABASE=trig_essalama"
}

if (-not $hasMongodbAuthDb) {
    $newLines += "MONGODB_AUTHENTICATION_DATABASE=admin"
}

# Écrire le nouveau contenu
$newLines | Set-Content $envFile

Write-Host ""
Write-Host "✅ Configuration MongoDB mise à jour!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Configuration appliquée:" -ForegroundColor Cyan
Write-Host "   DB_CONNECTION=mongodb"
Write-Host "   MONGODB_DSN=mongodb+srv://oumaymabenna2_db_user:***@trigessalama.sw3x05v.mongodb.net/?appName=trigEssalama"
Write-Host "   MONGODB_DATABASE=trig_essalama"
Write-Host "   MONGODB_AUTHENTICATION_DATABASE=admin"
Write-Host ""
Write-Host "🔄 N'oubliez pas d'exécuter:" -ForegroundColor Yellow
Write-Host "   php artisan config:clear"
Write-Host "   php artisan cache:clear"
Write-Host "   php artisan mongodb:test"
Write-Host ""
