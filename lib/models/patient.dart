import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Prefijo del contenido del QR del carnet digital.
const String kPatientQrPrefix = 'clinica-dental:paciente:';

/// Texto que codifica el QR del carnet: identifica al paciente por su id.
String patientQrPayload(String patientId) => '$kPatientQrPrefix$patientId';

/// Extrae el id de paciente de un texto leído del QR (o lo devuelve tal
/// cual si ya es un id).
String patientIdFromQr(String text) {
  final value = text.trim();
  return value.startsWith(kPatientQrPrefix)
      ? value.substring(kPatientQrPrefix.length)
      : value;
}

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

  /// false cuando el paciente se dio de baja: se oculta de las listas pero
  /// conserva su historial.
  final bool active;

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
    this.active = true,
  });

  Patient copyWith({
    String? name,
    String? phone,
    String? email,
    String? treatment,
    List<String>? medicalAlerts,
    bool? active,
  }) => Patient(
    id: id,
    userId: userId,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    lastVisit: lastVisit,
    nextAppointment: nextAppointment,
    treatment: treatment ?? this.treatment,
    avatarColor: avatarColor,
    medicalAlerts: medicalAlerts ?? this.medicalAlerts,
    active: active ?? this.active,
  );

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
      active: d['active'] ?? true,
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
    'active': active,
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
