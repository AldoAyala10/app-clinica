import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_clinica/main.dart';
import 'package:app_clinica/screens/welcome_screen.dart';
import 'package:app_clinica/screens/login_screen.dart';
import 'package:app_clinica/screens/register_screen.dart';
import 'package:app_clinica/screens/doctor/doctor_main_screen.dart';
import 'package:app_clinica/screens/patient/patient_main_screen.dart';
import 'package:app_clinica/widgets/custom_button.dart';

void main() {
  testWidgets(
      'ClinicaDentalApp launches WelcomeScreen and navigates to LoginScreen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ClinicaDentalApp());
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Clínica Dental'), findsOneWidget);
    expect(find.text('Atención Odontológica Especializada'), findsOneWidget);

    // Tap Iniciar Sesión button
    await tester.tap(find.text('Iniciar Sesión'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Doctor'), findsOneWidget);
    expect(find.text('Paciente'), findsOneWidget);
  });

  testWidgets('LoginScreen shows validation error for invalid email or password',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'correo-invalido');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.ensureVisible(find.byType(CustomButton).first);
    await tester.tap(find.byType(CustomButton).first);
    await tester.pumpAndSettle();

    expect(find.text('Ingresa un correo electrónico válido.'), findsOneWidget);
    expect(find.text('La contraseña debe tener al menos 6 caracteres.'), findsOneWidget);
  });

  testWidgets('RegisterScreen shows validation error for invalid email or password',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RegisterScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'María Moreno');
    await tester.enterText(find.byType(TextFormField).at(1), 'correo-invalido');
    await tester.enterText(find.byType(TextFormField).at(2), '4420000000');
    await tester.enterText(find.byType(TextFormField).at(3), '123');
    await tester.ensureVisible(find.byType(CustomButton).first);
    await tester.tap(find.byType(CustomButton).first);
    await tester.pumpAndSettle();

    expect(find.text('Ingresa un correo electrónico válido.'), findsOneWidget);
    expect(find.text('La contraseña debe tener al menos 6 caracteres.'), findsOneWidget);
  });

  testWidgets('DoctorMainScreen renders dashboard and navigation tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DoctorMainScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dr. Sandoval'), findsOneWidget);
    expect(find.text('PRÓXIMA CITA'), findsOneWidget);
    expect(find.text('Sofía Villanueva'), findsWidgets);
    expect(find.text('Agenda'), findsWidgets);
    expect(find.text('Pacientes'), findsWidgets);
    expect(find.text('Inventario'), findsWidgets);
  });

  testWidgets('PatientMainScreen renders home and booking elements',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PatientMainScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('¡Hola, María!'), findsOneWidget);
    expect(find.text('Tu sonrisa es nuestra prioridad'), findsOneWidget);
    expect(find.text('Dra. Sofía Vega'), findsOneWidget);
    expect(find.text('Limpieza Dental'), findsWidgets);
  });
}
