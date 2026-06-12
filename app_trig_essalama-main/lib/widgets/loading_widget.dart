import 'package:flutter/material.dart';

/// Widget d'indicateur de chargement réutilisable.
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
