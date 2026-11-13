import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../services/push_notification_service.dart';
import 'patient_home_tab.dart';
import 'patient_appointments_tab.dart';
import 'book_appointment_tab.dart';
import 'patient_profile_tab.dart';
import 'my_turn_tab.dart';

class PatientMainScreen extends StatefulWidget {
  const PatientMainScreen({super.key});

  @override
  State<PatientMainScreen> createState() => _PatientMainScreenState();
}

class _PatientMainScreenState extends State<PatientMainScreen> {
  int _currentIndex = 0;
  late final AppState _state;
  late final PushNotificationService _pushNotifications;

  @override
  void initState() {
    super.initState();
    _state = AppState(role: UserRole.patient);
    _pushNotifications = PushNotificationService();
    final uid = _state.uid;
    if (uid != null) unawaited(_pushNotifications.initialize(uid));
    _state.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    unawaited(_pushNotifications.dispose());
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      PatientHomeTab(
        state: _state,
        onTabChange: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      PatientAppointmentsTab(
        state: _state,
        onBookNew: () {
          setState(() {
            _currentIndex = 2; // Go to Agendar
          });
        },
      ),
      BookAppointmentTab(
        state: _state,
        onAppointmentBooked: () {
          setState(() {
            _currentIndex = 1; // Go to Mis Citas
          });
        },
      ),
      PatientProfileTab(state: _state),
      MyTurnTab(state: _state),
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
                color: AppTheme.successGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.account_circle_rounded,
                    color: AppTheme.successGreen,
                    size: 15,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Modo Paciente',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.successGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                Expanded(
                  child: _buildNavItem(
                    index: 0,
                    icon: Icons.home_rounded,
                    label: 'Inicio',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    index: 1,
                    icon: Icons.calendar_month_rounded,
                    label: 'Mis Citas',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    index: 2,
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Agendar',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    index: 3,
                    icon: Icons.person_rounded,
                    label: 'Mi Perfil',
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    index: 4,
                    icon: Icons.confirmation_number_outlined,
                    label: 'Mi Turno',
                  ),
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
