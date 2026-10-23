import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../services/auth_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'admin_login_screen.dart';
import 'admin_shell.dart';
import 'admin_state.dart';

/// Panel administrativo web para administración y recepción.
class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clínica Dental · Panel Administrativo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('es', 'ES'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
      home: const AdminAuthGate(),
    );
  }
}

/// Muestra el login o el panel según la sesión y el rol de la cuenta.
class AdminAuthGate extends StatelessWidget {
  const AdminAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges(),
      initialData: AuthService.instance.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) return const AdminLoginScreen();
        return _StaffSession(key: ValueKey(user.uid), uid: user.uid);
      },
    );
  }
}

class _StaffSession extends StatefulWidget {
  const _StaffSession({super.key, required this.uid});

  final String uid;

  @override
  State<_StaffSession> createState() => _StaffSessionState();
}

class _StaffSessionState extends State<_StaffSession> {
  late final Future<(UserRole, String)> _profile = _loadProfile();
  AdminState? _state;

  Future<(UserRole, String)> _loadProfile() async {
    final role = await AuthService.instance.getRole(widget.uid);
    final profile = await AuthService.instance.getProfile();
    return (role, (profile?['name'] as String?) ?? '');
  }

  @override
  void dispose() {
    _state?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(UserRole, String)>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _NoAccess(
            message: 'No se pudo cargar tu perfil. Intenta de nuevo.',
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final (role, name) = snapshot.data!;
        if (!role.isStaff) {
          return const _NoAccess(
            message:
                'Esta cuenta no tiene acceso al panel administrativo. '
                'Usa la app móvil.',
          );
        }
        _state ??= AdminState(role: role, staffName: name);
        return AdminShell(state: _state!);
      },
    );
  }
}

class _NoAccess extends StatelessWidget {
  const _NoAccess({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded,
                size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: AuthService.instance.signOut,
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
