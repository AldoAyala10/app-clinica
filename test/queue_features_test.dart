import 'package:app_clinica/admin/admin_state.dart';
import 'package:app_clinica/admin/pages/queue_page.dart';
import 'package:app_clinica/models/doctor.dart';
import 'package:app_clinica/models/queue_ticket.dart';
import 'package:app_clinica/repositories/firebase_clinic_repository.dart';
import 'package:app_clinica/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'helpers/firebase_fakes.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));
  setUp(() => setUpFirebase(signedInUid: receptionistUid));

  DateTime today() => DateUtils.dateOnly(DateTime.now());

  test('asigna números únicos y no duplica el registro de una cita', () async {
    final repository = FirebaseClinicRepository(db);
    final doctor = kClinicDoctors.first;
    final date = today();

    final first = await repository.registerQueueTicket(
      doctorId: doctor.id,
      doctorName: doctor.name,
      date: date,
      patientName: 'Ana García',
      source: QueueTicketSource.walkIn,
    );
    final appointment = await repository.registerQueueTicket(
      doctorId: doctor.id,
      doctorName: doctor.name,
      date: date,
      patientName: 'Luis Pérez',
      source: QueueTicketSource.appointment,
      appointmentId: 'appointment-1',
    );
    final duplicate = await repository.registerQueueTicket(
      doctorId: doctor.id,
      doctorName: doctor.name,
      date: date,
      patientName: 'Luis Pérez',
      source: QueueTicketSource.appointment,
      appointmentId: 'appointment-1',
    );

    expect(first.number, 1);
    expect(appointment.number, 2);
    expect(duplicate.number, appointment.number);
    expect(
      (await db
              .collection('queueCounters')
              .doc(FirebaseClinicRepository.queueKey(doctor.id, date))
              .get())
          .data()?['lastNumber'],
      2,
    );
  });

  test('llamar, atender y cancelar mantienen el estado y turno actual', () async {
    final repository = FirebaseClinicRepository(db);
    final doctor = kClinicDoctors.first;
    final date = today();
    final first = await repository.registerQueueTicket(
      doctorId: doctor.id,
      doctorName: doctor.name,
      date: date,
      patientName: 'Ana García',
      source: QueueTicketSource.walkIn,
    );
    final second = await repository.registerQueueTicket(
      doctorId: doctor.id,
      doctorName: doctor.name,
      date: date,
      patientName: 'Luis Pérez',
      source: QueueTicketSource.appointment,
      appointmentId: 'appointment-2',
    );
    final key = FirebaseClinicRepository.queueKey(doctor.id, date);

    await repository.callNextQueueTicket(queueKey: key, ticket: first);
    expect(
      (await db.collection('queueTickets').doc(first.id).get())
          .data()?['status'],
      QueueTicketStatus.inService.name,
    );
    expect(
      (await db.collection('queueBoards').doc(key).get())
          .data()?['currentTicketNumber'],
      1,
    );
    await expectLater(
      repository.callNextQueueTicket(queueKey: key, ticket: second),
      throwsA(isA<StateError>()),
    );

    await repository.finishQueueTicket(queueKey: key, ticket: first);
    expect(
      (await db.collection('queueBoards').doc(key).get())
          .data()?['currentTicketNumber'],
      isNull,
    );
    await repository.callNextQueueTicket(queueKey: key, ticket: second);
    await repository.finishQueueTicket(queueKey: key, ticket: second);
    expect(
      (await db.collection('queueTickets').doc(second.id).get())
          .data()?['status'],
      QueueTicketStatus.served.name,
    );

    final third = await repository.registerQueueTicket(
      doctorId: doctor.id,
      doctorName: doctor.name,
      date: date,
      patientName: 'Eva Ruiz',
      source: QueueTicketSource.walkIn,
    );
    await repository.cancelQueueTicket(third);
    expect(
      (await db.collection('queueTickets').doc(third.id).get())
          .data()?['status'],
      QueueTicketStatus.cancelled.name,
    );
  });

  testWidgets('el panel muestra la fila y el endpoint público', (tester) async {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final state = AdminState(
      role: UserRole.receptionist,
      staffName: 'Pedro Recepción',
      firebaseProjectId: 'test-project',
    );
    addTearDown(state.dispose);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: QueuePage(state: state))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Control de turnos'), findsOneWidget);
    expect(find.text('Llamar siguiente'), findsOneWidget);
    expect(find.text('Endpoint público del turno actual'), findsOneWidget);
    expect(find.textContaining('queueBoards/d1_'), findsOneWidget);
    final queueKey = FirebaseClinicRepository.queueKey(
      kClinicDoctors.first.id,
      today(),
    );
    final board = await db.collection('queueBoards').doc(queueKey).get();
    expect(board.exists, isTrue);
    expect(board.data()?['currentStatus'], 'sin_turno');
    expect(board.data(), isNot(contains('patientName')));
  });
}
