import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../models/appointment.dart';
import '../../models/doctor.dart';
import '../../widgets/custom_button.dart';

class BookAppointmentTab extends StatefulWidget {
  final AppState state;
  final VoidCallback onAppointmentBooked;

  const BookAppointmentTab({
    super.key,
    required this.state,
    required this.onAppointmentBooked,
  });

  @override
  State<BookAppointmentTab> createState() => _BookAppointmentTabState();
}

class _BookAppointmentTabState extends State<BookAppointmentTab> {
  int _selectedTreatmentIndex = 0;
  int _selectedDoctorIndex = 1; // Dra. Sofía Vega selected
  int _selectedTimeIndex = 1; // 10:30 AM selected
  late DateTime _selectedDate;
  final TextEditingController _reasonController = TextEditingController();
  String? _reasonError;
  bool _isSubmitting = false;

  final List<String> _treatments = [
    'Limpieza',
    'Ortodoncia',
    'Endodoncia',
    'Extracción',
    'Blanqueamiento',
  ];

  late final List<DateTime> _calendarDates = List.generate(
    7, (index) => DateUtils.dateOnly(DateTime.now()).add(Duration(days: index + 1)),
  );
  static const _weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  final List<String> _timeSlots = [
    '09:00 AM',
    '10:30 AM',
    '12:00 PM',
    '03:00 PM',
    '04:30 PM',
    '06:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = _calendarDates[3];
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final firstDate = today.add(const Duration(days: 1));
    final lastDate = today.add(const Duration(days: 180));
    final initialDate = _selectedDate.isAfter(lastDate) ? lastDate : _selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Selecciona la fecha de tu cita',
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleConfirmBooking() async {
    if (_isSubmitting) return;
    final reason = _reasonController.text.trim();
    if (reason.length < 5) {
      setState(() => _reasonError = 'Escribe al menos 5 caracteres para el motivo.');
      return;
    }

    final doctor = widget.state.doctors[_selectedDoctorIndex];
    final treatment = _treatments[_selectedTreatmentIndex];
    final time = _timeSlots[_selectedTimeIndex];
    final date = _selectedDate;
    final today = DateUtils.dateOnly(DateTime.now());

    if (!date.isAfter(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una fecha futura.')),
      );
      return;
    }

    // Validación local provisional: el backend deberá comprobar el horario
    // nuevamente antes de crear la cita, para evitar reservas simultáneas.
    final occupied = widget.state.appointments.any(
      (appointment) =>
          appointment.doctorName == doctor.name &&
          DateUtils.isSameDay(appointment.date, date) &&
          appointment.time.split(' - ').first == time &&
          (appointment.status == AppointmentStatus.confirmada ||
              appointment.status == AppointmentStatus.pendiente),
    );
    if (occupied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ese horario ya está ocupado para el odontólogo elegido.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // Solo demostración visual del loading. Reemplazar este Future y el
      // guardado local por la llamada asíncrona al repositorio real.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      widget.state.addAppointment(
        patientName: widget.state.patientName,
        doctorName: doctor.name,
        specialty: treatment,
        date: date,
        time: time,
        notes: reason,
      );
      _reasonController.clear();

      showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppTheme.successBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppTheme.successGreen,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                '¡Cita Agendada!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tu cita con ${doctor.name} para $treatment el ${date.day}/${date.month}/${date.year} a las $time se registró en modo demostración (solo en memoria).',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              CustomButton(
                text: 'Aceptar',
                onPressed: () {
                  Navigator.pop(context);
                  widget.onAppointmentBooked();
                },
              ),
            ],
          ),
        );
      },
    );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo agendar la cita. Intenta de nuevo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

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
              // Header matching Figma Screen 10
              const Text(
                'Agendar Cita',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Elige especialidad, profesional, fecha y hora',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Section 1: Selecciona Tratamiento
              const Text(
                'Selecciona Tratamiento',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _treatments.length,
                  itemBuilder: (context, index) {
                    final item = _treatments[index];
                    final isSelected = index == _selectedTreatmentIndex;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTreatmentIndex = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryBlue
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryBlue
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : AppTheme.softShadow,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              item,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Section 2: Selecciona Odontólogo matching Figma Screen 10
              const Text(
                'Selecciona Odontólogo',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(
                  widget.state.doctors.take(2).length,
                  (index) {
                    final doc = widget.state.doctors[index];
                    final isSelected = index == _selectedDoctorIndex;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: index == 0 ? 6 : 0,
                          left: index == 1 ? 6 : 0,
                        ),
                        child: _buildDoctorCard(doc, isSelected, () {
                          setState(() {
                            _selectedDoctorIndex = index;
                          });
                        }),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Section 3: Selecciona Fecha matching Figma Screen 10
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Selecciona Fecha',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  TextButton.icon(
                    key: const Key('book_date_picker'),
                    onPressed: _isSubmitting ? null : _pickDate,
                    icon: const Icon(Icons.calendar_month_rounded, size: 18),
                    label: const Text('Calendario'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _calendarDates.length,
                  itemBuilder: (context, index) {
                    final date = _calendarDates[index];
                    final isSelected = DateUtils.isSameDay(date, _selectedDate);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                      child: Container(
                        width: 52,
                        margin: const EdgeInsets.only(right: 8, bottom: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryBlue
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryBlue
                                        .withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : AppTheme.softShadow,
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _weekdays[date.weekday - 1],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white70
                                    : AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fecha seleccionada: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              // Section 4: Horas disponibles matching Figma Screen 10
              const Text(
                'Horas disponibles',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(_timeSlots.length, (index) {
                  final time = _timeSlots[index];
                  final isSelected = index == _selectedTimeIndex;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTimeIndex = index;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryBlue : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryBlue
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : AppTheme.softShadow,
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 28),

              // Motivo requerido por la HU-08 (Sprint 3).
              const Text(
                'Motivo de la consulta',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('booking_reason_field'),
                controller: _reasonController,
                maxLength: 250,
                minLines: 2,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) {
                  if (_reasonError != null) {
                    setState(() => _reasonError = null);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Describe brevemente qué necesitas consultar...',
                  errorText: _reasonError,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Submit Button matching Figma Screen 10
              CustomButton(
                text: 'Confirmar Cita',
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _handleConfirmBooking,
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Modo demostración: la cita no se guarda en un servidor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doc, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  )
                ]
              : AppTheme.softShadow,
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryBlue.withValues(alpha: 0.12)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.medical_services_rounded,
                color: isSelected ? AppTheme.primaryBlue : AppTheme.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              doc.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              doc.specialty,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
