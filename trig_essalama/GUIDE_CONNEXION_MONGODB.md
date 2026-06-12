# Guide Complet : Connexion de votre projet Laravel à MongoDB Atlas

Ce guide vous explique étape par étape comment connecter votre projet Laravel à MongoDB Atlas et à votre base de données `trig_essalama`.

---

## 📋 Prérequis

- Un compte MongoDB Atlas (gratuit disponible sur [mongodb.com/cloud/atlas](https://www.mongodb.com/cloud/atlas))
- PHP avec l'extension MongoDB installée
- Le package `jenssegers/mongodb` déjà installé (✅ déjà fait dans votre projet)

---

## 🔧 Étape 1 : Configuration MongoDB Atlas

### 1.1 Créer ou accéder à votre cluster MongoDB Atlas

1. Connectez-vous à [MongoDB Atlas](https://cloud.mongodb.com/)
2. Si vous n'avez pas de cluster, créez-en un :
   - Cliquez sur **"Create"** ou **"Build a Database"**
   - Choisissez le plan **FREE (M0)** pour commencer
   - Sélectionnez votre région (choisissez la plus proche de vous)
   - Cliquez sur **"Create"**

### 1.2 Créer un utilisateur de base de données

1. Dans votre cluster, allez dans **"Database Access"** (menu de gauche)
2. Cliquez sur **"Add New Database User"**
3. Choisissez **"Password"** comme méthode d'authentification
4. Créez un nom d'utilisateur (ex: `trig_essalama_user`)
5. Créez un mot de passe **fort** (⚠️ **IMPORTANT** : notez-le, vous en aurez besoin)
6. Pour les privilèges, sélectionnez **"Atlas admin"** ou **"Read and write to any database"**
7. Cliquez sur **"Add User"**

### 1.3 Autoriser l'accès réseau

1. Allez dans **"Network Access"** (menu de gauche)
2. Cliquez sur **"Add IP Address"**
3. Pour le développement local, vous avez deux options :
   
   **Option A : Autoriser toutes les IP (pour tester rapidement)**
   - Cliquez sur **"Allow Access from Anywhere"**
   - L'adresse sera `0.0.0.0/0`
   - ⚠️ **Note** : Cette option est moins sécurisée, utilisez-la uniquement pour le développement
   
   **Option B : Autoriser uniquement votre IP (recommandé)**
   - Cliquez sur **"Add Current IP Address"** (si vous êtes sur la même machine)
   - Ou entrez manuellement votre adresse IP publique
   - Vous pouvez trouver votre IP sur [whatismyip.com](https://www.whatismyip.com/)

4. Cliquez sur **"Confirm"**

### 1.4 Obtenir la chaîne de connexion (Connection String)

1. Retournez dans **"Database"** (menu de gauche)
2. Cliquez sur **"Connect"** sur votre cluster
3. Choisissez **"Connect your application"**
4. Sélectionnez **"Driver"** : `PHP`
5. Sélectionnez **"Version"** : `1.15` ou la version la plus récente
6. **Copiez la chaîne de connexion** qui ressemble à :
   ```
   mongodb+srv://<username>:<password>@cluster0.xxxxx.mongodb.net/
   ```
   ⚠️ **IMPORTANT** : Remplacez `<username>` et `<password>` par les identifiants que vous avez créés à l'étape 1.2

### 1.5 Créer la base de données `trig_essalama` (si elle n'existe pas)

1. Dans MongoDB Atlas, allez dans **"Database"** → **"Browse Collections"**
2. Si la base de données `trig_essalama` n'existe pas encore, elle sera créée automatiquement lors de la première insertion de données
3. Vous pouvez aussi créer manuellement une collection `admin` dans cette base de données

---

## 💻 Étape 2 : Configuration du projet Laravel

### 2.1 Vérifier l'extension PHP MongoDB

Ouvrez un terminal et exécutez :
```bash
php -m | grep mongodb
```

Si vous voyez `mongodb`, c'est bon ! Sinon, installez l'extension :

**Sur Windows (avec XAMPP/WAMP) :**
1. Téléchargez l'extension PHP MongoDB depuis [pecl.php.net/package/mongodb](https://pecl.php.net/package/mongodb)
2. Placez le fichier `.dll` dans le dossier `ext` de PHP
3. Ajoutez `extension=mongodb` dans votre `php.ini`
4. Redémarrez votre serveur web

**Sur Linux (Ubuntu/Debian) :**
```bash
sudo pecl install mongodb
sudo echo "extension=mongodb.so" >> /etc/php/8.2/cli/php.ini
sudo echo "extension=mongodb.so" >> /etc/php/8.2/apache2/php.ini
```

**Sur macOS :**
```bash
brew install php-mongodb
```

### 2.2 Configurer le fichier `.env`

1. Ouvrez le fichier `.env` à la racine de votre projet
2. Ajoutez ou modifiez les lignes suivantes :

```env
# Connexion par défaut
DB_CONNECTION=mongodb

# Configuration MongoDB Atlas avec DSN (Recommandé)
MONGODB_DSN=mongodb+srv://VOTRE_USERNAME:VOTRE_PASSWORD@cluster0.xxxxx.mongodb.net/
MONGODB_DATABASE=trig_essalama

# OU Configuration détaillée (Alternative si DSN ne fonctionne pas)
# MONGODB_HOST=cluster0.xxxxx.mongodb.net
# MONGODB_PORT=27017
# MONGODB_USERNAME=VOTRE_USERNAME
# MONGODB_PASSWORD=VOTRE_PASSWORD
# MONGODB_DATABASE=trig_essalama
# MONGODB_AUTHENTICATION_DATABASE=admin
```

**⚠️ REMPLACEZ :**
- `VOTRE_USERNAME` : Le nom d'utilisateur créé à l'étape 1.2
- `VOTRE_PASSWORD` : Le mot de passe créé à l'étape 1.2
- `cluster0.xxxxx.mongodb.net` : Votre URL de cluster MongoDB Atlas

**⚠️ IMPORTANT - Encodage du mot de passe :**
Si votre mot de passe contient des caractères spéciaux, vous devez les encoder en URL :
- `@` devient `%40`
- `#` devient `%23`
- `$` devient `%24`
- `%` devient `%25`
- `&` devient `%26`
- `+` devient `%2B`
- `=` devient `%3D`
- `?` devient `%3F`
- `/` devient `%2F`
- ` ` (espace) devient `%20`

**Exemple :**
Si votre mot de passe est `Mon@Pass#123`, la chaîne de connexion sera :
```
MONGODB_DSN=mongodb+srv://username:Mon%40Pass%23123@cluster0.xxxxx.mongodb.net/
```

### 2.3 Exemple de configuration complète `.env`

```env
APP_NAME="Trig Essalama"
APP_ENV=local
APP_KEY=base64:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
APP_DEBUG=true
APP_TIMEZONE=UTC
APP_URL=http://localhost

LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug

# Connexion par défaut
DB_CONNECTION=mongodb

# Configuration MongoDB Atlas
MONGODB_DSN=mongodb+srv://trig_essalama_user:MonMotDePasse123@cluster0.z0ygk2c.mongodb.net/
MONGODB_DATABASE=trig_essalama
```

---

## ✅ Étape 3 : Vérification de la connexion

### 3.1 Tester la connexion avec Tinker

Ouvrez un terminal dans le dossier de votre projet et exécutez :

```bash
php artisan tinker
```

Puis dans Tinker, testez la connexion :

```php
// Test 1 : Vérifier le nom de la base de données
DB::connection()->getDatabaseName();

// Test 2 : Lister les bases de données disponibles
DB::connection('mongodb')->getMongoClient()->listDatabases();

// Test 3 : Créer un utilisateur de test
$user = App\Models\User::create([
    'name' => 'Test User',
    'first_name' => 'Test',
    'last_name' => 'User',
    'email' => 'test@example.com',
    'password' => bcrypt('password123')
]);

// Test 4 : Vérifier que l'utilisateur a été créé
$user->_id;

// Test 5 : Vérifier dans MongoDB Atlas
// Allez dans MongoDB Atlas → Database → Browse Collections
// Vous devriez voir la collection "admin" avec votre utilisateur de test
```

### 3.2 Tester via le formulaire d'inscription

1. Démarrez votre serveur Laravel :
   ```bash
   php artisan serve
   ```

2. Allez sur `http://localhost:8000/register`

3. Remplissez le formulaire d'inscription

4. Vérifiez dans MongoDB Atlas :
   - Allez dans **"Database"** → **"Browse Collections"**
   - Sélectionnez votre cluster → `trig_essalama` → `admin`
   - Vous devriez voir le nouvel utilisateur créé !

---

## 🔍 Étape 4 : Dépannage

### Problème : "Class MongoDB\Laravel\Auth\User not found"

**Solution :**
```bash
composer require jenssegers/mongodb
php artisan config:clear
php artisan cache:clear
```

### Problème : "Connection timeout" ou "Could not connect"

**Solutions :**
1. Vérifiez que votre IP est autorisée dans MongoDB Atlas (Network Access)
2. Vérifiez que le mot de passe est correctement encodé dans le DSN
3. Vérifiez que l'extension PHP MongoDB est installée : `php -m | grep mongodb`
4. Essayez d'utiliser la configuration détaillée au lieu du DSN

### Problème : "Authentication failed"

**Solutions :**
1. Vérifiez que le nom d'utilisateur et le mot de passe sont corrects
2. Vérifiez que l'utilisateur a les bonnes permissions dans MongoDB Atlas
3. Vérifiez que `MONGODB_AUTHENTICATION_DATABASE` est défini sur `admin`

### Problème : Les données ne s'enregistrent pas

**Solutions :**
1. Vérifiez les logs Laravel : `storage/logs/laravel.log`
2. Vérifiez que `DB_CONNECTION=mongodb` est dans votre `.env`
3. Exécutez : `php artisan config:clear`
4. Vérifiez que le modèle User utilise la bonne collection :
   ```php
   protected $collection = 'admin';
   protected $database = 'trig_essalama';
   ```

---

## 📝 Résumé des fichiers modifiés

Votre projet est déjà configuré avec :
- ✅ `config/database.php` : Configuration MongoDB
- ✅ `app/Models/User.php` : Modèle utilisant MongoDB
- ✅ `app/Http/Controllers/AuthController.php` : Contrôleur d'inscription

**Il vous reste à :**
1. ✅ Configurer MongoDB Atlas (étapes 1.1 à 1.5)
2. ✅ Configurer le fichier `.env` (étape 2.2)
3. ✅ Tester la connexion (étape 3)

---

## 🎯 Checklist finale

- [ ] Cluster MongoDB Atlas créé
- [ ] Utilisateur de base de données créé
- [ ] Accès réseau autorisé (IP ajoutée)
- [ ] Chaîne de connexion obtenue
- [ ] Extension PHP MongoDB installée
- [ ] Fichier `.env` configuré avec les bonnes valeurs
- [ ] Connexion testée avec Tinker
- [ ] Formulaire d'inscription testé
- [ ] Données visibles dans MongoDB Atlas

---

## 📞 Support

Si vous rencontrez des problèmes :
1. Vérifiez les logs Laravel : `storage/logs/laravel.log`
2. Vérifiez les logs MongoDB Atlas dans le dashboard
3. Consultez la documentation : [jenssegers.github.io/mongodb](https://jenssegers.github.io/mongodb/)

---

**Bon développement ! 🚀**
