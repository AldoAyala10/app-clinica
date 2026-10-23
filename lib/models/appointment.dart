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
  final String? doctorId;

  /// Id de la ficha en `patients` (para pacientes sin cuenta en la app).
  final String? patientRecordId;
  final String patientName;
  final String doctorName;

  /// Consultorio donde se atiende la cita (vacío en citas antiguas).
  final String office;
  final String specialty;
  final DateTime date;
  final String time;
  AppointmentStatus status;
  final String notes;
  final Color avatarColor;

  Appointment({
    required this.id,
    this.patientId,
    this.doctorId,
    this.patientRecordId,
    required this.patientName,
    required this.doctorName,
    this.office = '',
    required this.specialty,
    required this.date,
    required this.time,
    required this.status,
    this.notes = '',
    this.avatarColor = const Color(0xFF0066FF),
  });

  Appointment copyWith({AppointmentStatus? status}) => Appointment(
    id: id,
    patientId: patientId,
    doctorId: doctorId,
    patientRecordId: patientRecordId,
    patientName: patientName,
    doctorName: doctorName,
    office: office,
    specialty: specialty,
    date: date,
    time: time,
    status: status ?? this.status,
    notes: notes,
    avatarColor: avatarColor,
  );

  factory Appointment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Appointment(
      id: doc.id,
      patientId: d['patientId'] as String?,
      doctorId: d['doctorId'] as String?,
      patientRecordId: d['patientRecordId'] as String?,
      patientName: d['patientName'] ?? '',
      doctorName: d['doctorName'] ?? '',
      office: d['office'] ?? '',
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
    'doctorId': doctorId,
    'patientName': patientName,
    'doctorName': doctorName,
    'office': office,
    'specialty': specialty,
    'date': Timestamp.fromDate(date),
    'time': time,
    'status': status.name,
    'notes': notes,
    'avatarColor': avatarColor.toARGB32(),
  };
}
