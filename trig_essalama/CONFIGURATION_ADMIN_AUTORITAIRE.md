# Configuration de l'Administrateur Autoritaire

## Important

L'Administrateur Autoritaire **n'est PAS stocké en base de données**. Ses identifiants sont validés directement via la configuration du fichier `config/admin_autoritaire.php`.

## Configuration

### ⚠️ Valeurs par défaut pour le développement

Pour faciliter le développement, des valeurs par défaut sont configurées :
- **Email** : `admin.autoritaire@trig-essalama.ma`
- **Mot de passe** : `admin123` (hash: `$2y$12$ynJkUCA/0TDWWPWpDtPV.e972qvFkAOcguaeSt2ndJpRKDzuHADaW`)
- **Code de sécurité** : `AUTOR001` ou `D8HWZA5M` (code universel)

**⚠️ IMPORTANT : Changez ces valeurs en production !**

### 1. Générer le hash du mot de passe

Pour générer le hash du mot de passe, utilisez la commande suivante dans le terminal :

```bash
php artisan tinker
```

Puis dans tinker :

```php
Hash::make('votre_mot_de_passe')
```

Copiez le hash généré.

### 2. Configurer les variables d'environnement

Ajoutez les variables suivantes dans votre fichier `.env` :

```env
# Email de l'administrateur autoritaire
ADMIN_AUTORITAIRE_EMAIL=admin.autoritaire@trig-essalama.ma

# Hash du mot de passe (généré avec Hash::make())
ADMIN_AUTORITAIRE_PASSWORD_HASH=$2y$12$VotreHashIci

# Code de sécurité (8 caractères)
ADMIN_AUTORITAIRE_SECURITY_CODE=AUTOR001

# Informations d'affichage (optionnel)
ADMIN_AUTORITAIRE_NAME=Administrateur Autoritaire
ADMIN_AUTORITAIRE_FIRST_NAME=Admin
ADMIN_AUTORITAIRE_LAST_NAME=Autoritaire
```

### 3. Codes de sécurité valides

Les codes de sécurité suivants sont acceptés pour l'admin autoritaire :

1. **Code universel** : `D8HWZA5M` (toujours valide)
2. **Code de configuration** : Celui défini dans `ADMIN_AUTORITAIRE_SECURITY_CODE`
3. **Codes d'enregistrement** : Les codes valides de la table `registration_codes`

### 4. Connexion

Pour se connecter en tant qu'Administrateur Autoritaire :

1. Sélectionner "Administrateur Autoritaire" dans le type de compte
2. Entrer l'email configuré
3. Entrer le mot de passe
4. Entrer un code de sécurité valide

### 5. Sécurité

- Le mot de passe doit être fort (minimum 8 caractères, avec majuscules, minuscules, chiffres et caractères spéciaux)
- Le code de sécurité doit être gardé secret
- Ne jamais commiter le fichier `.env` dans le dépôt Git
- Changer régulièrement le mot de passe et le code de sécurité

## Dépannage

### Problème : "Email ou mot de passe incorrect"

- Vérifiez que l'email dans `.env` correspond exactement à celui saisi (insensible à la casse)
- Vérifiez que le hash du mot de passe est correct
- Régénérez le hash si nécessaire

### Problème : "Code de sécurité invalide"

- Vérifiez que le code saisi correspond à un des codes valides
- Vérifiez que le code fait exactement 8 caractères
- Utilisez le code universel `D8HWZA5M` pour tester

### Problème : "Configuration système incomplète"

- Vérifiez que les variables `ADMIN_AUTORITAIRE_EMAIL` et `ADMIN_AUTORITAIRE_PASSWORD_HASH` sont définies dans votre fichier `.env`
- Si vous n'avez pas de fichier `.env`, copiez `.env.example` et configurez-le
- Pour le développement, vous pouvez utiliser les valeurs par défaut (voir section "Valeurs par défaut")

### Problème : Redirection vers la page de login

- Vérifiez que la session est bien créée (vérifiez les logs)
- Vérifiez que le middleware d'authentification fonctionne correctement
- Vérifiez que la route `/dashboard` est accessible
