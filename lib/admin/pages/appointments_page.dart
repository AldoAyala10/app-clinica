import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/appointment.dart';
import '../../theme/app_theme.dart';
import '../admin_state.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/appointment_form_dialog.dart';

enum AppointmentRange { upcoming, today, past, all }

/// US05: crear, modificar, confirmar y cancelar citas validando horarios.
class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key, required this.state});

  final AdminState state;

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  String _query = '';
  AppointmentRange _range = AppointmentRange.upcoming;
  AppointmentStatus? _status;
  String? _doctorId;

  List<Appointment> get _visibleAppointments {
    final today = DateUtils.dateOnly(DateTime.now());
    final q = _query.trim().toLowerCase();
    final list = widget.state.appointments.where((a) {
      final day = DateUtils.dateOnly(a.date);
      final inRange = switch (_range) {
        AppointmentRange.upcoming => !day.isBefore(today),
        AppointmentRange.today => day == today,
        AppointmentRange.past => day.isBefore(today),
        AppointmentRange.all => true,
      };
      if (!inRange) return false;
      if (_status != null && a.status != _status) return false;
      if (_doctorId != null && a.doctorId != _doctorId) return false;
      if (q.isEmpty) return true;
      return a.patientName.toLowerCase().contains(q) ||
          a.doctorName.toLowerCase().contains(q) ||
          a.specialty.toLowerCase().contains(q);
    }).toList();
    // Las pasadas, de la más reciente a la más antigua.
    if (_range == AppointmentRange.past) {
      list.sort((a, b) => b.date.compareTo(a.date));
    }
    return list;
  }

  void _showMessage(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? AppTheme.errorRed : AppTheme.successGreen,
      ),
    );
  }

  Future<void> _openForm([Appointment? appointment]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppointmentFormDialog(
        state: widget.state,
        appointment: appointment,
      ),
    );
    if (saved == true) {
      _showMessage(appointment == null ? 'Cita agendada.' : 'Cita modificada.');
    }
  }

  Future<void> _confirm(Appointment a) async {
    try {
      await widget.state.confirmAppointment(a);
      _showMessage('Cita de ${a.patientName} confirmada.');
    } catch (_) {
      _showMessage('No se pudo confirmar la cita.', error: true);
    }
  }

  Future<void> _cancel(Appointment a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar cita'),
        content: Text(
          '¿Cancelar la cita de ${a.patientName} con ${a.doctorName}? '
          'El horario quedará libre para otro paciente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar cita'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.state.cancelAppointment(a);
      _showMessage('Cita cancelada.');
    } catch (_) {
      _showMessage('No se pudo cancelar la cita.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final appointments = _visibleAppointments;
    final pending = state.appointments
        .where((a) => a.status == AppointmentStatus.pendiente)
        .length;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        AdminPageHeader(
          title: 'Citas',
          subtitle: '${state.appointments.length} en total · '
              '$pending pendientes de confirmar',
          actionLabel: 'Nueva cita',
          actionIcon: Icons.add_rounded,
          onAction: _openForm,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 280,
              child: TextField(
                key: const Key('appointments_search'),
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Paciente, odontólogo o tratamiento',
                  isDense: true,
                ),
              ),
            ),
            SegmentedButton<AppointmentRange>(
              segments: const [
                ButtonSegment(
                    value: AppointmentRange.upcoming, label: Text('Próximas')),
                ButtonSegment(value: AppointmentRange.today, label: Text('Hoy')),
                ButtonSegment(
                    value: AppointmentRange.past, label: Text('Pasadas')),
                ButtonSegment(value: AppointmentRange.all, label: Text('Todas')),
              ],
              selected: {_range},
              onSelectionChanged: (s) => setState(() => _range = s.first),
            ),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<AppointmentStatus?>(
                key: const Key('appointments_status_filter'),
                initialValue: _status,
                isDense: true,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  for (final s in AppointmentStatus.values)
                    DropdownMenuItem(value: s, child: Text(s.label)),
                ],
                onChanged: (s) => setState(() => _status = s),
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String?>(
                key: const Key('appointments_doctor_filter'),
                initialValue: _doctorId,
                isDense: true,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Odontólogo'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  for (final d in state.doctors)
                    DropdownMenuItem(value: d.id, child: Text(d.name)),
                ],
                onChanged: (id) => setState(() => _doctorId = id),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!state.appointmentsLoaded)
          const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (appointments.isEmpty)
          const AdminEmptyState(
            key: Key('appointments_empty'),
            icon: Icons.event_busy_rounded,
            message: 'No hay citas con estos filtros.',
          )
        else
          PaginatedDataTable(
            key: const Key('appointments_table'),
            rowsPerPage: appointments.length < 10 ? appointments.length : 10,
            showCheckboxColumn: false,
            columnSpacing: 20,
            columns: const [
              DataColumn(label: Text('Fecha')),
              DataColumn(label: Text('Hora')),
              DataColumn(label: Text('Paciente')),
              DataColumn(label: Text('Odontólogo')),
              DataColumn(label: Text('Consultorio')),
              DataColumn(label: Text('Tratamiento')),
              DataColumn(label: Text('Estado')),
              DataColumn(label: Text('Acciones')),
            ],
            source: _AppointmentsSource(
              appointments,
              onConfirm: _confirm,
              onEdit: _openForm,
              onCancel: _cancel,
            ),
          ),
      ],
    );
  }
}

class _AppointmentsSource extends DataTableSource {
  _AppointmentsSource(
    this.appointments, {
    required this.onConfirm,
    required this.onEdit,
    required this.onCancel,
  });

  final List<Appointment> appointments;
  final void Function(Appointment) onConfirm;
  final void Function(Appointment) onEdit;
  final void Function(Appointment) onCancel;

  static final _dateFormat = DateFormat('EEE dd/MM/yyyy', 'es');

  @override
  DataRow? getRow(int index) {
    if (index >= appointments.length) return null;
    final a = appointments[index];
    final open = a.status == AppointmentStatus.pendiente ||
        a.status == AppointmentStatus.confirmada;
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(_dateFormat.format(a.date))),
        DataCell(Text(a.time)),
        DataCell(Text(a.patientName,
            style: const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(Text(a.doctorName)),
        DataCell(Text(a.office.isEmpty ? '—' : a.office)),
        DataCell(Text(a.specialty)),
        DataCell(StatusChip(label: a.status.label, color: a.status.color)),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (a.status == AppointmentStatus.pendiente)
              IconButton(
                tooltip: 'Confirmar',
                icon: const Icon(Icons.check_circle_outline_rounded,
                    size: 20, color: AppTheme.successGreen),
                onPressed: () => onConfirm(a),
              ),
            IconButton(
              tooltip: 'Modificar',
              icon: const Icon(Icons.edit_calendar_outlined, size: 20),
              onPressed: open ? () => onEdit(a) : null,
            ),
            IconButton(
              tooltip: 'Cancelar',
              icon: Icon(Icons.event_busy_outlined,
                  size: 20, color: open ? AppTheme.errorRed : null),
              onPressed: open ? () => onCancel(a) : null,
            ),
          ],
        )),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => appointments.length;

  @override
  int get selectedRowCount => 0;
}
