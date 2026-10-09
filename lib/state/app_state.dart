import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../models/patient.dart';
import '../models/doctor.dart';
import '../models/inventory_item.dart';

enum UserRole { doctor, patient }

class AppState extends ChangeNotifier {
  /// Escucha en tiempo real los datos de Firestore que le tocan al rol:
  /// el doctor ve todo; el paciente solo sus propias citas.
  AppState({required UserRole role}) : _currentRole = role {
    _listen();
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final List<StreamSubscription> _subs = [];

  CollectionReference<Map<String, dynamic>> get _appointmentsRef =>
      _db.collection('appointments');
  CollectionReference<Map<String, dynamic>> get _patientsRef =>
      _db.collection('patients');
  CollectionReference<Map<String, dynamic>> get _inventoryRef =>
      _db.collection('inventory');

  final UserRole _currentRole;
  UserRole get currentRole => _currentRole;

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  // Patient Profile Info
  String patientName = '';
  String patientEmail = '';
  String patientPhone = '';

  // Doctor Profile Info
  String doctorName = '';
  String doctorSpecialty = 'Odontología Integral';
  String clinicName = 'Clínica Dental';

  // Doctors Directory
  final List<Doctor> doctors = [
    Doctor(
      id: 'd1',
      name: 'Dr. Carlos Sandoval',
      specialty: 'Odontología General',
      clinic: 'Clínica Dental',
      rating: 4.9,
      experience: '10 años exp.',
    ),
    Doctor(
      id: 'd2',
      name: 'Dra. Sofía Vega',
      specialty: 'Ortodoncia & Estética',
      clinic: 'Clínica Dental',
      rating: 5.0,
      experience: '8 años exp.',
    ),
    Doctor(
      id: 'd3',
      name: 'Dr. Roberto Mendoza',
      specialty: 'Endodoncia & Cirugía',
      clinic: 'Clínica Dental',
      rating: 4.8,
      experience: '12 años exp.',
    ),
  ];

  List<Patient> _patients = [];
  List<Patient> get patients => _patients;

  List<Appointment> _appointments = [];
  List<Appointment> get appointments => _appointments;

  List<InventoryItem> _inventory = [];
  List<InventoryItem> get inventory => _inventory;

  /// Mensaje del último error al leer o escribir en Firestore.
  String? lastError;

  bool _seedingInventory = false;

  void _listen() {
    final userId = uid;
    if (userId == null) return;

    _subs.add(
      _db.collection('users').doc(userId).snapshots().listen((doc) {
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

    final appointmentsQuery = _currentRole == UserRole.doctor
        ? _appointmentsRef
        : _appointmentsRef.where('patientId', isEqualTo: userId);
    _subs.add(
      appointmentsQuery.snapshots().listen((snap) {
        _appointments = snap.docs.map(Appointment.fromDoc).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        notifyListeners();
      }, onError: _onError),
    );

    if (_currentRole != UserRole.doctor) return;

    _subs.add(
      _patientsRef.snapshots().listen((snap) {
        _patients = snap.docs.map(Patient.fromDoc).toList()
          ..sort((a, b) => b.lastVisit.compareTo(a.lastVisit));
        notifyListeners();
      }, onError: _onError),
    );

    _subs.add(
      _inventoryRef.snapshots().listen((snap) {
        if (snap.docs.isEmpty && !snap.metadata.isFromCache) {
          _seedInventoryIfEmpty();
        }
        _inventory = snap.docs.map(InventoryItem.fromDoc).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        notifyListeners();
      }, onError: _onError),
    );
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
    final batch = _db.batch();
    for (final item in _seedInventory) {
      batch.set(_inventoryRef.doc(), item.toMap());
    }
    await batch.commit();
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
    super.dispose();
  }

  Future<void> addAppointment({
    String? patientId,
    required String patientName,
    required String doctorName,
    required String specialty,
    required DateTime date,
    required String time,
    AppointmentStatus status = AppointmentStatus.pendiente,
  }) {
    final appointment = Appointment(
      id: '',
      patientId: patientId,
      patientName: patientName,
      doctorName: doctorName,
      specialty: specialty,
      date: date,
      time: time,
      status: status,
      avatarColor: const Color(0xFF0066FF),
    );
    return _appointmentsRef.add({
      ...appointment.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateAppointmentStatus(String id, AppointmentStatus newStatus) {
    return _appointmentsRef.doc(id).update({'status': newStatus.name});
  }

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
    return _patientsRef.add(patient.toMap());
  }

  Future<void> updateStock(String id, int delta) async {
    final idx = _inventory.indexWhere((item) => item.id == id);
    if (idx == -1) return;
    final updated = (_inventory[idx].currentStock + delta).clamp(0, 9999);
    await _inventoryRef.doc(id).update({'currentStock': updated});
  }
}
