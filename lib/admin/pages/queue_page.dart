import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/appointment.dart';
import '../../models/doctor.dart';
import '../../models/queue_ticket.dart';
import '../../repositories/firebase_clinic_repository.dart';
import '../../theme/app_theme.dart';
import '../admin_state.dart';
import '../widgets/admin_page_header.dart';

class QueuePage extends StatefulWidget {
  const QueuePage({super.key, required this.state});

  final AdminState state;

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  late Doctor _doctor;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ticketsSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _boardSub;
  List<QueueTicket> _tickets = [];
  Map<String, dynamic>? _board;
  bool _loading = true;
  bool _saving = false;
  Object? _error;

  DateTime get _today => DateUtils.dateOnly(DateTime.now());
  String get _queueKey => FirebaseClinicRepository.queueKey(_doctor.id, _today);

  static final _timePattern = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$');

  static int _minutesAfterMidnight(String value) {
    final match = _timePattern.firstMatch(value.trim().toUpperCase());
    if (match == null) return 24 * 60;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3);
    return ((hour % 12) + (period == 'PM' ? 12 : 0)) * 60 + minute;
  }

  @override
  void initState() {
    super.initState();
    final preferred = widget.state.preferredDoctorId;
    _doctor = widget.state.doctors.firstWhere(
      (doctor) => doctor.id == preferred,
      orElse: () => widget.state.doctors.first,
    );
    _listen();
  }

  @override
  void dispose() {
    _ticketsSub?.cancel();
    _boardSub?.cancel();
    super.dispose();
  }

  void _listen() {
    _ticketsSub?.cancel();
    _boardSub?.cancel();
    setState(() {
      _loading = true;
      _error = null;
      _board = null;
    });
    final key = _queueKey;
    _ticketsSub = widget.state.watchQueue(key).listen(
      (snapshot) {
        if (!mounted) return;
        setState(() {
          _tickets = snapshot.docs.map(QueueTicket.fromDoc).toList()
            ..sort((a, b) => a.number.compareTo(b.number));
          _loading = false;
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _error = error;
          _loading = false;
        });
      },
    );
    _boardSub = widget.state.watchQueueBoard(key).listen(
      (snapshot) {
        if (!mounted) return;
        setState(() => _board = snapshot.data());
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() => _error = error);
      },
    );
    unawaited(_ensureBoard());
  }

  Future<void> _ensureBoard() async {
    try {
      await widget.state.ensureQueueBoard(_doctor, _today);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  List<Appointment> get _appointmentsToCheckIn {
    final queuedIds = _tickets.map((ticket) => ticket.appointmentId).toSet();
    return widget.state.appointments.where((appointment) {
      return DateUtils.isSameDay(appointment.date, _today) &&
          appointment.doctorId == _doctor.id &&
          (appointment.status == AppointmentStatus.confirmada ||
              appointment.status == AppointmentStatus.pendiente) &&
          !queuedIds.contains(appointment.id);
    }).toList()
      ..sort((a, b) =>
          _minutesAfterMidnight(a.time).compareTo(_minutesAfterMidnight(b.time)));
  }

  QueueTicket? get _currentTicket {
    final id = _board?['currentTicketId'] as String?;
    if (id == null) return null;
    for (final ticket in _tickets) {
      if (ticket.id == id) return ticket;
    }
    return null;
  }

  List<QueueTicket> get _waitingTickets => _tickets
      .where((ticket) => ticket.status == QueueTicketStatus.waiting)
      .toList();

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppTheme.errorRed : AppTheme.successGreen,
      ),
    );
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await action();
      _showMessage(successMessage);
    } catch (error) {
      _showMessage('No se pudo completar la operación: $error', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _registerWalkIn() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar llegada'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nombre del paciente',
            hintText: 'Escribe el nombre completo',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Asignar turno'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null) return;
    if (name.isEmpty) {
      _showMessage('Escribe el nombre del paciente.', error: true);
      return;
    }
    await _runAction(
      () async => widget.state.registerQueueTicket(
        doctor: _doctor,
        date: _today,
        patientName: name,
        source: QueueTicketSource.walkIn,
      ),
      successMessage: 'Turno asignado para $name.',
    );
  }

  Future<void> _checkInAppointment(Appointment appointment) =>
      _runAction(() async {
        await widget.state.registerQueueTicket(
          doctor: _doctor,
          date: _today,
          patientName: appointment.patientName,
          source: QueueTicketSource.appointment,
          appointmentId: appointment.id,
        );
      }, successMessage: 'Llegada registrada: ${appointment.patientName}.');

  @override
  Widget build(BuildContext context) {
    final waiting = _waitingTickets;
    final inService =
        _tickets.where((t) => t.status == QueueTicketStatus.inService).length;
    final served =
        _tickets.where((t) => t.status == QueueTicketStatus.served).length;
    final cancelled =
        _tickets.where((t) => t.status == QueueTicketStatus.cancelled).length;
    final current = _currentTicket;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        AdminPageHeader(
          title: 'Control de turnos',
          subtitle:
              '${DateFormat('EEEE d MMMM yyyy', 'es').format(_today)} · '
              'Gestión en tiempo real',
          actionLabel: 'Registrar llegada',
          actionIcon: Icons.person_add_alt_1_rounded,
          onAction: _saving ? null : () => _registerWalkIn(),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 320,
              child: DropdownButtonFormField<String>(
                key: const Key('queue_doctor_selector'),
                initialValue: _doctor.id,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Odontólogo',
                  prefixIcon: Icon(Icons.medical_services_outlined),
                ),
                items: [
                  for (final doctor in widget.state.doctors)
                    DropdownMenuItem(
                      value: doctor.id,
                      child: Text(doctor.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: _saving
                    ? null
                    : (id) {
                        if (id == null) return;
                        setState(() {
                          _doctor = widget.state.doctors.firstWhere(
                            (doctor) => doctor.id == id,
                          );
                        });
                        _listen();
                      },
              ),
            ),
            if (_board != null)
              _LiveBadge(
                label: 'Sincronizado en vivo',
                icon: Icons.wifi_tethering_rounded,
              ),
          ],
        ),
        const SizedBox(height: 18),
        _CurrentTurnCard(
          ticket: current,
          saving: _saving,
          onCallNext: waiting.isEmpty || current != null
              ? null
              : () => _runAction(
                    () => widget.state.callNextQueueTicket(
                      _queueKey,
                      waiting.first,
                    ),
                    successMessage: 'Turno ${waiting.first.number} llamado.',
                  ),
          onFinish: current == null
              ? null
              : () => _runAction(
                    () => widget.state.finishQueueTicket(_queueKey, current),
                    successMessage: 'Atención finalizada.',
                  ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(
              title: 'En espera',
              value: waiting.length,
              icon: Icons.hourglass_bottom_rounded,
              color: const Color(0xFFF59E0B),
            ),
            _MetricCard(
              title: 'En atención',
              value: inService,
              icon: Icons.medical_services_outlined,
              color: const Color(0xFF0066FF),
            ),
            _MetricCard(
              title: 'Atendidos',
              value: served,
              icon: Icons.check_circle_outline_rounded,
              color: const Color(0xFF10B981),
            ),
            _MetricCard(
              title: 'Cancelados',
              value: cancelled,
              icon: Icons.cancel_outlined,
              color: const Color(0xFFEF4444),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _EndpointCard(
          queueKey: _queueKey,
          projectId: widget.state.firebaseProjectId,
        ),
        const SizedBox(height: 20),
        _sectionTitle(
          'Citas de hoy',
          'Registra la llegada para incorporarlas a la fila.',
        ),
        const SizedBox(height: 10),
        if (!widget.state.appointmentsLoaded)
          const LinearProgressIndicator()
        else if (_appointmentsToCheckIn.isEmpty)
          const _EmptyPanel(
            icon: Icons.event_available_outlined,
            text: 'No hay citas pendientes de llegada para este odontólogo.',
          )
        else
          ..._appointmentsToCheckIn.map(
            (appointment) => _AppointmentArrivalCard(
              appointment: appointment,
              saving: _saving,
              onCheckIn: () => _checkInAppointment(appointment),
            ),
          ),
        const SizedBox(height: 20),
        _sectionTitle(
          'Fila del día',
          'Los turnos se asignan consecutivamente y conservan su historial.',
        ),
        const SizedBox(height: 10),
        if (_error != null)
          _ErrorPanel(
            message: 'No se pudo sincronizar la fila: $_error',
            onRetry: _listen,
          )
        else if (_loading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_tickets.isEmpty)
          const _EmptyPanel(
            icon: Icons.people_outline_rounded,
            text: 'Aún no hay turnos. Registra una llegada o una cita.',
          )
        else
          ..._tickets.map(
            (ticket) => _QueueTicketCard(
              ticket: ticket,
              saving: _saving,
              onCancel: ticket.status == QueueTicketStatus.waiting
                  ? () => _runAction(
                        () => widget.state.cancelQueueTicket(ticket),
                        successMessage: 'Turno ${ticket.number} cancelado.',
                      )
                  : null,
            ),
          ),
      ],
    );
  }

  Widget _sectionTitle(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 3),
      Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary)),
    ],
  );
}

class _CurrentTurnCard extends StatelessWidget {
  const _CurrentTurnCard({
    required this.ticket,
    required this.saving,
    required this.onCallNext,
    required this.onFinish,
  });

  final QueueTicket? ticket;
  final bool saving;
  final VoidCallback? onCallNext;
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context) {
    final active = ticket != null;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF073B86), Color(0xFF0066FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0066FF).withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Row(
            children: [
              Container(
                width: 68,
                height: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  active ? Icons.campaign_rounded : Icons.notifications_active,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      active ? 'TURNO ACTUAL' : 'LISTO PARA LLAMAR',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      active ? 'Turno ${ticket!.number}' : 'Sin paciente en atención',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (active) ...[
                      const SizedBox(height: 2),
                      Text(
                        ticket!.patientName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (!active)
                FilledButton.icon(
                  key: const Key('queue_call_next'),
                  onPressed: saving ? null : onCallNext,
                  icon: const Icon(Icons.record_voice_over_rounded),
                  label: const Text('Llamar siguiente'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0753C7),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                  ),
                )
              else
                FilledButton.icon(
                  key: const Key('queue_finish_current'),
                  onPressed: saving ? null : onFinish,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Marcar atendido'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0753C7),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                  ),
                ),
            ],
          );
          if (constraints.maxWidth >= 700) return content;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: content.children.take(2).toList()
                ..add(Expanded(child: content.children[2]))),
              const SizedBox(height: 16),
              active
                  ? FilledButton.icon(
                      onPressed: saving ? null : onFinish,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Marcar atendido'),
                    )
                  : FilledButton.icon(
                      onPressed: saving ? null : onCallNext,
                      icon: const Icon(Icons.record_voice_over_rounded),
                      label: const Text('Llamar siguiente'),
                    ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 170,
    child: Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _QueueTicketCard extends StatelessWidget {
  const _QueueTicketCard({
    required this.ticket,
    required this.saving,
    required this.onCancel,
  });

  final QueueTicket ticket;
  final bool saving;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (ticket.status) {
      QueueTicketStatus.waiting => const Color(0xFFF59E0B),
      QueueTicketStatus.inService => const Color(0xFF0066FF),
      QueueTicketStatus.served => const Color(0xFF10B981),
      QueueTicketStatus.cancelled => const Color(0xFFEF4444),
    };
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.12),
          child: Text(
            '${ticket.number}',
            style: TextStyle(color: statusColor, fontWeight: FontWeight.w800),
          ),
        ),
        title: Text(
          ticket.patientName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${ticket.source.label} · Turno ${ticket.number}',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        trailing: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            _StatusPill(label: ticket.status.label, color: statusColor),
            if (onCancel != null)
              IconButton(
                tooltip: 'Cancelar turno',
                onPressed: saving ? null : onCancel,
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppTheme.errorRed,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentArrivalCard extends StatelessWidget {
  const _AppointmentArrivalCard({
    required this.appointment,
    required this.saving,
    required this.onCheckIn,
  });

  final Appointment appointment;
  final bool saving;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: ListTile(
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFEAF1FF),
        child: Icon(Icons.event_available_rounded, color: Color(0xFF0066FF)),
      ),
      title: Text(
        appointment.patientName,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text('${appointment.time} · ${appointment.specialty}'),
      trailing: OutlinedButton.icon(
        onPressed: saving ? null : onCheckIn,
        icon: const Icon(Icons.how_to_reg_rounded, size: 18),
        label: const Text('Registrar llegada'),
      ),
    ),
  );
}

class _EndpointCard extends StatelessWidget {
  const _EndpointCard({required this.queueKey, required this.projectId});

  final String queueKey;
  final String projectId;

  @override
  Widget build(BuildContext context) {
    final endpoint =
        'https://firestore.googleapis.com/v1/projects/$projectId/'
        'databases/(default)/documents/queueBoards/$queueKey';
    return Card(
      elevation: 0,
      color: const Color(0xFFEFF5FF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.api_rounded, color: Color(0xFF0753C7)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Endpoint público del turno actual',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    endpoint,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Documento sin datos personales; los cambios se publican en vivo.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Copiar endpoint',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: endpoint));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Endpoint copiado.')),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFE7F8EF),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF10915A), size: 17),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF087544),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppTheme.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(color: AppTheme.textSecondary)),
        ),
      ],
    ),
  );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFFFFF1F1),
    child: ListTile(
      leading: const Icon(Icons.error_outline, color: AppTheme.errorRed),
      title: Text(message, style: const TextStyle(color: AppTheme.errorRed)),
      trailing: IconButton(
        tooltip: 'Reintentar',
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
      ),
    ),
  );
}
