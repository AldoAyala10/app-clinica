import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:app_clinica/screens/register_screen.dart';
import 'package:app_clinica/screens/doctor/doctor_dashboard_tab.dart';
import 'package:app_clinica/screens/doctor/doctor_agenda_tab.dart';
import 'package:app_clinica/state/app_state.dart';
import 'package:app_clinica/widgets/custom_button.dart';
import 'package:app_clinica/widgets/custom_text_field.dart';

import 'helpers/firebase_fakes.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  group('RegisterScreen Pruebas de Interfaz y Validación', () {
    setUp(() => setUpFirebase());

    testWidgets('Muestra errores cuando los campos son inválidos', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
      await tester.pumpAndSettle();

      // Presionar Crear Cuenta sin llenar campos
      await tester.ensureVisible(find.byType(CustomButton));
      await tester.tap(find.byType(CustomButton));
      await tester.pumpAndSettle();

      expect(find.text('Ingresa tu nombre completo.'), findsOneWidget);
      expect(find.text('Ingresa un correo electrónico válido.'), findsOneWidget);
      expect(find.text('La contraseña debe tener al menos 6 caracteres.'), findsOneWidget);
    });

    testWidgets('Permite registrar cuenta con datos válidos', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
      await tester.pumpAndSettle();

      final fields = find.byType(CustomTextField);
      await tester.enterText(fields.at(0), 'Nuevo Paciente');
      await tester.enterText(fields.at(1), 'paciente.nuevo@clinica.com');
      await tester.enterText(fields.at(2), '4425556677');
      await tester.enterText(fields.at(3), 'Password123');

      await tester.ensureVisible(find.byType(CustomButton));
      await tester.tap(find.byType(CustomButton));
      await tester.pumpAndSettle();

      expect(find.text('¡Cuenta creada exitosamente! Bienvenido a Clínica Dental'), findsOneWidget);
    });
  });

  group('DoctorDashboardTab y DoctorAgendaTab', () {
    late AppState state;

    setUp(() async {
      await setUpFirebase(signedInUid: doctorUid);
      state = AppState(role: UserRole.doctor);
    });

    tearDown(() => state.dispose());

    testWidgets('DoctorDashboardTab renderiza cabecera y estadísticas', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: DoctorDashboardTab(
          state: state,
          onTabChange: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Bienvenido de nuevo,'), findsOneWidget);
    });

    testWidgets('DoctorAgendaTab permite alternar filtros y días', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: DoctorAgendaTab(state: state),
      ));
      await tester.pumpAndSettle();

      // Filtro Todas
      expect(find.text('Todas'), findsOneWidget);
      
      // Alternar filtro a Confirmadas
      await tester.tap(find.text('Confirmadas'));
      await tester.pumpAndSettle();

      // Alternar filtro a Pendientes
      await tester.tap(find.text('Pendientes'));
      await tester.pumpAndSettle();
    });
  });
}
