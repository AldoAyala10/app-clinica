import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/patient.dart';
import '../models/queue_ticket.dart';
import '../repositories/firebase_clinic_repository.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';
import '../firebase_options.dart';

/// Estado del panel web: pacientes y citas en tiempo real, más las operaciones
/// de administración y el control compartido de turnos.
class AdminState extends ChangeNotifier {
  AdminState({
    required this.role,
    required this.staffName,
    String? doctorId,
    String? firebaseProjectId,
  }) : _firebaseProjectId = firebaseProjectId,
       _repository = FirebaseClinicRepository(AuthService.instance.db) {
    preferredDoctorId = doctorId ??
        doctors.where((doctor) => doctor.name == staffName)
            .map((doctor) => doctor.id)
            .firstOrNull;
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
  final String? _firebaseProjectId;
  final FirebaseClinicRepository _repository;
  final List<StreamSubscription> _subs = [];

  /// Solo el administrador gestiona pacientes; recepción gestiona citas.
  bool get canManagePatients => role == UserRole.admin;
  bool get canManageQueue => role.isStaff || role == UserRole.doctor;
  bool get canManageAppointments => role.isStaff;

  List<Doctor> get doctors => kClinicDoctors;
  late final String? preferredDoctorId;
  String get firebaseProjectId =>
      _firebaseProjectId ?? DefaultFirebaseOptions.web.projectId;

  Stream<QuerySnapshot<Map<String, dynamic>>> watchQueue(String queueKey) =>
      _repository.watchQueue(queueKey);

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchQueueBoard(
    String queueKey,
  ) => _repository.watchQueueBoard(queueKey);

  Future<void> ensureQueueBoard(Doctor doctor, DateTime date) =>
      _repository.ensureQueueBoard(doctorId: doctor.id, date: date);

  Future<QueueTicket> registerQueueTicket({
    required Doctor doctor,
    required DateTime date,
    required String patientName,
    required QueueTicketSource source,
    String? appointmentId,
  }) => _repository.registerQueueTicket(
    doctorId: doctor.id,
    doctorName: doctor.name,
    date: date,
    patientName: patientName,
    source: source,
    appointmentId: appointmentId,
  );

  Future<void> callNextQueueTicket(String queueKey, QueueTicket ticket) =>
      _repository.callNextQueueTicket(queueKey: queueKey, ticket: ticket);

  Future<void> finishQueueTicket(String queueKey, QueueTicket ticket) =>
      _repository.finishQueueTicket(queueKey: queueKey, ticket: ticket);

  Future<void> cancelQueueTicket(QueueTicket ticket) =>
      _repository.cancelQueueTicket(ticket);

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
