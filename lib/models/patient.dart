import 'package:flutter/material.dart';

class Patient {
  final String id;
  final String name;
  final String phone;
  final String email;
  final DateTime lastVisit;
  final String? nextAppointment;
  final String treatment;
  final Color avatarColor;
  final List<String> medicalAlerts;

  Patient({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.lastVisit,
    this.nextAppointment,
    required this.treatment,
    required this.avatarColor,
    this.medicalAlerts = const [],
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'P';
  }
}
