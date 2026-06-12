import 'app_language.dart';

/// Textes d'interface pour l'onboarding et le dialogue de localisation (FR / EN / Darija tunisienne).
class AppStrings {
  final AppLanguage lang;
  const AppStrings(this.lang);

  String _t({required String fr, required String en, required String tnd}) {
    switch (lang) {
      case AppLanguage.fr:
        return fr;
      case AppLanguage.en:
        return en;
      case AppLanguage.tnd:
        return tnd;
    }
  }

  String get chooseLanguage => _t(
        fr: 'Choisir la langue',
        en: 'Choose language',
        tnd: 'Khtar il louga',
      );

  String get skip => _t(fr: 'Passer', en: 'Skip', tnd: 'Fawit');

  String get continueLabel => _t(fr: 'Continuer', en: 'Continue', tnd: 'Kammel');

  String get start => _t(fr: 'Commencer', en: 'Get started', tnd: 'Bda');

  String get page0Title => 'Trig Essalama';

  String get page0Subtitle => _t(
        fr:
            'Votre sécurité sur la route, en temps réel.\nUne application conçue pour protéger vos trajets.',
        en:
            'Your safety on the road, in real time.\nAn app built to protect your journeys.',
        tnd:
            'Sécurité taw f tri9, f wa9telli.\nApp msawra bch tahfdk f trajets.',
      );

  String get page1Title => _t(
        fr: 'Routes dangereuses',
        en: 'Dangerous roads',
        tnd: 'Tri9at khater',
      );

  String get page1Subtitle => _t(
        fr:
            'Accidents, routes coupées, inondations.\nSoyez informé avant qu\'il ne soit trop tard.',
        en:
            'Accidents, road closures, floods.\nStay informed before it\'s too late.',
        tnd:
            '7awadeth, tri9 msakkra, inondations.\nKoun 3arif 9bal ma yfout il wa9t.',
      );

  String get page2Title => _t(
        fr: 'Carte intelligente',
        en: 'Smart map',
        tnd: 'KhariTa dhakiya',
      );

  String get page2Subtitle => _t(
        fr:
            'Alertes en temps réel, trafic & météo.\nItinéraires plus sûrs grâce à l\'IA.',
        en:
            'Real-time alerts, traffic & weather.\nSafer routes with AI.',
        tnd:
            'Tanzihat f wa9telli, trafic w méétéo.\nTrajets akthar aman b l-IA.',
      );

  String get page3Title => _t(
        fr: 'Vie privée protégée',
        en: 'Protected privacy',
        tnd: 'Khususiya mhamiya',
      );

  String get page3Subtitle => _t(
        fr:
            'Données anonymisées.\nLocalisation uniquement avec votre accord.',
        en:
            'Anonymized data.\nLocation only with your consent.',
        tnd:
            'Données anonymes.\nLokalisation ken b mowaf9tk.',
      );

  String get locationDialogTitle => _t(
        fr: 'Accès à la localisation',
        en: 'Location access',
        tnd: 'Accès lël position',
      );

  String get locationDialogBody => _t(
        fr:
            'Trig Essalama a besoin de votre position pour vous alerter en temps réel sur les dangers (accidents, inondations, travaux) et vous proposer des itinéraires plus sûrs.\n\nVos données restent anonymisées et ne sont utilisées que pour votre sécurité.',
        en:
            'Trig Essalama needs your location to alert you in real time to hazards (accidents, floods, roadworks) and suggest safer routes.\n\nYour data stays anonymized and is used only for your safety.',
        tnd:
            'Trig Essalama y7taj position taw bch yab3athlek tanzihat 3la lkhatr (7awadeth, inondations, chari3) w y9tare7 trajets akthar aman.\n\nDonnées taw anonymes w ma yt3mlch biha ken bch sécurité taw.',
      );

  String get later => _t(fr: 'Plus tard', en: 'Later', tnd: 'Ba3d');

  String get allow => _t(fr: 'Autoriser', en: 'Allow', tnd: 'Salla7');

  String labelForLanguage(AppLanguage l) {
    switch (l) {
      case AppLanguage.fr:
        return 'Français';
      case AppLanguage.en:
        return 'English';
      case AppLanguage.tnd:
        return 'الدارجة التونسية';
    }
  }

  String subtitleForLanguage(AppLanguage l) {
    switch (l) {
      case AppLanguage.fr:
        return 'France';
      case AppLanguage.en:
        return 'English';
      case AppLanguage.tnd:
        return 'Tounsi · Tunisian Darija';
    }
  }

  /// Exposé pour validateurs / callbacks hors [build].
  String tr({required String fr, required String en, required String tnd}) =>
      _t(fr: fr, en: en, tnd: tnd);

  // --- Navigation principale ---
  String get navHome => _t(fr: 'Accueil', en: 'Home', tnd: 'Lwel');
  String get navMap => _t(fr: 'Carte', en: 'Map', tnd: 'KhariTa');
  String get navAlerts => _t(fr: 'Alertes', en: 'Alerts', tnd: 'Tanzihat');
  String get navProfile => _t(fr: 'Profil', en: 'Profile', tnd: 'Profil');

  // --- Connexion ---
  String get emailHint => _t(fr: 'Email', en: 'Email', tnd: 'Email');
  String get passwordHint => _t(fr: 'Mot de passe', en: 'Password', tnd: 'Mot de passe');
  String get rememberMe => _t(fr: 'Se souvenir de moi', en: 'Remember me', tnd: 'Fakkerni');
  String get forgotPassword => _t(fr: 'Mot de passe oublié ?', en: 'Forgot password?', tnd: 'Nsit il mot de passe?');
  String get loginButton => _t(fr: 'Se connecter', en: 'Log in', tnd: 'Connecti');
  String get noAccount => _t(fr: 'Pas encore de compte ? ', en: 'No account yet? ', tnd: 'Ma 3andekch compte? ');
  String get signUp => _t(fr: 'S\'inscrire', en: 'Sign up', tnd: 'Sajjel');
  String get orContinueWith => _t(fr: 'Ou continuer avec', en: 'Or continue with', tnd: 'Walla kammel b');
  String get loginSuccess => _t(fr: 'Connexion réussie !', en: 'Login successful!', tnd: 'Connecti b naj7!');
  String get loginFailed => _t(fr: 'Email ou mot de passe incorrect', en: 'Incorrect email or password', tnd: 'Email wlla mot de passe ghalet');
  String get errorPrefix => _t(fr: 'Erreur : ', en: 'Error: ', tnd: 'Erreur: ');
  String get googleTokenError => _t(
        fr: 'Impossible de récupérer le jeton ID Google',
        en: 'Could not retrieve Google ID token',
        tnd: 'Ma njemchch njib Google token',
      );
  String get googleLoginOk => _t(fr: 'Connexion avec Google réussie !', en: 'Signed in with Google!', tnd: 'Connecti b Google!');
  String get googleAuthFailed => _t(fr: 'Échec de l\'authentification Google', en: 'Google sign-in failed', tnd: 'Google ma tjich');
  String get googleLoginError => _t(fr: 'Erreur de connexion Google : ', en: 'Google sign-in error: ', tnd: 'Erreur Google: ');
  String get appleUnavailable => _t(
        fr: 'Apple Sign-In n\'est pas disponible sur cet appareil',
        en: 'Apple Sign-In is not available on this device',
        tnd: 'Apple Sign-In ma 9achch f téléphone',
      );
  String get appleUserDefault => _t(fr: 'Utilisateur Apple', en: 'Apple user', tnd: 'User Apple');
  String get appleLoginOk => _t(fr: 'Connexion avec Apple réussie !', en: 'Signed in with Apple!', tnd: 'Connecti b Apple!');
  String get appleAuthFailed => _t(fr: 'Échec de l\'authentification Apple', en: 'Apple sign-in failed', tnd: 'Apple ma tjich');
  String get appleLoginError => _t(fr: 'Erreur de connexion Apple : ', en: 'Apple sign-in error: ', tnd: 'Erreur Apple: ');
  String get validateEmailEmpty => _t(fr: 'Veuillez entrer votre email', en: 'Please enter your email', tnd: 'Dkhil email taw');
  String get validateEmailInvalid => _t(fr: 'Email invalide', en: 'Invalid email', tnd: 'Email ghalet');
  String get validatePasswordEmpty => _t(fr: 'Veuillez entrer votre mot de passe', en: 'Please enter your password', tnd: 'Dkhil mot de passe');
  String get validatePasswordShort => _t(fr: 'Minimum 6 caractères', en: 'At least 6 characters', tnd: 'Akthar men 6 7arouf');

  // --- Inscription ---
  String get createAccount => _t(fr: 'Créer un compte', en: 'Create account', tnd: 'Sajjel compte');
  String get joinSubtitle => _t(fr: 'Rejoignez SmartRoad', en: 'Join SmartRoad', tnd: 'Dkhoul m3ana SmartRoad');
  String get firstNameHint => _t(fr: 'Prénom', en: 'First name', tnd: 'Ism');
  String get lastNameHint => _t(fr: 'Nom', en: 'Last name', tnd: 'L9ab');
  String get requiredField => _t(fr: 'Requis', en: 'Required', tnd: 'Darouri');
  String get min2chars => _t(fr: 'Min. 2 caractères', en: 'Min. 2 characters', tnd: 'Akthar men 2 7arf');
  String get min8chars => _t(fr: 'Min. 8 caractères', en: 'Min. 8 characters', tnd: 'Akthar men 8');
  String get needUppercase => _t(fr: 'Une majuscule', en: 'One uppercase letter', tnd: '7arf kbir');
  String get needDigit => _t(fr: 'Un chiffre', en: 'One digit', tnd: 'Ra9m');
  String get needSpecial => _t(fr: 'Un caractère spécial', en: 'One special character', tnd: '7arf spécial');
  String get confirmPasswordHint => _t(fr: 'Confirmer le mot de passe', en: 'Confirm password', tnd: 'Akked mot de passe');
  String get passwordMismatch => _t(fr: 'Ne correspond pas', en: 'Does not match', tnd: 'Ma ychbahch');
  String get acceptTermsSnack => _t(
        fr: 'Veuillez accepter les conditions d\'utilisation',
        en: 'Please accept the terms of use',
        tnd: '9bal l conditions d\'utilisation',
      );
  String get registerSuccess => _t(fr: 'Inscription réussie ! Redirection...', en: 'Registration successful! Redirecting...', tnd: 'Sajjel b naj7! ...');
  String get emailAlreadyExists => _t(fr: 'Un compte avec cet email existe déjà', en: 'An account with this email already exists', tnd: 'Compte b email hedha mawjoud');
  String get termsDialogTitle => _t(fr: 'Conditions d\'utilisation', en: 'Terms of use', tnd: 'Chourout l\'utilisation');
  String get termsDialogBody => _t(
        fr: 'En utilisant SmartRoad, vous acceptez nos conditions d\'utilisation et notre politique de confidentialité.',
        en: 'By using SmartRoad, you accept our terms of use and privacy policy.',
        tnd: 'B SmartRoad, ta9bel chouroutna w politique de confidentialité.',
      );
  String get close => _t(fr: 'Fermer', en: 'Close', tnd: 'Sedd');
  String get acceptTermsPrefix => _t(fr: 'J\'accepte les ', en: 'I accept the ', tnd: 'Na9bel ');
  String get termsLink => _t(fr: 'conditions d\'utilisation', en: 'terms of use', tnd: 'chourout l\'utilisation');
  String get acceptTermsMiddle => _t(fr: ' et la ', en: ' and the ', tnd: ' w ');
  String get privacyLink => _t(fr: 'politique de confidentialité', en: 'privacy policy', tnd: 'politique de confidentialité');
  String get registerButton => _t(fr: 'S\'inscrire', en: 'Register', tnd: 'Sajjel');
  String get alreadyAccount => _t(fr: 'Déjà un compte ? ', en: 'Already have an account? ', tnd: '3andek compte? ');
  String get signInLink => _t(fr: 'Se connecter', en: 'Log in', tnd: 'Connecti');

  // --- Mot de passe oublié ---
  String get forgotTitle => _t(fr: 'Mot de passe oublié', en: 'Forgot password', tnd: 'Nsit mot de passe');
  String get forgotSubtitle => _t(
        fr: 'Entrez votre email pour recevoir un lien de réinitialisation',
        en: 'Enter your email to receive a reset link',
        tnd: 'Dkhil email bch twassal link l réinitialisation',
      );
  String get sendResetLink => _t(fr: 'Envoyer le lien', en: 'Send link', tnd: 'B3ath il lien');
  String get forgotNoAccount => _t(fr: 'Pas de compte ? ', en: 'No account? ', tnd: 'Ma 3andekch compte? ');
  String get forgotSignUp => _t(fr: 'S\'inscrire', en: 'Sign up', tnd: 'Sajjel');
  String get emailSentTitle => _t(fr: 'Email envoyé !', en: 'Email sent!', tnd: 'Email tba3ath!');
  String get emailSentBody => _t(
        fr: 'Vérifiez votre boîte de réception pour réinitialiser votre mot de passe.',
        en: 'Check your inbox to reset your password.',
        tnd: 'Chouf l\'email bch tbadal mot de passe.',
      );
  String get backToLogin => _t(fr: 'Retour à la connexion', en: 'Back to login', tnd: 'Rje3 l connexion');
  String get resendEmail => _t(fr: 'Renvoyer l\'email', en: 'Resend email', tnd: 'A3id b3ath email');

  // --- Feedback ---
  String get feedbackShareTitle => _t(fr: 'Partagez votre avis', en: 'Share your feedback', tnd: 'Charek ra2yk');
  String get feedbackSubtitle => _t(
        fr: 'Votre retour aide Trig Essalama à protéger plus de vies.',
        en: 'Your feedback helps Trig Essalama protect more lives.',
        tnd: 'Ra2yk ya3awen Trig Essalama tahfadh akther min 7ayat.',
      );
  String get feedbackCommentTitle => _t(fr: 'Un commentaire ?', en: 'A comment?', tnd: 'Commentaire?');
  String get feedbackCommentSubtitle => _t(
        fr: 'Un détail qui pourrait nous aider ? On vous écoute.',
        en: 'Any detail that could help us? We listen.',
        tnd: 'Tafsil ya3awna? Rana nsma3ouk.',
      );
  String get feedbackCommentHint => _t(fr: 'Saisissez votre avis ici...', en: 'Type your feedback here...', tnd: 'Kteb ra2yk hina...');
  String get feedbackBack => _t(fr: 'Retour', en: 'Back', tnd: 'Rje3');
  String get feedbackNext => _t(fr: 'Suivant', en: 'Next', tnd: 'Li ba3d');
  String get feedbackReady => _t(fr: 'Prêt à envoyer ?', en: 'Ready to send?', tnd: 'Jahz tba3ath?');
  String get feedbackYourRating => _t(fr: 'Votre note :', en: 'Your rating:', tnd: 'Note taw:');
  String get feedbackYourComment => _t(fr: 'Votre commentaire :', en: 'Your comment:', tnd: 'Commentaire taw:');
  String get feedbackConfirmSend => _t(fr: 'Confirmer l\'envoi', en: 'Confirm send', tnd: 'Akked l\'envoi');
  String get feedbackModify => _t(fr: 'Modifier mes infos', en: 'Edit my info', tnd: 'Badal l infos');
  String get feedbackLoginRequired => _t(
        fr: 'Connectez-vous pour envoyer un avis.',
        en: 'Log in to send feedback.',
        tnd: 'Connecti bch tba3ath ra2yk.',
      );
  String get feedbackSent => _t(fr: 'Avis envoyé ! Merci citoyen 🛡️', en: 'Feedback sent! Thank you 🛡️', tnd: 'Ra2yk tba3ath! Chokran 🛡️');

  // --- Profil / réglages ---
  String get settingsPersonalInfo => _t(fr: 'Informations personnelles', en: 'Personal information', tnd: 'Ma3loumat taw');
  String get settingsEmergency => _t(fr: 'Contacts d\'urgence', en: 'Emergency contacts', tnd: 'Contacts d\'urgence');
  String get settingsLocation => _t(fr: 'Paramètres de localisation', en: 'Location settings', tnd: 'Paramètres position');
  String get settingsDarkMode => _t(fr: 'Mode sombre', en: 'Dark mode', tnd: 'Mode sombre');
  String get settingsHelp => _t(fr: 'Aide et support', en: 'Help & support', tnd: 'Aide w support');
  String get settingsLanguage => _t(fr: 'Langue', en: 'Language', tnd: 'Louga');
  String get sosTitle => _t(fr: 'SOS urgence', en: 'SOS emergency', tnd: 'SOS urgence');
  String get sosBody => _t(
        fr: 'Une alerte sera envoyée à vos contacts d\'urgence et aux autorités. Continuer ?',
        en: 'An alert will be sent to your emergency contacts and authorities. Continue?',
        tnd: 'Tanzihat twassal l contacts d\'urgence w l autorités. Tkammel?',
      );
  String get cancel => _t(fr: 'Annuler', en: 'Cancel', tnd: 'Fawit');
  String get sendSos => _t(fr: 'Envoyer SOS', en: 'Send SOS', tnd: 'B3ath SOS');
  String get emergencyAlertSent => _t(fr: 'Alerte d\'urgence envoyée', en: 'Emergency alert sent', tnd: 'Tanzihat tba3ath');
  String get sharingLocation => _t(fr: 'Partage de position avec les contacts d\'urgence', en: 'Sharing location with emergency contacts', tnd: 'Partage position m3 contacts');
  String get stopService => _t(fr: 'Arrêter le service', en: 'Stop service', tnd: 'Waqef service');
  String get serviceStopped => _t(fr: 'Service arrêté temporairement', en: 'Service stopped temporarily', tnd: 'Service waqef chwaya');
  String get logoutTitle => _t(fr: 'Déconnexion', en: 'Log out', tnd: 'Déconnexion');
  String get logoutConfirm => _t(fr: 'Voulez-vous vraiment vous déconnecter ?', en: 'Are you sure you want to log out?', tnd: 'Mta7eq bch tdeconnecti?');
  String get logoutButton => _t(fr: 'Déconnexion', en: 'Log out', tnd: 'Déconnexion');

  // --- Accueil (extraits) ---
  String get homeHeroTitle => _t(
        fr: 'Découvrez\nvotre route idéale !',
        en: 'Discover\nyour ideal route!',
        tnd: 'Chouf\nroute taw l mithali!',
      );
  String get loading => _t(fr: 'Chargement...', en: 'Loading...', tnd: 'Ycharga...');
  String get unknown => _t(fr: 'Inconnu', en: 'Unknown', tnd: 'Ma3roufch');
  String get weatherErrorLocation => _t(fr: 'Erreur localisation', en: 'Location error', tnd: 'Erreur position');
  String get searchPlaceholder => _t(fr: 'Où voulez-vous aller ?', en: 'Where do you want to go?', tnd: 'Win bech temchi?');
  String get planRoute => _t(fr: 'Planifier un trajet', en: 'Plan a route', tnd: 'Planifik trajet');
  String get voiceSearchSoon => _t(
        fr: 'Recherche vocale bientôt disponible',
        en: 'Voice search coming soon',
        tnd: 'Recherche vocale bientôt',
      );
  String get placeFallback => _t(fr: 'Lieu', en: 'Place', tnd: 'Blasa');
  String get locationFallback => _t(fr: 'Emplacement', en: 'Location', tnd: 'Blasa');
  String get securityLevelPrefix => _t(fr: 'Niveau de sécurité : ', en: 'Safety level: ', tnd: 'Sécurité: ');
  String get safetyScoreLabel => _t(fr: 'Score de sécurité', en: 'Safety score', tnd: 'Score sécurité');
  String get safeZoneDesc => _t(fr: 'Zone bien éclairée et surveillée.', en: 'Well-lit and monitored area.', tnd: 'Zone mawjou3a w mchahda.');
  String get cautionZoneDesc => _t(fr: 'Prudence conseillée dans cette zone.', en: 'Caution advised in this area.', tnd: 'Hadhér f zone hedhi.');
  String get itinerary => _t(fr: 'Itinéraire', en: 'Route', tnd: 'Trajet');
  String get citizenFallback => _t(fr: 'Citoyen', en: 'Citizen', tnd: 'Mouaten');
  String get nearbyAlertsTitle => _t(fr: 'Alertes à proximité', en: 'Nearby alerts', tnd: 'Tanzihat 9rib');
  String get seeAll => _t(fr: 'Voir tout', en: 'See all', tnd: 'Chouf l koll');
  String get reportProblemTitle => _t(fr: 'Signaler un problème', en: 'Report a problem', tnd: 'Signale moshkel');
  String get recommendedRoute => _t(fr: 'Trajet recommandé', en: 'Recommended route', tnd: 'Trajet mouche7');

  String get homeCameraPhotoOk => _t(
        fr: 'Photo enregistrée',
        en: 'Photo saved',
        tnd: 'Photo tsave',
      );

  String get cameraPageTitle => _t(fr: 'Appareil photo', en: 'Camera', tnd: 'Camera');
  String get cameraNoCamera => _t(
        fr: 'Aucune caméra disponible',
        en: 'No camera available',
        tnd: 'Ma 3andekch camera',
      );
  String get cameraPositionSnack => _t(
        fr: 'Position :',
        en: 'Location:',
        tnd: 'Position:',
      );
  String get cameraLocationDenied => _t(
        fr: 'Localisation refusée',
        en: 'Location permission denied',
        tnd: 'Position ma tjich',
      );
  String get cameraOpenMap => _t(fr: 'Voir sur la carte', en: 'View on map', tnd: 'Chouf 3la khariTa');
  String get cameraPositionReady => _t(
        fr: 'Position récupérée',
        en: 'Location captured',
        tnd: 'Position tchedet',
      );
  String get cameraSavingCapture => _t(
        fr: 'Enregistrement de la capture...',
        en: 'Saving capture...',
        tnd: 'Yhabet capture...',
      );
  String get cameraCaptureSaved => _t(
        fr: 'Photo et position enregistrées',
        en: 'Photo and location saved',
        tnd: 'Photo w position tsajlou',
      );
  String get cameraCaptureSaveError => _t(
        fr: 'Échec de l\'enregistrement de la capture',
        en: 'Failed to save capture',
        tnd: 'Ma nejmesh nsajel capture',
      );

  String get statusSecured => _t(fr: 'Sécurisé', en: 'Secure', tnd: 'Aman');
  String get statusHighRisk => _t(fr: 'Risque élevé', en: 'High risk', tnd: 'Khater 3ali');
  String get statusCaution => _t(fr: 'Attention recommandée', en: 'Caution advised', tnd: 'Hadhér');
  String get nearYou => _t(fr: 'Proche de vous', en: 'Near you', tnd: '9rib mink');
  String get weatherUpdated => _t(fr: 'Mis à jour', en: 'Updated', tnd: 'Mouche7');

  String get yes => _t(fr: 'Oui', en: 'Yes', tnd: 'Ey');
  String get no => _t(fr: 'Non', en: 'No', tnd: 'La');

  // --- Page alertes (liste démo) ---
  String get alertFilterAll => _t(fr: 'Toutes', en: 'All', tnd: 'L koll');
  String get alertFilterAccidents => _t(fr: 'Accidents', en: 'Accidents', tnd: '7awadeth');
  String get alertFilterWeather => _t(fr: 'Météo', en: 'Weather', tnd: 'Météo');
  String get alertFilterTraffic => _t(fr: 'Trafic', en: 'Traffic', tnd: 'Trafic');
  String get alertNotificationsOn => _t(
        fr: 'Notifications activées',
        en: 'Notifications enabled',
        tnd: 'Notifications mchaghla',
      );
  String get alertEmptyForCategory => _t(
        fr: 'Aucune alerte pour cette catégorie',
        en: 'No alerts for this category',
        tnd: 'Ma 3andekch tanzihat f category hedhi',
      );
  String get alertDetailPlace => _t(fr: 'Lieu :', en: 'Place:', tnd: 'Blasa:');
  String get alertDetailTime => _t(fr: 'Temps :', en: 'Time:', tnd: 'Wa9t:');
  String get alertDetailType => _t(fr: 'Type :', en: 'Type:', tnd: 'Type:');
  String get alertRetry => _t(fr: 'Réessayer', en: 'Retry', tnd: '3awed jarrab');
  String get alertEmptyList => _t(fr: 'Aucune alerte', en: 'No alerts', tnd: 'Ma 3andekch tanzihat');
  String get alertActive => _t(fr: 'Actives', en: 'Active', tnd: 'Actives');
  String get alertActiveCount => _t(fr: 'alertes', en: 'alerts', tnd: 'tanzihat');
  String get alertListUpdatedNew => _t(
        fr: 'Nouvelle(s) alerte(s) — la liste a été mise à jour',
        en: 'New alert(s) — list updated',
        tnd: 'Tanzihat jdida — liste tbaddlet',
      );
  String get alertUntitled => _t(fr: 'Alerte', en: 'Alert', tnd: 'Tanzih');
  String get alertDetailSource => _t(fr: 'Source :', en: 'Source:', tnd: 'Source:');
  String get alertDetailStatus => _t(fr: 'Statut :', en: 'Status:', tnd: 'Statut:');
  String get alertDetailRecommendation => _t(
        fr: 'Recommandation',
        en: 'Recommendation',
        tnd: 'Tawsiya',
      );
  String get alertDetailPriority => _t(fr: 'Priorité :', en: 'Priority:', tnd: 'Awlawiya:');
  String get alertDetailTemperature => _t(fr: 'Température :', en: 'Temperature:', tnd: '7arara:');

  String get alertDemoAccidentTitle => _t(fr: 'Accident grave', en: 'Serious accident', tnd: '7adsa kbira');
  String get alertDemoAccidentMessage => _t(
        fr: 'Collision sur route principale',
        en: 'Collision on main road',
        tnd: 'Collision f tri9 principal',
      );
  String get alertDemoAccidentTime => _t(fr: 'Il y a 5 min', en: '5 min ago', tnd: '9bal 5 min');
  String get alertDemoAccidentLocation => _t(fr: 'Sfax - Route Tunis', en: 'Sfax - Tunis road', tnd: 'Sfax - tri9 Tunis');

  String get alertDemoWeatherTitle => _t(fr: 'Pluie forte', en: 'Heavy rain', tnd: 'Sheta 3alis');
  String get alertDemoWeatherMessage => _t(
        fr: 'Visibilité réduite',
        en: 'Reduced visibility',
        tnd: 'Ma choufch mli7',
      );
  String get alertDemoWeatherTime => _t(fr: 'Il y a 10 min', en: '10 min ago', tnd: '9bal 10 min');
  String get alertDemoWeatherLocation => _t(fr: 'Centre ville', en: 'City center', tnd: 'Wasat l mdina');

  String get alertDemoTrafficTitle => _t(fr: 'Embouteillage', en: 'Traffic jam', tnd: 'Embouteillage');
  String get alertDemoTrafficMessage => _t(fr: 'Trafic dense', en: 'Heavy traffic', tnd: 'Trafic 3alis');
  String get alertDemoTrafficTime => _t(fr: 'Il y a 20 min', en: '20 min ago', tnd: '9bal 20 min');
  String get alertDemoTrafficLocation => _t(fr: 'Zone industrielle', en: 'Industrial zone', tnd: 'Zone industrielle');

  // --- En-tête profil ---
  String get profileScreenHeading => _t(fr: 'Profil', en: 'Profile', tnd: 'Profil');
  String get profileAvailable => _t(fr: 'Disponible', en: 'Available', tnd: 'Mawjoud');
  String get profileEnterName => _t(fr: 'Entrez votre nom', en: 'Enter your name', tnd: 'Dkhil ismek');
  String get profileEnterEmail => _t(fr: 'Entrez votre email', en: 'Enter your email', tnd: 'Dkhil email');

  // --- Statistiques (cartes) ---
  String get statAlertsSent => _t(fr: 'Alertes envoyées', en: 'Alerts sent', tnd: 'Tanzihat mba3tha');
  String get statMonitoredZones => _t(fr: 'Zones surveillées', en: 'Monitored zones', tnd: 'Zones mchahda');
  String get statEmergencyContacts => _t(fr: 'Contacts d\'urgence', en: 'Emergency contacts', tnd: 'Contacts d\'urgence');

  // --- Carte / navigation ---
  String get mapRiskLow => _t(fr: '🟢 Faible risque', en: '🟢 Low risk', tnd: '🟢 Khater sghir');
  String get mapRiskModerate => _t(
        fr: '🟠 Risque modéré (heure de pointe)',
        en: '🟠 Moderate risk (rush hour)',
        tnd: '🟠 Khater moutawasset',
      );
  String get mapRiskHigh => _t(
        fr: '⚠️ Risque élevé (nuit + historique)',
        en: '⚠️ High risk (night + history)',
        tnd: '⚠️ Khater 3ali',
      );

  String get mapLocationDisabled => _t(
        fr: 'Localisation désactivée',
        en: 'Location disabled',
        tnd: 'Position ma mchaghlech',
      );
  String get mapPositionError => _t(
        fr: 'Impossible d\'obtenir votre position',
        en: 'Could not get your position',
        tnd: 'Ma njemchch njib position taw',
      );
  String get mapCurrentPositionMissing => _t(
        fr: 'Position actuelle introuvable. Veuillez l\'activer.',
        en: 'Current position not found. Please enable it.',
        tnd: 'Position ma l9itnach. Fell7ha.',
      );
  String get mapCalculatingRouteSecure => _t(
        fr: 'Calcul de l\'itinéraire sécurisé...',
        en: 'Calculating safe route...',
        tnd: 'Y7seb trajet aman...',
      );
  String get mapCalculatingRoute => _t(
        fr: 'Calcul de l\'itinéraire...',
        en: 'Calculating route...',
        tnd: 'Y7seb trajet...',
      );
  String get mapNoRouteFound => _t(
        fr: 'Aucun itinéraire trouvé pour ce trajet.',
        en: 'No route found for this trip.',
        tnd: 'Ma l9itnach trajet.',
      );
  String get mapNetworkError => _t(
        fr: 'Erreur réseau ou service indisponible.',
        en: 'Network error or service unavailable.',
        tnd: 'Erreur réseau wlla service ma 9achch.',
      );
  String get mapNavigationStarted => _t(
        fr: 'Navigation démarrée !',
        en: 'Navigation started!',
        tnd: 'Navigation bdet!',
      );
  String get mapNavigationStartedVoice => _t(
        fr: 'Navigation démarrée, suivez l\'itinéraire sécurisé',
        en: 'Navigation started, follow the safe route',
        tnd: 'Navigation bdet, ittba3 trajet aman',
      );
  String get mapDeviationRecalcul => _t(
        fr: 'Déviation détectée. Recalcul...',
        en: 'Deviation detected. Recalculating...',
        tnd: 'Déviation. Y7seb men jdid...',
      );
  String get mapInvalidCoordinates => _t(
        fr: 'Lieu invalide : coordonnées corrompues.',
        en: 'Invalid place: corrupted coordinates.',
        tnd: 'Blasa ghalet: coordonnées.',
      );
  String get mapWaypointAdded => _t(fr: 'Étape ajoutée !', en: 'Stop added!', tnd: 'Mar7ala tzadet!');
  String get mapGuidanceStopped => _t(fr: 'Guidage arrêté', en: 'Guidance stopped', tnd: 'Guidage waqef');

  String get mapTtsSlowDown => _t(
        fr: 'Veuillez ralentir, vous dépassez la vitesse autorisée',
        en: 'Please slow down, you are exceeding the speed limit',
        tnd: 'Batel chwaya, 3adit l vitesse',
      );
  String get mapTtsDangerNearby => _t(
        fr: 'zone dangereuse détectée à proximité',
        en: 'dangerous zone detected nearby',
        tnd: 'zone khatera 9rib',
      );
  String get mapTtsDangerNearbySlow => _t(
        fr: 'zone dangereuse détectée à proximité, ralentissez',
        en: 'dangerous zone detected nearby, slow down',
        tnd: 'zone khatera 9rib, batel',
      );
  String get mapTtsArrived => _t(
        fr: 'Vous êtes arrivé à destination',
        en: 'You have arrived at your destination',
        tnd: 'Wselt l destination',
      );

  String get mapModeCar => _t(fr: '🚗 Voiture', en: '🚗 Car', tnd: '🚗 Karhba');
  String get mapModeMoto => _t(fr: '🏍️ Moto rapide', en: '🏍️ Fast motorcycle', tnd: '🏍️ Moto');
  String get mapModeMotoShort => _t(fr: 'Moto', en: 'Moto', tnd: 'Moto');
  String get mapModeBike => _t(fr: '🚴 Vélo', en: '🚴 Bike', tnd: '🚴 Velo');
  String get mapModeWalk => _t(fr: '🚶 Marche', en: '🚶 Walk', tnd: '🚶 Mashi');
  String get mapModeBus => _t(fr: '🚌 Bus', en: '🚌 Bus', tnd: '🚌 Bus');

  String get mapArrivalAt => _t(fr: 'Arrivée à', en: 'Arrival at', tnd: 'Wousoul');
  String get mapFastestRoute => _t(
        fr: 'Itinéraire le plus rapide',
        en: 'Fastest route',
        tnd: 'Asra3 trajet',
      );
  String get mapStart => _t(fr: 'Démarrer', en: 'Start', tnd: 'Bda');
  String get mapAddStops => _t(fr: 'Ajouter des étapes', en: 'Add stops', tnd: 'Zid mara7il');
  String get mapPrepareToStart => _t(fr: 'Préparez-vous à démarrer', en: 'Prepare to start', tnd: 'Jahz tba3ath');
  String get mapFollowRoute => _t(fr: 'Suivez l\'itinéraire', en: 'Follow the route', tnd: 'Itteba3 trajet');
  String get mapThenPrefix => _t(fr: 'Puis:', en: 'Then:', tnd: 'Ba3d:');

  String get mapQuitNavigationTitle => _t(fr: 'Quitter la navigation ?', en: 'Leave navigation?', tnd: 'Tkhrej men navigation?');
  String get mapQuitNavigationBody => _t(
        fr: 'Voulez-vous vraiment arrêter le guidage en cours ?',
        en: 'Do you really want to stop guidance?',
        tnd: 'Mta7eq bch twaqi3 guidage?',
      );
  String get mapQuit => _t(fr: 'Quitter', en: 'Leave', tnd: 'Khrej');

  String get mapAlertSpeeding => _t(fr: 'Vitesse excessive !', en: 'Excessive speed!', tnd: 'Vitesse 3aliya!');
  String get mapAlertDangerZone => _t(
        fr: 'Zone de danger identifiée',
        en: 'Danger zone identified',
        tnd: 'Zone khatera',
      );
  String get mapLiveUpdate => _t(
        fr: 'Mise à jour en temps réel',
        en: 'Live update',
        tnd: 'Mouche7 f wa9telli',
      );
  String get mapRouteTripPrefix => _t(fr: 'Trajet:', en: 'Trip:', tnd: 'Trajet:');

  String get mapRouteProblemsTitle =>
      _t(fr: 'Problèmes sur l\'itinéraire', en: 'Issues along the route', tnd: 'Machekil 3ala trajet');
  String mapRouteProblemsCount(int n) => _t(
        fr: '$n élément(s) (voirie + signalements)',
        en: '$n item(s) (road data + reports)',
        tnd: '$n 7aja (voirie + signalements)',
      );
  String get mapRouteProblemsEmpty => _t(
        fr: 'Aucun problème détecté sur cet itinéraire.',
        en: 'No issues detected along this route.',
        tnd: 'Ma fammach mochkil 3ala trajet hedha.',
      );

  String get mapRouteProblemsAlertTitle => _t(fr: 'Attention', en: 'Attention', tnd: 'Tannbi7');
  String mapRouteProblemsContainsIssues(int n) => _t(
        fr: 'Cet itinéraire contient $n problème(s).',
        en: 'This route has $n reported issue(s).',
        tnd: 'Trajet hedha fih $n mochkil.',
      );
  String get mapRouteProblemsWantAlt => _t(
        fr: 'Voulez-vous voir un itinéraire alternatif ?',
        en: 'Do you want to see an alternative route?',
        tnd: 'T7ebb tchouf trajet badil?',
      );
  String get mapRouteProblemsAlertYes => _t(fr: 'Oui', en: 'Yes', tnd: 'Ey');
  String get mapRouteProblemsAlertNo => _t(fr: 'Non', en: 'No', tnd: 'Le');
  String get mapRouteProblemsNoAlternatives => _t(
        fr: 'Aucune route alternative n\'a été proposée par le serveur d\'itinéraires pour ce trajet.',
        en: 'No alternative route was returned by the routing service for this trip.',
        tnd: 'Ma fammach trajet badil men serveur.',
      );
  String mapRouteProblemsMainLine(int n) => _t(
        fr: '🟢 Itinéraire principal : $n problème(s)',
        en: '🟢 Main route: $n issue(s)',
        tnd: '🟢 Trajet principal : $n mochkil',
      );
  String mapRouteProblemsAltLine(int index, int n, {required bool recommended}) {
    if (recommended) {
      return _t(
        fr: '🔵 ${mapRouteAlt(index)} : $n problème(s) — recommandé',
        en: '🔵 ${mapRouteAlt(index)}: $n issue(s) — recommended',
        tnd: '🔵 ${mapRouteAlt(index)} : $n mochkil — mouche7',
      );
    }
    return _t(
      fr: '🔵 ${mapRouteAlt(index)} : $n problème(s)',
      en: '🔵 ${mapRouteAlt(index)}: $n issue(s)',
      tnd: '🔵 ${mapRouteAlt(index)} : $n mochkil',
    );
  }

  String get mapRouteProblemsMainStillBest => _t(
        fr: 'L\'itinéraire principal reste le plus adapté (moins de pénalité globale).',
        en: 'The main route remains the best option overall.',
        tnd: 'Trajet principal howa l\'a7san.',
      );
  String mapRouteProblemsSwitchedToAlt(int index) => _t(
        fr: 'Itinéraire ${mapRouteAlt(index)} affiché (moins de problèmes estimés).',
        en: '${mapRouteAlt(index)} is now shown (fewer issues along the path).',
        tnd: 'Trajet ${mapRouteAlt(index)} ma3routh.',
      );
  String get mapRouteProblemsScanning => _t(
        fr: 'Analyse des itinéraires en cours…',
        en: 'Analyzing routes…',
        tnd: 'Qayed nfassar trajets…',
      );
  String get mapRouteProblemsPreviewHint => _t(
        fr: 'Les itinéraires sont affichés sur la carte avec des couleurs différentes.',
        en: 'Routes are shown on the map in different colors.',
        tnd: 'Trajets mawjoudin 3al khrita b alwan mokhtalfin.',
      );

  String get mapReportTitle => _t(fr: 'Que voyez-vous ?', en: 'What do you see?', tnd: 'Chnou chouft?');
  String get mapReportSent => _t(fr: 'Signalement envoyé :', en: 'Report sent:', tnd: 'Signalement tba3ath:');
  String get mapReportTrafficJam =>
      _t(fr: 'Embouteillage', en: 'Traffic jam', tnd: 'Embouteillage');
  String get mapReportPolice => _t(fr: 'Police', en: 'Police', tnd: 'Police');
  String get mapReportAccident => _t(fr: 'Accident', en: 'Accident', tnd: '7adsa');
  String get mapReportDanger =>
      _t(fr: 'Danger', en: 'Hazard', tnd: 'Khatar');
  String get mapReportRoadClosed =>
      _t(fr: 'Route fermée', en: 'Road closed', tnd: 'Tri9 msakkra');
  String get mapReportLaneBlocked =>
      _t(fr: 'Voie bloquée', en: 'Lane blocked', tnd: 'Voie msakkra');
  String get mapReportPavementCrack => _t(
        fr: 'Fissure de chaussée',
        en: 'Pavement crack',
        tnd: 'Fissure f chari3',
      );
  String get mapReportPothole =>
      _t(fr: 'Nid-de-poule', en: 'Pothole', tnd: 'Nid de poule');
  String get mapReportMapIssue =>
      _t(fr: 'Problème carte', en: 'Map issue', tnd: 'Moshkel kharita');
  String get mapReportBadWeather =>
      _t(fr: 'Mauvais temps', en: 'Bad weather', tnd: 'Jaw ma 7el');

  // Ne pas supprimer : après hot reload, d’anciennes fermetures peuvent encore résoudre
  // ces getters — s’ils manquent → Lookup failed. Non utilisés par la grille carte.
  String get mapReportFuelPrice =>
      _t(fr: 'Prix du carburant', en: 'Fuel price', tnd: 'Si3r essence');
  String get mapReportRoadsideAssistance => _t(
        fr: 'Assistance sur la route',
        en: 'Roadside assistance',
        tnd: 'Musaa3ada 3la tri9',
      );
  String get mapReportPlace =>
      _t(fr: 'Lieu', en: 'Place', tnd: 'Blasa');
  String get mapReportDebugging =>
      _t(fr: 'Débogage', en: 'Debugging', tnd: 'Debug');

  String get mapWhereTo => _t(fr: 'Où aller ?', en: 'Where to?', tnd: 'Win temchi?');
  String get mapSearchQuery => _t(fr: 'Votre recherche', en: 'Your search', tnd: 'Recherche taw');
  String get mapSearchTypeTwoChars => _t(
        fr: 'Tapez au moins 2 caractères pour lancer la recherche.',
        en: 'Type at least 2 characters to search.',
        tnd: 'Kteb akther men 7arfayn',
      );
  String get mapSearchNoResults => _t(
        fr: 'Aucun lieu trouvé pour cette recherche.',
        en: 'No place found for this search.',
        tnd: 'Ma l9itnach blasa',
      );
  String get mapYourCurrentLocation => _t(fr: 'Votre position', en: 'Your location', tnd: 'Position taw');
  String get mapHintFrom => _t(
        fr: 'Choisissez un point de départ',
        en: 'Choose a starting point',
        tnd: 'Khtar point de départ',
      );
  String get mapHintTo => _t(
        fr: 'Choisissez une destination',
        en: 'Choose a destination',
        tnd: 'Khtar destination',
      );
  /// Libellés barre recherche plein écran (alignés sur les hints carte).
  String get mapSearchStart => mapHintFrom;
  String get mapSearchDestination => mapHintTo;

  String get searchAroundMeChip => _t(
        fr: 'Autour de moi',
        en: 'Near me',
        tnd: '7awli',
      );
  String get searchNoResultsTitle => _t(
        fr: 'Aucun résultat trouvé',
        en: 'No results found',
        tnd: 'Ma l9itnach',
      );
  String get searchNoResultsSubtitle => _t(
        fr: 'Essayez une autre recherche',
        en: 'Try a different search',
        tnd: 'Jarreb recherche okhra',
      );
  String get searchPlaceSavedSnackbar => _t(
        fr: 'Lieu enregistré',
        en: 'Place saved',
        tnd: 'Blasa msjl',
      );
  String get searchCurrentLocationSection => _t(
        fr: 'Position actuelle',
        en: 'Current location',
        tnd: 'Position taw',
      );
  String get searchSavedPlacesSection => _t(
        fr: 'Lieux enregistrés',
        en: 'Saved places',
        tnd: 'Blayess msojlin',
      );
  String get searchCurrentLocationSubtitle => _t(
        fr: 'Utiliser le GPS',
        en: 'Use GPS',
        tnd: 'GPS',
      );
  String get mapAddWaypointHint => _t(fr: 'Ajouter une étape', en: 'Add a stop', tnd: 'Zid mar7ala');
  String get mapPlanRouteTitle => _t(fr: 'Planifier l\'itinéraire', en: 'Plan route', tnd: 'Planifik trajet');
  String get mapStartPointHint => _t(fr: 'Point de départ', en: 'Starting point', tnd: 'Point de départ');
  String get mapDestinationHint => _t(fr: 'Destination', en: 'Destination', tnd: 'Destination');
  String get mapDestination => _t(fr: 'Destination', en: 'Destination', tnd: 'Destination');
  String get mapAlternatives => _t(fr: 'Itinéraires alternatifs', en: 'Alternative routes', tnd: 'Trajets beddel');
  String get mapRemainingTime => _t(fr: 'Temps restant', en: 'Remaining time', tnd: 'Wa9t ba9i');
  String get mapRemainingDistance =>
      _t(fr: 'Distance restante', en: 'Remaining distance', tnd: 'Massafa ba9ya');
  String get mapWaypointLabel => _t(fr: 'Étape', en: 'Stop', tnd: 'Mar7ala');
  String get mapNavigationStart => _t(fr: 'Démarrer la navigation', en: 'Start navigation', tnd: 'Bda navigation');
  String get mapRecents => _t(fr: 'Récents', en: 'Recent', tnd: 'L akhir');

  String get searchRecentTitle => _t(fr: 'Récent', en: 'Recent', tnd: 'L akhir');
  String get searchClear => _t(fr: 'Effacer', en: 'Clear', tnd: 'Fawit');
  String get searchNoHistory => _t(
        fr: 'Aucun historique récent',
        en: 'No recent history',
        tnd: 'Ma 3andekch historique',
      );
  String get searchHome => _t(fr: 'Domicile', en: 'Home', tnd: 'Dar');
  String get searchWork => _t(fr: 'Travail', en: 'Work', tnd: 'Khedma');
  String get searchMore => _t(fr: 'Plus', en: 'More', tnd: 'Akther');
  String get searchAdd => _t(fr: 'Ajouter', en: 'Add', tnd: 'Zid');

  String get mapRoutePrincipal => _t(fr: 'Principal', en: 'Main', tnd: 'Principal');
  String mapRouteAlt(int index) => _t(fr: 'Alt $index', en: 'Alt $index', tnd: 'Alt $index');
  String get mapRouteSecured => _t(fr: '🟢 Sécurisé', en: '🟢 Secured', tnd: '🟢 Aman');
  String get mapRouteNormal => _t(fr: '🟡 Normal', en: '🟡 Normal', tnd: '🟡 Normal');
  String get mapRouteFast => _t(fr: '🔴 Rapide', en: '🔴 Fast', tnd: '🔴 Rapide');

  String get mapArrivedTitle => _t(fr: '🎉 Arrivé à destination !', en: '🎉 Arrived!', tnd: '🎉 Wselt!');
  String get mapArrivedDurationLine => _t(fr: 'Durée totale:', en: 'Total duration:', tnd: 'Muddet l koll:');
  String get mapTotalDistanceLabel => _t(fr: 'Distance totale:', en: 'Total distance:', tnd: 'Massafa l koll:');
  String get mapAverageSpeedLabel => _t(fr: 'Vitesse moyenne:', en: 'Average speed:', tnd: 'Vitesse moyenne:');
  String get mapHazardInstruction => _t(
        fr: '⚠️ Danger détecté ! Ralentissez',
        en: '⚠️ Danger detected! Slow down',
        tnd: '⚠️ Khatar! Batel',
      );
  String get mapRiskZoneStreet => _t(fr: 'Zone à risque', en: 'Risk zone', tnd: 'Zone khatera');

  // --- Embouteillages (Nouveaux) ---
  String get mapReportJamSubtitle => _t(
        fr: 'Signaler un ralentissement ou un blocage',
        en: 'Report a slowdown or blockage',
        tnd: 'Signale kabbout wlla blockage',
      );
  String get mapJamLevelLabel => _t(fr: 'Niveau d\'embouteillage', en: 'Traffic jam level', tnd: 'Level taw l embouteillage');
  String get mapJamLevelLow => _t(fr: 'Faible', en: 'Low', tnd: 'Sghir');
  String get mapJamLevelHigh => _t(fr: 'Élevé', en: 'High', tnd: '3ali');
  String get mapJamLevelFluid => _t(fr: 'Fluide', en: 'Fluid', tnd: 'Mchya');
  String get mapJamLevelSlow => _t(fr: 'Ralenti', en: 'Slow', tnd: 'Th9il');
  String get mapJamLevelBlocked => _t(fr: 'Bloqué', en: 'Blocked', tnd: 'Msakker');
  String get mapJamCauseLabel => _t(fr: 'Cause présumée', en: 'Presumed cause', tnd: 'Chnouwa l sbab');
  String get mapReportEvent => _t(fr: 'Événement', en: 'Event', tnd: 'Hadath');
  String get mapReportUnknown => _t(fr: 'Inconnu', en: 'Unknown', tnd: 'Ma3rfouch');
  String get mapReportJamCommentHint => _t(
        fr: 'Ajoutez une précision (ex: travaux, accident...)',
        en: 'Add a detail (e.g. works, accident...)',
        tnd: 'Zid tafsil (ex: khedma, accident...)',
      );
  String get mapButtonReport => _t(fr: 'Signaler', en: 'Report', tnd: 'Signali');
}
