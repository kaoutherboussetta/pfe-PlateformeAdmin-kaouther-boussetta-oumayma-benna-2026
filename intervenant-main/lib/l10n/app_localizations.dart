import 'package:flutter/material.dart';

/// Chaînes FR / EN / AR pour l’application (hors contenu serveur).
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = <Locale>[
    Locale('fr'),
    Locale('en'),
    Locale('ar'),
  ];

  String get _code => locale.languageCode;

  String _t(String key) {
    final Map<String, String>? m = _strings[_code] ?? _strings['fr'];
    return m![key] ?? _strings['fr']![key] ?? key;
  }

  static String equipePrefix(String langCode) {
    switch (langCode) {
      case 'en':
        return 'Team';
      case 'ar':
        return 'الفريق';
      default:
        return 'Équipe';
    }
  }

  List<String> equipeChoices() {
    final String p = equipePrefix(_code);
    return <String>['$p 1', '$p 2', '$p 3'];
  }

  String get appTitle => _t('appTitle');
  String get loginTitle => _t('loginTitle');
  String get loginProject => _t('loginProject');
  String get loginEmail => _t('loginEmail');
  String get loginPassword => _t('loginPassword');
  String get loginSubmit => _t('loginSubmit');
  String get loginCreateAccount => _t('loginCreateAccount');
  String get loginFooter => _t('loginFooter');
  String get loginEmailRequired => _t('loginEmailRequired');
  String get loginEmailInvalid => _t('loginEmailInvalid');
  String get loginPasswordRequired => _t('loginPasswordRequired');
  String get loginServerUrl => _t('loginServerUrl');
  String get accountCreatedSnackbar => _t('accountCreatedSnackbar');
  String get navChantiers => _t('navChantiers');
  String get navNotif => _t('navNotif');
  String get navChat => _t('navChat');
  String get navProfile => _t('navProfile');
  String get notificationsTitle => _t('notificationsTitle');
  String get notificationsNew => _t('notificationsNew');
  String get notificationsMarkAllReadTooltip => _t('notificationsMarkAllReadTooltip');
  String get notificationsLoading => _t('notificationsLoading');
  String get notificationsEmptyTitle => _t('notificationsEmptyTitle');
  String get notificationsEmptyUnreadTitle => _t('notificationsEmptyUnreadTitle');
  String get notificationsEmptyUnreadSubtitle => _t('notificationsEmptyUnreadSubtitle');
  String get notificationsEmptyDangerTitle => _t('notificationsEmptyDangerTitle');
  String get notificationsEmptyDangerSubtitle => _t('notificationsEmptyDangerSubtitle');

  /// Sous-titre sous le titre (ex. « 2 nouvelles »).
  String notificationsNewCountLine(int count) {
    if (count <= 0) return '';
    switch (_code) {
      case 'en':
        return '$count new';
      case 'ar':
        return '$count جديد';
      default:
        return count > 1 ? '$count nouvelles' : '$count nouvelle';
    }
  }

  String get notificationsEmptySubtitle => _t('notificationsEmptySubtitle');
  String get chantiersHeader => _t('chantiersHeader');
  String get profilePreferences => _t('profilePreferences');
  String get profileTheme => _t('profileTheme');
  String get profileThemeSystem => _t('profileThemeSystem');
  String get profileThemeLight => _t('profileThemeLight');
  String get profileThemeDark => _t('profileThemeDark');
  String get profileLanguage => _t('profileLanguage');
  String get profileChooseLanguage => _t('profileChooseLanguage');
  String get profileTeamInfo => _t('profileTeamInfo');
  String get profileResponsible => _t('profileResponsible');
  String get profilePhone => _t('profilePhone');
  String get profileZone => _t('profileZone');
  String get profileTeam => _t('profileTeam');
  String get profileMembers => _t('profileMembers');
  String get profileEdit => _t('profileEdit');
  String get profileModifyTitle => _t('profileModifyTitle');
  String get profileSave => _t('profileSave');
  String get profileCancel => _t('profileCancel');
  String get profileLogout => _t('profileLogout');
  String get profileLogoutConfirmTitle => _t('profileLogoutConfirmTitle');
  String get profileLogoutConfirmBody => _t('profileLogoutConfirmBody');
  String get profileHistory => _t('profileHistory');
  String get chatSupport => _t('chatSupport');
  String get chatAdmin => _t('chatAdmin');
  String get chatSenderMe => _t('chatSenderMe');
  String get chatMessageQuestion => _t('chatMessageQuestion');
  String get chatMessageAnswer => _t('chatMessageAnswer');
  String get chatOnline => _t('chatOnline');
  String get chatAttachmentGallery => _t('chatAttachmentGallery');
  String get chatAttachmentCamera => _t('chatAttachmentCamera');
  String get chatAttachmentDocument => _t('chatAttachmentDocument');
  String get chatClearConversation => _t('chatClearConversation');
  String get chatClearConfirmTitle => _t('chatClearConfirmTitle');
  String get chatClearConfirmBody => _t('chatClearConfirmBody');
  String get chatClearAction => _t('chatClearAction');
  String get commonCancel => _t('commonCancel');
  String get commonRetry => _t('commonRetry');
  String get commonNotProvided => _t('commonNotProvided');
  String get profileMembersCountLabel => _t('profileMembersCountLabel');
  String get profileHistoryStatusDone => _t('profileHistoryStatusDone');
  String get profileHistoryStatusInProgress => _t('profileHistoryStatusInProgress');
  String get profileHistoryStatusPending => _t('profileHistoryStatusPending');
  String get profileHistoryEmpty => _t('profileHistoryEmpty');
  String get chantierDetailTitle => _t('chantierDetailTitle');
  String get profileLoadError => _t('profileLoadError');
  String get profileErrorGeneric => _t('profileErrorGeneric');
  String get equipeLabelEdit => _t('equipeLabelEdit');
  String get profileHistoryTitle => _t('profileHistoryTitle');
  String get profileLogoutAction => _t('profileLogoutAction');
  String profileMembersLine(int n) => _t('profileMembersLine').replaceAll('{n}', '$n');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any((Locale l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

const Map<String, Map<String, String>> _strings = <String, Map<String, String>>{
  'fr': <String, String>{
    'appTitle': 'TRIG Essalama - Intervenants',
    'loginTitle': 'Connexion intervenant',
    'loginProject': 'Projet: TRIG Essalama',
    'loginEmail': 'Email',
    'loginPassword': 'Mot de passe',
    'loginSubmit': 'Se connecter',
    'loginCreateAccount': 'Créer un compte',
    'loginFooter': 'Créez un compte puis connectez-vous.',
    'loginEmailRequired': 'Email obligatoire',
    'loginEmailInvalid': 'Email invalide',
    'loginPasswordRequired': 'Mot de passe obligatoire',
    'loginServerUrl': 'URL du serveur',
    'accountCreatedSnackbar': 'Compte créé avec succès. Connectez-vous maintenant.',
    'navChantiers': 'Chantiers',
    'navNotif': 'Notif',
    'navChat': 'Chat',
    'navProfile': 'Profil',
    'notificationsTitle': 'Notifications',
    'notificationsNew': 'nouvelle',
    'notificationsMarkAllReadTooltip': 'Tout marquer comme lu',
    'notificationsLoading': 'Chargement des notifications...',
    'notificationsEmptyTitle': 'Aucune notification',
    'notificationsEmptyUnreadTitle': 'Aucune notification non lue',
    'notificationsEmptyUnreadSubtitle': 'Toutes vos notifications sont lues.',
    'notificationsEmptyDangerTitle': 'Aucun signalement danger',
    'notificationsEmptyDangerSubtitle': 'Aucune notification à risque élevé pour le moment.',
    'notificationsEmptySubtitle': 'Les nouvelles notifications apparaîtront ici.',
    'chantiersHeader': 'Chantiers',
    'profilePreferences': 'Préférences',
    'profileTheme': 'Apparence',
    'profileThemeSystem': 'Système (automatique)',
    'profileThemeLight': 'Clair',
    'profileThemeDark': 'Sombre',
    'profileLanguage': 'Langue',
    'profileChooseLanguage': 'Choisir la langue',
    'profileTeamInfo': 'Informations de l\'équipe',
    'profileResponsible': 'Responsable',
    'profilePhone': 'Téléphone',
    'profileZone': 'Zone d\'intervention',
    'profileTeam': 'Équipe',
    'profileMembers': 'Membres',
    'profileEdit': 'Modifier les informations',
    'profileModifyTitle': 'Modifier les informations',
    'profileSave': 'Enregistrer',
    'profileCancel': 'Annuler',
    'profileLogout': 'Déconnexion',
    'profileLogoutConfirmTitle': 'Déconnexion',
    'profileLogoutConfirmBody': 'Quitter la session ?',
    'profileHistory': 'Historique',
    'chatSupport': 'Support Client',
    'chatAdmin': 'Administrateur',
    'chatSenderMe': 'Moi',
    'chatMessageQuestion': 'Question',
    'chatMessageAnswer': 'Réponse',
    'chatOnline': 'En ligne',
    'chatAttachmentGallery': 'Galerie',
    'chatAttachmentCamera': 'Appareil photo',
    'chatAttachmentDocument': 'Document',
    'chatClearConversation': 'Effacer la conversation',
    'chatClearConfirmTitle': 'Effacer la conversation',
    'chatClearConfirmBody': 'Êtes-vous sûr de vouloir effacer tous les messages ?',
    'chatClearAction': 'Effacer',
    'commonCancel': 'Annuler',
    'commonRetry': 'Réessayer',
    'commonNotProvided': 'Non renseigné',
    'profileMembersCountLabel': 'Nombre de membres',
    'profileHistoryStatusDone': 'Terminé',
    'profileHistoryStatusInProgress': 'En cours',
    'profileHistoryStatusPending': 'En attente',
    'profileHistoryEmpty': 'Aucune intervention récente pour votre équipe.',
    'chantierDetailTitle': 'Détail de l\'intervention',
    'profileLoadError': 'Chargement profil impossible.',
    'profileErrorGeneric': 'Erreur profil',
    'equipeLabelEdit': 'Équipe',
    'profileHistoryTitle': 'Dernières interventions',
    'profileLogoutAction': 'Se déconnecter',
    'profileMembersLine': '{n} personnes',
  },
  'en': <String, String>{
    'appTitle': 'TRIG Essalama - Field staff',
    'loginTitle': 'Staff login',
    'loginProject': 'Project: TRIG Essalama',
    'loginEmail': 'Email',
    'loginPassword': 'Password',
    'loginSubmit': 'Sign in',
    'loginCreateAccount': 'Create account',
    'loginFooter': 'Create an account, then sign in.',
    'loginEmailRequired': 'Email is required',
    'loginEmailInvalid': 'Invalid email',
    'loginPasswordRequired': 'Password is required',
    'loginServerUrl': 'Server URL',
    'accountCreatedSnackbar': 'Account created. Please sign in.',
    'navChantiers': 'Sites',
    'navNotif': 'Notif',
    'navChat': 'Chat',
    'navProfile': 'Profile',
    'notificationsTitle': 'Notifications',
    'notificationsNew': 'new',
    'notificationsMarkAllReadTooltip': 'Mark all as read',
    'notificationsLoading': 'Loading notifications...',
    'notificationsEmptyTitle': 'No notifications',
    'notificationsEmptyUnreadTitle': 'No unread notifications',
    'notificationsEmptyUnreadSubtitle': 'All notifications are read.',
    'notificationsEmptyDangerTitle': 'No danger alerts',
    'notificationsEmptyDangerSubtitle': 'No high-risk notifications right now.',
    'notificationsEmptySubtitle': 'New notifications will appear here.',
    'chantiersHeader': 'Sites',
    'profilePreferences': 'Preferences',
    'profileTheme': 'Appearance',
    'profileThemeSystem': 'System (automatic)',
    'profileThemeLight': 'Light',
    'profileThemeDark': 'Dark',
    'profileLanguage': 'Language',
    'profileChooseLanguage': 'Choose language',
    'profileTeamInfo': 'Team information',
    'profileResponsible': 'Manager',
    'profilePhone': 'Phone',
    'profileZone': 'Intervention area',
    'profileTeam': 'Team',
    'profileMembers': 'Members',
    'profileEdit': 'Edit information',
    'profileModifyTitle': 'Edit information',
    'profileSave': 'Save',
    'profileCancel': 'Cancel',
    'profileLogout': 'Log out',
    'profileLogoutConfirmTitle': 'Log out',
    'profileLogoutConfirmBody': 'End this session?',
    'profileHistory': 'History',
    'chatSupport': 'Customer support',
    'chatAdmin': 'Admin',
    'chatSenderMe': 'Me',
    'chatMessageQuestion': 'Question',
    'chatMessageAnswer': 'Answer',
    'chatOnline': 'Online',
    'chatAttachmentGallery': 'Gallery',
    'chatAttachmentCamera': 'Camera',
    'chatAttachmentDocument': 'Document',
    'chatClearConversation': 'Clear conversation',
    'chatClearConfirmTitle': 'Clear conversation',
    'chatClearConfirmBody': 'Delete all messages?',
    'chatClearAction': 'Clear',
    'commonCancel': 'Cancel',
    'commonRetry': 'Retry',
    'commonNotProvided': 'Not provided',
    'profileMembersCountLabel': 'Number of members',
    'profileHistoryStatusDone': 'Completed',
    'profileHistoryStatusInProgress': 'In progress',
    'profileHistoryStatusPending': 'Pending',
    'profileHistoryEmpty': 'No recent work for your team.',
    'chantierDetailTitle': 'Intervention details',
    'profileLoadError': 'Could not load profile.',
    'profileErrorGeneric': 'Profile error',
    'equipeLabelEdit': 'Team',
    'profileHistoryTitle': 'Recent work',
    'profileLogoutAction': 'Sign out',
    'profileMembersLine': '{n} people',
  },
  'ar': <String, String>{
    'appTitle': 'TRIG Essalama - الميدان',
    'loginTitle': 'تسجيل دخول المكلف',
    'loginProject': 'المشروع: TRIG Essalama',
    'loginEmail': 'البريد الإلكتروني',
    'loginPassword': 'كلمة المرور',
    'loginSubmit': 'دخول',
    'loginCreateAccount': 'إنشاء حساب',
    'loginFooter': 'أنشئ حساباً ثم سجّل الدخول.',
    'loginEmailRequired': 'البريد إلزامي',
    'loginEmailInvalid': 'بريد غير صالح',
    'loginPasswordRequired': 'كلمة المرور إلزامية',
    'loginServerUrl': 'عنوان الخادم',
    'accountCreatedSnackbar': 'تم إنشاء الحساب. سجّل الدخول.',
    'navChantiers': 'المواقع',
    'navNotif': 'تنبيهات',
    'navChat': 'محادثة',
    'navProfile': 'الملف',
    'notificationsTitle': 'الإشعارات',
    'notificationsNew': 'جديد',
    'notificationsMarkAllReadTooltip': 'تعليم الكل كمقروء',
    'notificationsLoading': 'جاري تحميل الإشعارات...',
    'notificationsEmptyTitle': 'لا إشعارات',
    'notificationsEmptyUnreadTitle': 'لا إشعارات غير مقروءة',
    'notificationsEmptyUnreadSubtitle': 'جميع الإشعارات مقروءة.',
    'notificationsEmptyDangerTitle': 'لا تنبيهات خطرة',
    'notificationsEmptyDangerSubtitle': 'لا إشعارات عالية الخطورة حالياً.',
    'notificationsEmptySubtitle': 'ستظهر الإشعارات الجديدة هنا.',
    'chantiersHeader': 'المواقع',
    'profilePreferences': 'التفضيلات',
    'profileTheme': 'المظهر',
    'profileThemeSystem': 'النظام (تلقائي)',
    'profileThemeLight': 'فاتح',
    'profileThemeDark': 'داكن',
    'profileLanguage': 'اللغة',
    'profileChooseLanguage': 'اختر اللغة',
    'profileTeamInfo': 'معلومات الفريق',
    'profileResponsible': 'المسؤول',
    'profilePhone': 'الهاتف',
    'profileZone': 'منطقة التدخل',
    'profileTeam': 'الفريق',
    'profileMembers': 'الأعضاء',
    'profileEdit': 'تعديل المعلومات',
    'profileModifyTitle': 'تعديل المعلومات',
    'profileSave': 'حفظ',
    'profileCancel': 'إلغاء',
    'profileLogout': 'تسجيل الخروج',
    'profileLogoutConfirmTitle': 'تسجيل الخروج',
    'profileLogoutConfirmBody': 'إنهاء الجلسة؟',
    'profileHistory': 'السجل',
    'chatSupport': 'دعم العملاء',
    'chatAdmin': 'المسؤول',
    'chatSenderMe': 'أنا',
    'chatMessageQuestion': 'سؤال',
    'chatMessageAnswer': 'رد',
    'chatOnline': 'متصل',
    'chatAttachmentGallery': 'المعرض',
    'chatAttachmentCamera': 'الكاميرا',
    'chatAttachmentDocument': 'مستند',
    'chatClearConversation': 'مسح المحادثة',
    'chatClearConfirmTitle': 'مسح المحادثة',
    'chatClearConfirmBody': 'حذف كل الرسائل؟',
    'chatClearAction': 'مسح',
    'commonCancel': 'إلغاء',
    'commonRetry': 'إعادة المحاولة',
    'commonNotProvided': 'غير مُدخل',
    'profileMembersCountLabel': 'عدد الأعضاء',
    'profileHistoryStatusDone': 'مكتمل',
    'profileHistoryStatusInProgress': 'جاري',
    'profileHistoryStatusPending': 'قيد الانتظار',
    'profileHistoryEmpty': 'لا تدخلات حديثة لفريقك.',
    'chantierDetailTitle': 'تفاصيل التدخل',
    'profileLoadError': 'تعذّر تحميل الملف.',
    'profileErrorGeneric': 'خطأ في الملف',
    'equipeLabelEdit': 'الفريق',
    'profileHistoryTitle': 'آخر التدخلات',
    'profileLogoutAction': 'خروج',
    'profileMembersLine': '{n} أشخاص',
  },
};
