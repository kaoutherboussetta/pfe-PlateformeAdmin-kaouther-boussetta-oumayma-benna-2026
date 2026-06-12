import 'package:flutter/material.dart';

class TrafficJamModel {
  final String id;
  final double latitude;
  final double longitude;
  final String level;
  final int congestionLevel;
  final double averageSpeed;
  final String cause;
  final String description;
  final DateTime detectedAt;
  final bool isActive;

  TrafficJamModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.level,
    required this.congestionLevel,
    required this.averageSpeed,
    required this.cause,
    required this.description,
    required this.detectedAt,
    required this.isActive,
  });

  factory TrafficJamModel.fromJson(Map<String, dynamic> json) {
    return TrafficJamModel(
      id: json['_id']?.toString() ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      level: (json['level'] ?? 'moderate').toString(),
      congestionLevel: (json['congestionLevel'] ?? 50).toInt(),
      averageSpeed: (json['averageSpeed'] ?? 0).toDouble(),
      cause: (json['cause'] ?? 'unknown').toString(),
      description: (json['description'] ?? '').toString(),
      detectedAt: json['detectedAt'] != null
          ? DateTime.tryParse(json['detectedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isActive: json['isActive'] ?? true,
    );
  }

  Color getLevelColor() {
    switch (level) {
      case 'light':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'heavy':
        return Colors.deepOrange;
      case 'severe':
        return Colors.red;
      case 'blocked':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData getLevelIcon() {
    return Icons.traffic;
  }

  String getLevelLabel() {
    switch (level) {
      case 'light':
        return 'Circulation legere';
      case 'moderate':
        return 'Circulation dense';
      case 'heavy':
        return 'Tres dense';
      case 'severe':
        return 'Bouchon severe';
      case 'blocked':
        return 'Bloque';
      default:
        return 'Inconnu';
    }
  }
}
