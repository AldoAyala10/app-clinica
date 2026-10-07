import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/appointment.dart';
import '../../state/app_state.dart';
import '../../widgets/appointment_card.dart';

class DoctorAgendaTab extends StatefulWidget {
  final AppState state;

  const DoctorAgendaTab({super.key, required this.state});

  @override
  State<DoctorAgendaTab> createState() => _DoctorAgendaTabState();
}

class _DoctorAgendaTabState extends State<DoctorAgendaTab> {
  int _selectedDayIndex = 3; // Selected day in horizontal carousel
  int _selectedFilterIndex = 0; // 0: Todas, 1: Confirmadas, 2: Pendientes

  final List<Map<String, String>> _days = [
    {'day': 'D', 'date': '12'},
    {'day': 'L', 'date': '13'},
    {'day': 'M', 'date': '14'},
    {'day': 'M', 'date': '15'},
    {'day': 'J', 'date': '16'},
    {'day': 'V', 'date': '17'},
    {'day': 'S', 'date': '18'},
  ];

  final List<String> _filters = ['Todas', 'Confirmadas', 'Pendientes'];

  @override
  Widget build(BuildContext context) {
    List<Appointment> filteredAppointments = widget.state.appointments;
    if (_selectedFilterIndex == 1) {
      filteredAppointments = filteredAppointments
          .where((a) => a.status == AppointmentStatus.confirmada)
          .toList();
    } else if (_selectedFilterIndex == 2) {
      filteredAppointments = filteredAppointments
          .where((a) => a.status == AppointmentStatus.pendiente)
          .toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      floatingActionButton: FloatingActionButton(
        heroTag: 'doctor_agenda_fab',
        onPressed: () => _showNewAppointmentModal(context),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Agenda',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.softShadow,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Row(
                      children: [
                        Text(
                          'Octubre 2024',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal Days Carousel matching Figma Screen 6
            SizedBox(
              height: 82,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _days.length,
                itemBuilder: (context, index) {
                  final item = _days[index];
                  final isSelected = index == _selectedDayIndex;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDayIndex = index;
                      });
                    },
                    child: Container(
                      width: 52,
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryBlue : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : AppTheme.softShadow,
                        border: Border.all(
                          color: isSelected ? Colors.transparent : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['day']!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white70 : AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['date']!,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Filter Chips (Todas, Confirmadas, Pendientes)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(_filters.length, (index) {
                  final isSelected = _selectedFilterIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(_filters[index]),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                      ),
                      backgroundColor: Colors.white,
                      selectedColor: AppTheme.primaryBlue,
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected ? Colors.transparent : Colors.grey.shade300,
                        ),
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedFilterIndex = index;
                        });
                      },
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),

            // List of Appointments for the selected day
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: filteredAppointments.length,
                itemBuilder: (context, index) {
                  final app = filteredAppointments[index];
                  return AppointmentCard(
                    appointment: app,
                    isDoctorView: true,
                    onTap: () {},
                    onStatusToggle: () {
                      final next = app.status == AppointmentStatus.confirmada
                          ? AppointmentStatus.pendiente
                          : AppointmentStatus.confirmada;
                      widget.state.updateAppointmentStatus(app.id, next);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewAppointmentModal(BuildContext context) {
    final patientNameCtrl = TextEditingController();
    final specialtyCtrl = TextEditingController(text: 'Limpieza Dental');
    final timeCtrl = TextEditingController(text: '12:00 PM');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Agendar Nueva Cita',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: patientNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Paciente',
                  hintText: 'Ej. Laura Fuentes',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: specialtyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Procedimiento / Tratamiento',
                  hintText: 'Ej. Ortodoncia, Limpieza',
                  prefixIcon: Icon(Icons.medical_services_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: timeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Horario',
                  hintText: 'Ej. 09:30 AM',
                  prefixIcon: Icon(Icons.access_time_rounded),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (patientNameCtrl.text.isNotEmpty) {
                    widget.state.addAppointment(
                      patientName: patientNameCtrl.text.trim(),
                      doctorName: widget.state.doctorName,
                      specialty: specialtyCtrl.text.trim(),
                      date: DateTime.now(),
                      time: timeCtrl.text.trim(),
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Confirmar y Guardar',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
