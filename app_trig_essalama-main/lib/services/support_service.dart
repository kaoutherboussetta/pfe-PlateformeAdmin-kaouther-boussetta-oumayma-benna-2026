import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/support_item.dart';
import '../models/faq.dart';

class SupportService {
  // Données dynamiques - peuvent venir d'une API
  static List<SupportItem> getSupportItems() {
    return [
      SupportItem(
        id: 'live_chat',
        title: 'Chat en direct',
        subtitle: 'Discuter avec un conseiller',
        icon: Icons.chat,
        type: SupportItemType.liveChat,
        content: 'Disponible 24h/24, 7j/7',
        actionUrl: 'chat_screen',
      ),
      SupportItem(
        id: 'faq',
        title: 'FAQ',
        subtitle: 'Questions fréquentes',
        icon: Icons.help_outline,
        type: SupportItemType.faq,
        content: 'Trouvez des réponses à vos questions',
      ),
      SupportItem(
        id: 'contact',
        title: 'Contacter le support',
        subtitle: 'Réponse sous 24h',
        icon: Icons.support_agent,
        type: SupportItemType.contact,
        content: 'support@trig_essalama.com',
        actionUrl: 'mailto:support@trig_essalama.com?subject=Support%20Request',
        isExternal: true,
      ),
      SupportItem(
        id: 'bug',
        title: 'Signaler un problème',
        subtitle: 'Nous aider à améliorer l\'application',
        icon: Icons.bug_report,
        type: SupportItemType.bugReport,
        content: 'Décrivez le problème rencontré',
      ),
    ];
  }

  static List<SupportItem> getInfoItems() {
    return [
      SupportItem(
        id: 'terms',
        title: 'Conditions d\'utilisation',
        icon: Icons.description,
        type: SupportItemType.terms,
        content: 'Version 2.0 - Dernière mise à jour: Janvier 2024',
      ),
      SupportItem(
        id: 'privacy',
        title: 'Politique de confidentialité',
        icon: Icons.privacy_tip,
        type: SupportItemType.privacy,
        content: 'Comment nous protégeons vos données',
      ),
      SupportItem(
        id: 'about',
        title: 'À propos',
        icon: Icons.info_outline,
        type: SupportItemType.about,
        content: 'Trig Essalama v2.0.0',
      ),
    ];
  }

  static List<FAQ> getFAQs() {
    return [
      FAQ(
        question: 'Comment créer un compte ?',
        answer: 'Pour créer un compte, cliquez sur "S\'inscrire" sur l\'écran d\'accueil et suivez les instructions. Vous aurez besoin d\'une adresse email valide.',
        category: 'Compte',
        order: 1,
      ),
      FAQ(
        question: 'Comment réinitialiser mon mot de passe ?',
        answer: 'Sur l\'écran de connexion, cliquez sur "Mot de passe oublié". Vous recevrez un email avec les instructions pour réinitialiser votre mot de passe.',
        category: 'Compte',
        order: 2,
      ),
      FAQ(
        question: 'L\'application est-elle gratuite ?',
        answer: 'Oui, l\'application est entièrement gratuite. Certaines fonctionnalités premium seront disponibles prochainement.',
        category: 'Général',
        order: 3,
      ),
      FAQ(
        question: 'Comment signaler un contenu inapproprié ?',
        answer: 'Utilisez la fonction "Signaler" disponible sur chaque contenu, ou contactez notre support via la section "Signaler un problème".',
        category: 'Modération',
        order: 4,
      ),
    ];
  }

  static Future<void> sendBugReport(BuildContext context, String description, String? screenshotPath) async {
    // Logique d'envoi du rapport de bug
    await Future.delayed(const Duration(seconds: 1)); // Simulation d'envoi
    
    if (context.mounted) {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Rapport envoyé avec succès !'),
          backgroundColor: theme.colorScheme.primary, // Dynamic color
        ),
      );
    }
  }

  static Future<void> sendContactMessage(BuildContext context, String subject, String message) async {
    // Logique d'envoi du message de contact
    await Future.delayed(const Duration(seconds: 1)); // Simulation
    
    if (context.mounted) {
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Message envoyé ! Notre équipe vous répondra sous 24h.'),
          backgroundColor: theme.colorScheme.primary, // Dynamic color
        ),
      );
    }
  }

  static Future<void> handleAction(BuildContext context, SupportItem item) async {
    if (item.actionUrl != null) {
      if (item.isExternal) {
        final Uri uri = Uri.parse(item.actionUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      } else {
        // Navigation interne si besoin
        Navigator.pushNamed(context, '/${item.actionUrl}');
      }
    }
  }
}
