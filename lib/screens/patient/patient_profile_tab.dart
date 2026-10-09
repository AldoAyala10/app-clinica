import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../services/auth_service.dart';
import '../welcome_screen.dart';

class PatientProfileTab extends StatelessWidget {
  final AppState state;

  const PatientProfileTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header matching Figma Screen 11
              const Text(
                'Mi Perfil',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),

              // User Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.cardShadow,
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person_rounded,
                          size: 42,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      state.patientName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.patientEmail,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Paciente Activo • Clínica Dental',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.successGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Menu List Options Card matching Figma Screen 11
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: AppTheme.softShadow,
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.badge_outlined,
                        title: 'Datos personales',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.history_edu_rounded,
                        title: 'Historial clínico dental',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.credit_card_rounded,
                        title: 'Métodos de pago',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notificaciones',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.help_outline_rounded,
                        title: 'Ayuda y soporte',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Danger Zone: Logout Button matching Figma Screen 11
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.softShadow,
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () async {
                      await AuthService.instance.signOut();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const WelcomeScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: AppTheme.errorRed,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Cerrar Sesión',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.errorRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.textPrimary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 64,
      endIndent: 16,
      color: Colors.grey.shade100,
    );
  }
}
