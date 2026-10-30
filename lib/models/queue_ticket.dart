import 'package:cloud_firestore/cloud_firestore.dart';

enum QueueTicketStatus {
  waiting,
  inService,
  served,
  cancelled;

  String get label => switch (this) {
    QueueTicketStatus.waiting => 'En espera',
    QueueTicketStatus.inService => 'En atención',
    QueueTicketStatus.served => 'Atendido',
    QueueTicketStatus.cancelled => 'Cancelado',
  };
}

enum QueueTicketSource {
  appointment,
  walkIn;

  String get label => this == QueueTicketSource.appointment
      ? 'Con cita'
      : 'Por llegada';
}

class QueueTicket {
  const QueueTicket({
    required this.id,
    required this.queueKey,
    required this.doctorId,
    required this.doctorName,
    required this.queueDate,
    required this.number,
    required this.patientName,
    required this.source,
    required this.status,
    this.appointmentId,
    this.registeredAt,
  });

  final String id;
  final String queueKey;
  final String doctorId;
  final String doctorName;
  final String queueDate;
  final int number;
  final String patientName;
  final QueueTicketSource source;
  final QueueTicketStatus status;
  final String? appointmentId;
  final DateTime? registeredAt;

  factory QueueTicket.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return QueueTicket(
      id: doc.id,
      queueKey: data['queueKey'] as String,
      doctorId: data['doctorId'] as String,
      doctorName: data['doctorName'] as String? ?? '',
      queueDate: data['queueDate'] as String,
      number: data['number'] as int,
      patientName: data['patientName'] as String? ?? '',
      source: QueueTicketSource.values.byName(
        data['source'] as String? ?? QueueTicketSource.walkIn.name,
      ),
      status: QueueTicketStatus.values.byName(
        data['status'] as String? ?? QueueTicketStatus.waiting.name,
      ),
      appointmentId: data['appointmentId'] as String?,
      registeredAt: (data['registeredAt'] as Timestamp?)?.toDate(),
    );
  }
}
