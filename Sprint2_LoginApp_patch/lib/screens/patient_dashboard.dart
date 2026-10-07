import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../data/mock_appointments.dart';
import '../models/app_user.dart';
import '../theme/app_theme.dart';
import '../widgets/clinic_card.dart';
import '../widgets/tooth_logo.dart';
import 'login_screen.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key, required this.user});
  final AppUser user;

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  bool _qrEnabled = kHabilitarCarnetQR;
  late final List<MockAppointment> _appointments = mockAppointments();

  void _signOut() {
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Panel del paciente'),
          actions: [
            IconButton(
              key: const ValueKey('logoutButton'),
              tooltip: 'Cerrar sesión',
              onPressed: _signOut,
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
                          Text('¡Hola, ${widget.user.name}!',
                              style: const TextStyle(fontSize: 22,
                                  fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                          const SizedBox(height: 4),
                          const Text('Tu sonrisa es nuestra prioridad'),
                        ],
                      )),
                      const SizedBox(width: 12),
                      const CircleAvatar(
                        backgroundColor: Color(0xFFE8F1FF),
                        child: Icon(Icons.person_rounded, color: AppTheme.primaryBlue)),
                    ]),
                    const SizedBox(height: 24),
                    if (_appointments.isNotEmpty) ...[
                      ClinicCard(
                        featured: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Wrap(spacing: 16, runSpacing: 8, children: [
                              Text('TU PRÓXIMA CITA',
                                  style: TextStyle(color: Colors.white70,
                                      fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                              ClinicBadge(label: 'Confirmada', inverse: true),
                            ]),
                            const SizedBox(height: 16),
                            Text(_appointments.first.service,
                                style: const TextStyle(fontSize: 22,
                                    fontWeight: FontWeight.w800, color: Colors.white)),
                            const SizedBox(height: 6),
                            Text(_appointments.first.professional,
                                style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 18),
                            Wrap(spacing: 16, runSpacing: 8, children: [
                              Text(_appointments.first.dateLabel,
                                  style: const TextStyle(color: Colors.white)),
                              Text(_appointments.first.timeLabel,
                                  style: const TextStyle(color: Colors.white)),
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                    Wrap(spacing: 16, runSpacing: 8, children: [
                      const Text('Próximas citas',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary)),
                      ClinicBadge(label: '${_appointments.length} agendadas'),
                    ]),
                    const SizedBox(height: 14),
                    for (final appointment in _appointments) ...[
                      ClinicCard(child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFFE8F1FF),
                                borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.calendar_month_rounded,
                                color: AppTheme.primaryBlue)),
                          const SizedBox(width: 14),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(appointment.service,
                                  style: const TextStyle(fontSize: 15,
                                      fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                              const SizedBox(height: 6),
                              Text(appointment.professional),
                              const SizedBox(height: 6),
                              Text('${appointment.dateLabel} · ${appointment.timeLabel}'),
                              const SizedBox(height: 10),
                              const ClinicBadge(label: 'Confirmada'),
                            ],
                          )),
                        ],
                      )),
                      const SizedBox(height: 14),
                    ],
                    if (kHabilitarCarnetQR) ...[
                      const SizedBox(height: 10),
                      ClinicCard(child: Column(children: [
                        SwitchListTile(
                          key: const ValueKey('qrFeatureSwitch'),
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Carnet digital',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(_qrEnabled
                              ? 'Función de demostración habilitada'
                              : 'Función de demostración desactivada'),
                          value: _qrEnabled,
                          onChanged: (value) => setState(() => _qrEnabled = value),
                        ),
                        if (_qrEnabled) Container(
                          key: const ValueKey('digitalCard'),
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [
                              Color(0xFF0F172A), Color(0xFF1E293B)]),
                            borderRadius: BorderRadius.circular(20)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(children: [
                                ToothLogo(size: 32, showShadow: false),
                                SizedBox(width: 10),
                                Expanded(child: Text('CLÍNICA DENTAL SONRISAS',
                                    style: TextStyle(color: Colors.white,
                                        fontWeight: FontWeight.w800, fontSize: 11))),
                              ]),
                              const SizedBox(height: 16),
                              Text(widget.user.name,
                                  style: const TextStyle(color: Colors.white,
                                      fontSize: 18, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(widget.user.email,
                                  style: const TextStyle(color: Colors.white70)),
                              const SizedBox(height: 16),
                              const Center(child: Icon(Icons.qr_code_rounded,
                                  color: Colors.white, size: 100)),
                              const Center(child: Text('Vista de demostración · QR no escaneable',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70, fontSize: 11))),
                            ],
                          ),
                        ),
                      ])),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
