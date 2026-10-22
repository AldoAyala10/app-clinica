import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:app_clinica/models/appointment.dart';
import 'package:app_clinica/models/doctor.dart';
import 'package:app_clinica/models/inventory_item.dart';
import 'package:app_clinica/models/patient.dart';
import 'package:app_clinica/repositories/firebase_clinic_repository.dart';

void main() {
  group('Appointment & AppointmentStatus Models', () {
    test('AppointmentStatus tiene etiquetas y colores correctos para todos los estados', () {
      // // ARRANGE & ACT & ASSERT
      expect(AppointmentStatus.confirmada.label, 'Confirmada');
      expect(AppointmentStatus.pendiente.label, 'Pendiente');
      expect(AppointmentStatus.completada.label, 'Completada');
      expect(AppointmentStatus.cancelada.label, 'Cancelada');

      expect(AppointmentStatus.confirmada.color, const Color(0xFF10B981));
      expect(AppointmentStatus.pendiente.color, const Color(0xFFF59E0B));
      expect(AppointmentStatus.completada.color, const Color(0xFF0066FF));
      expect(AppointmentStatus.cancelada.color, const Color(0xFFEF4444));

      expect(AppointmentStatus.confirmada.bgLight, const Color(0xFFE6F9F0));
      expect(AppointmentStatus.pendiente.bgLight, const Color(0xFFFEF3C7));
      expect(AppointmentStatus.completada.bgLight, const Color(0xFFE0EDFF));
      expect(AppointmentStatus.cancelada.bgLight, const Color(0xFFFEE2E2));
    });

    test('Appointment copyWith y toMap funcionan correctamente', () {
      // // ARRANGE
      final date = DateTime(2026, 11, 15, 10, 30);
      final appointment = Appointment(
        id: 'cita-1',
        patientId: 'pac-1',
        doctorId: 'doc-1',
        patientName: 'Juan Pérez',
        doctorName: 'Dra. Sofía Vega',
        specialty: 'Ortodoncia',
        date: date,
        time: '10:30 AM',
        status: AppointmentStatus.pendiente,
        notes: 'Ajuste de brackets',
      );

      // // ACT
      final updated = appointment.copyWith(status: AppointmentStatus.confirmada);
      final map = updated.toMap();

      // // ASSERT
      expect(updated.status, AppointmentStatus.confirmada);
      expect(updated.patientName, 'Juan Pérez');
      expect(map['patientName'], 'Juan Pérez');
      expect(map['status'], 'confirmada');
      expect(map['time'], '10:30 AM');
      expect(map['doctorId'], 'doc-1');
      expect(map['patientId'], 'pac-1');
    });

    test('Appointment.fromDoc deserializa correctamente desde Firestore', () async {
      // // ARRANGE
      final db = FakeFirebaseFirestore();
      final date = DateTime(2026, 12, 1, 9, 0);
      final ref = await db.collection('appointments').add({
        'patientId': 'p-99',
        'doctorId': 'd-99',
        'patientName': 'Laura Ríos',
        'doctorName': 'Dr. Carlos Sandoval',
        'specialty': 'Limpieza',
        'date': Timestamp.fromDate(date),
        'time': '09:00 AM',
        'status': 'completada',
        'notes': 'Todo en orden',
        'avatarColor': 0xFF0066FF,
      });

      // // ACT
      final snapshot = await ref.get();
      final appointment = Appointment.fromDoc(snapshot);

      // // ASSERT
      expect(appointment.id, ref.id);
      expect(appointment.patientName, 'Laura Ríos');
      expect(appointment.status, AppointmentStatus.completada);
      expect(appointment.time, '09:00 AM');
    });
  });

  group('FirebaseClinicRepository Pruebas Unitarias', () {
    late FakeFirebaseFirestore db;
    late FirebaseClinicRepository repo;

    setUp(() {
      db = FakeFirebaseFirestore();
      repo = FirebaseClinicRepository(db);
    });

    test('slotId genera el identificador normalizado', () {
      // // ARRANGE
      final date = DateTime(2026, 10, 25);
      
      // // ACT
      final id = FirebaseClinicRepository.slotId('doc-1', date, '10:30 AM');

      // // ASSERT
      expect(id, 'doc-1_2026-10-25_10:30AM');
    });

    test('isSlotTaken reporta disponibilidad con precisión', () async {
      // // ARRANGE
      final date = DateTime(2026, 10, 25);
      const doctorId = 'doc-test';
      const time = '11:00 AM';

      // // ACT & ASSERT (Inicialmente libre)
      expect(await repo.isSlotTaken(doctorId, date, time), isFalse);

      // Ocupamos el slot
      final slotKey = FirebaseClinicRepository.slotId(doctorId, date, time);
      await db.collection('slots').doc(slotKey).set({'patientId': 'pac-test'});

      // // ASSERT (Ahora ocupado)
      expect(await repo.isSlotTaken(doctorId, date, time), isTrue);
    });

    test('addAppointment agrega una cita en Firestore', () async {
      // // ARRANGE
      final date = DateTime(2026, 11, 20);

      // // ACT
      await repo.addAppointment(
        patientId: 'pac-123',
        patientName: 'Mario Casas',
        doctorName: 'Dr. Roberto Mendoza',
        specialty: 'Endodoncia',
        date: date,
        time: '04:00 PM',
        notes: 'Molestia persistente',
        status: AppointmentStatus.pendiente,
      );

      // // ASSERT
      final docs = (await db.collection('appointments').get()).docs;
      expect(docs.length, 1);
      final data = docs.first.data();
      expect(data['patientName'], 'Mario Casas');
      expect(data['specialty'], 'Endodoncia');
      expect(data['status'], 'pendiente');
    });

    test('seedInventory guarda lista de suministros en lote', () async {
      // // ARRANGE
      final items = [
        InventoryItem(
          id: '',
          name: 'Guantes de Látex M',
          category: 'Protección',
          currentStock: 100,
          minStock: 20,
          unit: 'cajas',
          batch: 'LOT-2026-A',
          expiryDate: DateTime(2028, 1, 1),
        ),
        InventoryItem(
          id: '',
          name: 'Anestesia Lidocaína',
          category: 'Medicamentos',
          currentStock: 50,
          minStock: 10,
          unit: 'ampollas',
          batch: 'LOT-2026-B',
          expiryDate: DateTime(2027, 6, 1),
        ),
      ];

      // // ACT
      await repo.seedInventory(items);

      // // ASSERT
      final docs = (await db.collection('inventory').get()).docs;
      expect(docs.length, 2);
    });

    test('updateAppointmentStatus actualiza estado y elimina slot si es cancelada', () async {
      // // ARRANGE
      const doctorId = 'doc-77';
      final date = DateTime(2026, 11, 5);
      const time = '02:00 PM';
      final slotKey = FirebaseClinicRepository.slotId(doctorId, date, time);
      await db.collection('slots').doc(slotKey).set({'patientId': 'p-1'});
      
      final appRef = await db.collection('appointments').add({
        'status': 'pendiente',
        'slotId': slotKey,
      });

      // // ACT (Confirmar primero)
      await repo.updateAppointmentStatus(appRef.id, AppointmentStatus.confirmada);
      expect((await appRef.get()).data()?['status'], 'confirmada');
      expect((await db.collection('slots').doc(slotKey).get()).exists, isTrue);

      // // ACT (Cancelar después -> debe liberar el slot)
      await repo.updateAppointmentStatus(appRef.id, AppointmentStatus.cancelada);
      expect((await appRef.get()).data()?['status'], 'cancelada');
      expect((await db.collection('slots').doc(slotKey).get()).exists, isFalse);
    });

    test('addPatient y updateStock persisten modificaciones', () async {
      // // ARRANGE
      final patient = Patient(
        id: '',
        name: 'Elena Ramos',
        phone: '4421112233',
        email: 'elena@gmail.com',
        lastVisit: DateTime(2026, 2, 1),
        treatment: 'Blanqueamiento',
        avatarColor: Colors.teal,
      );

      // // ACT addPatient
      await repo.addPatient(patient);
      final patients = (await db.collection('patients').get()).docs;
      expect(patients.length, 1);
      expect(patients.first.data()['name'], 'Elena Ramos');

      // // ACT updateStock
      final itemRef = await db.collection('inventory').add({'currentStock': 25});
      await repo.updateStock(itemRef.id, 80);
      expect((await itemRef.get()).data()?['currentStock'], 80);
    });

    test('Streams watchUser, watchAppointments, watchPatients y watchInventory emiten datos', () async {
      // // ARRANGE & ACT
      final userStream = repo.watchUser('user-xyz');
      final appointmentsStream = repo.watchAppointments();
      final patientsStream = repo.watchPatients();
      final inventoryStream = repo.watchInventory();

      // // ASSERT
      expect(userStream, isA<Stream<DocumentSnapshot<Map<String, dynamic>>>>());
      expect(appointmentsStream, isA<Stream<QuerySnapshot<Map<String, dynamic>>>>());
      expect(patientsStream, isA<Stream<QuerySnapshot<Map<String, dynamic>>>>());
      expect(inventoryStream, isA<Stream<QuerySnapshot<Map<String, dynamic>>>>());
    });
  });
}
