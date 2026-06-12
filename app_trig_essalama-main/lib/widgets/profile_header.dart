import 'dart:convert';
import 'package:flutter/material.dart';
import '../l10n/context_l10n.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';

class ProfileHeader extends StatefulWidget {
  final UserModel? user;
  final String variant; // 'default', 'editing', 'loading'
  final VoidCallback onEditPressed;

  const ProfileHeader({
    super.key,
    required this.user,
    required this.variant,
    required this.onEditPressed,
  });

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  /// ImageProvider pour URL réseau ou photo en base64 (data:image/...).
  ImageProvider? get _profileImageProvider {
    final url = widget.user?.profileImage;
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:')) {
      try {
        final base64 = url.contains(',') ? url.split(',').last : url;
        return MemoryImage(base64Decode(base64));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(url);
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.variant) {
      case 'loading':
        return _buildLoadingHeader();
      case 'editing':
        return _buildEditingHeader();
      default:
        return _buildDefaultHeader();
    }
  }
  Widget _buildDefaultHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = context.strings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              s.profileScreenHeading,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onBackground,
                fontSize: 28,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.softGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.softGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    s.profileAvailable,
                    style: const TextStyle(
                      color: AppTheme.softGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: widget.onEditPressed,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        border: Border.all(
                          color: isDark ? AppTheme.surfaceDark : Colors.white,
                          width: 4,
                        ),
                        image: _profileImageProvider != null
                            ? DecorationImage(
                                image: _profileImageProvider!,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _profileImageProvider == null
                          ? Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? AppTheme.surfaceDark : AppTheme.lightGrey,
                              ),
                              child: Icon(
                                Icons.person_rounded,
                                size: 50,
                                color: isDark ? AppTheme.secondaryGrey : Colors.grey[400],
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.iosBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.user?.name ?? 'John Doe',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.user?.email ?? 'john.doe@example.com',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.secondaryGrey,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildEditingHeader() {
    final s = context.strings;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.alertOrange, width: 1),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.alertOrange, width: 2),
                  color: AppTheme.primaryBlack,
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_rounded,
                    size: 40,
                    color: AppTheme.secondaryGrey,
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.5),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: AppTheme.whiteText,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlack,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    s.profileEnterName,
                    style: const TextStyle(color: AppTheme.secondaryGrey),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlack,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    s.profileEnterEmail,
                    style: const TextStyle(color: AppTheme.secondaryGrey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryBlack,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppTheme.alertOrange,
                strokeWidth: 2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlack,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 150,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlack,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
