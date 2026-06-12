/// Doit rester aligné avec `PORT` dans `backend/.env` et `process.env.PORT || 3000` dans `server.js`.
/// Le tunnel ngrok doit cibler ce port (ex. `ngrok http 3000`).
const int kBackendDefaultPort = 3000;

/// Racine API par défaut (vide = auto-découverte via [kBackendFallbackBaseUrls]).
const String kBackendDefaultBaseUrl = '';

/// URLs essayées automatiquement si aucune URL n'est enregistrée (ngrok puis réseau local).
/// Ordre : tunnel public d'abord (fonctionne hors Wi‑Fi), puis IP LAN du PC (`npm run dev`).
const List<String> kBackendFallbackBaseUrls = <String>[
  'https://alibi-deepen-pursuant.ngrok-free.dev',
  'http://192.168.100.112:3000',
];

/// Compat : ancien nom conservé pour les imports existants.
String get kBackendLocalhostBaseUrl => kBackendDefaultBaseUrl;
