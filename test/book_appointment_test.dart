import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_clinica/screens/patient/book_appointment_tab.dart';
import 'package:app_clinica/state/app_state.dart';

void main() {
  late AppState state;

  setUp(() {
    state = AppState();
    state.login(UserRole.patient);
  });

  Future<void> openForm(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: BookAppointmentTab(
        state: state,
        onAppointmentBooked: () {},
      ),
    ));
    await tester.pumpAndSettle();
  }

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
    expect(state.appointments.length, 9);
  });

  testWidgets('HU-08: muestra loading y guarda motivo en datos locales',
      (tester) async {
    await openForm(tester);
    const motivo = 'Dolor en una muela al masticar';
    await tester.ensureVisible(find.byKey(const Key('booking_reason_field')));
    await tester.enterText(find.byKey(const Key('booking_reason_field')), motivo);
    await tester.ensureVisible(find.text('Confirmar Cita'));
    final before = state.appointments.length;
    await tester.tap(find.text('Confirmar Cita'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(state.appointments.length, before + 1);
    expect(state.appointments.first.notes, motivo);
    expect(find.text('¡Cita Agendada!'), findsOneWidget);
  });

  testWidgets('HU-08: evita duplicar una hora ocupada localmente',
      (tester) async {
    // La selección inicial del formulario corresponde al cuarto día siguiente,
    // a las 10:30 con la doctora Sofía Vega.
    state.addAppointment(
      patientName: 'Otra paciente',
      doctorName: state.doctors[1].name,
      specialty: 'Limpieza',
      date: DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 4)),
      time: '10:30 AM',
    );
    await openForm(tester);
    await tester.ensureVisible(find.byKey(const Key('booking_reason_field')));
    await tester.enterText(
      find.byKey(const Key('booking_reason_field')),
      'Consulta para limpieza general',
    );
    await tester.ensureVisible(find.text('Confirmar Cita'));
    final before = state.appointments.length;
    await tester.tap(find.text('Confirmar Cita'));
    await tester.pump();
    expect(
      find.text('Ese horario ya está ocupado para el odontólogo elegido.'),
      findsOneWidget,
    );
    expect(state.appointments.length, before);
  });
}
