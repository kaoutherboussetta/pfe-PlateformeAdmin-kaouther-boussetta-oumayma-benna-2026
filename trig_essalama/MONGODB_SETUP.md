# Configuration MongoDB Atlas

## Instructions pour configurer MongoDB Atlas avec votre projet Laravel

### 1. Configuration du fichier .env

Ouvrez votre fichier `.env` et ajoutez/modifiez les lignes suivantes :

```env
# Connexion par défaut
DB_CONNECTION=mongodb

# Configuration MongoDB Atlas
MONGODB_DSN=mongodb+srv://<db_username>:<db_password>@cluster0.z0ygk2c.mongodb.net/
MONGODB_DATABASE=votre_nom_de_base_de_donnees

# Ou configuration détaillée (alternative)
# MONGODB_HOST=cluster0.z0ygk2c.mongodb.net
# MONGODB_PORT=27017
# MONGODB_USERNAME=votre_username
# MONGODB_PASSWORD=votre_password
# MONGODB_DATABASE=votre_nom_de_base_de_donnees
# MONGODB_AUTHENTICATION_DATABASE=admin
```

### 2. Remplacez les valeurs suivantes :

- **`<db_username>`** : Remplacez par votre nom d'utilisateur MongoDB Atlas
- **`<db_password>`** : Remplacez par votre mot de passe MongoDB Atlas
- **`votre_nom_de_base_de_donnees`** : Remplacez par le nom de votre base de données (par exemple : `trig_essalama`)

### 3. Exemple de configuration complète :

```env
DB_CONNECTION=mongodb
MONGODB_DSN=mongodb+srv://monuser:monpassword123@cluster0.z0ygk2c.mongodb.net/
MONGODB_DATABASE=trig_essalama
```

**⚠️ IMPORTANT :** 
- Assurez-vous que votre mot de passe ne contient pas de caractères spéciaux qui nécessitent un encodage URL. Si c'est le cas, encodez-les (par exemple, `@` devient `%40`, `#` devient `%23`, etc.)
- Ne commitez jamais votre fichier `.env` dans Git (il devrait déjà être dans `.gitignore`)

### 4. Vérification de la connexion

Pour tester la connexion, vous pouvez utiliser Tinker :

```bash
php artisan tinker
```

Puis dans Tinker :
```php
DB::connection('mongodb')->getMongoClient()->listDatabases();
```

Ou simplement :
```php
DB::connection()->getDatabaseName();
```

### 5. Utilisation dans vos modèles

Pour utiliser MongoDB avec vos modèles Laravel, étendez `Jenssegers\Mongodb\Eloquent\Model` au lieu de `Illuminate\Database\Eloquent\Model` :

```php
<?php

namespace App\Models;

use Jenssegers\Mongodb\Eloquent\Model;

class User extends Model
{
    protected $connection = 'mongodb';
    // ...
}
```

### 6. Notes importantes

- Le package `jenssegers/mongodb` est installé et configuré
- La connexion MongoDB est maintenant la connexion par défaut
- Assurez-vous que l'extension PHP `mongodb` est activée dans votre `php.ini`
- Vérifiez que votre IP est autorisée dans MongoDB Atlas (Network Access)
