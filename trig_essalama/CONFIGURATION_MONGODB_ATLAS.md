# Configuration MongoDB Atlas - Instructions Finales

## ✅ Ce qui a été fait

1. ✅ Package `jenssegers/mongodb` installé
2. ✅ Configuration MongoDB ajoutée dans `config/database.php`
3. ✅ Extension PHP MongoDB installée
4. ✅ Fichier `.env` configuré avec la connexion MongoDB

## 🔧 Étape finale : Remplacer le mot de passe

**IMPORTANT :** Vous devez remplacer `<db_password>` dans votre fichier `.env` par votre mot de passe MongoDB Atlas réel.

### Option 1 : Édition manuelle

1. Ouvrez le fichier `.env` à la racine du projet
2. Trouvez la ligne :
   ```
   MONGODB_DSN=mongodb+srv://oumaymabenna2_db_user:<db_password>@trigessalama.sw3x05v.mongodb.net/
   ```
3. Remplacez `<db_password>` par votre mot de passe réel

### Option 2 : Encodage du mot de passe (si caractères spéciaux)

Si votre mot de passe contient des caractères spéciaux, vous devez les encoder en URL :

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

**Exemple :** Si votre mot de passe est `Mon@Pass#123`, la ligne sera :
```
MONGODB_DSN=mongodb+srv://oumaymabenna2_db_user:Mon%40Pass%23123@trigessalama.sw3x05v.mongodb.net/
```

### Option 3 : Utiliser PowerShell pour encoder automatiquement

```powershell
# Remplacez "VotreMotDePasse" par votre mot de passe réel
$password = "VotreMotDePasse"
$encodedPassword = [System.Web.HttpUtility]::UrlEncode($password)
Write-Host "Mot de passe encodé : $encodedPassword"
```

## ✅ Vérification de la connexion

Une fois le mot de passe remplacé, testez la connexion :

### Test 1 : Via Tinker

```bash
php artisan tinker
```

Puis dans Tinker :
```php
DB::connection()->getDatabaseName();
```

Vous devriez voir : `"trig_essalama"`

### Test 2 : Lister les bases de données

```php
DB::connection('mongodb')->getMongoClient()->listDatabases();
```

### Test 3 : Créer un utilisateur de test

```php
$user = App\Models\User::create([
    'name' => 'Test User',
    'first_name' => 'Test',
    'last_name' => 'User',
    'email' => 'test@example.com',
    'password' => bcrypt('password123')
]);
echo "Utilisateur créé avec l'ID : " . $user->_id;
```

## 🔍 Vérifications importantes

1. **IP autorisée dans MongoDB Atlas :**
   - Allez dans MongoDB Atlas → Network Access
   - Assurez-vous que votre IP est autorisée (ou utilisez `0.0.0.0/0` pour le développement)

2. **Utilisateur MongoDB :**
   - Vérifiez que l'utilisateur `oumaymabenna2_db_user` existe dans MongoDB Atlas
   - Vérifiez que le mot de passe est correct

3. **Base de données :**
   - La base de données `trig_essalama` sera créée automatiquement lors de la première insertion

## 📝 Configuration actuelle dans `.env`

```
DB_CONNECTION=mongodb
MONGODB_DSN=mongodb+srv://oumaymabenna2_db_user:<db_password>@trigessalama.sw3x05v.mongodb.net/
MONGODB_DATABASE=trig_essalama
MONGODB_AUTHENTICATION_DATABASE=admin
```

## 🚨 Dépannage

### Erreur : "Connection timeout"
- Vérifiez que votre IP est autorisée dans MongoDB Atlas (Network Access)
- Vérifiez que le mot de passe est correctement encodé

### Erreur : "Authentication failed"
- Vérifiez le nom d'utilisateur et le mot de passe
- Vérifiez que l'utilisateur a les bonnes permissions

### Erreur : "Could not connect"
- Vérifiez que l'extension PHP MongoDB est installée : `php -m | grep mongodb`
- Vérifiez les logs Laravel : `storage/logs/laravel.log`

## 🎯 Prochaines étapes

Une fois la connexion testée avec succès :
1. Testez le formulaire d'inscription sur `http://localhost:8000/register`
2. Vérifiez dans MongoDB Atlas que les données sont bien enregistrées
3. Votre projet est maintenant connecté à MongoDB Atlas ! 🎉
