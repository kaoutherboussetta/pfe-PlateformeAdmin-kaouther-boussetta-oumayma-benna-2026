import 'package:flutter/material.dart';

/// Écran ouvert depuis une notification push (payload `type` == `alert`).
class AlertPushDetailPage extends StatelessWidget {
  const AlertPushDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final alertId = ModalRoute.of(context)?.settings.arguments as String? ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Alerte')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            alertId.isEmpty
                ? 'Aucun identifiant d’alerte.'
                : 'Alerte : $alertId',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
