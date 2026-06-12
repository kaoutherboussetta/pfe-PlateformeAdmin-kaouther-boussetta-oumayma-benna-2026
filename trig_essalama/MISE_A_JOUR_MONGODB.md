# Mise à jour de la connexion MongoDB

## 🔗 Nouvelle connexion MongoDB

Votre nouvelle chaîne de connexion MongoDB est :
```
mongodb+srv://oumaymabenna2_db_user:<db_password>@trigessalama.sw3x05v.mongodb.net/?appName=trigEssalama
```

## 📝 Méthode 1 : Utiliser le script PowerShell (Recommandé)

1. Ouvrez PowerShell dans le dossier du projet
2. Exécutez le script :
   ```powershell
   .\update-mongodb-connection.ps1
   ```
3. Entrez votre mot de passe MongoDB quand demandé
4. Le script mettra à jour automatiquement votre fichier `.env`

## 📝 Méthode 2 : Modification manuelle du fichier `.env`

1. Ouvrez le fichier `.env` à la racine du projet
2. Trouvez ou ajoutez ces lignes :

```env
DB_CONNECTION=mongodb
MONGODB_DSN=mongodb+srv://oumaymabenna2_db_user:VOTRE_MOT_DE_PASSE@trigessalama.sw3x05v.mongodb.net/?appName=trigEssalama
MONGODB_DATABASE=trig_essalama
MONGODB_AUTHENTICATION_DATABASE=admin
```

**⚠️ IMPORTANT :**
- Remplacez `VOTRE_MOT_DE_PASSE` par votre vrai mot de passe MongoDB
- Si votre mot de passe contient des caractères spéciaux, vous devez les encoder en URL :
  - `@` → `%40`
  - `#` → `%23`
  - `$` → `%24`
  - `%` → `%25`
  - `&` → `%26`
  - `+` → `%2B`
  - `=` → `%3D`
  - `?` → `%3F`
  - `/` → `%2F`
  - Espace → `%20`

**Exemple :**
Si votre mot de passe est `Mon@Pass#123`, la ligne sera :
```
MONGODB_DSN=mongodb+srv://oumaymabenna2_db_user:Mon%40Pass%23123@trigessalama.sw3x05v.mongodb.net/?appName=trigEssalama
```

## 🔄 Après la mise à jour

1. **Vider le cache Laravel :**
   ```bash
   php artisan config:clear
   php artisan cache:clear
   ```

2. **Tester la connexion :**
   ```bash
   php artisan mongodb:test
   ```

3. **Si la connexion réussit :**
   - Vous verrez "✅ Connexion MongoDB réussie!"
   - Vous pouvez maintenant utiliser le formulaire d'inscription

## 🔍 Encodage automatique du mot de passe

Si vous voulez encoder votre mot de passe automatiquement, utilisez PowerShell :

```powershell
$password = "VotreMotDePasse"
$encoded = [System.Web.HttpUtility]::UrlEncode($password)
Write-Host "Mot de passe encodé : $encoded"
```

## ✅ Vérification

Après avoir mis à jour le `.env`, testez avec :

```bash
php artisan mongodb:test
```

Vous devriez voir :
- ✅ Connexion MongoDB réussie!
- Base de données: trig_essalama
- Collection: admin

## 🆘 Problèmes courants

### Erreur : "bad auth : authentication failed"
- Vérifiez que le mot de passe est correct
- Vérifiez que le mot de passe est correctement encodé si il contient des caractères spéciaux
- Vérifiez que l'utilisateur `oumaymabenna2_db_user` existe dans MongoDB Atlas

### Erreur : "Connection timeout"
- Vérifiez que votre IP est autorisée dans MongoDB Atlas (Network Access)
- Vérifiez votre connexion internet

### Erreur : "Could not connect"
- Vérifiez que l'extension PHP MongoDB est installée : `php -m | grep mongodb`
- Vérifiez les logs Laravel : `storage/logs/laravel.log`
