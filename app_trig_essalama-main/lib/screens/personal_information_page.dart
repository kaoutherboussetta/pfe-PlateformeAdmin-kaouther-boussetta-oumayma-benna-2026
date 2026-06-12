import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../services/login_history_service.dart';
import 'edit_profile_page.dart';

/// Page d'informations personnelles - Version Design System Professionnel
class PersonalInformationPage extends StatelessWidget {
  const PersonalInformationPage({super.key});

  static String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUser;
          if (user == null) {
            return const Center(
              child: Text(
                'Aucune information disponible',
                style: TextStyle(color: AppTheme.secondaryGrey),
              ),
            );
          }
          return CustomScrollView(
            slivers: [
              // AppBar personnalisée
              SliverAppBar(
                expandedHeight: 280,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gradient d'arrière-plan
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppTheme.alertOrange.withValues(alpha: 0.2),
                              Theme.of(context).scaffoldBackgroundColor,
                            ],
                          ),
                        ),
                      ),
                      // Contenu du header
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 30,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Photo de profil
                            Stack(
                              children: [
                                _buildPhoto(context, user.profileImage),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.alertOrange,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.primaryBlack,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.verified,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            // Informations utilisateur
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${user.firstName} ${user.lastName}'.trim(),
                                    style: TextStyle(
                                      color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.alertOrange.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: AppTheme.alertOrange.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.star_rounded,
                                              size: 16,
                                              color: AppTheme.alertOrange,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Membre ${_formatDate(user.createdAt).split('/').last}',
                                              style: TextStyle(
                                                color: AppTheme.alertOrange,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                leading: Padding(
                  padding: const EdgeInsets.only(left: 12, top: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, 
                          color: Colors.white, size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12, top: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit_rounded, 
                            color: Colors.white, size: 22),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const EditProfilePage()),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Contenu principal
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Sections d'informations
                    _buildGlassSection(context, 'Informations personnelles', [
                      _GlassInfoItem(
                        icon: Icons.badge_outlined,
                        label: 'Nom complet',
                        value: '${user.lastName} ${user.firstName}'.trim(),
                        isHighlighted: true,
                      ),
                      _GlassInfoItem(
                        icon: Icons.cake_outlined,
                        label: 'Date de naissance',
                        value: _formatDate(user.dateOfBirth),
                        trailing: const Icon(Icons.celebration_outlined, 
                            color: AppTheme.secondaryGrey, size: 18),
                      ),
                      _GlassInfoItem(
                        icon: Icons.wc_outlined,
                        label: 'Genre',
                        value: user.gender ?? 'Non spécifié',
                      ),
                      _GlassInfoItem(
                        icon: Icons.location_city_rounded,
                        label: 'Ville / Région',
                        value: user.cityRegion ?? 'Non spécifié',
                      ),
                    ]),

                    const SizedBox(height: 16),

                    _buildGlassSection(context, 'Coordonnées', [
                      _GlassInfoItem(
                        icon: Icons.email_outlined,
                        label: 'Adresse email',
                        value: user.email ?? 'Non renseigné',
                        isVerified: user.email != null,
                      ),
                      _GlassInfoItem(
                        icon: Icons.phone_outlined,
                        label: 'Numéro de téléphone',
                        value: user.phone ?? 'Non renseigné',
                        isVerified: user.phone != null,
                      ),
                      _GlassInfoItem(
                        icon: Icons.home_outlined,
                        label: 'Adresse postale',
                        value: user.location ?? 'Non renseigné',
                      ),
                    ]),

                    const SizedBox(height: 16),

                    const _LoginHistoryBlock(),

                    const SizedBox(height: 16),

                    _buildGlassSection(context, 'Informations système', [
                      _GlassInfoItem(
                        icon: Icons.fingerprint_rounded,
                        label: 'Identifiant unique',
                        value: user.id,
                        isTechnical: true,
                      ),
                      _GlassInfoItem(
                        icon: Icons.update_rounded,
                        label: 'Dernière mise à jour',
                        value: DateTime.now().toString().substring(0, 10),
                        isTechnical: true,
                      ),
                    ]),

                    const SizedBox(height: 30),

                    // Bouton d'action principal
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.alertOrange,
                            AppTheme.alertOrange.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.alertOrange.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const EditProfilePage()),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit_rounded, color: Theme.of(context).colorScheme.onPrimary),
                            const SizedBox(width: 8),
                            Text(
                              'Modifier mon profil',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGlassSection(BuildContext context, String title, List<_GlassInfoItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.secondaryGrey,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  if (index > 0)
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                    ),
                  _buildGlassInfoRow(context, item),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassInfoRow(BuildContext context, _GlassInfoItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.alertOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item.icon,
              color: item.isTechnical 
                  ? AppTheme.secondaryGrey 
                  : AppTheme.alertOrange,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    color: item.isTechnical 
                        ? AppTheme.secondaryGrey.withOpacity(0.7)
                        : AppTheme.secondaryGrey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: TextStyle(
                    color: item.isHighlighted 
                        ? (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white) 
                        : (item.isTechnical 
                            ? AppTheme.secondaryGrey.withOpacity(0.7)
                            : (Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.9) ?? Colors.white.withOpacity(0.9))),
                    fontSize: item.isTechnical ? 13 : 15,
                    fontWeight: item.isHighlighted 
                        ? FontWeight.w600 
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (item.trailing != null) item.trailing!,
          if (item.isVerified)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: Colors.green,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhoto(BuildContext context, String? profileImage) {
    Widget photoChild;
    
    if (profileImage != null && profileImage.isNotEmpty) {
      if (profileImage.startsWith('data:')) {
        try {
          final base64 = profileImage.contains(',') 
              ? profileImage.split(',').last 
              : profileImage;
          photoChild = Image.memory(
            base64Decode(base64),
            fit: BoxFit.cover,
          );
        } catch (_) {
          photoChild = _buildPhotoPlaceholder(context);
        }
      } else {
        photoChild = Image.network(
          profileImage,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPhotoPlaceholder(context),
        );
      }
    } else {
      photoChild = _buildPhotoPlaceholder(context);
    }

    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.alertOrange.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipOval(child: photoChild),
    );
  }

  Widget _buildPhotoPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: const Icon(
        Icons.person_outline_rounded,
        size: 45,
        color: AppTheme.secondaryGrey,
      ),
    );
  }
}

/// Historique des connexions (données locales, enrichi à chaque login réussi).
class _LoginHistoryBlock extends StatefulWidget {
  const _LoginHistoryBlock();

  @override
  State<_LoginHistoryBlock> createState() => _LoginHistoryBlockState();
}

class _LoginHistoryBlockState extends State<_LoginHistoryBlock> {
  List<LoginHistoryEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await LoginHistoryService.load();
    if (!mounted) return;
    setState(() {
      // Afficher uniquement les 5 dernières connexions
      _entries = list.take(5).toList();
      _loading = false;
    });
  }

  String _formatEntryDateTime(DateTime d) {
    final date =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    final time =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '$date · $time';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            'Historique des connexions',
            style: TextStyle(
              color: AppTheme.secondaryGrey,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          ),
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : _entries.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.alertOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.history_rounded,
                              color: AppTheme.alertOrange,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Aucune connexion enregistrée pour le moment. '
                              'Les connexions réussies apparaîtront ici après votre prochaine connexion.',
                              style: TextStyle(
                                color: AppTheme.secondaryGrey.withOpacity(0.9),
                                fontSize: 14,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: _entries.asMap().entries.map((entry) {
                        final index = entry.key;
                        final e = entry.value;
                        return Column(
                          children: [
                            if (index > 0)
                              Container(
                                height: 1,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          AppTheme.alertOrange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      e.success
                                          ? Icons.login_rounded
                                          : Icons.cancel_outlined,
                                      color: e.success
                                          ? AppTheme.alertOrange
                                          : Colors.redAccent,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          e.location,
                                          style: TextStyle(
                                            color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${e.device} · ${_formatEntryDateTime(e.at)}',
                                          style: TextStyle(
                                            color: AppTheme.secondaryGrey
                                                .withOpacity(0.85),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (e.success)
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.green,
                                        size: 18,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
        ),
      ],
    );
  }
}

class _GlassInfoItem {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final bool isVerified;
  final bool isHighlighted;
  final bool isTechnical;

  const _GlassInfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.isVerified = false,
    this.isHighlighted = false,
    this.isTechnical = false,
  });
}