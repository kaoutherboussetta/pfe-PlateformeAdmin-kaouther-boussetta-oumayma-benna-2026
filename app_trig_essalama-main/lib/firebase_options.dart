// Fichier généré à partir de `android/app/google-services.json` (projet trigessalamaapp).
// Pour iOS / Web, exécutez `flutterfire configure` et régénérez ce fichier.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions ne sont pas configurées pour le web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions ne sont configurées que pour Android.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBUYxPOXsx72GpsEol4YRWBUfCPoJaT184',
    appId: '1:575819831562:android:bb7a3d2006ec0cf64d42f3',
    messagingSenderId: '575819831562',
    projectId: 'trigessalamaapp',
    storageBucket: 'trigessalamaapp.firebasestorage.app',
  );
}
