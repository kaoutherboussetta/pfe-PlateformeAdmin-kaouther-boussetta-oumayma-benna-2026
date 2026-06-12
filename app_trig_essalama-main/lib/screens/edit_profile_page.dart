import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityRegionController = TextEditingController();

  DateTime? _dateOfBirth;
  String? _gender; // 'Homme' | 'Femme'

  File? _profileImage;
  /// true si l'utilisateur a choisi "Supprimer" la photo (à enregistrer en base).
  bool _removeProfileImage = false;
  bool _isLoading = false;
  bool _isSaving = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityRegionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      final full = user.fullName?.trim() ?? '';
      if (full.isNotEmpty) {
        final parts = full.split(RegExp(r'\s+'));
        _prenomController.text = parts.first;
        _nomController.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }
      _emailController.text = user.email ?? '';
      _phoneController.text = user.phone ?? '';
      _addressController.text = user.location ?? '';
      _dateOfBirth = user.dateOfBirth;
      _gender = user.gender;
      _cityRegionController.text = user.cityRegion ?? '';
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'Choisir une date';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.alertOrange,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
          _removeProfileImage = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo mise à jour'),
              backgroundColor: AppTheme.alertOrange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar('Erreur: $e');
    }
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: AppTheme.secondaryGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Changer la photo de profil',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImagePickerOption(
                  icon: Icons.photo_camera_rounded,
                  label: 'Appareil photo',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildImagePickerOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Galerie',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                _buildImagePickerOption(
                  icon: Icons.delete_rounded,
                  label: 'Supprimer',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _profileImage = null;
                      _removeProfileImage = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('La photo sera supprimée au prochain enregistrement'),
                        backgroundColor: AppTheme.alertOrange,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePlaceholder() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: const Icon(
        Icons.person_rounded,
        size: 60,
        color: AppTheme.secondaryGrey,
      ),
    );
  }

  Widget _buildImagePickerOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5), width: 2),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser != null) {
        final fullName =
            '${_prenomController.text.trim()} ${_nomController.text.trim()}'.trim();
        final updatedUser = currentUser.copyWith(
          fullName: fullName.isEmpty ? currentUser.fullName : fullName,
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          location: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          dateOfBirth: _dateOfBirth,
          gender: _gender,
          cityRegion: _cityRegionController.text.trim().isEmpty ? null : _cityRegionController.text.trim(),
        );

        String? profileImagePayload;
        if (_removeProfileImage) {
          profileImagePayload = '';
        } else if (_profileImage != null) {
          final bytes = await _profileImage!.readAsBytes();
          profileImagePayload = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        }
        await authProvider.updateUserProfile(updatedUser, profileImagePayload);

        if (mounted) {
          _showSuccessSnackBar('Profil mis à jour');
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Erreur: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => _ChangePasswordDialog(
        onSuccess: () {
          Navigator.pop(context);
          _showSuccessSnackBar('Mot de passe modifié avec succès');
        },
        onError: _showErrorSnackBar,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.alertOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back_rounded, color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Modifier le profil',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isSaving)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _saveProfile,
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.alertOrange,
                  backgroundColor: AppTheme.alertOrange.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Enregistrer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_isSaving)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppTheme.alertOrange,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.alertOrange),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Photo de profil
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.alertOrange,
                                      Colors.orange,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.alertOrange.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(3),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).scaffoldBackgroundColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipOval(
                                    child: _profileImage != null
                                        ? Image.file(
                                            _profileImage!,
                                            fit: BoxFit.cover,
                                            width: 140,
                                            height: 140,
                                          )
                                        : Consumer<AuthProvider>(
                                            builder: (context, authProvider, child) {
                                              final user = authProvider.currentUser;
                                              final imageUrl = user?.profileImage;
                                              if (imageUrl != null && imageUrl.isNotEmpty) {
                                                if (imageUrl.startsWith('data:')) {
                                                  try {
                                                    final base64 = imageUrl.contains(',')
                                                        ? imageUrl.split(',').last
                                                        : imageUrl;
                                                    return Image.memory(
                                                      base64Decode(base64),
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) =>
                                                          _buildProfilePlaceholder(),
                                                    );
                                                  } catch (_) {
                                                    return _buildProfilePlaceholder();
                                                  }
                                                }
                                                return Image.network(
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      _buildProfilePlaceholder(),
                                                );
                                              }
                                              return _buildProfilePlaceholder();
                                            },
                                          ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 5,
                                right: 5,
                                child: GestureDetector(
                                  onTap: _showImagePickerDialog,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.alertOrange,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.primaryBlack,
                                        width: 3,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: AppTheme.whiteText,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Prénom
                        _buildTextField(
                          controller: _prenomController,
                          label: 'Prénom',
                          icon: Icons.person_outline_rounded,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Entrez votre prénom';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Nom
                        _buildTextField(
                          controller: _nomController,
                          label: 'Nom',
                          icon: Icons.badge_outlined,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Entrez votre nom';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Numéro de téléphone
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Numéro de téléphone',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),

                        // Email
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Entrez votre email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Email invalide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Adresse
                        _buildTextField(
                          controller: _addressController,
                          label: 'Adresse',
                          icon: Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 12),

                        // Date de naissance
                        _buildDateTile(
                          label: 'Date de naissance',
                          value: _formatDate(_dateOfBirth),
                          icon: Icons.cake_rounded,
                          onTap: _pickDateOfBirth,
                        ),
                        const SizedBox(height: 12),

                        // Genre
                        _buildGenreSelector(),
                        const SizedBox(height: 12),

                        // Ville / Région
                        _buildTextField(
                          controller: _cityRegionController,
                          label: 'Ville / Région',
                          icon: Icons.public_outlined,
                        ),
                        const SizedBox(height: 24),

                        // Mot de passe
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: InkWell(
                            onTap: _showChangePasswordDialog,
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.alertOrange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.lock_rounded,
                                      color: AppTheme.alertOrange,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Mot de passe',
                                          style: TextStyle(
                                            color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Changer le mot de passe',
                                          style: TextStyle(
                                            color: AppTheme.secondaryGrey,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: AppTheme.secondaryGrey,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
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
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText, fontSize: 16),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.secondaryGrey, fontSize: 14),
          prefixIcon: Icon(icon, color: AppTheme.alertOrange, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          floatingLabelStyle: const TextStyle(color: AppTheme.alertOrange),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.alertOrange, width: 2),
          ),
          errorStyle: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildDateTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.alertOrange, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.secondaryGrey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.calendar_today_rounded, color: AppTheme.secondaryGrey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGenreSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wc_rounded, color: AppTheme.alertOrange, size: 22),
              const SizedBox(width: 16),
              Text(
                'Genre',
                style: const TextStyle(
                  color: AppTheme.secondaryGrey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildGenreChip(label: 'Homme', value: 'Homme'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGenreChip(label: 'Femme', value: 'Femme'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenreChip({required String label, required String value}) {
    final selected = _gender == value;
    return InkWell(
      onTap: () => setState(() => _gender = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.alertOrange.withValues(alpha: 0.2) : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.alertOrange : Theme.of(context).dividerColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppTheme.alertOrange : (Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText),
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

/// Boîte de dialogue pour changer le mot de passe (actuel + nouveau + confirmation).
class _ChangePasswordDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  final void Function(String message) onError;

  const _ChangePasswordDialog({
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final current = _currentController.text;
    final newPwd = _newController.text;
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.changePassword(current, newPwd);
      if (mounted) widget.onSuccess();
    } catch (e) {
      if (mounted) widget.onError('Erreur: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(
        'Changer le mot de passe',
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _currentController,
                obscureText: _obscureCurrent,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText),
                decoration: InputDecoration(
                  labelText: 'Mot de passe actuel',
                  labelStyle: const TextStyle(color: AppTheme.secondaryGrey),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.secondaryGrey,
                    ),
                    onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.alertOrange, width: 2),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Entrez le mot de passe actuel';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newController,
                obscureText: _obscureNew,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText),
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  labelStyle: const TextStyle(color: AppTheme.secondaryGrey),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.secondaryGrey,
                    ),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.alertOrange, width: 2),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Entrez le nouveau mot de passe';
                  if (v.length < 6) return 'Au moins 6 caractères';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText),
                decoration: InputDecoration(
                  labelText: 'Confirmer le nouveau mot de passe',
                  labelStyle: const TextStyle(color: AppTheme.secondaryGrey),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.secondaryGrey,
                    ),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.alertOrange, width: 2),
                  ),
                ),
                validator: (v) {
                  if (v != _newController.text) return 'Les mots de passe ne correspondent pas';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: AppTheme.secondaryGrey),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.alertOrange,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Modifier'),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
