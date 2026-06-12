# Correctif Authentification Admin Autoritaire

## Problème identifié

L'admin autoritaire utilisait `Auth::guard('admin')` alors qu'il n'existe pas en base de données. Cela causait une boucle de redirection vers la page de login car Laravel ne pouvait pas relire l'utilisateur depuis le provider Eloquent.

## Solution implémentée

### 1. Authentification par session uniquement

L'admin autoritaire utilise maintenant **uniquement la session** pour l'authentification, sans passer par `Auth::guard('admin')`.

### 2. Middleware dédié

Un nouveau middleware `EnsureAutoritaireAuthenticated` vérifie la présence de `autoritaire_authenticated` dans la session.

### 3. Séparation claire

- **Admin Technique** → `Auth::guard('admin')` + base de données
- **Admin Autoritaire** → Session uniquement + configuration

## Fichiers modifiés

1. **app/Http/Controllers/AuthController.php**
   - Logique de connexion admin autoritaire simplifiée
   - Utilise uniquement la session (pas `Auth::guard`)

2. **app/Http/Middleware/EnsureAutoritaireAuthenticated.php** (nouveau)
   - Vérifie `autoritaire_authenticated` dans la session

3. **bootstrap/app.php**
   - Enregistrement du middleware `autoritaire.auth`

4. **routes/web.php**
   - Route dashboard protégée par `autoritaire.auth`
   - Gestion des deux types d'admins

5. **app/Http/Middleware/IsAdminAutoritaire.php**
   - Mis à jour pour utiliser la nouvelle clé de session

## Configuration requise

### 1. Vérifier SESSION_DRIVER dans .env

```env
SESSION_DRIVER=file
# ou
SESSION_DRIVER=database
# ou
SESSION_DRIVER=redis
```

⚠️ **IMPORTANT** : Ne pas utiliser `SESSION_DRIVER=array` en production (réservé aux tests).

### 2. Vider le cache de configuration

Si vous modifiez `.env` ou `config/admin_autoritaire.php`, exécutez :

```bash
php artisan config:clear
php artisan cache:clear
```

### 3. Variables d'environnement

```env
ADMIN_AUTORITAIRE_EMAIL=admin.autoritaire@trig-essalama.ma
ADMIN_AUTORITAIRE_PASSWORD_HASH=$2y$12$VotreHashIci
ADMIN_AUTORITAIRE_SECURITY_CODE=AUTOR001
```

## Test de connexion

1. Aller sur `/login`
2. Sélectionner "Administrateur Autoritaire"
3. Entrer :
   - Email : celui configuré dans `.env`
   - Mot de passe : celui utilisé pour générer le hash
   - Code de sécurité : `D8HWZA5M` (code universel) ou celui configuré
4. Vous devriez être redirigé vers `/dashboard` sans retourner à la page de login

## Architecture

```
Admin Autoritaire
├── Validation : config/admin_autoritaire.php
├── Authentification : Session uniquement
├── Middleware : EnsureAutoritaireAuthenticated
└── Pas de modèle en base de données

Admin Technique
├── Validation : Base de données (Admin ou User)
├── Authentification : Auth::guard('admin')
├── Middleware : IsAdminTechnique
└── Modèle en base de données
```

## Notes de sécurité

- Le mot de passe est vérifié avec `Hash::check()` (méthode Laravel recommandée)
- Les codes de sécurité sont stockés en clair dans la config (pourrait être amélioré avec des hashes)
- La session est régénérée à chaque connexion (`session()->regenerate()`)
- Le middleware vérifie l'authentification à chaque requête

## Dépannage

### Problème : Redirection vers login après connexion

1. Vérifier `SESSION_DRIVER` dans `.env` (ne pas utiliser `array`)
2. Exécuter `php artisan config:clear`
3. Vérifier que le middleware est bien enregistré dans `bootstrap/app.php`
4. Vérifier les logs Laravel pour les erreurs de session

### Problème : "Veuillez vous connecter" sur dashboard

1. Vérifier que `autoritaire_authenticated` est bien dans la session
2. Vérifier que le middleware `autoritaire.auth` est appliqué sur la route
3. Vérifier que la session n'est pas expirée
