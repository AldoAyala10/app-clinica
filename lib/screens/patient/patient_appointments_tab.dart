import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/appointment.dart';
import '../../state/app_state.dart';
import '../../widgets/appointment_card.dart';
import '../../widgets/patient_dashboard_feedback.dart';
import '../../widgets/patient_appointments_loading.dart';

class PatientAppointmentsTab extends PatientAppointmentsScreen {
  @override
  final AppState state;
  final VoidCallback onBookNew;
  @override
  final PatientAppointmentsLoader? appointmentLoader;

  const PatientAppointmentsTab({
    super.key,
    required this.state,
    required this.onBookNew,
    this.appointmentLoader,
  });

  @override
  State<PatientAppointmentsTab> createState() => _PatientAppointmentsTabState();
}

class _PatientAppointmentsTabState extends State<PatientAppointmentsTab>
    with PatientAppointmentsLoading<PatientAppointmentsTab> {
  int _selectedTabIndex = 0; // 0: Próximas, 1: Historial
  @override
  Widget build(BuildContext context) {
    // AppState ya trae solo las citas de este paciente (por uid).
    final patientAppointments = appointmentSource;
    final today = DateUtils.dateOnly(DateTime.now());
    final upcoming = patientAppointments
        .where((a) =>
            !a.date.isBefore(today) &&
            (a.status == AppointmentStatus.confirmada ||
                a.status == AppointmentStatus.pendiente))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final past = patientAppointments
        .where((a) =>
        a.status != AppointmentStatus.cancelada &&
        (a.status == AppointmentStatus.completada ||
          a.date.isBefore(today)))
        .toList();
    final activeList = _selectedTabIndex == 0 ? upcoming : past;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header matching Figma Screen 9
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mis Citas',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: widget.onBookNew,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      'Nueva',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Segmented Control Tabs (Próximas | Historial)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.softShadow,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTabIndex = 0;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 0
                                ? AppTheme.primaryBlue
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _selectedTabIndex == 0
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryBlue
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              'Próximas (${upcoming.length})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _selectedTabIndex == 0
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTabIndex = 1;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 1
                                ? AppTheme.primaryBlue
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _selectedTabIndex == 1
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryBlue
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              'Historial (${past.length})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _selectedTabIndex == 1
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Estado de la lista: cargando, error, vacío o resultados.
              Expanded(
                child: patientStatus == PatientViewStatus.loading
                    ? const Center(
                        child: PatientDashboardFeedback(
                          key: Key('patient_appointments_loading'),
                          loading: true,
                          title: 'Cargando tus citas',
                          message: 'Un momento, estamos preparando tu agenda.',
                        ),
                      )
                    : patientStatus == PatientViewStatus.error
                        ? Center(
                            child: PatientDashboardFeedback(
                              key: const Key('patient_appointments_error'),
                              icon: Icons.cloud_off_rounded,
                              title: 'No pudimos obtener tus citas',
                              message: 'No se pudo consultar tu agenda. Inténtalo otra vez.',
                              actionText: 'Reintentar',
                              onAction: refreshAppointments,
                            ),
                          )
                        : activeList.isEmpty
                            ? Center(
                                child: PatientDashboardFeedback(
                                  key: const Key('patient_appointments_empty'),
                                  icon: Icons.event_available_rounded,
                                  title: _selectedTabIndex == 0
                                      ? 'No tienes citas próximas agendadas'
                                      : 'No hay citas en tu historial',
                                  message: _selectedTabIndex == 0
                                      ? 'Agenda una consulta para empezar.'
                                      : 'Tus citas completadas aparecerán aquí.',
                                  actionText: 'Agendar cita',
                                  onAction: widget.onBookNew,
                                ),
                              )
                            : ListView.builder(
                                itemCount: activeList.length,
                                itemBuilder: (context, index) {
                                  final source = activeList[index];
                                  final appointment = _selectedTabIndex == 1 &&
                                          source.status !=
                                              AppointmentStatus.completada
                                      ? source.copyWith(
                                          status: AppointmentStatus.completada,
                                        )
                                      : source;
                                  return AppointmentCard(
                                    appointment: appointment,
                                    isDoctorView: false,
                                    onTap: () => _showAppointmentDetails(
                                        context, appointment),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAppointmentDetails(BuildContext context, Appointment app) {
    final today = DateUtils.dateOnly(DateTime.now());
    final canModify = !app.date.isBefore(today) &&
      (app.status == AppointmentStatus.confirmada ||
        app.status == AppointmentStatus.pendiente);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    app.doctorName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: app.status.bgLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      app.status.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: app.status.color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Especialidad: ${app.specialty}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Horario: ${app.time}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (app.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Indicaciones del consultorio:\n${app.notes}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (canModify) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _rescheduleAppointment(app);
                        },
                        icon: const Icon(Icons.edit_calendar_outlined),
                        label: const Text('Reprogramar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _cancelAppointment(app);
                        },
                        icon: const Icon(Icons.event_busy_outlined),
                        label: const Text('Cancelar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorRed,
                          side: const BorderSide(color: AppTheme.errorRed),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _cancelAppointment(Appointment appointment) async {
    try {
      await widget.state.updateAppointmentStatus(
        appointment.id,
        AppointmentStatus.cancelada,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La cita se canceló correctamente.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cancelar la cita. Intenta de nuevo.'),
        ),
      );
    }
  }

  Future<void> _rescheduleAppointment(Appointment appointment) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate: today.add(const Duration(days: 1)),
      firstDate: today.add(const Duration(days: 1)),
      lastDate: today.add(const Duration(days: 180)),
      helpText: 'Selecciona una nueva fecha',
    );
    if (date == null || !mounted) return;

    const times = [
      '09:00 AM',
      '10:30 AM',
      '12:00 PM',
      '03:00 PM',
      '04:30 PM',
      '06:00 PM',
    ];
    final time = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Selecciona un horario'),
        children: times
            .map((value) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(dialogContext, value),
                  child: Text(value),
                ))
            .toList(),
      ),
    );
    if (time == null || !mounted) return;

    try {
      await widget.state.rescheduleAppointment(
        appointment: appointment,
        date: date,
        time: time,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La cita se reprogramó correctamente.')),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is StateError
          ? error.message.toString()
          : 'No se pudo reprogramar la cita. Intenta de nuevo.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
