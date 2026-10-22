import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'admin/admin_app.dart';
import 'firebase_options.dart';
import 'main.dart' show StartupErrorApp;

/// Punto de entrada del Panel Administrativo Web:
///   flutter run -d chrome -t lib/main_admin.dart
///   flutter build web -t lib/main_admin.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    runApp(StartupErrorApp(error: e));
    return;
  }
  runApp(const AdminApp());
}
