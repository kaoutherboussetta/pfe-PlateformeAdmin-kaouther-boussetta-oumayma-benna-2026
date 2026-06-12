import 'package:flutter/material.dart';

class SupportItem {
  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;
  final SupportItemType type;
  final String? content;
  final String? actionUrl;
  final bool isExternal;

  SupportItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.type,
    this.content,
    this.actionUrl,
    this.isExternal = false,
  });
}

enum SupportItemType {
  faq,
  contact,
  bugReport,
  terms,
  privacy,
  about,
  liveChat,
}
