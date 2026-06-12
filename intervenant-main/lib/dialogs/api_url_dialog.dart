import 'package:flutter/material.dart';
import 'package:intervenant/constants/backend_defaults.dart';
import 'package:intervenant/services/auth_api_service.dart';

/// Ouvre le dialogue pour saisir l’URL du backend (même réseau Wi‑Fi que le PC).
///
/// Le [TextEditingController] vit dans l’état du dialogue : le disposer trop tôt
/// (avant la fin du démontage du route) déclenche l’assertion Flutter
/// `_dependents.isEmpty` sur les InheritedWidgets.
Future<void> showApiUrlEditorDialog(
  BuildContext context, {
  VoidCallback? onSaved,
}) async {
  final String? url = await showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) => _ApiUrlEditorDialog(initialUrl: AuthApiService.baseUrl),
  );

  if (url == null || !context.mounted) return;

  final String trimmed = url.trim();
  if (trimmed.isEmpty) return;

  final bool saved = await AuthApiService.saveBaseUrl(trimmed);
  if (!saved) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sur téléphone, localhost ne fonctionne pas. Utilisez l’IP du PC (Wi‑Fi) ou une URL ngrok.',
          ),
        ),
      );
    }
    return;
  }
  onSaved?.call();
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('API : ${AuthApiService.baseUrl}')),
  );
}

class _ApiUrlEditorDialog extends StatefulWidget {
  const _ApiUrlEditorDialog({required this.initialUrl});

  final String initialUrl;

  @override
  State<_ApiUrlEditorDialog> createState() => _ApiUrlEditorDialogState();
}

class _ApiUrlEditorDialogState extends State<_ApiUrlEditorDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('URL du serveur backend'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'URL du backend sans chemin : http://IP:PORT '
            '(par défaut :$kBackendDefaultPort ; voir PORT dans backend/.env). '
            'ngrok/https possible. Pas de localhost sur téléphone.',
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'URL de base (sans /api/...)',
              hintText:
                  'https://alibi-deepen-pursuant.ngrok-free.dev ou http://192.168.100.112:$kBackendDefaultPort',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
