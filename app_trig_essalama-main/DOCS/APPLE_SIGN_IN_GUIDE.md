# Guide d'intégration Apple Sign-In

Ce guide détaille les étapes manuelles nécessaires pour finaliser l'intégration de la connexion Apple dans l'application **Trig Essalama**.

## Étape 1 : Mise à jour des dépendances Flutter

> [!NOTE]
> Cette étape a déjà été préparée dans `pubspec.yaml` par Antigravity.

```bash
# 1. Téléchargez les nouvelles dépendances
flutter pub get

# 2. Allez dans le dossier iOS (sur macOS uniquement)
cd ios

# 3. Installez les pods iOS
pod install

# 4. Revenez à la racine du projet
cd ..
```

## Étape 2 : Configuration dans Xcode (macOS requis)

### 2.1 Ouvrir le projet
Ouvrez `ios/Runner.xcworkspace` dans Xcode.

### 2.2 Configurer le Signing
1. Sélectionnez le projet **Runner** (icône bleue).
2. Allez dans l'onglet **Signing & Capabilities**.
3. Cochez **Automatically manage signing**.
4. Sélectionnez votre **Team** Apple Developer.

### 2.3 Bundle Identifier
Vérifiez que le **Bundle Identifier** est unique (ex: `com.trigressalama.app`). 
> [!IMPORTANT]
> Cette valeur doit correspondre à la variable `audience` dans votre fichier `server.js` (actuellement définie sur `com.trigressalama.app`).

### 2.4 Ajouter la capacité "Sign in with Apple"
1. Cliquez sur le bouton **+ Capability** (en haut à gauche).
2. Recherchez et ajoutez **Sign in with Apple**.

---

## Étape 3 : Configuration du fichier Info.plist

> [!NOTE]
> Cette étape a déjà été effectuée par Antigravity.

Le fichier `ios/Runner/Info.plist` contient désormais :
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>apple</string>
        </array>
    </dict>
</array>
```

---

## Étape 4 : Configuration Apple Developer (Compte payant)

Si vous avez un compte payant :
1. Allez sur [developer.apple.com](https://developer.apple.com).
2. Dans **Identifiers**, créez un **App ID** avec le même **Bundle ID** que dans Xcode.
3. Activez la capacité **Sign in with Apple**.

---

## Étape 5 : Configuration du backend (Node.js)

> [!NOTE]
> Les dépendances ont été ajoutées à `package.json` et la logique de validation intégrée à `server.js`.

**Vérification Bundle ID** : 
Dans `server.js`, assurez-vous que la ligne suivante utilise votre Bundle ID réel :
```javascript
audience: 'com.trigressalama.app' // Doit correspondre à Xcode
```

---

## Étape 6 : Tester sur un iPhone Réel

**Apple Sign-In ne peut pas être testé sur simulateur pour la première connexion.**

1. Connectez votre iPhone.
2. Activez le **Mode Développeur** sur l'iPhone (*Paramètres → Confidentialité et sécurité → Mode Développeur*).
3. Dans Xcode, sélectionnez votre iPhone et cliquez sur **▶️ Play**.
4. Testez la connexion et vérifiez les logs du backend pour confirmer la validation du token.
