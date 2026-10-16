import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_clinica/models/appointment.dart';
import 'package:app_clinica/screens/patient/book_appointment_tab.dart';
import 'package:app_clinica/state/app_state.dart';

import 'helpers/firebase_fakes.dart';

void main() {
  late AppState state;

  setUp(() => setUpFirebase(signedInUid: patientUid));

  /// AppState se crea dentro de cada prueba para que sus streams corran en
  /// el reloj simulado del test.
  void createState() {
    state = AppState(role: UserRole.patient);
    addTearDown(state.dispose);
  }

  Future<void> openForm(WidgetTester tester) async {
    createState();
    await tester.pumpWidget(MaterialApp(
      home: BookAppointmentTab(
        state: state,
        onAppointmentBooked: () {},
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<int> appointmentCount() async =>
      (await db.collection('appointments').get()).docs.length;

  testWidgets('HU-08: el calendario abre DatePicker', (tester) async {
    await openForm(tester);
    await tester.ensureVisible(find.byKey(const Key('book_date_picker')));
    await tester.tap(find.byKey(const Key('book_date_picker')));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    Navigator.of(tester.element(find.byType(DatePickerDialog))).pop();
    await tester.pumpAndSettle();
  });

  testWidgets('HU-08: exige un motivo de al menos cinco caracteres',
      (tester) async {
    await openForm(tester);
    await tester.ensureVisible(find.text('Confirmar Cita'));
    await tester.tap(find.text('Confirmar Cita'));
    await tester.pumpAndSettle();
    expect(
      find.text('Escribe al menos 5 caracteres para el motivo.'),
      findsOneWidget,
    );
    expect(await appointmentCount(), 0);
  });

  testWidgets('HU-08: guarda la cita con motivo en Firestore y aparta horario',
      (tester) async {
    await openForm(tester);
    const motivo = 'Dolor en una muela al masticar';
    await tester.ensureVisible(find.byKey(const Key('booking_reason_field')));
    await tester.enterText(
        find.byKey(const Key('booking_reason_field')), motivo);
    await tester.ensureVisible(find.text('Confirmar Cita'));
    await tester.tap(find.text('Confirmar Cita'));
    await tester.pumpAndSettle();

    final docs = (await db.collection('appointments').get()).docs;
    expect(docs.length, 1);
    final data = docs.single.data();
    expect(data['notes'], motivo);
    expect(data['patientId'], patientUid);
    expect(data['status'], 'pendiente');
    final slot = await db.collection('slots').doc(data['slotId']).get();
    expect(slot.exists, isTrue);
    expect(find.text('¡Cita Agendada!'), findsOneWidget);
  });

  testWidgets('HU-08: evita reservar una hora ocupada por otro paciente',
      (tester) async {
    await openForm(tester);
    // La selección inicial del formulario es el cuarto día siguiente,
    // a las 10:30 con la doctora Sofía Vega.
    final date =
        DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 4));
    await db
        .collection('slots')
        .doc(AppState.slotId(state.doctors[1].id, date, '10:30 AM'))
        .set({'patientId': 'otro-paciente'});

    await tester.ensureVisible(find.byKey(const Key('booking_reason_field')));
    await tester.enterText(
      find.byKey(const Key('booking_reason_field')),
      'Consulta para limpieza general',
    );
    await tester.ensureVisible(find.text('Confirmar Cita'));
    await tester.tap(find.text('Confirmar Cita'));
    await tester.pumpAndSettle();
    expect(
      find.text('Ese horario ya está ocupado para el odontólogo elegido.'),
      findsOneWidget,
    );
    expect(await appointmentCount(), 0);
  });

  test('Cancelar una cita libera su horario', () async {
    createState();
    final date = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 2));
    await state.bookAppointment(
      doctor: state.doctors[0],
      specialty: 'Limpieza',
      date: date,
      time: '09:00 AM',
      notes: 'Revisión general',
    );
    final appointment = (await db.collection('appointments').get()).docs.single;
    final slotId = appointment.data()['slotId'] as String;
    expect((await db.collection('slots').doc(slotId).get()).exists, isTrue);

    await state.updateAppointmentStatus(appointment.id, AppointmentStatus.cancelada);

    expect((await db.collection('slots').doc(slotId).get()).exists, isFalse);
  });
}
