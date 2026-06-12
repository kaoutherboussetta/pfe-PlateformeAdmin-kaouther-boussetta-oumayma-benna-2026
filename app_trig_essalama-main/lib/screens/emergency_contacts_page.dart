import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/emergency_contact_model.dart';
import '../providers/auth_provider.dart';
import '../services/emergency_contacts_service.dart';

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  List<EmergencyContact> _contacts = [];
  bool _loading = true;
  String? _error;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isPrimary = false;
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final userId = user?.id;
    if (userId == null || userId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Utilisateur non connecté';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = Provider.of<EmergencyContactsService>(context, listen: false);
      final list = await service.getContacts(userId);
      if (mounted) {
        setState(() {
          _contacts = list;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showContactDialog({int? index}) {
    if (index != null) {
      // Mode édition
      final contact = _contacts[index];
      _nameController.text = contact.name;
      _phoneController.text = contact.phone;
      _relationshipController.text = contact.relationship;
      _emailController.text = contact.email;
      _isPrimary = contact.isPrimary;
      _editingIndex = index;
    } else {
      // Mode ajout
      _nameController.clear();
      _phoneController.clear();
      _relationshipController.clear();
      _emailController.clear();
      _isPrimary = false;
      _editingIndex = null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Material(
          color: Colors.transparent,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.secondaryGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    index == null ? 'Ajouter un contact' : 'Modifier le contact',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Formulaire
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Nom
                      _buildTextField(
                        controller: _nameController,
                        label: 'Nom complet',
                        icon: Icons.person_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Le nom est requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Téléphone
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Numéro de téléphone',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Le numéro est requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Relation
                      _buildTextField(
                        controller: _relationshipController,
                        label: 'Relation',
                        icon: Icons.people_outlined,
                        hintText: 'Père, mère, ami, conjoint...',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La relation est requise';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Email (optionnel)
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email (optionnel)',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      
                      // Contact principal
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: _isPrimary ? AppTheme.alertOrange : AppTheme.secondaryGrey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Définir comme contact principal',
                                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText),
                              ),
                            ),
                            Switch(
                              value: _isPrimary,
                              onChanged: (value) {
                                setState(() => _isPrimary = value);
                                setModalState(() {});
                              },
                              activeTrackColor: AppTheme.alertOrange.withOpacity(0.5),
                              activeColor: AppTheme.alertOrange,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Boutons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (index != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final contact = _contacts[index];
                          final id = contact.id;
                          if (id == null) return;
                          final userId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
                          if (userId == null) {
                            _showSnackBar('Utilisateur non connecté');
                            return;
                          }
                          try {
                            final service = Provider.of<EmergencyContactsService>(context, listen: false);
                            await service.deleteContact(userId, id);
                            if (!mounted) return;
                            setState(() => _contacts.removeAt(index));
                            Navigator.pop(context);
                            _showSnackBar('Contact supprimé');
                          } catch (e) {
                            if (mounted) _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Supprimer'),
                      ),
                    ),
                  if (index != null) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        final userId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
                        if (userId == null) {
                          _showSnackBar('Utilisateur non connecté');
                          return;
                        }
                        final contact = EmergencyContact(
                          name: _nameController.text.trim(),
                          phone: _phoneController.text.trim(),
                          relationship: _relationshipController.text.trim(),
                          email: _emailController.text.trim(),
                          isPrimary: _isPrimary,
                        );
                        try {
                          final service = Provider.of<EmergencyContactsService>(context, listen: false);
                          if (_editingIndex != null) {
                            final id = _contacts[_editingIndex!].id;
                            if (id == null) return;
                            final updated = await service.updateContact(userId, id, contact);
                            if (!mounted) return;
                            setState(() {
                              _contacts[_editingIndex!] = updated;
                            });
                            _showSnackBar('Contact modifié');
                          } else {
                            final created = await service.addContact(userId, contact);
                            if (!mounted) return;
                            setState(() => _contacts.add(created));
                            _showSnackBar('Contact ajouté');
                          }
                          Navigator.pop(context);
                        } catch (e) {
                          if (mounted) _showSnackBar(e.toString().replaceFirst('Exception: ', ''));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.alertOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(index == null ? 'Ajouter' : 'Enregistrer'),
                    ),
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText),
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.secondaryGrey),
        hintText: hintText,
        hintStyle: const TextStyle(color: AppTheme.secondaryGrey),
        prefixIcon: Icon(icon, color: AppTheme.alertOrange),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.alertOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.alertOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Contacts d\'urgence',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: AppTheme.secondaryGrey),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  title: Text(
                    'Contacts d\'urgence',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText),
                  ),
                  content: const Text(
                    'Ces contacts seront notifiés en cas d\'urgence '
                    'lors de vos trajets. Le contact principal sera '
                    'contacté en premier.',
                    style: TextStyle(color: AppTheme.secondaryGrey),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Compris', style: TextStyle(color: AppTheme.alertOrange)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.alertOrange),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.alertOrange),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.secondaryGrey),
                        ),
                        const SizedBox(height: 24),
                        TextButton.icon(
                          onPressed: _loadContacts,
                          icon: const Icon(Icons.refresh_rounded, color: AppTheme.alertOrange),
                          label: const Text('Réessayer', style: TextStyle(color: AppTheme.alertOrange)),
                        ),
                      ],
                    ),
                  ),
                )
              : _contacts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.contact_emergency_rounded,
                              size: 50,
                              color: AppTheme.secondaryGrey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun contact d\'urgence',
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Ajoutez des contacts pour être prévenu\nen cas d\'urgence',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.secondaryGrey),
                          ),
                          const SizedBox(height: 24),
                          _buildAddButton(),
                        ],
                      ),
                    )
                  : Column(
              children: [
                // En-tête avec statistiques
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.alertOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.contact_emergency_rounded,
                          color: AppTheme.alertOrange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Contacts d\'urgence',
                              style: TextStyle(
                                color: AppTheme.secondaryGrey,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${_contacts.length} contact${_contacts.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildAddButton(isCompact: true),
                    ],
                  ),
                ),
                
                // Liste des contacts
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _contacts.length,
                    itemBuilder: (context, index) {
                      final contact = _contacts[index];
                      return _buildContactCard(contact, index);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAddButton({bool isCompact = false}) {
    if (isCompact) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.alertOrange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.add_rounded, color: AppTheme.alertOrange),
          onPressed: () => _showContactDialog(),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => _showContactDialog(),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Ajouter un contact'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.alertOrange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildContactCard(EmergencyContact contact, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: contact.isPrimary 
              ? AppTheme.alertOrange.withOpacity(0.5)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showContactDialog(index: index),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar avec initiales
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: contact.isPrimary
                            ? AppTheme.alertOrange.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: contact.isPrimary ? AppTheme.alertOrange : AppTheme.secondaryGrey,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Informations
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  contact.name,
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyLarge?.color ?? Theme.of(context).colorScheme.onSurface,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (contact.isPrimary)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.alertOrange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        color: AppTheme.alertOrange,
                                        size: 14,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Principal',
                                        style: TextStyle(
                                          color: AppTheme.alertOrange,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            contact.relationship,
                            style: const TextStyle(
                              color: AppTheme.secondaryGrey,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone_rounded,
                                size: 14,
                                color: AppTheme.secondaryGrey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                contact.phone,
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          if (contact.email.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.email_rounded,
                                  size: 14,
                                  color: AppTheme.secondaryGrey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  contact.email,
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Flèche d'édition
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.secondaryGrey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}