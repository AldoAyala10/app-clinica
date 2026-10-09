import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum AppointmentStatus {
  confirmada,
  pendiente,
  completada,
  cancelada;

  String get label {
    switch (this) {
      case AppointmentStatus.confirmada:
        return 'Confirmada';
      case AppointmentStatus.pendiente:
        return 'Pendiente';
      case AppointmentStatus.completada:
        return 'Completada';
      case AppointmentStatus.cancelada:
        return 'Cancelada';
    }
  }

  Color get color {
    switch (this) {
      case AppointmentStatus.confirmada:
        return const Color(0xFF10B981);
      case AppointmentStatus.pendiente:
        return const Color(0xFFF59E0B);
      case AppointmentStatus.completada:
        return const Color(0xFF0066FF);
      case AppointmentStatus.cancelada:
        return const Color(0xFFEF4444);
    }
  }

  Color get bgLight {
    switch (this) {
      case AppointmentStatus.confirmada:
        return const Color(0xFFE6F9F0);
      case AppointmentStatus.pendiente:
        return const Color(0xFFFEF3C7);
      case AppointmentStatus.completada:
        return const Color(0xFFE0EDFF);
      case AppointmentStatus.cancelada:
        return const Color(0xFFFEE2E2);
    }
  }
}

class Appointment {
  final String id;

  /// uid de la cuenta del paciente; null si el paciente no tiene cuenta.
  final String? patientId;
  final String patientName;
  final String doctorName;
  final String specialty;
  final DateTime date;
  final String time;
  AppointmentStatus status;
  final String notes;
  final Color avatarColor;

  Appointment({
    required this.id,
    this.patientId,
    required this.patientName,
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.time,
    required this.status,
    this.notes = '',
    this.avatarColor = const Color(0xFF0066FF),
  });

  factory Appointment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Appointment(
      id: doc.id,
      patientId: d['patientId'] as String?,
      patientName: d['patientName'] ?? '',
      doctorName: d['doctorName'] ?? '',
      specialty: d['specialty'] ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      time: d['time'] ?? '',
      status:
          AppointmentStatus.values.asNameMap()[d['status']] ??
          AppointmentStatus.pendiente,
      notes: d['notes'] ?? '',
      avatarColor: Color(d['avatarColor'] ?? 0xFF0066FF),
    );
  }

  Map<String, dynamic> toMap() => {
    'patientId': patientId,
    'patientName': patientName,
    'doctorName': doctorName,
    'specialty': specialty,
    'date': Timestamp.fromDate(date),
    'time': time,
    'status': status.name,
    'notes': notes,
    'avatarColor': avatarColor.toARGB32(),
  };
}
