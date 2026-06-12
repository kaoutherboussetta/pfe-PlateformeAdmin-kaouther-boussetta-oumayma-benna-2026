import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/context_l10n.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  void _showLogoutDialog(BuildContext parentContext, AuthProvider authProvider) {
    final s = parentContext.stringsRead;
    final navigator = Navigator.of(parentContext, rootNavigator: true);
    showDialog<void>(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).colorScheme.surface,
        title: Text(
          s.logoutTitle,
          style: TextStyle(
            color: Theme.of(dialogContext).textTheme.bodyLarge?.color ?? AppTheme.whiteText,
          ),
        ),
        content: Text(
          s.logoutConfirm,
          style: const TextStyle(color: AppTheme.secondaryGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(s.cancel, style: const TextStyle(color: AppTheme.secondaryGrey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await authProvider.logout();
              if (!parentContext.mounted) return;
              navigator.pushReplacementNamed('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: AppTheme.whiteText,
            ),
            child: Text(s.logoutButton),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final s = context.strings;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextButton(
        onPressed: () => _showLogoutDialog(context, authProvider),
        style: TextButton.styleFrom(
          backgroundColor: AppTheme.softRed.withValues(alpha: 0.12),
          foregroundColor: AppTheme.softRed,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              s.logoutButton,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
