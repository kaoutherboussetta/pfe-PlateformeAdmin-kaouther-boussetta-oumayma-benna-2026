import 'package:flutter/material.dart';

import '../models/alert_model.dart';

class AlertLocationLabel extends StatelessWidget {
  final AlertModel alert;
  final String loadingPlaceholder;
  final TextStyle? style;
  final int maxLines;
  final TextOverflow overflow;

  const AlertLocationLabel({
    super.key,
    required this.alert,
    this.loadingPlaceholder = '...',
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    final text = (alert.locationNamed == null || alert.locationNamed!.trim().isEmpty)
        ? loadingPlaceholder
        : alert.locationNamed!.trim();
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
