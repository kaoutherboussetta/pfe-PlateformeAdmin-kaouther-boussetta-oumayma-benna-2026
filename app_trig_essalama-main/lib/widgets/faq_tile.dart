import 'package:flutter/material.dart';
import '../models/faq.dart';

class FAQTile extends StatelessWidget {
  final FAQ faq;

  const FAQTile({super.key, required this.faq});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.1),
        ),
      ),
      child: ExpansionTile(
        title: Text(
          faq.question,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        iconColor: theme.colorScheme.primary,
        collapsedIconColor: theme.colorScheme.secondary,
        childrenPadding: const EdgeInsets.all(16),
        expandedAlignment: Alignment.topLeft,
        children: [
          Text(
            faq.answer,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
