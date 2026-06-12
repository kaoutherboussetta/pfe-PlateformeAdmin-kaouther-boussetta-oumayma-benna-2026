/// Langues supportées : français, anglais, darija tunisienne (texte en translittération latine).
enum AppLanguage {
  fr('fr'),
  en('en'),
  tnd('tnd');

  final String code;
  const AppLanguage(this.code);

  static AppLanguage? fromCode(String? code) {
    if (code == null) return null;
    for (final v in AppLanguage.values) {
      if (v.code == code) return v;
    }
    return null;
  }
}
