import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../models/patient.dart';
import '../models/doctor.dart';
import '../models/inventory_item.dart';

enum UserRole {
  doctor,
  patient,
}

class AppState extends ChangeNotifier {
  static final AppState session = AppState();

  UserRole _currentRole = UserRole.doctor;
  UserRole get currentRole => _currentRole;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  // Patient Profile Info
  String patientName = 'María Moreno';
  String patientEmail = 'paciente@test.com';
  String patientPhone = '+52 442 892 1042';

  // Doctor Profile Info
  String doctorName = 'Dr. Sandoval';
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

  // Patients Directory (Screen 7 in Figma)
  final List<Patient> _patients = [
    Patient(
      id: 'p1',
      name: 'Ana Martínez Ortiz',
      phone: '442 123 4567',
      email: 'ana.martinez@gmail.com',
      lastVisit: DateTime(2024, 10, 12),
      treatment: 'Ortodoncia',
      avatarColor: const Color(0xFF3B82F6),
      medicalAlerts: ['Alergia a la penicilina'],
    ),
    Patient(
      id: 'p2',
      name: 'Alejandro Gómez',
      phone: '442 234 5678',
      email: 'alejandro.g@outlook.com',
      lastVisit: DateTime(2024, 10, 10),
      treatment: 'Profilaxis Profunda',
      avatarColor: const Color(0xFF10B981),
    ),
    Patient(
      id: 'p3',
      name: 'Diego Castro',
      phone: '442 345 6789',
      email: 'diegocastro@gmail.com',
      lastVisit: DateTime(2024, 10, 5),
      treatment: 'Endodoncia',
      avatarColor: const Color(0xFFF59E0B),
      medicalAlerts: ['Hipertensión controlada'],
    ),
    Patient(
      id: 'p4',
      name: 'Fernanda Mendoza',
      phone: '442 456 7890',
      email: 'fer.mendoza@gmail.com',
      lastVisit: DateTime(2024, 9, 28),
      treatment: 'Blanqueamiento Dental',
      avatarColor: const Color(0xFF6366F1),
    ),
    Patient(
      id: 'p5',
      name: 'Elena Torres',
      phone: '442 567 8901',
      email: 'elena.torres@yahoo.com',
      lastVisit: DateTime(2024, 9, 20),
      treatment: 'Implante Dental',
      avatarColor: const Color(0xFFEC4899),
    ),
    Patient(
      id: 'p6',
      name: 'Gabriel Silva',
      phone: '442 678 9012',
      email: 'gsilva@empresa.com',
      lastVisit: DateTime(2024, 9, 15),
      treatment: 'Revisión General',
      avatarColor: const Color(0xFF14B8A6),
    ),
    Patient(
      id: 'p7',
      name: 'Valeria Ramos',
      phone: '442 789 0123',
      email: 'valeria.ramos@gmail.com',
      lastVisit: DateTime(2024, 9, 2),
      treatment: 'Ajuste de Brackets',
      avatarColor: const Color(0xFF8B5CF6),
    ),
  ];

  List<Patient> get patients => _patients;

  // Appointments (Screens 4, 5, 6, 8, 9 in Figma)
  final List<Appointment> _appointments = [
    Appointment(
      id: 'a1',
      patientName: 'Sofía Villanueva',
      doctorName: 'Dr. Carlos Sandoval',
      specialty: 'Limpieza Dental',
      date: DateTime.now(),
      time: '09:30 AM',
      status: AppointmentStatus.confirmada,
      notes: 'Limpieza dental y aplicación de flúor preventivo',
      avatarColor: const Color(0xFF3B82F6),
    ),
    Appointment(
      id: 'a2',
      patientName: 'Alberto Ojeda',
      doctorName: 'Dra. Sofía Vega',
      specialty: 'Ortodoncia - Ajuste',
      date: DateTime.now(),
      time: '11:30 AM',
      status: AppointmentStatus.pendiente,
      notes: 'Cambio de ligaduras y arco superior',
      avatarColor: const Color(0xFFF59E0B),
    ),
    Appointment(
      id: 'a3',
      patientName: 'Carlos Morales',
      doctorName: 'Dr. Carlos Sandoval',
      specialty: 'Limpieza Dental',
      date: DateTime.now().add(const Duration(days: 1)),
      time: '09:00 AM - 10:00 AM',
      status: AppointmentStatus.confirmada,
      notes: 'Profilaxis ultrasónica anual',
      avatarColor: const Color(0xFF10B981),
    ),
    Appointment(
      id: 'a4',
      patientName: 'Laura Fuentes',
      doctorName: 'Dra. Sofía Vega',
      specialty: 'Profilaxis Profunda',
      date: DateTime.now().add(const Duration(days: 1)),
      time: '10:30 AM - 11:30 AM',
      status: AppointmentStatus.confirmada,
      notes: 'Tratamiento gingival preventivo',
      avatarColor: const Color(0xFF6366F1),
    ),
    Appointment(
      id: 'a5',
      patientName: 'Jorge Herrera',
      doctorName: 'Dr. Roberto Mendoza',
      specialty: 'Extracción Molar',
      date: DateTime.now().add(const Duration(days: 2)),
      time: '01:00 PM - 02:00 PM',
      status: AppointmentStatus.pendiente,
      notes: 'Extracción tercer molar inferior derecho',
      avatarColor: const Color(0xFFF97316),
    ),
    Appointment(
      id: 'a6',
      patientName: 'Alejandra Rosales',
      doctorName: 'Dra. Sofía Vega',
      specialty: 'Revisión Brackets',
      date: DateTime.now().add(const Duration(days: 2)),
      time: '03:30 PM - 04:30 PM',
      status: AppointmentStatus.confirmada,
      notes: 'Control semestral ortodoncia estética',
      avatarColor: const Color(0xFF10B981),
    ),
    // Patient perspective appointments (María Moreno)
    Appointment(
      id: 'a7',
      patientName: 'María Moreno',
      doctorName: 'Dra. Sofía Vega',
      specialty: 'Ortodoncia - Revisión Mensual',
      date: DateTime.now().add(const Duration(days: 3)),
      time: '10:00 AM - 11:00 AM',
      status: AppointmentStatus.confirmada,
      notes: 'Revisión mensual de brackets estéticos de zafiro',
      avatarColor: const Color(0xFFEC4899),
    ),
    Appointment(
      id: 'a8',
      patientName: 'María Moreno',
      doctorName: 'Dr. Carlos Sandoval',
      specialty: 'Limpieza Dental y Profilaxis',
      date: DateTime.now().add(const Duration(days: 12)),
      time: '04:30 PM - 05:30 PM',
      status: AppointmentStatus.pendiente,
      notes: 'Profilaxis ultrasónica semestral',
      avatarColor: const Color(0xFF0066FF),
    ),
    Appointment(
      id: 'a9',
      patientName: 'María Moreno',
      doctorName: 'Dra. Sofía Vega',
      specialty: 'Ajuste de Retenedor',
      date: DateTime.now().subtract(const Duration(days: 30)),
      time: '11:00 AM - 12:00 PM',
      status: AppointmentStatus.completada,
      notes: 'Ajuste final exitoso',
      avatarColor: const Color(0xFF8B5CF6),
    ),
  ];

  List<Appointment> get appointments => _appointments;

  List<Appointment> get upcomingPatientAppointments {
    final now = DateTime.now();
    final result = _appointments.where((appointment) =>
        appointment.patientName == patientName &&
        !appointment.date.isBefore(DateTime(now.year, now.month, now.day)) &&
        (appointment.status == AppointmentStatus.confirmada ||
            appointment.status == AppointmentStatus.pendiente)).toList();
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  // LabStock Dental Laboratory Supplies
  final List<InventoryItem> _inventory = [
    InventoryItem(
      id: 'i1',
      name: 'Lidocaína 2% con Epinefrina',
      category: 'Anestésicos',
      currentStock: 18,
      minStock: 20,
      unit: 'Cajas (50 carpules)',
      batch: 'LID-2024-09B',
      expiryDate: DateTime(2025, 12, 31),
    ),
    InventoryItem(
      id: 'i2',
      name: 'Resina Compuesta Filtek 3M A2',
      category: 'Restauración',
      currentStock: 42,
      minStock: 15,
      unit: 'Jeringas 4g',
      batch: 'RS-3M-991',
      expiryDate: DateTime(2026, 6, 30),
    ),
    InventoryItem(
      id: 'i3',
      name: 'Guantes de Nitrilo Talla M',
      category: 'Descartables',
      currentStock: 8,
      minStock: 25,
      unit: 'Cajas (100 u)',
      batch: 'GN-441-MX',
      expiryDate: DateTime(2027, 1, 15),
    ),
    InventoryItem(
      id: 'i4',
      name: 'Brackets Metálicos Roth 0.22',
      category: 'Ortodoncia',
      currentStock: 14,
      minStock: 10,
      unit: 'Kits completos',
      batch: 'BK-RTH-2024',
      expiryDate: DateTime(2028, 4, 30),
    ),
    InventoryItem(
      id: 'i5',
      name: 'Agujas Desechables Cortas 27G',
      category: 'Descartables',
      currentStock: 65,
      minStock: 30,
      unit: 'Cajas (100 u)',
      batch: 'AG-27G-88',
      expiryDate: DateTime(2026, 11, 20),
    ),
    InventoryItem(
      id: 'i6',
      name: 'Alginato Kromopan Tipo I',
      category: 'Impresión',
      currentStock: 5,
      minStock: 12,
      unit: 'Bolsas 450g',
      batch: 'KROM-2024-X',
      expiryDate: DateTime(2025, 8, 15),
    ),
  ];

  List<InventoryItem> get inventory => _inventory;

  // State modification actions
  void login(UserRole role) {
    _currentRole = role;
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    notifyListeners();
  }

  void addAppointment({
    required String patientName,
    required String doctorName,
    required String specialty,
    required DateTime date,
    required String time,
  }) {
    _appointments.insert(
      0,
      Appointment(
        id: 'a_${DateTime.now().millisecondsSinceEpoch}',
        patientName: patientName,
        doctorName: doctorName,
        specialty: specialty,
        date: date,
        time: time,
        status: AppointmentStatus.confirmada,
        avatarColor: const Color(0xFF0066FF),
      ),
    );
    notifyListeners();
  }

  void updateAppointmentStatus(String id, AppointmentStatus newStatus) {
    final idx = _appointments.indexWhere((a) => a.id == id);
    if (idx != -1) {
      _appointments[idx].status = newStatus;
      notifyListeners();
    }
  }

  void addPatient({
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
    _patients.insert(
      0,
      Patient(
        id: 'p_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        phone: phone,
        email: email,
        lastVisit: DateTime.now(),
        treatment: treatment,
        avatarColor: colors[_patients.length % colors.length],
      ),
    );
    notifyListeners();
  }

  void updateStock(String id, int delta) {
    final idx = _inventory.indexWhere((item) => item.id == id);
    if (idx != -1) {
      final current = _inventory[idx].currentStock;
      final updated = (current + delta).clamp(0, 9999);
      _inventory[idx].currentStock = updated;
      notifyListeners();
    }
  }
}
