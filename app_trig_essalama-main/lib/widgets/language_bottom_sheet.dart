import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_language.dart';
import '../providers/locale_provider.dart';

/// Affiche le sélecteur Français / English / Darija (même UI que l'onboarding).
void showAppLanguagePicker(BuildContext context) {
  const primaryColor = Color(0xFF0088CC);
  const textSecondary = Color(0xFFAEAEB2);

  final locale = context.read<LocaleProvider>();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF1A1A1A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  locale.strings.chooseLanguage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...AppLanguage.values.map((l) {
                final selected = locale.language == l;
                return ListTile(
                  leading: Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    color: selected ? primaryColor : textSecondary,
                  ),
                  title: Text(
                    locale.strings.labelForLanguage(l),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    locale.strings.subtitleForLanguage(l),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
                  ),
                  onTap: () async {
                    await locale.setLanguage(l);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}
