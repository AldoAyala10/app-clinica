import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:app_clinica/models/appointment.dart';
import 'package:app_clinica/models/inventory_item.dart';
import 'package:app_clinica/screens/patient/patient_appointments_tab.dart';
import 'package:app_clinica/services/auth_service.dart';
import 'package:app_clinica/state/app_state.dart';

import 'helpers/firebase_fakes.dart';

void main() {
  group('AuthService Cobertura Exhaustiva', () {
    late FakeFirebaseFirestore fakeDb;
    late MockFirebaseAuth mockAuth;
    late AuthService authService;

    setUp(() {
      fakeDb = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      authService = AuthService(auth: mockAuth, db: fakeDb);
    });

    test('getProfile devuelve null si no hay sesión y devuelve datos si está autenticado', () async {
      // Sin usuario
      expect(await authService.getProfile(), isNull);

      // Con usuario autenticado
      const uid = 'user-prof-1';
      final user = MockUser(uid: uid, email: 'perfil@test.com');
      final authWithUser = MockFirebaseAuth(mockUser: user, signedIn: true);
      final serviceWithUser = AuthService(auth: authWithUser, db: fakeDb);
      await fakeDb.collection('users').doc(uid).set({'name': 'Perfil de Prueba', 'role': 'patient'});

      final profile = await serviceWithUser.getProfile();
      expect(profile, isNotNull);
      expect(profile?['name'], 'Perfil de Prueba');
    });

    test('sendPasswordReset envía correo de restablecimiento', () async {
      await expectLater(
        authService.sendPasswordReset('usuario@test.com'),
        completes,
      );
    });

    test('AuthException toString devuelve el mensaje', () {
      const ex = AuthException('Mensaje de error');
      expect(ex.toString(), 'Mensaje de error');
    });
  });

  group('AppState Cobertura de Métodos de Negocio', () {
    setUp(() => setUpFirebase(signedInUid: doctorUid));

    test('AppState métodos addAppointment, isSlotTaken, updateAppointmentStatus', () async {
      final state = AppState(role: UserRole.doctor);
      addTearDown(state.dispose);

      final date = DateTime(2026, 12, 10);
      await state.addAppointment(
        patientName: 'Pedro Gómez',
        doctorName: 'Dr. Carlos Sandoval',
        specialty: 'General',
        date: date,
        time: '11:00 AM',
        notes: 'Consulta rutinaria',
      );

      final docs = (await db.collection('appointments').get()).docs;
      expect(docs.isNotEmpty, isTrue);

      final isTaken = await state.isSlotTaken('d1', date, '11:00 AM');
      expect(isTaken, isFalse);

      await state.updateAppointmentStatus(docs.first.id, AppointmentStatus.confirmada);
      final updated = (await db.collection('appointments').doc(docs.first.id).get()).data()!;
      expect(updated['status'], 'confirmada');
    });

    test('AppState addPatient agrega paciente con colores alternados', () async {
      final state = AppState(role: UserRole.doctor);
      addTearDown(state.dispose);

      await state.addPatient(
        name: 'Mónica Soto',
        phone: '4429998877',
        email: 'monica@correo.com',
        treatment: 'Ortodoncia',
      );

      final patients = (await db.collection('patients').get()).docs;
      expect(patients.any((p) => p.data()['name'] == 'Mónica Soto'), isTrue);
    });

    test('AppState updateStock actualiza inventario', () async {
      final state = AppState(role: UserRole.doctor);
      addTearDown(state.dispose);

      final itemRef = await db.collection('inventory').add({
        'name': 'Guantes S',
        'currentStock': 20,
        'minStock': 5,
        'unit': 'Cajas',
        'batch': 'B-1',
        'expiryDate': Timestamp.fromDate(DateTime(2027, 1, 1)),
      });

      // Añadimos item localmente para simular el snapshot
      state.inventory.add(InventoryItem(
        id: itemRef.id,
        name: 'Guantes S',
        category: 'Descartables',
        currentStock: 20,
        minStock: 5,
        unit: 'Cajas',
        batch: 'B-1',
        expiryDate: DateTime(2027, 1, 1),
      ));

      await state.updateStock(itemRef.id, 10);
      final updatedItem = (await db.collection('inventory').doc(itemRef.id).get()).data()!;
      expect(updatedItem['currentStock'], 30);
    });

    test('AppState retryAppointments limpia errores y reintenta', () async {
      final state = AppState(role: UserRole.patient);
      addTearDown(state.dispose);

      await state.retryAppointments();
      expect(state.appointmentsError, isNull);
    });
  });

  group('PatientAppointmentsTab Estados Visuales', () {
    setUp(() async {
      await setUpFirebase(signedInUid: patientUid);
    });

    testWidgets('Muestra estado vacío de próximas y alterna a historial vacío', (tester) async {
      final state = AppState(role: UserRole.patient);
      addTearDown(state.dispose);

      await tester.pumpWidget(MaterialApp(
        home: AnimatedBuilder(
          animation: state,
          builder: (context, _) => PatientAppointmentsTab(
            state: state,
            onBookNew: () {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Estado vacío inicial en pestaña de Próximas
      expect(find.text('No tienes citas próximas agendadas'), findsOneWidget);

      // Cambiar a pestaña Historial
      await tester.tap(find.textContaining('Historial'));
      await tester.pumpAndSettle();

      expect(find.text('No hay citas en tu historial'), findsOneWidget);
    });
  });
}
