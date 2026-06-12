import 'package:flutter/material.dart';
import '../models/support_item.dart';
import '../services/support_service.dart';
import '../widgets/faq_tile.dart';
import '../widgets/contact_form.dart';
import '../widgets/bug_report_form.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<SupportItem> _supportItems = [];
  List<SupportItem> _infoItems = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadItems();
  }

  void _loadItems() {
    setState(() {
      _supportItems = SupportService.getSupportItems();
      _infoItems = SupportService.getInfoItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Aide & Support",
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Support'),
            Tab(text: 'Informations'),
          ],
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.secondary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSupportTab(theme),
          _buildInfoTab(theme),
        ],
      ),
    );
  }

  Widget _buildSupportTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Section Support
        _buildSectionHeader(
          'Support & Assistance',
          Icons.support_agent,
          theme,
        ),
        ..._supportItems.map((item) => _buildSupportTile(item, theme)).toList(),

        const SizedBox(height: 24),

        // Section FAQ
         // Footer
        Center(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                "Trig Essalama v2.0.0",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "© 2026 Trig Essalama - Tous droits réservés",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(
          'Documents & Informations',
          Icons.info_outline,
          theme,
        ),
        ..._infoItems.map((item) => _buildSupportTile(item, theme)).toList(),
        
        const SizedBox(height: 40),
        
        Center(
          child: Column(
            children: [
              Text(
                "Trig Essalama v2.0.0",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "© 2026 Trig Essalama - Tous droits réservés",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportTile(SupportItem item, ThemeData theme) {
    return Card(
      color: theme.colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Icon(item.icon, color: theme.colorScheme.primary),
        ),
        title: Text(
          item.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: item.subtitle != null
            ? Text(
                item.subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              )
            : null,
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: theme.colorScheme.secondary),
        onTap: () => _handleItemTap(item),
      ),
    );
  }

  void _handleItemTap(SupportItem item) {
    switch (item.type) {
      case SupportItemType.faq:
        _showFAQDialog();
        break;
      case SupportItemType.contact:
        _showContactDialog();
        break;
      case SupportItemType.bugReport:
        _showBugReportDialog();
        break;
      case SupportItemType.terms:
        _showTermsDialog();
        break;
      case SupportItemType.privacy:
        _showPrivacyDialog();
        break;
      case SupportItemType.about:
        _showAboutDialog();
        break;
      case SupportItemType.liveChat:
        _startLiveChat();
        break;
    }
  }

  void _showFAQDialog() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Foire aux Questions',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Divider(color: theme.dividerColor),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: SupportService.getFAQs()
                      .map((faq) => FAQTile(faq: faq))
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showContactDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          'Contacter le support',
          style: theme.textTheme.titleLarge,
        ),
        content: const ContactForm(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: theme.colorScheme.secondary)),
          ),
        ],
      ),
    );
  }

  void _showBugReportDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          'Signaler un problème',
          style: theme.textTheme.titleLarge,
        ),
        content: const BugReportForm(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: TextStyle(color: theme.colorScheme.secondary)),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          "Conditions d'utilisation",
          style: theme.textTheme.titleLarge,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Version 2.0 - Mars 2026",
                style: TextStyle(color: theme.colorScheme.primary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Text(
                "Bienvenue sur Trig Essalama, votre application dédiée à la sécurité routière.\n\n"
                "1. Acceptation des conditions\n"
                "En utilisant Trig Essalama, vous acceptez pleinement ces conditions d'utilisation.\n\n"
                "2. Utilisation responsable\n"
                "Notre application fournit des informations en temps réel sur les contrôles routiers. "
                "Ces informations sont données à titre indicatif et ne remplacent pas le respect du code de la route.\n\n"
                "3. Exactitude des informations\n"
                "Nous nous efforçons de maintenir des informations à jour et précises, mais nous ne pouvons garantir l'exactitude en temps réel.\n\n"
                "4. Comportement utilisateur\n"
                "Vous vous engagez à utiliser l'application de manière responsable.\n\n"
                "5. Protection des données\n"
                "Vos données sont traitées conformément à notre politique de confidentialité.\n\n"
                "6. Modifications\n"
                "Trig Essalama se réserve le droit de modifier ces conditions à tout moment.\n\n"
                "Pour toute question, contactez-nous à support@trig_essalama.com",
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer', style: TextStyle(color: theme.colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Text(
          "Politique de confidentialité",
          style: theme.textTheme.titleLarge,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Dernière mise à jour : Mars 2026",
                style: TextStyle(color: theme.colorScheme.primary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Text(
                "Chez Trig Essalama, nous prenons la protection de vos données très au sérieux.\n\n"
                "1. Données collectées\n"
                "• Localisation (uniquement lorsque l'application est active)\n"
                "• Historique des signalements\n"
                "• Adresse email (pour le support)\n"
                "• Données d'utilisation anonymisées\n\n"
                "2. Utilisation des données\n"
                "• Amélioration des signalements en temps réel\n"
                "• Personnalisation de l'expérience utilisateur\n"
                "• Analyse des zones à risque\n"
                "• Communication avec le support\n\n"
                "3. Protection des données\n"
                "Nous utilisons un cryptage avancé pour protéger vos informations. "
                "Vos données ne sont jamais vendues à des tiers.\n\n"
                "4. Vos droits\n"
                "• Accéder à vos données\n"
                "• Rectifier vos informations\n"
                "• Supprimer votre compte\n"
                "• Limiter le traitement des données\n\n"
                "5. Conservation\n"
                "Vos données sont conservées pendant la durée d'utilisation de votre compte. "
                "Vous pouvez demander leur suppression à tout moment.\n\n"
                "Pour exercer vos droits, contactez : dpo@trig_essalama.com",
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer', style: TextStyle(color: theme.colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.security_rounded,
                color: theme.colorScheme.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Trig Essalama',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 2.0.0',
              style: TextStyle(color: theme.colorScheme.secondary),
            ),
            const SizedBox(height: 8),
            const Text(
              "Application intelligente pour la sécurité routière",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Divider(color: theme.dividerColor),
            const SizedBox(height: 16),
            Text(
              '© 2026 Trig Essalama\nTous droits réservés',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email, size: 14, color: theme.colorScheme.secondary),
                const SizedBox(width: 4),
                Text(
                  'contact@trig_essalama.com',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer', style: TextStyle(color: theme.colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  void _startLiveChat() {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Service de chat en direct - Bientôt disponible'),
        backgroundColor: theme.colorScheme.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}