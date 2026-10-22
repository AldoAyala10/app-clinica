import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/inventory_item.dart';
import '../models/patient.dart';

class FirebaseClinicRepository {
  FirebaseClinicRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _appointments =>
      _db.collection('appointments');
  CollectionReference<Map<String, dynamic>> get _patients =>
      _db.collection('patients');
  CollectionReference<Map<String, dynamic>> get _inventory =>
      _db.collection('inventory');
  CollectionReference<Map<String, dynamic>> get _slots =>
      _db.collection('slots');

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUser(String uid) =>
      _db.collection('users').doc(uid).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAppointments({
    String? patientId,
  }) =>
      // includeMetadataChanges avisa cuando se pierde o recupera la red.
      (patientId == null
              ? _appointments
              : _appointments.where('patientId', isEqualTo: patientId))
          .snapshots(includeMetadataChanges: true);

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPatients() =>
      _patients.snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchInventory() =>
      _inventory.snapshots();

  Future<void> seedInventory(List<InventoryItem> items) async {
    final batch = _db.batch();
    for (final item in items) {
      batch.set(_inventory.doc(), item.toMap());
    }
    await batch.commit();
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
  }) async {
    final appointment = Appointment(
      id: '',
      patientId: patientId,
      patientName: patientName,
      doctorName: doctorName,
      specialty: specialty,
      date: date,
      time: time,
      status: status,
      notes: notes,
      avatarColor: const Color(0xFF0066FF),
    );
    await _appointments.add({
      ...appointment.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static String slotId(String doctorId, DateTime date, String time) {
    final day = '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return '${doctorId}_${day}_${time.replaceAll(' ', '')}';
  }

  static String? _doctorIdFromSlotId(String? value) {
    if (value == null) return null;
    return RegExp(r'^(.+)_\d{4}-\d{2}-\d{2}_')
        .firstMatch(value)
        ?.group(1);
  }

  Future<bool> isSlotTaken(String doctorId, DateTime date, String time) async {
    return (await _slots.doc(slotId(doctorId, date, time)).get()).exists;
  }

  Future<void> bookAppointment({
    required String patientId,
    required String patientName,
    required Doctor doctor,
    required String specialty,
    required DateTime date,
    required String time,
    required String notes,
  }) async {
    final slot = _slots.doc(slotId(doctor.id, date, time));
    final appointmentRef = _appointments.doc();
    final appointment = Appointment(
      id: appointmentRef.id,
      patientId: patientId,
      patientName: patientName,
      doctorId: doctor.id,
      doctorName: doctor.name,
      office: doctor.office,
      specialty: specialty,
      date: date,
      time: time,
      status: AppointmentStatus.pendiente,
      notes: notes,
    );
    final batch = _db.batch()
      ..set(slot, {
        'patientId': patientId,
        'appointmentId': appointmentRef.id,
        'doctorId': doctor.id,
      })
      ..set(appointmentRef, {
        ...appointment.toMap(),
        'slotId': slot.id,
        'createdAt': FieldValue.serverTimestamp(),
      });
    await batch.commit();
  }

  Future<void> updateAppointmentStatus(
    String id,
    AppointmentStatus newStatus,
  ) async {
    final appointmentRef = _appointments.doc(id);
    final appointment = await appointmentRef.get();
    final batch = _db.batch()
      ..update(appointmentRef, {'status': newStatus.name});
    if (newStatus == AppointmentStatus.cancelada) {
      final slotId = appointment.data()?['slotId'] as String?;
      if (slotId != null) batch.delete(_slots.doc(slotId));
    }
    await batch.commit();
  }

  Future<void> rescheduleAppointment({
    required Appointment appointment,
    required DateTime date,
    required String time,
  }) async {
    final appointmentRef = _appointments.doc(appointment.id);
    final snapshot = await appointmentRef.get();
    final data = snapshot.data();
    final oldSlotId = data?['slotId'] as String?;
    final doctorId = data?['doctorId'] as String? ??
        appointment.doctorId ??
        _doctorIdFromSlotId(oldSlotId);
    if (doctorId == null || doctorId.isEmpty) {
      throw StateError('No se encontró el odontólogo de esta cita.');
    }

    final newSlotId = slotId(doctorId, date, time);
    if (oldSlotId == newSlotId) return;
    if (await _slots.doc(newSlotId).get().then((doc) => doc.exists)) {
      throw StateError('Ese horario ya está ocupado. Elige otro.');
    }

    final batch = _db.batch()
      ..set(_slots.doc(newSlotId), {
        'patientId': appointment.patientId,
        'appointmentId': appointment.id,
        'doctorId': doctorId,
      })
      ..update(appointmentRef, {
        'date': Timestamp.fromDate(date),
        'time': time,
        'slotId': newSlotId,
      });
    if (oldSlotId != null) batch.delete(_slots.doc(oldSlotId));
    await batch.commit();
  }

  Future<void> addPatient(Patient patient) async {
    await _patients.add(patient.toMap());
  }

  // ---------------------------------------------------------------------
  // Panel administrativo (US03 pacientes, US05 citas)
  // ---------------------------------------------------------------------

  /// Da de alta un paciente y devuelve el id de su ficha.
  Future<String> createPatient(Patient patient) async {
    final ref = await _patients.add({
      ...patient.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Edita los datos de contacto y clínicos de la ficha.
  Future<void> updatePatient(Patient patient) {
    return _patients.doc(patient.id).update({
      'name': patient.name,
      'phone': patient.phone,
      'email': patient.email,
      'treatment': patient.treatment,
      'medicalAlerts': patient.medicalAlerts,
    });
  }

  /// Baja lógica: el paciente deja de aparecer pero conserva su historial.
  Future<void> setPatientActive(String patientId, bool active) {
    return _patients.doc(patientId).update({'active': active});
  }

  /// Horarios del día que ya tiene ocupados el doctor.
  Future<Set<String>> takenTimes(String doctorId, DateTime date) async {
    final taken = <String>{};
    await Future.wait(kTimeSlots.map((time) async {
      if (await isSlotTaken(doctorId, date, time)) taken.add(time);
    }));
    return taken;
  }

  /// Crea una cita desde recepción, apartando el horario del doctor. Lanza
  /// [StateError] si el horario ya está ocupado.
  Future<void> createStaffAppointment({
    required Patient patient,
    required Doctor doctor,
    required String specialty,
    required DateTime date,
    required String time,
    String notes = '',
    AppointmentStatus status = AppointmentStatus.confirmada,
  }) async {
    final slot = _slots.doc(slotId(doctor.id, date, time));
    if ((await slot.get()).exists) {
      throw StateError('Ese horario ya está ocupado para ${doctor.name}.');
    }
    final appointmentRef = _appointments.doc();
    final appointment = Appointment(
      id: appointmentRef.id,
      patientId: patient.userId,
      patientName: patient.name,
      doctorId: doctor.id,
      doctorName: doctor.name,
      office: doctor.office,
      specialty: specialty,
      date: date,
      time: time,
      status: status,
      notes: notes,
      avatarColor: patient.avatarColor,
    );
    final batch = _db.batch()
      ..set(slot, {
        'patientId': patient.userId,
        'appointmentId': appointmentRef.id,
        'doctorId': doctor.id,
      })
      ..set(appointmentRef, {
        ...appointment.toMap(),
        'patientRecordId': patient.id,
        'slotId': slot.id,
        'createdAt': FieldValue.serverTimestamp(),
      });
    await batch.commit();
  }

  /// Modifica una cita desde recepción. Si cambia el doctor, el día o la
  /// hora, mueve el horario apartado validando que el nuevo esté libre.
  Future<void> updateStaffAppointment({
    required Appointment appointment,
    required Doctor doctor,
    required String specialty,
    required DateTime date,
    required String time,
    required String notes,
  }) async {
    final appointmentRef = _appointments.doc(appointment.id);
    final oldSlotId = (await appointmentRef.get()).data()?['slotId'] as String?;
    final newSlotId = slotId(doctor.id, date, time);

    final batch = _db.batch();
    if (oldSlotId != newSlotId) {
      if ((await _slots.doc(newSlotId).get()).exists) {
        throw StateError('Ese horario ya está ocupado para ${doctor.name}.');
      }
      batch.set(_slots.doc(newSlotId), {
        'patientId': appointment.patientId,
        'appointmentId': appointment.id,
        'doctorId': doctor.id,
      });
      if (oldSlotId != null) batch.delete(_slots.doc(oldSlotId));
    }
    batch.update(appointmentRef, {
      'doctorId': doctor.id,
      'doctorName': doctor.name,
      'office': doctor.office,
      'specialty': specialty,
      'date': Timestamp.fromDate(date),
      'time': time,
      'notes': notes,
      'slotId': newSlotId,
    });
    await batch.commit();
  }

  Future<void> updateStock(String id, int stock) async {
    await _inventory.doc(id).update({'currentStock': stock});
  }
}