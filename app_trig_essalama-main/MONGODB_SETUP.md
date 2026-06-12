# Configuration MongoDB Atlas

Ce projet est configuré pour se connecter à MongoDB Atlas.

## Configuration

### 1. Mettre à jour le mot de passe

Dans le fichier `lib/config/mongodb_config.dart`, remplacez `<db_password>` par votre vrai mot de passe MongoDB Atlas.

**OU** utilisez directement la chaîne de connexion complète dans `lib/main.dart` :

```dart
// Remplacez 'VOTRE_MOT_DE_PASSE' par votre mot de passe réel
await MongoDBService.connect('VOTRE_MOT_DE_PASSE');
```

### 2. Utilisation directe avec la chaîne de connexion complète

Si vous préférez utiliser la chaîne de connexion complète directement, vous pouvez modifier `main.dart` :

```dart
// Dans main.dart, remplacez :
await MongoDBService.connect('VOTRE_MOT_DE_PASSE');

// Par :
await MongoDBService.connectWithUri(
  'mongodb+srv://oumaymabenna2_db_user:VOTRE_MOT_DE_PASSE@trigessalama.sw3x05v.mongodb.net/?appName=trigEssalama'
);
```

## Utilisation du service MongoDB

### Connexion

Le service se connecte automatiquement au démarrage de l'application dans `main.dart`.

### Exemples d'utilisation

Consultez le fichier `lib/examples/mongodb_example.dart` pour des exemples complets d'utilisation.

#### Insérer un document

```dart
final collection = MongoDBService.getCollection('ma_collection');
await collection.insertOne({'nom': 'Valeur', 'date': DateTime.now()});
```

#### Lire des documents

```dart
final collection = MongoDBService.getCollection('ma_collection');
final documents = await collection.find().toList();
```

#### Mettre à jour un document

```dart
final collection = MongoDBService.getCollection('ma_collection');
await collection.update(
  {'nom': 'Valeur'},
  {'\$set': {'modifie': true}}
);
```

#### Supprimer un document

```dart
final collection = MongoDBService.getCollection('ma_collection');
await collection.deleteOne({'nom': 'Valeur'});
```

## Vérification de la connexion

L'application affiche le statut de la connexion MongoDB sur l'écran d'accueil. Vous pouvez également tester la connexion manuellement :

```dart
final isConnected = await MongoDBService.testConnection();
```

## Important - Sécurité

⚠️ **ATTENTION** : Pour des raisons de sécurité, il est recommandé de :
1. Ne pas commiter le mot de passe dans le code source
2. Utiliser des variables d'environnement ou un fichier de configuration non versionné
3. Considérer l'utilisation d'une API backend plutôt qu'une connexion directe depuis l'application mobile

## Configuration MongoDB Atlas

Assurez-vous que :
1. Votre adresse IP est autorisée dans MongoDB Atlas (Network Access)
2. L'utilisateur de base de données a les permissions nécessaires
3. La connexion utilise le bon cluster et la bonne base de données
