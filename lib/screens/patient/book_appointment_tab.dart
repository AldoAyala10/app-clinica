import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
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
  int _selectedDayIndex = 3; // 17 Octubre selected
  int _selectedTimeIndex = 1; // 10:30 AM selected

  final List<String> _treatments = [
    'Limpieza',
    'Ortodoncia',
    'Endodoncia',
    'Extracción',
    'Blanqueamiento',
  ];

  final List<Map<String, String>> _calendarDays = [
    {'day': 'Lun', 'date': '14'},
    {'day': 'Mar', 'date': '15'},
    {'day': 'Mié', 'date': '16'},
    {'day': 'Jue', 'date': '17'},
    {'day': 'Vie', 'date': '18'},
    {'day': 'Sáb', 'date': '19'},
    {'day': 'Dom', 'date': '20'},
  ];

  final List<String> _timeSlots = [
    '09:00 AM',
    '10:30 AM',
    '12:00 PM',
    '03:00 PM',
    '04:30 PM',
    '06:00 PM',
  ];

  void _handleConfirmBooking() {
    final doctor = widget.state.doctors[_selectedDoctorIndex];
    final treatment = _treatments[_selectedTreatmentIndex];
    final time = _timeSlots[_selectedTimeIndex];
    final day = _calendarDays[_selectedDayIndex]['date'];

    widget.state.addAppointment(
      patientName: widget.state.patientName,
      doctorName: doctor.name,
      specialty: treatment,
      date: DateTime(2024, 10, int.tryParse(day ?? '17') ?? 17),
      time: time,
    );

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
                'Tu cita con ${doctor.name} para $treatment el $day de Octubre a las $time ha sido confirmada.',
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
                  Text(
                    'Octubre 2024',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _calendarDays.length,
                  itemBuilder: (context, index) {
                    final item = _calendarDays[index];
                    final isSelected = index == _selectedDayIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDayIndex = index;
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
                              item['day']!,
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
                              item['date']!,
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
              const SizedBox(height: 32),

              // Submit Button matching Figma Screen 10
              CustomButton(
                text: 'Confirmar Cita',
                onPressed: _handleConfirmBooking,
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
