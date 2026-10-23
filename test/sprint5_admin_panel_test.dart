import 'package:app_clinica/admin/admin_app.dart';
import 'package:app_clinica/admin/admin_login_screen.dart';
import 'package:app_clinica/admin/admin_shell.dart';
import 'package:app_clinica/admin/admin_state.dart';
import 'package:app_clinica/admin/pages/appointments_page.dart';
import 'package:app_clinica/admin/pages/patients_page.dart';
import 'package:app_clinica/models/appointment.dart';
import 'package:app_clinica/models/doctor.dart';
import 'package:app_clinica/repositories/firebase_clinic_repository.dart';
import 'package:app_clinica/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'helpers/firebase_fakes.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  /// Pantalla de escritorio para que quepan las tablas del panel.
  void useDesktopSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  AdminState createState({UserRole role = UserRole.admin}) {
    final state = AdminState(role: role, staffName: 'Laura Admin');
    addTearDown(state.dispose);
    return state;
  }

  Future<void> pumpPage(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: page)));
    await tester.pumpAndSettle();
  }

  DateTime tomorrow() =>
      DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1));

  group('AdminState (US03 pacientes)', () {
    setUp(() => setUpFirebase(signedInUid: adminUid));

    testWidgets('alta, edición, baja y reactivación de un paciente',
        (tester) async {
      final state = createState();
      await tester.pumpAndSettle();

      final id = await state.createPatient(
        name: 'Ana Martínez',
        phone: '4421234567',
        email: 'ana@test.com',
        treatment: 'Ortodoncia',
        medicalAlerts: ['Alergia a la penicilina'],
      );
      await tester.pumpAndSettle();
      final created = state.patientById(id)!;
      expect(created.active, isTrue);
      expect(created.medicalAlerts, ['Alergia a la penicilina']);

      await state.updatePatient(created.copyWith(phone: '4429999999'));
      await tester.pumpAndSettle();
      expect(state.patientById(id)!.phone, '4429999999');

      await state.deactivatePatient(state.patientById(id)!);
      await tester.pumpAndSettle();
      expect(state.patientById(id)!.active, isFalse);
      expect(state.activePatients.where((p) => p.id == id), isEmpty);

      await state.reactivatePatient(state.patientById(id)!);
      await tester.pumpAndSettle();
      expect(state.patientById(id)!.active, isTrue);
    });

    test('solo el administrador gestiona pacientes', () {
      expect(createState().canManagePatients, isTrue);
      expect(createState(role: UserRole.receptionist).canManagePatients,
          isFalse);
    });
  });

  group('AdminState (US05 citas)', () {
    setUp(() => setUpFirebase(signedInUid: receptionistUid));

    testWidgets('valida cruces de horario, modifica y cancela', (tester) async {
      final state = createState(role: UserRole.receptionist);
      await tester.pumpAndSettle();
      final patientId = await state.createPatient(
        name: 'Diego Castro',
        phone: '4423456789',
        email: 'diego@test.com',
      );
      await tester.pumpAndSettle();
      final patient = state.patientById(patientId)!;
      final doctor = kClinicDoctors.first;
      final day = tomorrow();

      await state.createAppointment(
        patient: patient,
        doctor: doctor,
        specialty: 'Limpieza',
        date: day,
        time: '09:00 AM',
      );
      await tester.pumpAndSettle();
      final appointment = state.appointments.single;
      expect(appointment.office, doctor.office);
      expect(appointment.patientRecordId, patientId);
      expect(appointment.status, AppointmentStatus.confirmada);
      expect(await state.takenTimes(doctor, day), {'09:00 AM'});

      // Mismo odontólogo, día y hora: se rechaza.
      await expectLater(
        state.createAppointment(
          patient: patient,
          doctor: doctor,
          specialty: 'Ortodoncia',
          date: day,
          time: '09:00 AM',
        ),
        throwsA(isA<StateError>()),
      );

      // Otro odontólogo a la misma hora sí se puede.
      expect(await state.takenTimes(kClinicDoctors[1], day), isEmpty);

      await state.updateAppointment(
        appointment: appointment,
        doctor: doctor,
        specialty: 'Limpieza',
        date: day,
        time: '12:00 PM',
        notes: 'Movida por recepción',
      );
      await tester.pumpAndSettle();
      expect(state.appointments.single.time, '12:00 PM');
      expect(await state.takenTimes(doctor, day), {'12:00 PM'});

      await state.cancelAppointment(state.appointments.single);
      await tester.pumpAndSettle();
      expect(state.appointments.single.status, AppointmentStatus.cancelada);
      expect(await state.takenTimes(doctor, day), isEmpty);
    });

    testWidgets('confirmar una cita pendiente', (tester) async {
      final state = createState(role: UserRole.receptionist);
      await addAppointment(
        patientId: patientUid,
        patientName: 'María Moreno',
        date: tomorrow(),
        status: AppointmentStatus.pendiente,
      );
      await tester.pumpAndSettle();
      await state.confirmAppointment(state.appointments.single);
      await tester.pumpAndSettle();
      expect(state.appointments.single.status, AppointmentStatus.confirmada);
    });

    test('modificar a un horario ocupado se rechaza', () async {
      final repo = FirebaseClinicRepository(db);
      final doctor = kClinicDoctors.first;
      final day = tomorrow();
      await db
          .collection('slots')
          .doc(FirebaseClinicRepository.slotId(doctor.id, day, '03:00 PM'))
          .set({'patientId': 'otro'});
      final ref = await db.collection('appointments').add({
        'patientName': 'Diego',
        'doctorName': doctor.name,
        'doctorId': doctor.id,
        'specialty': 'Limpieza',
        'date': day,
        'time': '09:00 AM',
        'status': 'confirmada',
      });
      final appointment = Appointment.fromDoc(await ref.get());
      await expectLater(
        repo.updateStaffAppointment(
          appointment: appointment,
          doctor: doctor,
          specialty: 'Limpieza',
          date: day,
          time: '03:00 PM',
          notes: '',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('Acceso al panel', () {
    testWidgets('sin sesión muestra el login del panel', (tester) async {
      await setUpFirebase();
      await tester.pumpWidget(const AdminApp());
      await tester.pumpAndSettle();
      expect(find.byType(AdminLoginScreen), findsOneWidget);
      expect(find.text('Panel Administrativo'), findsOneWidget);
    });

    testWidgets('el login exige correo y contraseña', (tester) async {
      await setUpFirebase();
      await tester.pumpWidget(const MaterialApp(home: AdminLoginScreen()));
      await tester.tap(find.text('Entrar al panel'));
      await tester.pumpAndSettle();
      expect(find.text('Escribe tu correo y contraseña.'), findsOneWidget);
    });

    testWidgets('una cuenta de paciente no puede entrar al panel',
        (tester) async {
      final auth = await setUpFirebase(loginUid: patientUid);
      await tester.pumpWidget(const MaterialApp(home: AdminLoginScreen()));
      await tester.enterText(find.byType(TextFormField).at(0), 'paciente@test.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'paciente123');
      await tester.tap(find.text('Entrar al panel'));
      await tester.pumpAndSettle();
      expect(find.text('Esta cuenta no tiene acceso al panel administrativo.'),
          findsOneWidget);
      expect(auth.currentUser, isNull);
    });

    testWidgets('el administrador entra y ve Pacientes y Citas',
        (tester) async {
      useDesktopSize(tester);
      await setUpFirebase(loginUid: adminUid);
      await tester.pumpWidget(const AdminApp());
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'admin@test.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'admin123');
      await tester.tap(find.text('Entrar al panel'));
      await tester.pumpAndSettle();

      expect(find.byType(AdminShell), findsOneWidget);
      expect(find.text('Laura Admin'), findsOneWidget);
      expect(find.byType(PatientsPage), findsOneWidget);

      await tester.tap(find.text('Citas').first);
      await tester.pumpAndSettle();
      expect(find.byType(AppointmentsPage), findsOneWidget);

      await tester.tap(find.byTooltip('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.byType(AdminLoginScreen), findsOneWidget);
    });

    testWidgets('recepción solo ve el gestor de citas', (tester) async {
      useDesktopSize(tester);
      await setUpFirebase(signedInUid: receptionistUid);
      await tester.pumpWidget(const AdminApp());
      await tester.pumpAndSettle();
      expect(find.byType(AppointmentsPage), findsOneWidget);
      expect(find.byType(PatientsPage), findsNothing);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('Recepción'), findsOneWidget);
    });

    testWidgets('una sesión de paciente abierta ve "sin acceso"',
        (tester) async {
      await setUpFirebase(signedInUid: patientUid);
      await tester.pumpWidget(const AdminApp());
      await tester.pumpAndSettle();
      expect(
        find.textContaining('no tiene acceso al panel administrativo'),
        findsOneWidget,
      );
    });
  });

  group('Pantalla Pacientes', () {
    setUp(() => setUpFirebase(signedInUid: adminUid));

    testWidgets('da de alta un paciente desde el formulario', (tester) async {
      useDesktopSize(tester);
      final state = createState();
      await pumpPage(tester, ListenableBuilder(
        listenable: state,
        builder: (_, _) => PatientsPage(state: state),
      ));
      expect(find.byKey(const Key('patients_empty')), findsOneWidget);

      await tester.tap(find.text('Nuevo paciente'));
      await tester.pumpAndSettle();

      // Validaciones del formulario.
      await tester.tap(find.byKey(const Key('patient_form_save')));
      await tester.pumpAndSettle();
      expect(find.text('Escribe el nombre completo.'), findsOneWidget);
      expect(find.text('El teléfono debe tener 10 dígitos.'), findsOneWidget);
      expect(find.text('Escribe un correo válido.'), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('patient_form_name')), 'Valeria Ramos');
      await tester.enterText(
          find.byKey(const Key('patient_form_phone')), '442 789 0123');
      await tester.enterText(
          find.byKey(const Key('patient_form_email')), 'valeria@test.com');
      await tester.enterText(
          find.byKey(const Key('patient_form_alerts')), 'Diabetes, Hipertensión');
      await tester.tap(find.byKey(const Key('patient_form_save')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('patients_table')), findsOneWidget);
      expect(find.text('Valeria Ramos'), findsOneWidget);
      expect(state.patients.single.medicalAlerts, ['Diabetes', 'Hipertensión']);
    });

    testWidgets('busca, consulta, edita y da de baja', (tester) async {
      useDesktopSize(tester);
      final state = createState();
      await state.createPatient(
          name: 'Gabriel Silva', phone: '4426789012', email: 'gabriel@test.com');
      final otherId = await state.createPatient(
          name: 'Elena Torres', phone: '4425678901', email: 'elena@test.com');
      await pumpPage(tester, ListenableBuilder(
        listenable: state,
        builder: (_, _) => PatientsPage(state: state),
      ));
      expect(find.text('Gabriel Silva'), findsOneWidget);
      expect(find.text('Elena Torres'), findsOneWidget);

      // Buscar por el contenido del QR del carnet.
      await tester.enterText(find.byKey(const Key('patients_search')),
          'clinica-dental:paciente:$otherId');
      await tester.pumpAndSettle();
      expect(find.text('Gabriel Silva'), findsNothing);
      expect(find.text('Elena Torres'), findsOneWidget);

      // Consultar.
      await tester.tap(find.byTooltip('Consultar'));
      await tester.pumpAndSettle();
      expect(find.text('Historial de citas (0)'), findsOneWidget);
      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();

      // Editar.
      await tester.tap(find.byTooltip('Editar'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('patient_form_treatment')), 'Implante');
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();
      expect(state.patientById(otherId)!.treatment, 'Implante');

      // Dar de baja (con confirmación).
      await tester.tap(find.byTooltip('Dar de baja'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Dar de baja'));
      await tester.pumpAndSettle();
      expect(state.patientById(otherId)!.active, isFalse);
      expect(find.byKey(const Key('patients_empty')), findsOneWidget);

      // Aparece en "Dados de baja" y se puede reactivar.
      await tester.tap(find.text('Dados de baja'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Reactivar'));
      await tester.pumpAndSettle();
      expect(state.patientById(otherId)!.active, isTrue);
    });
  });

  group('Pantalla Citas', () {
    setUp(() => setUpFirebase(signedInUid: receptionistUid));

    Future<AdminState> openPage(WidgetTester tester) async {
      useDesktopSize(tester);
      final state = createState(role: UserRole.receptionist);
      await state.createPatient(
          name: 'Fernanda Mendoza', phone: '4424567890', email: 'fer@test.com');
      await pumpPage(tester, ListenableBuilder(
        listenable: state,
        builder: (_, _) => AppointmentsPage(state: state),
      ));
      return state;
    }

    testWidgets('agenda una cita y bloquea el horario ocupado', (tester) async {
      final state = await openPage(tester);
      final doctor = kClinicDoctors.first;
      await db
          .collection('slots')
          .doc(FirebaseClinicRepository.slotId(doctor.id, tomorrow(), '09:00 AM'))
          .set({'patientId': 'otro'});
      expect(find.byKey(const Key('appointments_empty')), findsOneWidget);

      await tester.tap(find.text('Nueva cita'));
      await tester.pumpAndSettle();

      // Sin paciente ni horario no se guarda.
      await tester.tap(find.byKey(const Key('appointment_form_save')));
      await tester.pumpAndSettle();
      expect(find.text('Selecciona un paciente.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('appointment_form_patient')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fernanda Mendoza').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('appointment_form_save')));
      await tester.pumpAndSettle();
      expect(find.text('Selecciona un horario disponible.'), findsOneWidget);

      // El horario ocupado aparece marcado y deshabilitado.
      expect(find.text('09:00 AM · ocupado'), findsOneWidget);
      final busy = tester.widget<ChoiceChip>(find.byKey(const Key('slot_09:00 AM')));
      expect(busy.onSelected, isNull);

      await tester.tap(find.byKey(const Key('slot_10:30 AM')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('appointment_form_save')));
      await tester.pumpAndSettle();

      expect(find.text('Cita agendada.'), findsOneWidget);
      expect(state.appointments.single.time, '10:30 AM');
      expect(find.byKey(const Key('appointments_table')), findsOneWidget);
      expect(find.text('Consultorio 1'), findsOneWidget);
    });

    testWidgets('filtra, modifica y cancela desde la tabla', (tester) async {
      final state = await openPage(tester);
      await state.createAppointment(
        patient: state.patients.single,
        doctor: kClinicDoctors[1],
        specialty: 'Ortodoncia',
        date: tomorrow(),
        time: '12:00 PM',
      );
      await tester.pumpAndSettle();
      expect(find.text('Fernanda Mendoza'), findsOneWidget);

      // Filtro "Hoy": la cita es de mañana.
      await tester.tap(find.text('Hoy'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('appointments_empty')), findsOneWidget);
      await tester.tap(find.text('Próximas'));
      await tester.pumpAndSettle();

      // Búsqueda sin resultados.
      await tester.enterText(
          find.byKey(const Key('appointments_search')), 'zzz');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('appointments_empty')), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key('appointments_search')), 'fernanda');
      await tester.pumpAndSettle();

      // Modificar: cambiar el horario.
      await tester.ensureVisible(find.byTooltip('Modificar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Modificar'));
      await tester.pumpAndSettle();
      expect(find.text('Modificar cita'), findsOneWidget);
      await tester.tap(find.byKey(const Key('slot_04:30 PM')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('appointment_form_save')));
      await tester.pumpAndSettle();
      expect(state.appointments.single.time, '04:30 PM');

      // Cancelar con confirmación.
      await tester.ensureVisible(find.byTooltip('Cancelar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cancelar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Cancelar cita'));
      await tester.pumpAndSettle();
      expect(state.appointments.single.status, AppointmentStatus.cancelada);
      expect(find.byTooltip('Modificar'), findsOneWidget);
      final edit = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.edit_calendar_outlined));
      expect(edit.onPressed, isNull);
    });

    testWidgets('confirma una cita pendiente desde la tabla', (tester) async {
      final state = await openPage(tester);
      await addAppointment(
        patientId: patientUid,
        patientName: 'María Moreno',
        date: tomorrow(),
        status: AppointmentStatus.pendiente,
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('1 pendientes de confirmar'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Confirmar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Confirmar'));
      await tester.pumpAndSettle();
      expect(state.appointments.single.status, AppointmentStatus.confirmada);
    });
  });
}
