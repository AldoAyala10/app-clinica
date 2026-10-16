import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:app_clinica/screens/login_screen.dart';
import 'package:app_clinica/screens/doctor/doctor_main_screen.dart';
import 'package:app_clinica/services/auth_service.dart';
import 'package:app_clinica/state/app_state.dart';
import 'package:app_clinica/widgets/custom_button.dart';

import 'helpers/firebase_fakes.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));
  setUp(() => setUpFirebase(signedInUid: doctorUid));

  Future<void> renderLogin(
    WidgetTester tester, {
    LoginAuthenticator? authenticate,
  }) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(authenticate: authenticate)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> submit(
    WidgetTester tester, {
    String email = 'doctor@test.com',
    String password = 'doctor123',
  }) async {
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await tester.ensureVisible(find.byType(CustomButton).first);
    await tester.tap(find.byType(CustomButton).first);
    await tester.pump();
  }

  testWidgets('Login: credenciales incorrectas muestran mensaje específico',
      (tester) async {
    await renderLogin(tester, authenticate: (email, password) async {
      throw const AuthException('Correo o contraseña incorrectos.');
    });
    await submit(tester, password: 'contrasena-equivocada');
    await tester.pumpAndSettle();
    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    expect(find.byType(DoctorMainScreen), findsNothing);
  });

  testWidgets('Login: muestra loading y bloquea pulsaciones repetidas',
      (tester) async {
    final pendingLogin = Completer<UserRole>();
    var requests = 0;
    await renderLogin(tester, authenticate: (email, password) {
      requests++;
      return pendingLogin.future;
    });

    await submit(tester);
    expect(requests, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<CustomButton>(find.byType(CustomButton).first);
    expect(button.isLoading, isTrue);
    expect(button.onPressed, isNull);

    // Cambiar de rol durante la solicitud no debe alterar el acceso: si el
    // cambio se aplicara, la cuenta de doctor sería rechazada como paciente.
    await tester.ensureVisible(find.text('Paciente').first);
    await tester.tap(find.text('Paciente').first);
    await tester.pump();
    expect(requests, 1);

    pendingLogin.complete(UserRole.doctor);
    await tester.pumpAndSettle();
    expect(find.byType(DoctorMainScreen), findsOneWidget);
    expect(requests, 1);
  });

  testWidgets('Login: error de conexión y permite reintentar', (tester) async {
    var attempts = 0;
    await renderLogin(tester, authenticate: (email, password) async {
      attempts++;
      if (attempts == 1) {
        throw const AuthException('Sin conexión a internet. Revisa tu red.');
      }
      return UserRole.doctor;
    });

    await submit(tester);
    await tester.pumpAndSettle();
    expect(find.text('Sin conexión a internet. Revisa tu red.'), findsOneWidget);
    expect(
      tester.widget<CustomButton>(find.byType(CustomButton).first).isLoading,
      isFalse,
    );

    await tester.ensureVisible(find.byType(CustomButton).first);
    await tester.tap(find.byType(CustomButton).first);
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.byType(DoctorMainScreen), findsOneWidget);
  });

  testWidgets('Login: timeout muestra mensaje diferente', (tester) async {
    await renderLogin(tester, authenticate: (email, password) async {
      throw TimeoutException('Simulación de tiempo de espera');
    });
    await submit(tester);
    await tester.pumpAndSettle();
    expect(
      find.text('La conexión tardó demasiado. Intenta de nuevo.'),
      findsOneWidget,
    );
    expect(find.byType(DoctorMainScreen), findsNothing);
  });
}
