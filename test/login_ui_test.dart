import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_clinica/screens/login_screen.dart';
import 'package:app_clinica/screens/doctor/doctor_main_screen.dart';
import 'package:app_clinica/state/app_state.dart';
import 'package:app_clinica/widgets/custom_button.dart';

void main() {
  setUp(() => AppState.session.logout());
  tearDown(() => AppState.session.logout());

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
    String email = 'admin@test.com',
    String password = 'admin123',
  }) async {
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await tester.ensureVisible(find.byType(CustomButton).first);
    await tester.tap(find.byType(CustomButton).first);
    await tester.pump();
  }

  testWidgets('Login Mock: credenciales incorrectas muestran mensaje específico',
      (tester) async {
    await renderLogin(tester);
    await submit(tester, password: 'contrasena-equivocada');
    await tester.pumpAndSettle();
    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    expect(AppState.session.isLoggedIn, isFalse);
  });

  testWidgets('Login Mock: muestra loading y bloquea pulsaciones repetidas',
      (tester) async {
    final pendingLogin = Completer<UserRole?>();
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

    // Un cambio de rol durante la solicitud tampoco debe alterar el acceso.
    await tester.ensureVisible(find.text('Paciente').first);
    await tester.tap(find.text('Paciente').first);
    await tester.pump();
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField).first).controller?.text,
      'admin@test.com',
    );
    expect(requests, 1);

    pendingLogin.complete(UserRole.doctor);
    await tester.pumpAndSettle();
    expect(find.byType(DoctorMainScreen), findsOneWidget);
    expect(requests, 1);
  });

  testWidgets('Login Mock: error de conexión simulado y permite reintentar',
      (tester) async {
    var attempts = 0;
    await renderLogin(tester, authenticate: (email, password) async {
      attempts++;
      if (attempts == 1) throw const LoginConnectionException();
      return UserRole.doctor;
    });

    await submit(tester);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'No se pudo conectar con el servidor. Revisa tu conexión e intenta de nuevo.'
      ),
      findsOneWidget,
    );
    expect(AppState.session.isLoggedIn, isFalse);
    expect(tester.widget<CustomButton>(find.byType(CustomButton).first).isLoading,
        isFalse);

    await tester.ensureVisible(find.byType(CustomButton).first);
    await tester.tap(find.byType(CustomButton).first);
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.byType(DoctorMainScreen), findsOneWidget);
  });

  testWidgets('Login Mock: timeout simulado muestra mensaje diferente',
      (tester) async {
    await renderLogin(tester, authenticate: (email, password) async {
      throw TimeoutException('Simulación de tiempo de espera');
    });
    await submit(tester);
    await tester.pumpAndSettle();
    expect(
      find.text('La conexión tardó demasiado. Intenta de nuevo.'),
      findsOneWidget,
    );
    expect(AppState.session.isLoggedIn, isFalse);
  });
}
