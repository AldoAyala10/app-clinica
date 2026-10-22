import 'dart:async';

import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/patient.dart';
import '../repositories/firebase_clinic_repository.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';

/// Estado del panel administrativo web: pacientes y citas de toda la
/// clínica en tiempo real, más las operaciones de alta, edición y baja.
class AdminState extends ChangeNotifier {
  AdminState({required this.role, required this.staffName})
    : _repository = FirebaseClinicRepository(AuthService.instance.db) {
    _subs
      ..add(
        _repository.watchPatients().listen((snap) {
          _patients = snap.docs.map(Patient.fromDoc).toList()
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          patientsLoaded = true;
          notifyListeners();
        }, onError: _onError),
      )
      ..add(
        _repository.watchAppointments().listen((snap) {
          _appointments = snap.docs.map(Appointment.fromDoc).toList()
            ..sort((a, b) => a.date.compareTo(b.date));
          appointmentsLoaded = true;
          notifyListeners();
        }, onError: _onError),
      );
  }

  final UserRole role;
  final String staffName;
  final FirebaseClinicRepository _repository;
  final List<StreamSubscription> _subs = [];

  /// Solo el administrador gestiona pacientes; recepción gestiona citas.
  bool get canManagePatients => role == UserRole.admin;

  List<Doctor> get doctors => kClinicDoctors;

  List<Patient> _patients = [];
  List<Patient> get patients => _patients;
  List<Patient> get activePatients =>
      _patients.where((p) => p.active).toList();
  bool patientsLoaded = false;

  List<Appointment> _appointments = [];
  List<Appointment> get appointments => _appointments;
  bool appointmentsLoaded = false;

  String? lastError;

  void _onError(Object error) {
    lastError = error.toString();
    debugPrint('Firestore (panel): $error');
    notifyListeners();
  }

  Patient? patientById(String id) {
    for (final patient in _patients) {
      if (patient.id == id) return patient;
    }
    return null;
  }

  // Pacientes (US03)

  static const _avatarColors = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF6366F1),
    Color(0xFFEC4899),
  ];

  Future<String> createPatient({
    required String name,
    required String phone,
    required String email,
    String treatment = '',
    List<String> medicalAlerts = const [],
  }) {
    return _repository.createPatient(
      Patient(
        id: '',
        name: name.trim(),
        phone: phone.trim(),
        email: email.trim(),
        lastVisit: DateTime.now(),
        treatment: treatment.trim(),
        avatarColor: _avatarColors[_patients.length % _avatarColors.length],
        medicalAlerts: medicalAlerts,
      ),
    );
  }

  Future<void> updatePatient(Patient patient) =>
      _repository.updatePatient(patient);

  Future<void> deactivatePatient(Patient patient) =>
      _repository.setPatientActive(patient.id, false);

  Future<void> reactivatePatient(Patient patient) =>
      _repository.setPatientActive(patient.id, true);

  // Citas (US05)

  Future<Set<String>> takenTimes(Doctor doctor, DateTime date) =>
      _repository.takenTimes(doctor.id, date);

  Future<void> createAppointment({
    required Patient patient,
    required Doctor doctor,
    required String specialty,
    required DateTime date,
    required String time,
    String notes = '',
  }) => _repository.createStaffAppointment(
    patient: patient,
    doctor: doctor,
    specialty: specialty,
    date: date,
    time: time,
    notes: notes,
  );

  Future<void> updateAppointment({
    required Appointment appointment,
    required Doctor doctor,
    required String specialty,
    required DateTime date,
    required String time,
    required String notes,
  }) => _repository.updateStaffAppointment(
    appointment: appointment,
    doctor: doctor,
    specialty: specialty,
    date: date,
    time: time,
    notes: notes,
  );

  Future<void> confirmAppointment(Appointment appointment) => _repository
      .updateAppointmentStatus(appointment.id, AppointmentStatus.confirmada);

  Future<void> cancelAppointment(Appointment appointment) => _repository
      .updateAppointmentStatus(appointment.id, AppointmentStatus.cancelada);

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }
}
