import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../services/auth_service.dart';
import '../welcome_screen.dart';
import 'doctor_dashboard_tab.dart';
import 'doctor_agenda_tab.dart';
import 'doctor_patients_tab.dart';
import 'doctor_inventory_tab.dart';

class DoctorMainScreen extends StatefulWidget {
  const DoctorMainScreen({super.key});

  @override
  State<DoctorMainScreen> createState() => _DoctorMainScreenState();
}

class _DoctorMainScreenState extends State<DoctorMainScreen> {
  int _currentIndex = 0;
  late final AppState _state;

  @override
  void initState() {
    super.initState();
    _state = AppState(role: UserRole.doctor);
    _state.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      DoctorDashboardTab(
        state: _state,
        onTabChange: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      DoctorAgendaTab(state: _state),
      DoctorPatientsTab(state: _state),
      DoctorInventoryTab(state: _state),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    color: AppTheme.primaryBlue,
                    size: 15,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Modo Doctor',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: AppTheme.errorRed,
              size: 20,
            ),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await AuthService.instance.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F223D).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_rounded,
                  label: 'Inicio',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.calendar_month_rounded,
                  label: 'Agenda',
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.people_alt_rounded,
                  label: 'Pacientes',
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.inventory_2_rounded,
                  label: 'Inventario',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.textMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.primaryBlue : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
