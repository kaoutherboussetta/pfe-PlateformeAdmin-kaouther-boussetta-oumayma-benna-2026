import 'package:flutter/material.dart';
import '../services/support_service.dart';

class ContactForm extends StatefulWidget {
  const ContactForm({super.key});

  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: theme.colorScheme.surface,
      hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary),
      ),
    );

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sujet',
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _subjectController,
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            decoration: inputDecoration.copyWith(hintText: 'Sujet de votre message'),
            validator: (value) => (value == null || value.isEmpty) ? 'Veuillez entrer un sujet' : null,
          ),
          const SizedBox(height: 16),
          Text(
            'Message',
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _messageController,
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            maxLines: 4,
            decoration: inputDecoration.copyWith(hintText: 'Décrivez votre demande...'),
            validator: (value) => (value == null || value.isEmpty) ? 'Veuillez entrer votre message' : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Envoyer', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      await SupportService.sendContactMessage(context, _subjectController.text, _messageController.text);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
