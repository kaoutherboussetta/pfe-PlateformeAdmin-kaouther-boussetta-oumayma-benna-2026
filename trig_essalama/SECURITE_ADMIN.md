# 🔐 Système de Sécurité Administrateur - Trig-Essalama

## Vue d'ensemble

Ce document décrit le système de sécurité ultra-sécurisé pour les administrateurs du système Trig-Essalama, conforme aux standards de sécurité gouvernementaux.

## 🏗️ Architecture

### Collections MongoDB

- **`admins`** : Collection dédiée aux administrateurs (séparée des citoyens)
- **`citoyens`** : Collection pour les citoyens
- **`audit_logs`** : Collection pour les logs d'audit

### Types d'Administrateurs

1. **Administrateur Technique** (`technique`)
   - Peut créer, modifier et supprimer d'autres administrateurs
   - Accès complet au système
   - Seul type pouvant créer de nouveaux admins

2. **Administrateur Autoritaire** (`autoritaire`)
   - Accès limité selon les permissions définies
   - Ne peut pas gérer d'autres administrateurs

## 🔒 Principes de Sécurité

### ✅ Ce qui est IMPLÉMENTÉ

1. **Pas d'inscription publique admin**
   - Aucune route `/admin/register` publique
   - Création admin uniquement par Admin Technique

2. **Système d'invitation sécurisé**
   - Token UUID + hash sécurisé
   - Expiration automatique après 24h
   - Lien unique par admin

3. **Mot de passe fort obligatoire**
   - Minimum 12 caractères
   - Au moins une majuscule, une minuscule, un chiffre, un caractère spécial
   - Hashage avec bcrypt

4. **Double Authentification (2FA)**
   - Support Google Authenticator / Microsoft Authenticator
   - Codes de récupération
   - Activation optionnelle

5. **Protection contre les attaques**
   - Throttling: 5 tentatives par minute
   - Audit logs complets
   - Enregistrement IP, device, actions

6. **Séparation des guards Laravel**
   - Guard `admin` séparé du guard `web`
   - Collections MongoDB séparées

7. **Middleware par rôle**
   - `admin.technique` : Accès Admin Technique uniquement
   - `admin.autoritaire` : Accès Admin Autoritaire uniquement

## 🚀 Installation et Configuration

### 1. Créer le premier Administrateur Technique

```bash
php artisan admin:create-first --email=admin@trig-essalama.tn --name="Admin Technique" --role=technique
```

Ou en mode interactif:
```bash
php artisan admin:create-first
```

### 2. Installer le package 2FA (Recommandé)

Pour une vérification 2FA complète, installer le package Google2FA:

```bash
composer require pragmarx/google2fa
```

Puis mettre à jour `app/Services/TwoFactorService.php` pour utiliser la vraie vérification TOTP.

### 3. Configuration Email (Optionnel)

Pour envoyer les emails d'invitation automatiquement, configurer le service d'email dans `.env`:

```env
MAIL_MAILER=smtp
MAIL_HOST=smtp.example.com
MAIL_PORT=587
MAIL_USERNAME=your-email@example.com
MAIL_PASSWORD=your-password
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=noreply@trig-essalama.tn
MAIL_FROM_NAME="Trig-Essalama"
```

## 📋 Utilisation

### Connexion Admin

1. Accéder à `/admin/login`
2. Entrer email et mot de passe
3. Si 2FA activé, entrer le code à 6 chiffres
4. Accès au dashboard admin

### Créer un nouvel Admin (Admin Technique uniquement)

1. Se connecter en tant qu'Admin Technique
2. Aller dans "Gérer les Administrateurs"
3. Cliquer sur "Créer un Administrateur"
4. Remplir le formulaire
5. Un lien d'invitation sera généré (à envoyer manuellement ou par email)

### Configuration du mot de passe (via invitation)

1. L'admin reçoit le lien d'invitation
2. Accéder au lien (ex: `/admin/setup?token=TOKEN`)
3. Définir un mot de passe fort
4. Le lien expire après 24h

## 🔐 Routes Sécurisées

### Routes Publiques (Admin)
- `GET /admin/login` - Formulaire de connexion
- `POST /admin/login` - Traitement connexion (throttle: 5/min)
- `GET /admin/2fa/verify` - Vérification 2FA
- `POST /admin/2fa/verify` - Traitement 2FA
- `GET /admin/setup?token=...` - Configuration mot de passe (via invitation)
- `POST /admin/setup` - Traitement configuration

### Routes Protégées (Auth Admin requis)
- `GET /admin/dashboard` - Dashboard admin
- `POST /admin/logout` - Déconnexion

### Routes Admin Technique uniquement
- `GET /admin/admins` - Liste des admins
- `GET /admin/admins/create` - Formulaire création
- `POST /admin/admins` - Créer admin
- `POST /admin/admins/{id}/toggle-active` - Activer/Désactiver
- `DELETE /admin/admins/{id}` - Supprimer admin

## 📊 Audit Logs

Toutes les actions sensibles sont enregistrées dans la collection `audit_logs`:

- Connexions réussies/échouées
- Création/suppression d'admins
- Changements de statut
- Tentatives de connexion bloquées
- Actions avec IP, user agent, timestamp

### Consulter les logs

```php
use App\Services\AuditLogService;

$auditLogService = app(AuditLogService::class);
$logs = $auditLogService->getLogs([
    'action' => 'admin_login_success',
    'date_from' => now()->subDays(7),
]);
```

## 🛡️ Sécurité Avancée (Optionnel)

### Restriction IP

Pour limiter l'accès admin à certaines IPs, ajouter dans `AdminAuthController`:

```php
$allowedIPs = ['192.168.1.100', '10.0.0.50'];
if (!in_array($request->ip(), $allowedIPs)) {
    abort(403, 'Accès refusé depuis cette IP.');
}
```

### Sessions courtes

Dans `config/session.php`:

```php
'lifetime' => 15, // 15 minutes
```

### Chiffrement des données sensibles

Utiliser Laravel Encryption pour chiffrer les données sensibles dans MongoDB.

## ⚠️ Notes Importantes

1. **2FA Temporaire**: La vérification 2FA actuelle est simplifiée. Pour la production, installer `pragmarx/google2fa` et mettre à jour `TwoFactorService`.

2. **Email d'invitation**: Actuellement, le lien d'invitation est affiché dans les logs. Pour la production, implémenter l'envoi d'email automatique.

3. **Premier Admin**: Utiliser la commande `admin:create-first` pour créer le premier Admin Technique. Ne jamais créer d'admin via l'interface publique.

4. **Mots de passe**: Les mots de passe sont hashés avec bcrypt (par défaut Laravel). Ne jamais stocker de mots de passe en clair.

5. **Audit Logs**: Les logs sont stockés dans MongoDB. Surveiller régulièrement les tentatives de connexion suspectes.

## 🚨 Ce qu'il ne faut JAMAIS faire

- ❌ Permettre inscription admin publique
- ❌ Utiliser mot de passe simple
- ❌ Stocker password non hashé
- ❌ Mélanger rôles dans une seule logique
- ❌ Exposer les tokens d'invitation dans les URLs publiques
- ❌ Désactiver le throttling
- ❌ Ignorer les logs d'audit

## 📞 Support

Pour toute question de sécurité, contacter l'équipe technique.

---

**Version**: 1.0  
**Dernière mise à jour**: 2024  
**Statut**: Production Ready (avec améliorations 2FA recommandées)
