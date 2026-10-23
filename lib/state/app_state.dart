import 'dart:async';

import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../models/patient.dart';
import '../models/doctor.dart';
import '../models/inventory_item.dart';
import '../services/auth_service.dart';
import '../repositories/firebase_clinic_repository.dart';

enum UserRole {
  doctor,
  patient,
  admin,
  receptionist;

  /// Personal que trabaja desde el panel administrativo web.
  bool get isStaff => this == admin || this == receptionist;

  String get label => switch (this) {
    UserRole.doctor => 'Doctor',
    UserRole.patient => 'Paciente',
    UserRole.admin => 'Administrador',
    UserRole.receptionist => 'Recepción',
  };
}

class AppState extends ChangeNotifier {
  /// Escucha en tiempo real los datos de Firestore que le tocan al rol:
  /// el doctor ve todo; el paciente solo sus propias citas.
  AppState({required UserRole role}) : _currentRole = role {
    _listen();
  }

    late final FirebaseClinicRepository _repository =
      FirebaseClinicRepository(AuthService.instance.db);
  final List<StreamSubscription> _subs = [];

  final UserRole _currentRole;
  UserRole get currentRole => _currentRole;

  String? get uid => AuthService.instance.currentUser?.uid;

  // Patient Profile Info
  String patientName = '';
  String patientEmail = '';
  String patientPhone = '';

  // Doctor Profile Info
  String doctorName = '';
  String doctorSpecialty = 'Odontología Integral';
  String clinicName = 'Clínica Dental';

  // Doctors Directory
  final List<Doctor> doctors = kClinicDoctors;

  List<Patient> _patients = [];
  List<Patient> get patients => _patients;

  List<Appointment> _appointments = [];
  List<Appointment> get appointments => _appointments;

  /// Citas confirmadas o pendientes de hoy en adelante, de la más próxima a
  /// la más lejana. Para el paciente, [appointments] ya son solo las suyas.
  List<Appointment> get upcomingPatientAppointments {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _appointments
        .where((a) =>
            !a.date.isBefore(today) &&
            (a.status == AppointmentStatus.confirmada ||
                a.status == AppointmentStatus.pendiente))
        .toList();
  }

  List<InventoryItem> _inventory = [];
  List<InventoryItem> get inventory => _inventory;

  /// Mensaje del último error al leer o escribir en Firestore.
  String? lastError;

  bool _seedingInventory = false;

  void _listen() {
    final userId = uid;
    if (userId == null) return;

    _subs.add(
      _repository.watchUser(userId).listen((doc) {
        final d = doc.data();
        if (d == null) return;
        if (_currentRole == UserRole.doctor) {
          doctorName = d['name'] ?? doctorName;
        } else {
          patientName = d['name'] ?? patientName;
          patientEmail = d['email'] ?? patientEmail;
          patientPhone = d['phone'] ?? patientPhone;
        }
        notifyListeners();
      }, onError: _onError),
    );

    _listenAppointments();

    if (_currentRole != UserRole.doctor) return;

    _subs.add(
      _repository.watchPatients().listen((snap) {
        _patients = snap.docs.map(Patient.fromDoc).toList()
          ..sort((a, b) => b.lastVisit.compareTo(a.lastVisit));
        notifyListeners();
      }, onError: _onError),
    );

    _subs.add(
      _repository.watchInventory().listen((snap) {
        if (snap.docs.isEmpty && !snap.metadata.isFromCache) {
          _seedInventoryIfEmpty();
        }
        _inventory = snap.docs.map(InventoryItem.fromDoc).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        notifyListeners();
      }, onError: _onError),
    );
  }

  StreamSubscription? _appointmentsSub;

  /// true cuando las citas vienen de la copia local porque no hay red.
  bool appointmentsOffline = false;

  /// Falso hasta que llega la primera respuesta de Firestore con las citas.
  bool appointmentsLoaded = false;

  /// Error al leer las citas; se limpia al reintentar.
  Object? appointmentsError;

  void _listenAppointments() {
    final userId = uid;
    if (userId == null) return;
    _appointmentsSub = _repository
      .watchAppointments(
        patientId: _currentRole == UserRole.doctor ? null : userId,
      )
      .listen(
      (snap) {
        _appointments = snap.docs.map(Appointment.fromDoc).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        appointmentsLoaded = true;
        appointmentsError = null;
        appointmentsOffline = snap.metadata.isFromCache;
        notifyListeners();
      },
      onError: (Object error) {
        appointmentsError = error;
        _onError(error);
      },
    );
  }

  /// Vuelve a suscribirse a las citas después de un error.
  Future<void> retryAppointments() async {
    await _appointmentsSub?.cancel();
    appointmentsLoaded = false;
    appointmentsError = null;
    notifyListeners();
    _listenAppointments();
  }

  void _onError(Object error) {
    lastError = error.toString();
    debugPrint('Firestore: $error');
    notifyListeners();
  }

  /// La primera vez que un doctor abre el inventario vacío, se carga el
  /// catálogo base de insumos.
  Future<void> _seedInventoryIfEmpty() async {
    if (_seedingInventory) return;
    _seedingInventory = true;
    await _repository.seedInventory(_seedInventory);
  }

  static final List<InventoryItem> _seedInventory = [
    InventoryItem(
      id: 'i1',
      name: 'Lidocaína 2% con Epinefrina',
      category: 'Anestésicos',
      currentStock: 18,
      minStock: 20,
      unit: 'Cajas (50 carpules)',
      batch: 'LID-2024-09B',
      expiryDate: DateTime(2027, 12, 31),
    ),
    InventoryItem(
      id: 'i2',
      name: 'Resina Compuesta Filtek 3M A2',
      category: 'Restauración',
      currentStock: 42,
      minStock: 15,
      unit: 'Jeringas 4g',
      batch: 'RS-3M-991',
      expiryDate: DateTime(2028, 6, 30),
    ),
    InventoryItem(
      id: 'i3',
      name: 'Guantes de Nitrilo Talla M',
      category: 'Descartables',
      currentStock: 8,
      minStock: 25,
      unit: 'Cajas (100 u)',
      batch: 'GN-441-MX',
      expiryDate: DateTime(2029, 1, 15),
    ),
    InventoryItem(
      id: 'i4',
      name: 'Brackets Metálicos Roth 0.22',
      category: 'Ortodoncia',
      currentStock: 14,
      minStock: 10,
      unit: 'Kits completos',
      batch: 'BK-RTH-2024',
      expiryDate: DateTime(2030, 4, 30),
    ),
    InventoryItem(
      id: 'i5',
      name: 'Agujas Desechables Cortas 27G',
      category: 'Descartables',
      currentStock: 65,
      minStock: 30,
      unit: 'Cajas (100 u)',
      batch: 'AG-27G-88',
      expiryDate: DateTime(2028, 11, 20),
    ),
    InventoryItem(
      id: 'i6',
      name: 'Alginato Kromopan Tipo I',
      category: 'Impresión',
      currentStock: 5,
      minStock: 12,
      unit: 'Bolsas 450g',
      batch: 'KROM-2024-X',
      expiryDate: DateTime(2027, 8, 15),
    ),
  ];

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    _appointmentsSub?.cancel();
    super.dispose();
  }

  Future<void> addAppointment({
    String? patientId,
    required String patientName,
    required String doctorName,
    required String specialty,
    required DateTime date,
    required String time,
    String notes = '',
    AppointmentStatus status = AppointmentStatus.pendiente,
  }) {
    return _repository.addAppointment(
      patientId: patientId,
      patientName: patientName,
      doctorName: doctorName,
      specialty: specialty,
      date: date,
      time: time,
      notes: notes,
      status: status,
    );
  }

  /// Un horario (doctor + día + hora) solo puede tener una cita activa.
  static String slotId(String doctorId, DateTime date, String time) {
    return FirebaseClinicRepository.slotId(doctorId, date, time);
  }

  Future<bool> isSlotTaken(String doctorId, DateTime date, String time) async {
    return _repository.isSlotTaken(doctorId, date, time);
  }

  /// El paciente solicita una cita: aparta el horario y crea la cita juntos,
  /// así dos pacientes no pueden quedarse con el mismo horario. Las reglas de
  /// Firestore rechazan el apartado si el horario ya existe.
  Future<void> bookAppointment({
    required Doctor doctor,
    required String specialty,
    required DateTime date,
    required String time,
    required String notes,
  }) async {
    final userId = uid;
    if (userId == null) throw StateError('No hay sesión iniciada.');
    return _repository.bookAppointment(
      patientId: userId,
      patientName: patientName,
      doctor: doctor,
      specialty: specialty,
      date: date,
      time: time,
      notes: notes,
    );
  }

  Future<void> updateAppointmentStatus(
    String id,
    AppointmentStatus newStatus,
  ) async {
    return _repository.updateAppointmentStatus(id, newStatus);
  }

  Future<void> rescheduleAppointment({
    required Appointment appointment,
    required DateTime date,
    required String time,
  }) =>
      _repository.rescheduleAppointment(
        appointment: appointment,
        date: date,
        time: time,
      );

  Future<void> addPatient({
    required String name,
    required String phone,
    required String email,
    required String treatment,
  }) {
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF6366F1),
      const Color(0xFFEC4899),
    ];
    final patient = Patient(
      id: '',
      name: name,
      phone: phone,
      email: email,
      lastVisit: DateTime.now(),
      treatment: treatment,
      avatarColor: colors[_patients.length % colors.length],
    );
    return _repository.addPatient(patient);
  }

  Future<void> updateStock(String id, int delta) async {
    final idx = _inventory.indexWhere((item) => item.id == id);
    if (idx == -1) return;
    final updated = (_inventory[idx].currentStock + delta).clamp(0, 9999);
    await _repository.updateStock(id, updated);
  }
}
