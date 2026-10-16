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
      patientId == null
          ? _appointments.snapshots()
          : _appointments.where('patientId', isEqualTo: patientId).snapshots();

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

  Future<void> updateStock(String id, int stock) async {
    await _inventory.doc(id).update({'currentStock': stock});
  }
}