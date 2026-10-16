import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:app_clinica/main.dart';
import 'package:app_clinica/models/appointment.dart';
import 'package:app_clinica/screens/welcome_screen.dart';
import 'package:app_clinica/screens/login_screen.dart';
import 'package:app_clinica/screens/register_screen.dart';
import 'package:app_clinica/screens/doctor/doctor_main_screen.dart';
import 'package:app_clinica/screens/patient/patient_main_screen.dart';
import 'package:app_clinica/services/auth_service.dart';
import 'package:app_clinica/state/app_state.dart';
import 'package:app_clinica/widgets/custom_button.dart';

import 'helpers/firebase_fakes.dart';

Future<void> _submit(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(CustomButton).first);
  await tester.tap(find.byType(CustomButton).first);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  testWidgets('WelcomeScreen navega a LoginScreen', (tester) async {
    await setUpFirebase();
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Clínica Dental'), findsOneWidget);
    expect(find.text('Atención Odontológica Especializada'), findsOneWidget);

    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Doctor'), findsOneWidget);
    expect(find.text('Paciente'), findsOneWidget);
  });

  testWidgets('LoginScreen valida correo y contraseña', (tester) async {
    await setUpFirebase();
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'correo-invalido');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await _submit(tester);

    expect(find.text('Ingresa un correo electrónico válido.'), findsOneWidget);
    expect(find.text('La contraseña debe tener al menos 6 caracteres.'),
        findsOneWidget);
  });

  testWidgets('RegisterScreen valida correo y contraseña', (tester) async {
    await setUpFirebase();
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'María Moreno');
    await tester.enterText(find.byType(TextFormField).at(1), 'correo-invalido');
    await tester.enterText(find.byType(TextFormField).at(2), '4420000000');
    await tester.enterText(find.byType(TextFormField).at(3), '123');
    await _submit(tester);

    expect(find.text('Ingresa un correo electrónico válido.'), findsOneWidget);
    expect(find.text('La contraseña debe tener al menos 6 caracteres.'),
        findsOneWidget);
  });

  testWidgets('Login rechaza rol cruzado y entra con el rol correcto',
      (tester) async {
    final auth = await setUpFirebase();
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();

    // "Doctor" está seleccionado por defecto, pero la cuenta es de paciente.
    await tester.enterText(
        find.byType(TextFormField).at(0), 'paciente@test.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'paciente123');
    await _submit(tester);

    expect(find.text('Esta cuenta es de paciente. Selecciona "Paciente".'),
        findsOneWidget);
    expect(auth.currentUser, isNull);

    await tester.tap(find.text('Paciente').first);
    await tester.pumpAndSettle();
    await _submit(tester);

    expect(find.byType(PatientMainScreen), findsOneWidget);
    expect(find.text('¡Hola, María!'), findsOneWidget);
  });

  test('Registro crea perfil y ficha de paciente en Firestore', () async {
    await setUpFirebase();
    await AuthService.instance.register(
      name: 'Laura Fuentes',
      email: 'laura@test.com',
      phone: '4421112233',
      password: 'secreta123',
    );

    final uid = AuthService.instance.currentUser!.uid;
    final user = await db.collection('users').doc(uid).get();
    final patient = await db.collection('patients').doc(uid).get();

    expect(user.data()!['role'], 'patient');
    expect(patient.data()!['userId'], uid);
    expect(patient.data()!['name'], 'Laura Fuentes');
  });

  testWidgets('El paciente solo ve sus próximas citas, ordenadas',
      (tester) async {
    await setUpFirebase(signedInUid: patientUid);
    final now = DateTime.now();
    await addAppointment(
        patientId: patientUid,
        patientName: 'María Moreno',
        date: now.add(const Duration(days: 12)));
    await addAppointment(
        patientId: patientUid,
        patientName: 'María Moreno',
        date: now.add(const Duration(days: 3)),
        status: AppointmentStatus.pendiente);
    await addAppointment(
        patientId: patientUid,
        patientName: 'María Moreno',
        date: now.subtract(const Duration(days: 30)),
        status: AppointmentStatus.completada);
    await addAppointment(
        patientId: 'otro-paciente',
        patientName: 'María Moreno',
        date: now.add(const Duration(days: 1)));

    final state = AppState(role: UserRole.patient);
    addTearDown(state.dispose);
    await tester.pumpAndSettle();

    expect(state.appointments.length, 3);
    final upcoming = state.upcomingPatientAppointments;
    expect(upcoming.length, 2);
    expect(upcoming.first.date.isBefore(upcoming.last.date), isTrue);
  });

  testWidgets('DoctorMainScreen muestra el panel con datos del doctor',
      (tester) async {
    await setUpFirebase(signedInUid: doctorUid);
    await tester.pumpWidget(const MaterialApp(home: DoctorMainScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Dr. Carlos Sandoval'), findsOneWidget);
    expect(find.text('PRÓXIMA CITA'), findsOneWidget);
    expect(find.text('Agenda'), findsWidgets);
    expect(find.text('Pacientes'), findsWidgets);
    expect(find.text('Inventario'), findsWidgets);
  });

  testWidgets('Cerrar sesión regresa a la bienvenida', (tester) async {
    final auth = await setUpFirebase(signedInUid: doctorUid);
    await tester.pumpWidget(const MaterialApp(home: DoctorMainScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(auth.currentUser, isNull);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(DoctorMainScreen), findsNothing);
  });

  testWidgets('AuthGate sin sesión muestra la bienvenida', (tester) async {
    await setUpFirebase();
    await tester.pumpWidget(const MaterialApp(home: AuthGate()));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Modo Doctor'), findsNothing);
  });

  testWidgets('AuthGate con sesión de doctor abre su panel', (tester) async {
    await setUpFirebase(signedInUid: doctorUid);
    await tester.pumpWidget(const MaterialApp(home: AuthGate()));
    await tester.pumpAndSettle();

    expect(find.byType(DoctorMainScreen), findsOneWidget);
    expect(find.text('Modo Doctor'), findsOneWidget);
  });
}
