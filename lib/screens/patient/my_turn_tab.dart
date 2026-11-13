import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/queue_ticket.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

class MyTurnTab extends StatefulWidget {
  const MyTurnTab({super.key, required this.state});

  final AppState state;

  @override
  State<MyTurnTab> createState() => _MyTurnTabState();
}

class _MyTurnTabState extends State<MyTurnTab> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _ticketsStream;

  @override
  void initState() {
    super.initState();
    _ticketsStream = widget.state.watchMyQueueTickets(DateTime.now());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FAFD),
    body: SafeArea(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _ticketsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _Feedback(
              icon: Icons.cloud_off_rounded,
              title: 'No se pudo cargar tu turno',
              message: 'Revisa tu conexión e inténtalo de nuevo.',
              action: () => setState(() {
                _ticketsStream = widget.state.watchMyQueueTickets(
                  DateTime.now(),
                );
              }),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tickets =
              snapshot.data!.docs
                  .map(QueueTicket.fromDoc)
                  .where(
                    (ticket) =>
                        ticket.status == QueueTicketStatus.waiting ||
                        ticket.status == QueueTicketStatus.inService,
                  )
                  .toList()
                ..sort((a, b) {
                  if (a.status != b.status) {
                    return a.status == QueueTicketStatus.inService ? -1 : 1;
                  }
                  return a.number.compareTo(b.number);
                });
          if (tickets.isEmpty) {
            return const _Feedback(
              icon: Icons.confirmation_number_outlined,
              title: 'Aún no tienes un turno activo',
              message:
                  'Cuando recepción registre tu llegada, aquí verás el avance '
                  'de tu turno en tiempo real.',
            );
          }
          final ticket = tickets.first;
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            key: ValueKey(ticket.id),
            stream: widget.state.watchQueueBoard(ticket.queueKey),
            builder: (context, boardSnapshot) => _TurnDetails(
              ticket: ticket,
              board: boardSnapshot.data?.data(),
              boardError: boardSnapshot.error,
            ),
          );
        },
      ),
    ),
  );
}

class _TurnDetails extends StatelessWidget {
  const _TurnDetails({
    required this.ticket,
    required this.board,
    required this.boardError,
  });

  final QueueTicket ticket;
  final Map<String, dynamic>? board;
  final Object? boardError;

  @override
  Widget build(BuildContext context) {
    final inService = ticket.status == QueueTicketStatus.inService;
    final turnsAhead = ticket.turnsAhead;
    final currentNumber = board?['currentTicketNumber'] as int?;
    final positionText = inService
        ? 'Es tu turno'
        : turnsAhead == null
        ? 'Actualizando tu posición…'
        : turnsAhead == 0
        ? 'Eres el siguiente'
        : 'Faltan $turnsAhead ${turnsAhead == 1 ? 'turno' : 'turnos'} '
              'para ti';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Mi Turno',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sigue el avance de la fila en tiempo real.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 22),
        Container(
          key: const Key('my_turn_card'),
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF073B86), Color(0xFF0066FF)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TU NÚMERO',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${ticket.number}',
                key: const Key('my_turn_number'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                positionText,
                key: const Key('my_turn_position'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (!inService && turnsAhead == 2) ...[
                const SizedBox(height: 10),
                const Text(
                  '¡Prepárate! Faltan pocos turnos para que seas atendido.',
                  key: Key('my_turn_two_ahead'),
                  style: TextStyle(color: Colors.white),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                'Turno actual: ${currentNumber == null ? '—' : '#$currentNumber'}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEAF1FF),
              child: Icon(
                Icons.medical_services_outlined,
                color: AppTheme.primaryBlue,
              ),
            ),
            title: Text(ticket.doctorName),
            subtitle: Text('Fecha: ${ticket.queueDate}'),
            trailing: const Icon(Icons.wifi_tethering_rounded),
          ),
        ),
        if (boardError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No se pudo actualizar el turno actual: $boardError',
              style: const TextStyle(color: AppTheme.errorRed),
            ),
          ),
      ],
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 54, color: AppTheme.primaryBlue),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: action, child: const Text('Reintentar')),
          ],
        ],
      ),
    ),
  );
}
