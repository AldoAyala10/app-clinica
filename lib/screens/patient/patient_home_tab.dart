import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../models/appointment.dart';
import '../../widgets/patient_dashboard_feedback.dart';
import '../../widgets/patient_appointments_loading.dart';
import '../../widgets/appointment_card.dart';

class PatientHomeTab extends PatientAppointmentsScreen {
  final AppState state;
  final Function(int) onTabChange;
  final PatientAppointmentsLoader? appointmentLoader;

  const PatientHomeTab({
    super.key,
    required this.state,
    required this.onTabChange,
    this.appointmentLoader,
  });

  @override
  State<PatientHomeTab> createState() => _PatientHomeTabState();
}

class _PatientHomeTabState extends State<PatientHomeTab>
    with PatientAppointmentsLoading<PatientHomeTab> {
  List<Appointment> get _upcomingAppointments {
    if (patientStatus != PatientViewStatus.ready) return const [];
    // Con AppState se leen datos actualizados tras agendar/cancelar una cita.
    final source = appointmentSource;
    final today = DateUtils.dateOnly(DateTime.now());
    final result = source
        .where((appointment) =>
            appointment.patientName == widget.state.patientName &&
            !appointment.date.isBefore(today) &&
            (appointment.status == AppointmentStatus.confirmada ||
                appointment.status == AppointmentStatus.pendiente))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _upcomingAppointments;
    final next = upcoming.isEmpty ? null : upcoming.first;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header matching Figma Screen 8
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Hola, ${widget.state.patientName.split(" ").first}!',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tu sonrisa es nuestra prioridad',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person_rounded,
                        color: AppTheme.primaryBlue,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tarjeta principal: estados de carga, error y contenido.
              if (patientStatus == PatientViewStatus.loading)
                const PatientDashboardFeedback(
                  key: Key('patient_home_loading'),
                  loading: true,
                  title: 'Cargando tus citas',
                  message: 'Estamos preparando la información de tus citas.',
                )
              else if (patientStatus == PatientViewStatus.error)
                PatientDashboardFeedback(
                  key: const Key('patient_home_error'),
                  icon: Icons.cloud_off_rounded,
                  title: 'No se pudieron cargar tus citas',
                  message: 'Ocurrió un error al obtener la información. Vuelve a intentarlo.',
                  actionText: 'Reintentar',
                  onAction: refreshAppointments,
                )
              else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0066FF),
                      Color(0xFF004EC2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0066FF).withValues(alpha: 0.35),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PRÓXIMA CITA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                            letterSpacing: 1.2,
                          ),
                        ),
                        if (next != null) Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            next.status.label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      next?.doctorName ?? 'Sin citas próximas',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      next?.specialty ?? 'Agenda una cita para comenzar',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 15,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Flexible(child: Text(
                              next == null ? 'Sin fecha' : '${next.date.day}/${next.date.month}/${next.date.year} · ${next.time}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            )),
                          ],
                        )),
                        ElevatedButton(
                          onPressed: () => widget.onTabChange(next == null ? 2 : 1),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryBlue,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          child: Text(
                            next == null ? 'Agendar' : 'Ver Cita',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Próximas citas',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              if (patientStatus == PatientViewStatus.ready && upcoming.isEmpty)
                PatientDashboardFeedback(
                  key: const Key('patient_home_empty'),
                  icon: Icons.event_available_rounded,
                  title: 'Todavía no tienes citas programadas',
                  message: 'Elige un servicio y agenda tu primera consulta.',
                  actionText: 'Agendar cita',
                  onAction: () => widget.onTabChange(2),
                )
              else if (patientStatus == PatientViewStatus.ready)
                ...upcoming.take(3).map((appointment) => AppointmentCard(
                  appointment: appointment,
                  isDoctorView: false,
                )),
              const SizedBox(height: 12),

              // Services 2x2 Grid matching Figma Screen 8
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Servicios Odontológicos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.onTabChange(2), // Go to Agendar
                    child: const Text(
                      'Agendar',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _buildServiceCard(
                      title: 'Limpieza Dental',
                      icon: Icons.cleaning_services_rounded,
                      color: const Color(0xFF0066FF),
                      bgColor: const Color(0xFFE8F1FF),
                      onTap: () => widget.onTabChange(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildServiceCard(
                      title: 'Ortodoncia',
                      icon: Icons.sentiment_very_satisfied_rounded,
                      color: const Color(0xFF10B981),
                      bgColor: const Color(0xFFE6F9F0),
                      onTap: () => widget.onTabChange(2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildServiceCard(
                      title: 'Endodoncia',
                      icon: Icons.health_and_safety_rounded,
                      color: const Color(0xFFF59E0B),
                      bgColor: const Color(0xFFFEF3C7),
                      onTap: () => widget.onTabChange(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildServiceCard(
                      title: 'Blanqueamiento',
                      icon: Icons.auto_awesome_rounded,
                      color: const Color(0xFF8B5CF6),
                      bgColor: const Color(0xFFF3E8FF),
                      onTap: () => widget.onTabChange(2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Dental Care Tips matching Figma Screen 8
              const Text(
                'Consejos de Cuidado Dental',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              _buildTipCard(
                title: 'Técnica de cepillado correcta',
                description:
                    'Cepilla tus dientes suavemente en círculos durante al menos 2 minutos, 3 veces al día.',
                icon: Icons.brush_rounded,
                color: const Color(0xFF0066FF),
              ),
              const SizedBox(height: 10),
              _buildTipCard(
                title: 'Uso diario de hilo dental',
                description:
                    'El hilo dental remueve placa bacteriana donde el cepillo no alcanza. Hazlo antes de dormir.',
                icon: Icons.waves_rounded,
                color: const Color(0xFF10B981),
              ),
              const SizedBox(height: 10),
              _buildTipCard(
                title: 'Evita bebidas con alta pigmentación',
                description:
                    'Disminuye el consumo de café, té negro o refrescos de cola para mantener tu esmalte brillante.',
                icon: Icons.emoji_food_beverage_rounded,
                color: const Color(0xFFF59E0B),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required String title,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
