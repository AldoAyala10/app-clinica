import 'dart:async';

import 'package:app_clinica/models/appointment.dart';
import 'package:app_clinica/screens/patient/patient_home_tab.dart';
import 'package:app_clinica/screens/patient/patient_appointments_tab.dart';
import 'package:app_clinica/state/app_state.dart';
import 'package:app_clinica/widgets/appointment_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'helpers/firebase_fakes.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));
  late AppState state;

  setUp(() async {
    await setUpFirebase(signedInUid: patientUid);
    final now = DateTime.now();
    await addAppointment(
      patientId: patientUid,
      patientName: 'María Moreno',
      date: now.add(const Duration(days: 3)),
    );
    await addAppointment(
      patientId: patientUid,
      patientName: 'María Moreno',
      date: now.subtract(const Duration(days: 30)),
      status: AppointmentStatus.completada,
    );
  });

  /// AppState se crea dentro de cada prueba para que sus streams corran en
  /// el reloj simulado del test.
  void createState() {
    state = AppState(role: UserRole.patient);
    addTearDown(state.dispose);
  }

  /// Las pestañas se reconstruyen cuando AppState avisa, igual que en
  /// PatientMainScreen.
  Widget rebuildOnChange(Widget Function() child) => ListenableBuilder(
        listenable: state,
        builder: (context, _) => child(),
      );

  Future<void> showHome(WidgetTester tester,
      {Future<List<Appointment>> Function()? loader,
      void Function(int)? onTabChange}) async {
    createState();
    await tester.pumpWidget(MaterialApp(
      home: rebuildOnChange(() => PatientHomeTab(
            state: state,
            onTabChange: onTabChange ?? (_) {},
            appointmentLoader: loader,
          )),
    ));
  }

  Future<void> showAppointments(WidgetTester tester,
      {Future<List<Appointment>> Function()? loader,
      VoidCallback? onBookNew}) async {
    createState();
    await tester.pumpWidget(MaterialApp(
      home: rebuildOnChange(() => PatientAppointmentsTab(
            state: state,
            onBookNew: onBookNew ?? () {},
            appointmentLoader: loader,
          )),
    ));
  }

  testWidgets('Dashboard: muestra las citas que llegan de Firestore',
      (tester) async {
    await showHome(tester);
    await tester.pumpAndSettle();
    expect(find.text('¡Hola, María!'), findsOneWidget);
    expect(find.text('PRÓXIMA CITA'), findsOneWidget);
    expect(find.byType(AppointmentCard), findsWidgets);
  });

  testWidgets('Dashboard: muestra cargando, vacío y permite agendar',
      (tester) async {
    final pending = Completer<List<Appointment>>();
    var selectedTab = -1;
    await showHome(tester,
        loader: () => pending.future, onTabChange: (tab) => selectedTab = tab);
    await tester.pump();
    expect(find.byKey(const Key('patient_home_loading')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(<Appointment>[]);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('patient_home_empty')), findsOneWidget);
    await tester.ensureVisible(find.text('Agendar cita'));
    await tester.tap(find.text('Agendar cita'));
    expect(selectedTab, 2);
  });

  testWidgets('Dashboard: error y botón reintentar recupera citas',
      (tester) async {
    var attempts = 0;
    await showHome(tester, loader: () async {
      attempts++;
      if (attempts == 1) throw StateError('Servidor simulado no disponible');
      return List<Appointment>.of(state.appointments);
    });
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('patient_home_error')), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('PRÓXIMA CITA'), findsOneWidget);
  });

  testWidgets('Mis Citas: carga y muestra vacío con acción Agendar',
      (tester) async {
    final pending = Completer<List<Appointment>>();
    var requestedBooking = false;
    await showAppointments(
      tester,
      loader: () => pending.future,
      onBookNew: () => requestedBooking = true,
    );
    await tester.pump();
    expect(
        find.byKey(const Key('patient_appointments_loading')), findsOneWidget);
    pending.complete(<Appointment>[]);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('patient_appointments_empty')), findsOneWidget);
    await tester.tap(find.text('Agendar cita'));
    expect(requestedBooking, isTrue);
  });

  testWidgets('Mis Citas: error, reintentar y lista recuperada',
      (tester) async {
    var attempts = 0;
    await showAppointments(tester, loader: () async {
      attempts++;
      if (attempts == 1) throw Exception('Error de red simulado');
      return List<Appointment>.of(state.appointments);
    });
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('patient_appointments_error')), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.byType(AppointmentCard), findsWidgets);
  });

  testWidgets('Mis Citas: diferencia próximas de historial (Firestore)',
      (tester) async {
    await showAppointments(tester);
    await tester.pumpAndSettle();
    expect(find.byType(AppointmentCard), findsOneWidget);
    await tester.tap(find.text('Historial (1)'));
    await tester.pumpAndSettle();
    expect(find.byType(AppointmentCard), findsOneWidget);
  });
}
