import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Patient {
  /// Para pacientes registrados en la app coincide con su uid.
  final String id;

  /// uid de la cuenta del paciente; null si lo dio de alta el doctor.
  final String? userId;
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
    this.userId,
    required this.name,
    required this.phone,
    required this.email,
    required this.lastVisit,
    this.nextAppointment,
    required this.treatment,
    required this.avatarColor,
    this.medicalAlerts = const [],
  });

  factory Patient.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Patient(
      id: doc.id,
      userId: d['userId'] as String?,
      name: d['name'] ?? '',
      phone: d['phone'] ?? '',
      email: d['email'] ?? '',
      lastVisit: (d['lastVisit'] as Timestamp?)?.toDate() ?? DateTime.now(),
      treatment: d['treatment'] ?? '',
      avatarColor: Color(d['avatarColor'] ?? 0xFF3B82F6),
      medicalAlerts: List<String>.from(d['medicalAlerts'] ?? const []),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'name': name,
    'phone': phone,
    'email': email,
    'lastVisit': Timestamp.fromDate(lastVisit),
    'treatment': treatment,
    'avatarColor': avatarColor.toARGB32(),
    'medicalAlerts': medicalAlerts,
  };

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
