import 'package:flutter/material.dart';
import '../services/support_service.dart';

class BugReportForm extends StatefulWidget {
  const BugReportForm({super.key});

  @override
  State<BugReportForm> createState() => _BugReportFormState();
}

class _BugReportFormState extends State<BugReportForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String? _selectedSeverity;
  bool _includeScreenshot = false;
  bool _isLoading = false;

  final List<String> _severityLevels = ['Faible', 'Moyen', 'Élevé', 'Critique'];

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
            'Description du problème',
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionController,
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            maxLines: 4,
            decoration: inputDecoration.copyWith(hintText: 'Décrivez le problème en détail...'),
            validator: (value) => (value == null || value.isEmpty) ? 'Veuillez décrire le problème' : null,
          ),
          const SizedBox(height: 16),
          Text(
            'Sévérité',
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedSeverity,
            dropdownColor: theme.colorScheme.surface,
            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            decoration: inputDecoration,
            items: _severityLevels.map((level) => DropdownMenuItem(value: level, child: Text(level))).toList(),
            onChanged: (value) => setState(() => _selectedSeverity = value),
            validator: (value) => (value == null) ? 'Veuillez sélectionner la sévérité' : null,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Inclure capture d\'écran',
              style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14),
            ),
            value: _includeScreenshot,
            onChanged: (value) => setState(() => _includeScreenshot = value),
            activeColor: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Envoyer le rapport', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      await SupportService.sendBugReport(context, _descriptionController.text, _includeScreenshot ? 'screenshot_path' : null);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}
