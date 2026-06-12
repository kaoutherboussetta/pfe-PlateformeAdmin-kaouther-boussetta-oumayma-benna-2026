import 'package:flutter/material.dart';

import '../models/alert_model.dart';

class AlertMessageWithZone extends StatelessWidget {
  final AlertModel alert;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;

  const AlertMessageWithZone({
    super.key,
    required this.alert,
    this.style,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    final msg = alert.message.trim();
    return Text(
      msg.isEmpty ? '...' : msg,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
