import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/appointment.dart';
import '../../models/patient.dart';
import '../../theme/app_theme.dart';
import '../admin_state.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/patient_form_dialog.dart';

enum PatientFilter { active, inactive, all }

/// US03: alta, consulta, edición y baja de pacientes.
class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key, required this.state});

  final AdminState state;

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  String _query = '';
  PatientFilter _filter = PatientFilter.active;

  List<Patient> get _visiblePatients {
    final q = patientIdFromQr(_query).toLowerCase();
    return widget.state.patients.where((p) {
      final matchesFilter = switch (_filter) {
        PatientFilter.active => p.active,
        PatientFilter.inactive => !p.active,
        PatientFilter.all => true,
      };
      if (!matchesFilter) return false;
      if (q.isEmpty) return true;
      // El id permite buscar con el código del carnet digital del paciente.
      return p.name.toLowerCase().contains(q) ||
          p.email.toLowerCase().contains(q) ||
          p.phone.contains(q) ||
          p.id.toLowerCase() == q ||
          (p.userId?.toLowerCase() == q);
    }).toList();
  }

  void _showMessage(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? AppTheme.errorRed : AppTheme.successGreen,
      ),
    );
  }

  Future<void> _create() async {
    final data = await showDialog<PatientFormData>(
      context: context,
      builder: (_) => const PatientFormDialog(),
    );
    if (data == null) return;
    try {
      await widget.state.createPatient(
        name: data.name,
        phone: data.phone,
        email: data.email,
        treatment: data.treatment,
        medicalAlerts: data.medicalAlerts,
      );
      _showMessage('Paciente ${data.name} dado de alta.');
    } catch (e) {
      _showMessage('No se pudo dar de alta al paciente.', error: true);
    }
  }

  Future<void> _edit(Patient patient) async {
    final data = await showDialog<PatientFormData>(
      context: context,
      builder: (_) => PatientFormDialog(patient: patient),
    );
    if (data == null) return;
    try {
      await widget.state.updatePatient(patient.copyWith(
        name: data.name,
        phone: data.phone,
        email: data.email,
        treatment: data.treatment,
        medicalAlerts: data.medicalAlerts,
      ));
      _showMessage('Datos de ${data.name} actualizados.');
    } catch (e) {
      _showMessage('No se pudieron guardar los cambios.', error: true);
    }
  }

  Future<void> _toggleActive(Patient patient) async {
    if (patient.active) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Dar de baja paciente'),
          content: Text(
            '${patient.name} dejará de aparecer en las listas y no se le '
            'podrán agendar citas. Su historial se conserva y puedes '
            'reactivarlo después.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Dar de baja'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await widget.state.deactivatePatient(patient);
      _showMessage('${patient.name} fue dado de baja.');
    } else {
      await widget.state.reactivatePatient(patient);
      _showMessage('${patient.name} fue reactivado.');
    }
  }

  void _showDetail(Patient patient) {
    final history = widget.state.appointments
        .where((a) =>
            a.patientRecordId == patient.id ||
            (patient.userId != null && a.patientId == patient.userId))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    showDialog<void>(
      context: context,
      builder: (_) => _PatientDetailDialog(patient: patient, history: history),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final patients = _visiblePatients;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        AdminPageHeader(
          title: 'Pacientes',
          subtitle: '${state.activePatients.length} activos · '
              '${state.patients.length - state.activePatients.length} dados de baja',
          actionLabel: 'Nuevo paciente',
          actionIcon: Icons.person_add_alt_1_rounded,
          onAction: _create,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 320,
              child: TextField(
                key: const Key('patients_search'),
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Buscar por nombre, correo, teléfono o ID',
                  isDense: true,
                ),
              ),
            ),
            SegmentedButton<PatientFilter>(
              segments: const [
                ButtonSegment(
                    value: PatientFilter.active, label: Text('Activos')),
                ButtonSegment(
                    value: PatientFilter.inactive,
                    label: Text('Dados de baja')),
                ButtonSegment(value: PatientFilter.all, label: Text('Todos')),
              ],
              selected: {_filter},
              onSelectionChanged: (s) => setState(() => _filter = s.first),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!state.patientsLoaded)
          const Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (patients.isEmpty)
          const AdminEmptyState(
            key: Key('patients_empty'),
            icon: Icons.person_search_rounded,
            message: 'No hay pacientes que coincidan con la búsqueda.',
          )
        else
          PaginatedDataTable(
            key: const Key('patients_table'),
            rowsPerPage: patients.length < 10 ? patients.length : 10,
            showCheckboxColumn: false,
            columnSpacing: 24,
            columns: const [
              DataColumn(label: Text('Nombre')),
              DataColumn(label: Text('Teléfono')),
              DataColumn(label: Text('Correo')),
              DataColumn(label: Text('Tratamiento')),
              DataColumn(label: Text('App')),
              DataColumn(label: Text('Estado')),
              DataColumn(label: Text('Acciones')),
            ],
            source: _PatientsSource(
              patients,
              onView: _showDetail,
              onEdit: _edit,
              onToggleActive: _toggleActive,
            ),
          ),
      ],
    );
  }
}

class _PatientsSource extends DataTableSource {
  _PatientsSource(
    this.patients, {
    required this.onView,
    required this.onEdit,
    required this.onToggleActive,
  });

  final List<Patient> patients;
  final void Function(Patient) onView;
  final void Function(Patient) onEdit;
  final void Function(Patient) onToggleActive;

  @override
  DataRow? getRow(int index) {
    if (index >= patients.length) return null;
    final p = patients[index];
    return DataRow.byIndex(
      index: index,
      onSelectChanged: (_) => onView(p),
      cells: [
        DataCell(Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600))),
        DataCell(Text(p.phone)),
        DataCell(Text(p.email)),
        DataCell(Text(p.treatment.isEmpty ? '—' : p.treatment)),
        DataCell(Icon(
          p.userId != null ? Icons.phone_iphone_rounded : Icons.remove,
          size: 18,
          color: p.userId != null ? AppTheme.primaryBlue : AppTheme.textMuted,
        )),
        DataCell(StatusChip(
          label: p.active ? 'Activo' : 'Baja',
          color: p.active ? AppTheme.successGreen : AppTheme.textMuted,
        )),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Consultar',
              icon: const Icon(Icons.visibility_outlined, size: 20),
              onPressed: () => onView(p),
            ),
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => onEdit(p),
            ),
            IconButton(
              tooltip: p.active ? 'Dar de baja' : 'Reactivar',
              icon: Icon(
                p.active
                    ? Icons.person_off_outlined
                    : Icons.settings_backup_restore_rounded,
                size: 20,
                color: p.active ? AppTheme.errorRed : AppTheme.successGreen,
              ),
              onPressed: () => onToggleActive(p),
            ),
          ],
        )),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => patients.length;

  @override
  int get selectedRowCount => 0;
}

class _PatientDetailDialog extends StatelessWidget {
  const _PatientDetailDialog({required this.patient, required this.history});

  final Patient patient;
  final List<Appointment> history;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy', 'es');
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 140,
                child: Text(label,
                    style: const TextStyle(color: AppTheme.textSecondary)),
              ),
              Expanded(
                child: SelectableText(value,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );

    return AlertDialog(
      title: Text(patient.name),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              row('ID de paciente', patient.userId ?? patient.id),
              row('Teléfono', patient.phone),
              row('Correo', patient.email),
              row('Tratamiento', patient.treatment.isEmpty ? '—' : patient.treatment),
              row('Alertas médicas',
                  patient.medicalAlerts.isEmpty ? 'Ninguna' : patient.medicalAlerts.join(', ')),
              row('Cuenta en la app', patient.userId != null ? 'Sí' : 'No'),
              row('Estado', patient.active ? 'Activo' : 'Dado de baja'),
              const Divider(height: 24),
              Text('Historial de citas (${history.length})',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (history.isEmpty)
                const Text('Sin citas registradas.',
                    style: TextStyle(color: AppTheme.textSecondary))
              else
                for (final a in history)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text('${dateFormat.format(a.date)} · ${a.time}'),
                    subtitle: Text('${a.specialty} · ${a.doctorName}'),
                    trailing: StatusChip(label: a.status.label, color: a.status.color),
                  ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
