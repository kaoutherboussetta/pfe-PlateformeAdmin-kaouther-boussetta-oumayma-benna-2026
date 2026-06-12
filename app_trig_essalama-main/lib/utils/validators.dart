/// Validateurs pour les champs de formulaire.
class Validators {
  Validators._();

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez entrer un nom';
    }
    if (value.trim().length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez entrer un email';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Email invalide';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().length < 8) {
      return 'Numéro invalide';
    }
    return null;
  }
}
