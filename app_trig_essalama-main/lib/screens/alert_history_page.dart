import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AlertHistoryPage extends StatelessWidget {
  const AlertHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText,
        title: const Text('Alert History'),
      ),
      body: Center(
        child: Text(
          'Alert History',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.whiteText, fontSize: 18),
        ),
      ),
    );
  }
}
