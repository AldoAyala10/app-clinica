import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_app/main.dart';

void main() {
  Future<void> signIn(
    WidgetTester tester, {
    required String email,
    required String password,
  }) async {
    await tester.pumpWidget(const LoginApp());
    await tester.enterText(find.byKey(const ValueKey('emailField')), email);
    await tester.enterText(
      find.byKey(const ValueKey('passwordField')),
      password,
    );
    await tester.ensureVisible(find.byKey(const ValueKey('loginButton')));
    await tester.tap(find.byKey(const ValueKey('loginButton')));
    await tester.pumpAndSettle();
  }

  testWidgets('el paciente llega a su dashboard con citas mock', (tester) async {
    await signIn(
      tester,
      email: 'paciente@test.com',
      password: 'Paciente123',
    );

    expect(find.text('Panel del paciente'), findsOneWidget);
    expect(find.text('Próximas citas'), findsOneWidget);
    expect(find.text('Limpieza dental'), findsNWidgets(2));
    expect(find.text('Revisión general'), findsOneWidget);
    expect(find.text('Carnet digital'), findsOneWidget);
  });

  testWidgets('el administrador llega al panel administrativo', (tester) async {
    await signIn(tester, email: 'admin@test.com', password: 'Admin123');

    expect(find.text('Panel de administración'), findsOneWidget);
    expect(find.text('Gestión de pacientes'), findsOneWidget);
    expect(
      find.text(
        'Este panel inicial confirma el acceso del administrador. '
        'El listado y la gestión de pacientes se conectarán al backend en '
        'el Sprint 3.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('rechaza credenciales incorrectas sin salir del login', (
    tester,
  ) async {
    await signIn(tester, email: 'paciente@test.com', password: 'incorrecta');

    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    expect(find.text('Panel del paciente'), findsNothing);
    expect(find.text('Panel de administración'), findsNothing);
  });

  testWidgets('cerrar sesión limpia la ruta y vuelve al login', (tester) async {
    await signIn(
      tester,
      email: 'paciente@test.com',
      password: 'Paciente123',
    );

    await tester.tap(find.byKey(const ValueKey('logoutButton')));
    await tester.pumpAndSettle();

    expect(find.text('Clínica Dental Sonrisas'), findsOneWidget);
    expect(find.text('Panel del paciente'), findsNothing);
  });

  testWidgets('el rol autenticado prevalece sobre el selector visual', (tester) async {
    await tester.pumpWidget(const LoginApp());
    await tester.ensureVisible(find.text('Usar administrador'));
    await tester.tap(find.text('Usar administrador'));
    await tester.enterText(find.byKey(const ValueKey('emailField')), 'paciente@test.com');
    await tester.enterText(find.byKey(const ValueKey('passwordField')), 'Paciente123');
    await tester.ensureVisible(find.byKey(const ValueKey('loginButton')));
    await tester.tap(find.byKey(const ValueKey('loginButton')));
    await tester.pumpAndSettle();
    expect(find.text('Panel del paciente'), findsOneWidget);
    expect(find.text('Panel de administración'), findsNothing);
  });

  testWidgets('el carnet se puede ocultar y volver a mostrar', (tester) async {
    await signIn(tester, email: 'paciente@test.com', password: 'Paciente123');
    final toggle = find.byKey(const ValueKey('qrFeatureSwitch'));
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('digitalCard')), findsNothing);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('digitalCard')), findsOneWidget);
  });

  testWidgets('correo inválido mantiene el formulario', (tester) async {
    await signIn(tester, email: 'sin-arroba', password: 'Paciente123');
    expect(find.text('Ingresa un correo electrónico válido.'), findsOneWidget);
    expect(find.text('Panel del paciente'), findsNothing);
  });

  testWidgets('interfaz usable a 320 px y texto ampliado', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await signIn(tester, email: 'paciente@test.com', password: 'Paciente123');
    await tester.ensureVisible(find.byKey(const ValueKey('digitalCard')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('logoutButton')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final context = tester.element(find.byKey(const ValueKey('emailField')));
    expect(Navigator.of(context).canPop(), isFalse);
  });
}
