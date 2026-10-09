import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/doctor/doctor_main_screen.dart';
import 'screens/patient/patient_main_screen.dart';
import 'services/auth_service.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Sin esto, un fallo de Firebase deja la pantalla en blanco.
    runApp(StartupErrorApp(error: e));
    return;
  }
  runApp(const ClinicaDentalApp());
}

class StartupErrorApp extends StatelessWidget {
  final Object error;
  const StartupErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No se pudo conectar con Firebase:\n\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class ClinicaDentalApp extends StatelessWidget {
  const ClinicaDentalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clínica Dental',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
      home: const AuthGate(),
    );
  }
}

/// Si ya hay una sesión abierta, entra directo al panel según el rol.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    if (user == null) return const WelcomeScreen();

    return FutureBuilder<UserRole>(
      future: AuthService.instance.getRole(user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const WelcomeScreen();
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data == UserRole.doctor
            ? const DoctorMainScreen()
            : const PatientMainScreen();
      },
    );
  }
}
