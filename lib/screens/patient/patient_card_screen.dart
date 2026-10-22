import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/patient.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tooth_logo.dart';

/// US04: carnet digital del paciente con un QR único generado a partir de su
/// ID, para identificarse al llegar a la clínica.
class PatientCardScreen extends StatelessWidget {
  const PatientCardScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final patientId = state.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text('Mi carnet digital'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) => patientId == null
            ? const Center(child: Text('Inicia sesión para ver tu carnet.'))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _CardFront(state: state, patientId: patientId),
                    const SizedBox(height: 20),
                    const Text(
                      'Muestra este código en recepción al llegar a tu cita.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CardFront extends StatelessWidget {
  const _CardFront({required this.state, required this.patientId});

  final AppState state;
  final String patientId;

  /// Código corto y legible para dictarlo si el QR no se puede leer.
  String get _shortCode => patientId.length <= 8
      ? patientId.toUpperCase()
      : patientId.substring(0, 8).toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('patient_card'),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.cardShadow,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryBlue, AppTheme.primaryDarkBlue],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                const ToothLogo(size: 44),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CLÍNICA DENTAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Carnet de paciente',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Paciente',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                Text(
                  state.patientName.isEmpty ? 'Paciente' : state.patientName,
                  key: const Key('patient_card_name'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                QrImageView(
                  key: const Key('patient_card_qr'),
                  data: patientQrPayload(patientId),
                  size: 200,
                  backgroundColor: Colors.white,
                  semanticsLabel: 'Código QR del paciente',
                ),
                const SizedBox(height: 12),
                Text(
                  'ID: $_shortCode',
                  key: const Key('patient_card_code'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const Divider(height: 28),
                _InfoRow(icon: Icons.email_outlined, value: state.patientEmail),
                _InfoRow(icon: Icons.phone_outlined, value: state.patientPhone),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
