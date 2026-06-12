# Configuration DB_URI pour MongoDB

## ✅ Configuration effectuée

Le fichier `config/database.php` a été mis à jour avec :

```php
'mongodb' => [
    'driver' => 'mongodb',
    'dsn' => env('DB_URI'),
],
```

## 📝 Étape importante : Ajouter DB_URI dans .env

Vous devez maintenant ajouter `DB_URI` dans votre fichier `.env` :

```env
DB_CONNECTION=mongodb
DB_URI=mongodb+srv://oumaymabenna2_db_user:VOTRE_MOT_DE_PASSE@trigessalama.sw3x05v.mongodb.net/?appName=trigEssalama
```

**⚠️ IMPORTANT :**
- Remplacez `VOTRE_MOT_DE_PASSE` par votre vrai mot de passe MongoDB
- Si votre mot de passe contient des caractères spéciaux, encodez-les en URL :
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

## 🔄 Après avoir ajouté DB_URI dans .env

Exécutez ces commandes :

```bash
php artisan config:clear
php artisan cache:clear
php artisan serve
```

## ✅ Vérification

Testez la connexion avec :

```bash
php artisan mongodb:test
```

Vous devriez voir "✅ Connexion MongoDB réussie!"
