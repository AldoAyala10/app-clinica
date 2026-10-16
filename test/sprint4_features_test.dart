import 'package:app_clinica/models/appointment.dart';
import 'package:app_clinica/models/patient.dart';
import 'package:app_clinica/screens/doctor/doctor_patients_tab.dart';
import 'package:app_clinica/screens/patient/patient_appointments_tab.dart';
import 'package:app_clinica/screens/patient/patient_profile_tab.dart';
import 'package:app_clinica/state/app_state.dart';
import 'package:app_clinica/widgets/appointment_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'helpers/firebase_fakes.dart';

void main() {
  setUp(() async {
    await setUpFirebase(signedInUid: patientUid);
    await initializeDateFormatting('es');
  });

  test('HU-10: reprogramar mueve la cita y su horario reservado', () async {
    final state = AppState(role: UserRole.patient);
    addTearDown(state.dispose);
    final today = DateUtils.dateOnly(DateTime.now());
    final originalDate = today.add(const Duration(days: 2));
    final newDate = today.add(const Duration(days: 5));

    await state.bookAppointment(
      doctor: state.doctors.first,
      specialty: 'Limpieza',
      date: originalDate,
      time: '09:00 AM',
      notes: 'Revisión general',
    );

    final doc = (await db.collection('appointments').get()).docs.single;
    final appointment = Appointment.fromDoc(doc);
    final oldSlotId = doc.data()['slotId'] as String;
    final newSlotId = AppState.slotId(state.doctors.first.id, newDate, '12:00 PM');

    await state.rescheduleAppointment(
      appointment: appointment,
      date: newDate,
      time: '12:00 PM',
    );

    final updated = (await db.collection('appointments').doc(doc.id).get()).data()!;
    expect((updated['date'] as dynamic).toDate(), newDate);
    expect(updated['time'], '12:00 PM');
    expect(updated['doctorId'], state.doctors.first.id);
    expect((await db.collection('slots').doc(oldSlotId).get()).exists, isFalse);
    expect((await db.collection('slots').doc(newSlotId).get()).exists, isTrue);
  });

  test('HU-10: rechaza un horario ocupado sin mover la cita original', () async {
    final state = AppState(role: UserRole.patient);
    addTearDown(state.dispose);
    final today = DateUtils.dateOnly(DateTime.now());
    final originalDate = today.add(const Duration(days: 2));
    final targetDate = today.add(const Duration(days: 5));

    await state.bookAppointment(
      doctor: state.doctors.first,
      specialty: 'Limpieza',
      date: originalDate,
      time: '09:00 AM',
      notes: 'Revisión general',
    );
    final doc = (await db.collection('appointments').get()).docs.single;
    final appointment = Appointment.fromDoc(doc);
    final oldSlotId = doc.data()['slotId'] as String;
    await db.collection('slots').doc(
      AppState.slotId(state.doctors.first.id, targetDate, '12:00 PM'),
    ).set({'patientId': 'otro-paciente'});

    await expectLater(
      state.rescheduleAppointment(
        appointment: appointment,
        date: targetDate,
        time: '12:00 PM',
      ),
      throwsA(isA<StateError>()),
    );

    final unchanged = (await db.collection('appointments').doc(doc.id).get()).data()!;
    expect((unchanged['date'] as dynamic).toDate(), originalDate);
    expect((await db.collection('slots').doc(oldSlotId).get()).exists, isTrue);
  });

  testWidgets('HU-10: cancelar desde el modal libera horario y confirma',
      (tester) async {
    final state = AppState(role: UserRole.patient);
    addTearDown(state.dispose);
    final date = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 2));
    await state.bookAppointment(
      doctor: state.doctors.first,
      specialty: 'Limpieza',
      date: date,
      time: '09:00 AM',
      notes: 'Revisión general',
    );

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
    await tester.tap(find.byType(AppointmentCard));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('La cita se canceló correctamente.'), findsOneWidget);
    final doc = (await db.collection('appointments').get()).docs.single;
    expect(doc.data()['status'], AppointmentStatus.cancelada.name);
    final slotId = doc.data()['slotId'] as String;
    expect((await db.collection('slots').doc(slotId).get()).exists, isFalse);
  });

  testWidgets('HU-11: el perfil muestra las citas pasadas como completadas',
      (tester) async {
    final yesterday = DateUtils.dateOnly(DateTime.now())
        .subtract(const Duration(days: 1));
    await addAppointment(
      patientId: patientUid,
      patientName: 'María Moreno',
      date: yesterday,
      status: AppointmentStatus.pendiente,
    );
    await addAppointment(
      patientId: patientUid,
      patientName: 'María Moreno',
      date: yesterday,
      status: AppointmentStatus.cancelada,
    );
    final state = AppState(role: UserRole.patient);
    addTearDown(state.dispose);

    await tester.pumpWidget(MaterialApp(
      home: AnimatedBuilder(
        animation: state,
        builder: (context, _) => PatientProfileTab(state: state),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Historial clínico dental').first);
    await tester.pumpAndSettle();

    expect(find.byType(AppointmentCard), findsOneWidget);
    expect(find.text('Completada'), findsOneWidget);
  });

  testWidgets('HU-09: pagina pacientes y busca por correo', (tester) async {
    for (var index = 0; index < 10; index++) {
      await db.collection('patients').add(
        Patient(
          id: '',
          name: 'Paciente $index',
          phone: '4420000000',
          email: 'persona$index@example.com',
          lastVisit: DateTime(2026, 1, 1),
          treatment: 'Limpieza',
          avatarColor: Colors.blue,
        ).toMap(),
      );
    }
    final state = AppState(role: UserRole.doctor);
    addTearDown(state.dispose);

    await tester.pumpWidget(MaterialApp(
      home: AnimatedBuilder(
        animation: state,
        builder: (context, _) => DoctorPatientsTab(state: state),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('10 pacientes'), findsOneWidget);
    await tester.tap(find.byKey(const Key('patients_page_next')));
    await tester.pumpAndSettle();
    expect(find.text('Paciente 9'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('patient_search')),
      'persona3@example.com',
    );
    await tester.pumpAndSettle();
    expect(find.text('1 pacientes'), findsOneWidget);
    expect(find.text('Paciente 3'), findsOneWidget);
    expect(find.text('Paciente 9'), findsNothing);
  });
}