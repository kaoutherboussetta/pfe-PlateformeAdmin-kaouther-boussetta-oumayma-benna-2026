import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intervenant/l10n/app_localizations.dart';
import 'package:intervenant/models/probleme_voirie.dart';
import 'package:intervenant/pages/chantier_detail_page.dart';
import 'package:intervenant/pages/login_intervenant_page.dart';
import 'package:intervenant/services/app_settings_controller.dart';
import 'package:intervenant/services/auth_api_service.dart';

/// Libellé affiché : « Équipe 1 » / « Team 1 » / « الفريق 1 » selon la langue.
String displayEquipeLabel(String raw, String langCode) {
  final String t = raw.trim();
  final String prefix = AppLocalizations.equipePrefix(langCode);
  if (t.isEmpty) return '$prefix 1';
  final Match? m = RegExp(r'[123]').firstMatch(t);
  if (m != null) return '$prefix ${m.group(0)}';
  final String lower = t.toLowerCase();
  if (lower.contains('trois') || lower == 'three') return '$prefix 3';
  if (lower.contains('deux') || lower == 'two') return '$prefix 2';
  return '$prefix 1';
}

String _equipeAvatarDigit(String equipeLine) {
  final Match? m = RegExp(r'(\d)$').firstMatch(equipeLine.trim());
  return m != null ? m.group(1)! : 'E';
}

/// Valeur stable pour l’API (format « Équipe N ») quelle que soit la langue d’affichage.
String _equipeToApiString(String selectedLabel) {
  final Match? m = RegExp(r'(\d)\s*$').firstMatch(selectedLabel.trim());
  final String n = m?.group(1) ?? '1';
  return 'Équipe $n';
}

// Alignement avec la logique métier de `chantiers_page` (buckets de statut).
enum _ProblemeStatutBucket { enAttente, enCours, termine, autre }

_ProblemeStatutBucket _problemeStatutBucket(String raw) {
  final String s = raw.toLowerCase().trim();
  if (s.contains('termin')) return _ProblemeStatutBucket.termine;
  if (s.contains('attente')) return _ProblemeStatutBucket.enAttente;
  if (s.contains('cours') || s.contains('progress')) return _ProblemeStatutBucket.enCours;
  return _ProblemeStatutBucket.autre;
}

DateTime _problemeSortTime(ProblemeVoirie p) {
  final DateTime? u = DateTime.tryParse(p.updatedAt);
  if (u != null) return u;
  final DateTime? d = DateTime.tryParse(p.dateDetection);
  if (d != null) return d;
  return DateTime.fromMillisecondsSinceEpoch(0);
}

String _historyTitleForProbleme(ProblemeVoirie p, String langCode) {
  if (langCode == 'ar' && p.descriptionAr.trim().isNotEmpty) return p.descriptionAr.trim();
  if (langCode == 'fr' && p.descriptionFr.trim().isNotEmpty) return p.descriptionFr.trim();
  if (p.description.trim().isNotEmpty) return p.description.trim();
  if (p.descriptionFr.trim().isNotEmpty) return p.descriptionFr.trim();
  if (p.problemType.trim().isNotEmpty) return p.problemType.trim();
  return p.address.trim().isNotEmpty ? p.address.trim() : '—';
}

String _historyStatusLabel(ProblemeVoirie p, AppLocalizations l10n) {
  switch (_problemeStatutBucket(p.status)) {
    case _ProblemeStatutBucket.termine:
      return l10n.profileHistoryStatusDone;
    case _ProblemeStatutBucket.enCours:
      return l10n.profileHistoryStatusInProgress;
    case _ProblemeStatutBucket.enAttente:
      return l10n.profileHistoryStatusPending;
    case _ProblemeStatutBucket.autre:
      final String s = p.status.trim();
      return s.isNotEmpty ? s : l10n.profileHistoryStatusPending;
  }
}

String _formatProfileHistoryDate(BuildContext context, ProblemeVoirie p) {
  final String raw = p.updatedAt.trim().isNotEmpty ? p.updatedAt : p.dateDetection;
  if (raw.isEmpty) return '—';
  final DateTime? dt = DateTime.tryParse(raw);
  if (dt == null) return raw;
  final Locale locale = Localizations.localeOf(context);
  final String locName =
      locale.languageCode == 'ar' ? 'ar' : locale.languageCode == 'en' ? 'en' : 'fr_FR';
  try {
    return DateFormat('dd/MM/yyyy', locName).format(dt.toLocal());
  } catch (_) {
    return DateFormat('dd/MM/yyyy').format(dt.toLocal());
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({required this.name, required this.email, this.team, super.key});

  final String name;
  final String email;
  final String? team;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;
  List<ProblemeVoirie> _problemesTeam = const <ProblemeVoirie>[];
  bool _loadingProblemes = false;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    await _loadProfile();
    await _loadTeamProblemes();
  }

  String _teamLabelForFetch() {
    final Map<String, dynamic> p = _profile ?? _fallbackProfile();
    final String s = '${p['speciality'] ?? ''} ${p['team'] ?? ''}'.trim();
    if (s.isNotEmpty) return s;
    return widget.team?.trim() ?? '';
  }

  Future<void> _loadTeamProblemes() async {
    final String label = _teamLabelForFetch();
    if (_baseUrl.isEmpty || label.isEmpty) {
      if (mounted) {
        setState(() {
          _problemesTeam = const <ProblemeVoirie>[];
          _loadingProblemes = false;
        });
      }
      return;
    }
    if (mounted) setState(() => _loadingProblemes = true);
    try {
      final List<ProblemeVoirie> list =
          await AuthApiService.instance.fetchProblemesVoirie(teamLabel: label, limit: 5000);
      if (!mounted) return;
      setState(() {
        _problemesTeam = list;
        _loadingProblemes = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _problemesTeam = const <ProblemeVoirie>[];
        _loadingProblemes = false;
      });
    }
  }

  List<ProblemeVoirie> _recentProblemesForHistory({int maxItems = 5}) {
    if (_problemesTeam.isEmpty) return const <ProblemeVoirie>[];
    final List<ProblemeVoirie> sorted = List<ProblemeVoirie>.from(_problemesTeam);
    sorted.sort((ProblemeVoirie a, ProblemeVoirie b) => _problemeSortTime(b).compareTo(_problemeSortTime(a)));
    if (sorted.length <= maxItems) return sorted;
    return sorted.sublist(0, maxItems);
  }

  String get _email => widget.email.trim().toLowerCase();
  String get _baseUrl => AuthApiService.baseUrl.trim();

  Future<void> _loadProfile() async {
    if (_baseUrl.isEmpty || _email.isEmpty) {
      setState(() {
        _loading = false;
        _profile = _fallbackProfile();
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final Uri url = Uri.parse('$_baseUrl/api/profile').replace(queryParameters: {'email': _email});
      final res = await http.get(url, headers: const {'Accept': 'application/json'});
      final Map<String, dynamic> body = _decodeMap(res.body);
      if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
        final Map<String, dynamic> item = Map<String, dynamic>.from((body['item'] as Map?) ?? {});
        setState(() {
          _profile = item;
          _loading = false;
        });
        AppSettingsController.instance.applyFromProfileMap(item);
        return;
      }
      setState(() {
        _profile = _fallbackProfile();
        _loading = false;
        _error = (body['message'] as String?) ??
            AppLocalizations(AppSettingsController.instance.locale).profileLoadError;
      });
    } catch (e) {
      setState(() {
        _profile = _fallbackProfile();
        _loading = false;
        _error = '${AppLocalizations(AppSettingsController.instance.locale).profileErrorGeneric}: $e';
      });
    }
  }

  Map<String, dynamic> _fallbackProfile() {
    return {
      'name': widget.name,
      'responsable': widget.name,
      'email': widget.email,
      'phone': '+216 22 000 000',
      'zone': 'Sfax Centre',
      'speciality': widget.team?.trim().isNotEmpty == true ? widget.team!.trim() : '',
      'membersCount': 5,
      'completedChantiers': 25,
      'currentChantiers': 3,
      'urgentChantiers': 1,
      'avgInterventionTime': '2h',
      'rating': 4.8,
      'darkModeEnabled': false,
      'themeMode': 'system',
      'preferredLanguage': 'fr',
    };
  }

  Future<void> _updateProfileField(Map<String, dynamic> patch) async {
    if (_baseUrl.isEmpty || _email.isEmpty) return;
    final Uri url = Uri.parse('$_baseUrl/api/profile');
    await http.patch(
      url,
      headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'email': _email, ...patch}),
    );
  }

  Map<String, dynamic> _decodeMap(String s) {
    try {
      final Object? d = jsonDecode(s);
      if (d is Map<String, dynamic>) return d;
      if (d is Map) return Map<String, dynamic>.from(d);
    } catch (_) {}
    return <String, dynamic>{};
  }

  /// En-tête : spécialité / équipe (session) si absent du document API.
  Map<String, dynamic> _headerProfile() {
    final Map<String, dynamic> p = Map<String, dynamic>.from(_profile ?? _fallbackProfile());
    final String spec = (p['speciality'] ?? p['team'] ?? '').toString().trim();
    if (spec.isEmpty) {
      final String t = widget.team?.trim() ?? '';
      if (t.isNotEmpty) p['speciality'] = t;
    }
    return p;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _refreshAll,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Hero Header
                SliverToBoxAdapter(
                  child: _ModernProfileHeader(profile: _headerProfile()),
                ),
                // Contenu principal
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _ModernInfoCard(profile: _profile ?? _fallbackProfile(), onUpdate: _updateProfileField),
                      const SizedBox(height: 16),
                      _ModernHistoryCard(
                        loading: _loadingProblemes,
                        items: _recentProblemesForHistory(),
                      ),
                      const SizedBox(height: 16),
                      _ModernSettingsCard(profile: _profile ?? _fallbackProfile(), onUpdate: _updateProfileField),
                      const SizedBox(height: 16),
                      _LogoutButton(),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        _ErrorBanner(error: _error!),
                      ],
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

// ==================== MODERN PROFILE HEADER ====================

class _ModernProfileHeader extends StatelessWidget {
  const _ModernProfileHeader({required this.profile});

  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String email = profile['email'] ?? '';
    final String rawEquipe =
        (profile['speciality'] ?? profile['team'] ?? '').toString().trim();
    final String langCode = Localizations.localeOf(context).languageCode;
    final String equipeLine = displayEquipeLabel(rawEquipe, langCode);
    final String avatarLetter = rawEquipe.isEmpty && email.isNotEmpty
        ? email[0].toUpperCase()
        : _equipeAvatarDigit(equipeLine);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Text(
                        avatarLetter,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          equipeLine,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.25,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== MODERN INFO CARD ====================

class _ModernInfoCard extends StatelessWidget {
  const _ModernInfoCard({
    required this.profile,
    required this.onUpdate,
  });

  final Map<String, dynamic> profile;
  final Future<void> Function(Map<String, dynamic>) onUpdate;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String langCode = Localizations.localeOf(context).languageCode;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.business_center_rounded, color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.profileTeamInfo,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _openEditDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _InfoRow(
              icon: Icons.person_outline_rounded,
              label: l10n.profileResponsible,
              value: profile['responsable'] ?? '',
            ),
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.phone_outlined,
              label: l10n.profilePhone,
              value: profile['phone'] ?? '',
            ),
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: l10n.profileZone,
              value: profile['zone'] ?? '',
            ),
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.groups_outlined,
              label: l10n.profileTeam,
              value: displayEquipeLabel('${profile['speciality'] ?? ''} ${profile['team'] ?? ''}', langCode),
            ),
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.group_outlined,
              label: l10n.profileMembers,
              value: l10n.profileMembersLine((profile['membersCount'] as num?)?.toInt() ?? 0),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditDialog(BuildContext context) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String langCode = l10n.locale.languageCode;
    final List<String> equipeChoices = l10n.equipeChoices();
    final TextEditingController responsableCtrl = TextEditingController(text: profile['responsable'] ?? '');
    final TextEditingController phoneCtrl = TextEditingController(text: profile['phone'] ?? '');
    final TextEditingController zoneCtrl = TextEditingController(text: profile['zone'] ?? '');
    final TextEditingController membersCtrl = TextEditingController(text: '${profile['membersCount'] ?? 1}');
    bool saving = false;
    String selectedEquipe =
        displayEquipeLabel('${profile['speciality'] ?? ''} ${profile['team'] ?? ''}', langCode);
    if (!equipeChoices.contains(selectedEquipe)) {
      selectedEquipe = equipeChoices.first;
    }

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.profileModifyTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogTextField(
                    controller: responsableCtrl, label: l10n.profileResponsible, icon: Icons.person_outline_rounded),
                const SizedBox(height: 12),
                _DialogTextField(
                    controller: phoneCtrl,
                    label: l10n.profilePhone,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                _DialogTextField(controller: zoneCtrl, label: l10n.profileZone, icon: Icons.location_on_outlined),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.equipeLabelEdit,
                    prefixIcon: Icon(Icons.groups_outlined, color: Theme.of(context).colorScheme.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedEquipe,
                      items: equipeChoices
                          .map(
                            (String e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(e),
                            ),
                          )
                          .toList(),
                      onChanged: (String? v) {
                        if (v != null) setDialogState(() => selectedEquipe = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _DialogTextField(
                  controller: membersCtrl,
                  label: l10n.profileMembersCountLabel,
                  icon: Icons.group_outlined,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: Text(l10n.profileCancel),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final int members = int.tryParse(membersCtrl.text.trim()) ?? 1;
                      final String apiEquipe = _equipeToApiString(selectedEquipe);
                      final Map<String, dynamic> patch = {
                        'responsable': responsableCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                        'zone': zoneCtrl.text.trim(),
                        'speciality': apiEquipe,
                        'team': apiEquipe,
                        'membersCount': members < 1 ? 1 : members,
                      };
                      setDialogState(() => saving = true);
                      await onUpdate(patch);
                      if (context.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    },
              child: saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.profileSave),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.outline),
        const SizedBox(width: 12),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : l10n.commonNotProvided,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _DialogTextField extends StatelessWidget {
  const _DialogTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ==================== MODERN HISTORY CARD ====================

class _ModernHistoryCard extends StatelessWidget {
  const _ModernHistoryCard({
    required this.loading,
    required this.items,
  });

  final bool loading;
  final List<ProblemeVoirie> items;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String langCode = Localizations.localeOf(context).languageCode;

    final List<Widget> bodyChildren = <Widget>[
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.history_rounded, color: Colors.teal, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            l10n.profileHistoryTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      const SizedBox(height: 16),
    ];

    if (loading && items.isEmpty) {
      bodyChildren.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else if (items.isEmpty) {
      bodyChildren.add(
        Text(
          l10n.profileHistoryEmpty,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    } else {
      for (int i = 0; i < items.length; i++) {
        if (i > 0) {
          bodyChildren.add(Divider(color: theme.colorScheme.outlineVariant));
        }
        final ProblemeVoirie p = items[i];
        bodyChildren.add(
          _HistoryItem(
            title: _historyTitleForProbleme(p, langCode),
            status: _historyStatusLabel(p, l10n),
            statusColor: ChantierDetailPage.statusColor(p.status),
            date: _formatProfileHistoryDate(context, p),
          ),
        );
      }
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: bodyChildren,
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({
    required this.title,
    required this.status,
    required this.statusColor,
    required this.date,
  });

  final String title;
  final String status;
  final Color statusColor;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== MODERN SETTINGS CARD ====================

class _ModernSettingsCard extends StatelessWidget {
  const _ModernSettingsCard({
    required this.profile,
    required this.onUpdate,
  });

  final Map<String, dynamic> profile;
  final Future<void> Function(Map<String, dynamic>) onUpdate;

  static const Map<String, String> _kLanguageCodes = <String, String>{
    'fr': 'Français',
    'en': 'English',
    'ar': 'العربية',
  };

  static Future<void> _applyTheme(ThemeMode? mode, Future<void> Function(Map<String, dynamic>) onUpdate) async {
    if (mode == null) return;
    await AppSettingsController.instance.setThemeMode(mode);
    final String modeStr = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await onUpdate(<String, dynamic>{
      'themeMode': modeStr,
      'darkModeEnabled': mode == ThemeMode.dark,
    });
  }

  String _languageLabel(String? code) {
    final String c = (code ?? 'fr').toLowerCase();
    return _kLanguageCodes[c] ?? c.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ListenableBuilder(
          listenable: AppSettingsController.instance,
          builder: (BuildContext context, _) {
            final ThemeMode themeMode = AppSettingsController.instance.themeMode;
            final String activeLang = AppSettingsController.instance.locale.languageCode;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.settings_rounded, color: Colors.grey, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.profilePreferences,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.profileTheme,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant),
                ),
                RadioListTile<ThemeMode>(
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  title: Text(l10n.profileThemeSystem),
                  value: ThemeMode.system,
                  groupValue: themeMode,
                  onChanged: (ThemeMode? v) => _applyTheme(v, onUpdate),
                ),
                RadioListTile<ThemeMode>(
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  title: Text(l10n.profileThemeLight),
                  value: ThemeMode.light,
                  groupValue: themeMode,
                  onChanged: (ThemeMode? v) => _applyTheme(v, onUpdate),
                ),
                RadioListTile<ThemeMode>(
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  title: Text(l10n.profileThemeDark),
                  value: ThemeMode.dark,
                  groupValue: themeMode,
                  onChanged: (ThemeMode? v) => _applyTheme(v, onUpdate),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.profileLanguage),
                  subtitle: Text(
                    _languageLabel(activeLang),
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.outline),
                  onTap: () => _showLanguagePicker(context, l10n, onUpdate),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showLanguagePicker(
    BuildContext context,
    AppLocalizations l10n,
    Future<void> Function(Map<String, dynamic>) onUpdate,
  ) {
    final String current = AppSettingsController.instance.locale.languageCode;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.profileChooseLanguage, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            for (final MapEntry<String, String> entry in _kLanguageCodes.entries)
              ListTile(
                leading: Icon(
                  current == entry.key ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: current == entry.key ? Theme.of(sheetContext).colorScheme.primary : Colors.grey,
                ),
                title: Text(entry.value),
                subtitle: Text(entry.key.toUpperCase()),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await AppSettingsController.instance.setLocale(Locale(entry.key));
                  await onUpdate(<String, dynamic>{'preferredLanguage': entry.key});
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ==================== LOGOUT BUTTON ====================

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return FilledButton.icon(
      onPressed: () => _showLogoutConfirmation(context),
      icon: const Icon(Icons.logout_rounded),
      label: Text(l10n.profileLogout),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.profileLogoutConfirmTitle),
        content: Text(l10n.profileLogoutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.profileCancel),
          ),
          FilledButton(
            onPressed: () async {
              await AuthApiService.logoutClearSession();
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => LoginIntervenantPage()),
                (route) => false,
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: Text(l10n.profileLogoutAction),
          ),
        ],
      ),
    );
  }
}

// ==================== ERROR BANNER ====================

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}