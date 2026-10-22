import 'package:app_clinica/main.dart';
import 'package:app_clinica/models/appointment.dart';
import 'package:app_clinica/models/doctor.dart';
import 'package:app_clinica/models/patient.dart';
import 'package:app_clinica/screens/login_screen.dart';
import 'package:app_clinica/screens/patient/patient_appointments_tab.dart';
import 'package:app_clinica/screens/patient/patient_card_screen.dart';
import 'package:app_clinica/screens/patient/patient_main_screen.dart';
import 'package:app_clinica/screens/welcome_screen.dart';
import 'package:app_clinica/state/app_state.dart';
import 'package:app_clinica/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'helpers/firebase_fakes.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  AppState createPatientState() {
    final state = AppState(role: UserRole.patient);
    addTearDown(state.dispose);
    return state;
  }

  group('US04 Carnet digital', () {
    test('el QR codifica el ID del paciente y se puede leer de vuelta', () {
      final payload = patientQrPayload('abc123');
      expect(payload, 'clinica-dental:paciente:abc123');
      expect(patientIdFromQr(payload), 'abc123');
      expect(patientIdFromQr('  abc123 '), 'abc123');
    });

    testWidgets('muestra nombre, QR único y código del paciente',
        (tester) async {
      await setUpFirebase(signedInUid: patientUid);
      final state = createPatientState();
      await tester.pumpWidget(
        MaterialApp(home: PatientCardScreen(state: state)),
      );
      await tester.pumpAndSettle();

      expect(find.text('María Moreno'), findsOneWidget);
      expect(find.text('paciente@test.com'), findsOneWidget);
      expect(find.text('ID: PACIENTE'), findsOneWidget);
      final qr = tester.widget<QrImageView>(
          find.byKey(const Key('patient_card_qr')));
      expect(qr, isNotNull);
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('se abre desde el perfil del paciente', (tester) async {
      await setUpFirebase(signedInUid: patientUid);
      await tester.pumpWidget(const MaterialApp(home: PatientMainScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mi Perfil'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mi carnet digital'));
      await tester.pumpAndSettle();
      expect(find.byType(PatientCardScreen), findsOneWidget);
      expect(find.byKey(const Key('patient_card')), findsOneWidget);
    });

    testWidgets('sin sesión pide iniciar sesión', (tester) async {
      await setUpFirebase();
      final state = createPatientState();
      await tester.pumpWidget(
        MaterialApp(home: PatientCardScreen(state: state)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Inicia sesión para ver tu carnet.'), findsOneWidget);
    });
  });

  group('US06 Mis Citas', () {
    Future<AppState> showAppointments(WidgetTester tester) async {
      final state = createPatientState();
      await tester.pumpWidget(MaterialApp(
        home: ListenableBuilder(
          listenable: state,
          builder: (_, _) =>
              PatientAppointmentsTab(state: state, onBookNew: () {}),
        ),
      ));
      await tester.pumpAndSettle();
      return state;
    }

    testWidgets('muestra fecha, hora, odontólogo y consultorio',
        (tester) async {
      await setUpFirebase(signedInUid: patientUid);
      final state = createPatientState();
      await state.bookAppointment(
        doctor: kClinicDoctors[2],
        specialty: 'Endodoncia',
        date: DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 3)),
        time: '03:00 PM',
        notes: 'Dolor en molar',
      );
      await showAppointments(tester);

      expect(find.text('Dr. Roberto Mendoza'), findsOneWidget);
      expect(find.text('03:00 PM'), findsOneWidget);
      expect(find.text('Consultorio 3'), findsOneWidget);
    });

    testWidgets('solo muestra las citas del paciente autenticado',
        (tester) async {
      await setUpFirebase(signedInUid: patientUid);
      final tomorrow =
          DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1));
      await addAppointment(
          patientId: patientUid, patientName: 'María Moreno', date: tomorrow);
      await addAppointment(
          patientId: 'otro-paciente',
          patientName: 'Otra Persona',
          date: tomorrow,
          doctorName: 'Dr. Carlos Sandoval');
      final state = await showAppointments(tester);
      expect(state.appointments.length, 1);
      expect(find.text('Dra. Sofía Vega'), findsOneWidget);
      expect(find.text('Dr. Carlos Sandoval'), findsNothing);
    });

    testWidgets('sin red avisa que muestra las citas guardadas',
        (tester) async {
      await setUpFirebase(signedInUid: patientUid);
      final state = await showAppointments(tester);
      expect(find.byKey(const Key('patient_appointments_offline')),
          findsNothing);

      state.appointmentsOffline = true;
      await tester.pumpWidget(MaterialApp(
        home: PatientAppointmentsTab(state: state, onBookNew: () {}),
      ));
      await tester.pump();
      expect(find.byKey(const Key('patient_appointments_offline')),
          findsOneWidget);
      expect(find.textContaining('Sin conexión'), findsOneWidget);
    });

    testWidgets('listado vacío ofrece agendar', (tester) async {
      await setUpFirebase(signedInUid: patientUid);
      await showAppointments(tester);
      expect(find.byKey(const Key('patient_appointments_empty')),
          findsOneWidget);
    });
  });

  group('Personal administrativo en la app móvil', () {
    testWidgets('el login avisa que debe usar el panel web', (tester) async {
      await setUpFirebase();
      await tester.pumpWidget(MaterialApp(
        home: LoginScreen(authenticate: (_, _) async => UserRole.receptionist),
      ));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byType(TextFormField).at(0), 'recepcion@test.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'recepcion123');
      await tester.ensureVisible(find.byType(CustomButton).first);
      await tester.tap(find.byType(CustomButton).first);
      await tester.pumpAndSettle();
      expect(
        find.text('Esta cuenta es del personal administrativo. '
            'Entra desde el panel web.'),
        findsOneWidget,
      );
    });

    testWidgets('AuthGate cierra la sesión del personal', (tester) async {
      final auth = await setUpFirebase(signedInUid: adminUid);
      await tester.pumpWidget(const MaterialApp(home: AuthGate()));
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(auth.currentUser, isNull);
    });
  });

  test('roles: etiquetas y personal', () {
    expect(UserRole.admin.isStaff, isTrue);
    expect(UserRole.receptionist.isStaff, isTrue);
    expect(UserRole.doctor.isStaff, isFalse);
    expect(UserRole.receptionist.label, 'Recepción');
    expect(doctorById('d2')!.office, 'Consultorio 2');
    expect(doctorById('nadie'), isNull);
    expect(AppointmentStatus.values.length, 4);
  });
}
