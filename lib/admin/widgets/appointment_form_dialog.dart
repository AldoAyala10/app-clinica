import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/appointment.dart';
import '../../models/doctor.dart';
import '../../theme/app_theme.dart';
import '../admin_state.dart';

/// Crea (sin [appointment]) o modifica una cita. Muestra qué horarios del
/// odontólogo ya están ocupados ese día y valida antes de guardar.
/// Devuelve true si se guardó.
class AppointmentFormDialog extends StatefulWidget {
  const AppointmentFormDialog({super.key, required this.state, this.appointment});

  final AdminState state;
  final Appointment? appointment;

  @override
  State<AppointmentFormDialog> createState() => _AppointmentFormDialogState();
}

class _AppointmentFormDialogState extends State<AppointmentFormDialog> {
  late final Appointment? _original = widget.appointment;
  bool get _editing => _original != null;

  String? _patientId;
  late Doctor _doctor;
  late String _treatment;
  late DateTime _date;
  String? _time;
  late final TextEditingController _notes;

  Set<String> _taken = {};
  bool _loadingSlots = false;
  bool _saving = false;
  String? _error;

  List<String> get _treatments => {
        ...kTreatments,
        if (_original != null) _original.specialty,
      }.toList();

  @override
  void initState() {
    super.initState();
    final a = _original;
    final today = DateUtils.dateOnly(DateTime.now());
    _patientId = a?.patientRecordId;
    _doctor = doctorById(a?.doctorId) ??
        widget.state.doctors.firstWhere(
          (d) => d.name == a?.doctorName,
          orElse: () => widget.state.doctors.first,
        );
    _treatment = a?.specialty ?? kTreatments.first;
    _date = a != null ? DateUtils.dateOnly(a.date) : today.add(const Duration(days: 1));
    _time = a?.time;
    _notes = TextEditingController(text: a?.notes);
    _loadTaken();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  /// El horario original de la cita que se edita no cuenta como ocupado.
  bool _isOwnSlot(String time) {
    final a = _original;
    return a != null &&
        a.doctorId == _doctor.id &&
        DateUtils.isSameDay(a.date, _date) &&
        a.time == time;
  }

  Future<void> _loadTaken() async {
    setState(() => _loadingSlots = true);
    final doctor = _doctor;
    final date = _date;
    final taken = await widget.state.takenTimes(doctor, date);
    if (!mounted || doctor != _doctor || date != _date) return;
    setState(() {
      _taken = taken.where((t) => !_isOwnSlot(t)).toSet();
      _loadingSlots = false;
      if (_time != null && _taken.contains(_time)) _time = null;
    });
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Fecha de la cita',
    );
    if (picked == null) return;
    setState(() => _date = picked);
    _loadTaken();
  }

  Future<void> _save() async {
    final patient = _editing ? null : widget.state.patientById(_patientId ?? '');
    if (!_editing && patient == null) {
      setState(() => _error = 'Selecciona un paciente.');
      return;
    }
    final time = _time;
    if (time == null) {
      setState(() => _error = 'Selecciona un horario disponible.');
      return;
    }
    if (_date.isBefore(DateUtils.dateOnly(DateTime.now()))) {
      setState(() => _error = 'La fecha no puede estar en el pasado.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_editing) {
        await widget.state.updateAppointment(
          appointment: _original!,
          doctor: _doctor,
          specialty: _treatment,
          date: _date,
          time: time,
          notes: _notes.text.trim(),
        );
      } else {
        await widget.state.createAppointment(
          patient: patient!,
          doctor: _doctor,
          specialty: _treatment,
          date: _date,
          time: time,
          notes: _notes.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } on StateError catch (e) {
      // Otro usuario ganó el horario mientras se llenaba el formulario.
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
      _loadTaken();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'No se pudo guardar la cita. Intenta de nuevo.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat("EEEE d 'de' MMMM yyyy", 'es').format(_date);

    return AlertDialog(
      title: Text(_editing ? 'Modificar cita' : 'Nueva cita'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_editing)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline_rounded),
                  title: Text(_original!.patientName),
                  subtitle: const Text('Paciente'),
                )
              else
                DropdownButtonFormField<String>(
                  key: const Key('appointment_form_patient'),
                  initialValue: _patientId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Paciente *',
                    hintText: widget.state.activePatients.isEmpty
                        ? 'No hay pacientes activos'
                        : 'Selecciona un paciente',
                  ),
                  items: [
                    for (final p in widget.state.activePatients)
                      DropdownMenuItem(value: p.id, child: Text(p.name)),
                  ],
                  onChanged: (id) => setState(() => _patientId = id),
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const Key('appointment_form_doctor'),
                initialValue: _doctor.id,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Odontólogo *'),
                items: [
                  for (final d in widget.state.doctors)
                    DropdownMenuItem(
                      value: d.id,
                      child: Text('${d.name} · ${d.office}'),
                    ),
                ],
                onChanged: (id) {
                  if (id == null) return;
                  setState(() => _doctor = doctorById(id)!);
                  _loadTaken();
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const Key('appointment_form_treatment'),
                initialValue: _treatment,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Tratamiento *'),
                items: [
                  for (final t in _treatments)
                    DropdownMenuItem(value: t, child: Text(t)),
                ],
                onChanged: (t) => setState(() => _treatment = t ?? _treatment),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const Key('appointment_form_date'),
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month_rounded),
                label: Text(dateLabel),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Horario',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  if (_loadingSlots)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in kTimeSlots)
                    ChoiceChip(
                      key: Key('slot_$t'),
                      label: Text(_taken.contains(t) ? '$t · ocupado' : t),
                      selected: _time == t,
                      onSelected: _taken.contains(t) || _loadingSlots
                          ? null
                          : (_) => setState(() => _time = t),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('appointment_form_notes'),
                controller: _notes,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Notas / motivo'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  key: const Key('appointment_form_error'),
                  style: const TextStyle(
                    color: AppTheme.errorRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('appointment_form_save'),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_editing ? 'Guardar cambios' : 'Agendar cita'),
        ),
      ],
    );
  }
}
