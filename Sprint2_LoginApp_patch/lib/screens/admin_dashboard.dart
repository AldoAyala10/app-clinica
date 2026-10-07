import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../theme/app_theme.dart';
import '../widgets/clinic_card.dart';
import '../widgets/tooth_logo.dart';
import 'login_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key, required this.user});
  final AppUser user;

  void _signOut(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Panel de administración'),
          actions: [
            IconButton(
              key: const ValueKey('logoutButton'),
              tooltip: 'Cerrar sesión',
              onPressed: () => _signOut(context),
              icon: const Icon(Icons.logout_rounded, color: AppTheme.errorRed),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bienvenido de nuevo,',
                              style: TextStyle(color: AppTheme.textSecondary)),
                          Text(user.name,
                              style: const TextStyle(fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary)),
                        ],
                      )),
                      const ToothLogo(size: 52),
                    ]),
                    const SizedBox(height: 24),
                    ClinicCard(
                      featured: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ClinicBadge(label: 'Administrador', inverse: true),
                          const SizedBox(height: 18),
                          const Icon(Icons.admin_panel_settings_outlined,
                              size: 36, color: Colors.white),
                          const SizedBox(height: 12),
                          const Text('Clínica Dental Sonrisas',
                              style: TextStyle(fontSize: 22,
                                  fontWeight: FontWeight.w800, color: Colors.white)),
                          const SizedBox(height: 8),
                          Text(user.email,
                              style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ClinicCard(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F1FF),
                            borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.people_alt_rounded,
                              color: AppTheme.primaryBlue, size: 28),
                        ),
                        const SizedBox(height: 16),
                        const Text('Gestión de pacientes',
                            style: TextStyle(fontSize: 18,
                                fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                        const SizedBox(height: 8),
                        const Text(
                          'Este panel inicial confirma el acceso del administrador. '
                          'El listado y la gestión de pacientes se conectarán al '
                          'backend en el Sprint 3.',
                          style: TextStyle(height: 1.6)),
                      ],
                    )),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
