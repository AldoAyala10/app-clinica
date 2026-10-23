import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/tooth_logo.dart';
import 'admin_state.dart';
import 'pages/appointments_page.dart';
import 'pages/patients_page.dart';

/// Marco del panel: menú lateral (Pacientes solo para administración) y la
/// página activa.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.state});

  final AdminState state;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    // Las páginas se construyen dentro del ListenableBuilder para que se
    // redibujen cada vez que llegan datos nuevos de Firestore.
    final pages = <({IconData icon, String label, WidgetBuilder build})>[
      if (state.canManagePatients)
        (
          icon: Icons.people_alt_rounded,
          label: 'Pacientes',
          build: (_) => PatientsPage(state: state),
        ),
      (
        icon: Icons.calendar_month_rounded,
        label: 'Citas',
        build: (_) => AppointmentsPage(state: state),
      ),
    ];
    final current = pages[_index.clamp(0, pages.length - 1)];
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // Se sale del panel con "Cerrar sesión", no con la flecha de regreso.
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: const Row(
          children: [
            ToothLogo(size: 32),
            SizedBox(width: 10),
            Text(
              'Clínica Dental · Panel Administrativo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  state.staffName.isEmpty ? 'Personal' : state.staffName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  state.role.label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_rounded, color: AppTheme.errorRed),
            onPressed: AuthService.instance.signOut,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (pages.length > 1)
            NavigationRail(
              extended: wide,
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final p in pages)
                  NavigationRailDestination(
                    icon: Icon(p.icon),
                    label: Text(p.label),
                  ),
              ],
            ),
          Expanded(
            child: ListenableBuilder(
              listenable: state,
              builder: (context, _) => current.build(context),
            ),
          ),
        ],
      ),
    );
  }
}
