const {
  onDocumentCreated,
  onDocumentWritten,
} = require('firebase-functions/v2/firestore');
const logger = require('firebase-functions/logger');
const { initializeApp } = require('firebase-admin/app');
const { FieldValue, getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const {
  calculateTurnsAhead,
  ticketsApproachingTurn,
} = require('./queue_logic');

initializeApp();

const db = getFirestore();

exports.updateQueuePositions = onDocumentWritten(
  { document: 'queueTickets/{ticketId}', region: 'us-central1' },
  async (event) => {
    const before = event.data?.before;
    const after = event.data?.after;
    if (!after?.exists) return;

    const ticket = after.data();
    const previousStatus = before?.exists ? before.data().status : null;
    const affectsQueue =
      (!before?.exists && ticket.status === 'waiting') ||
      (previousStatus === 'waiting' && ticket.status !== 'waiting');
    if (!affectsQueue || typeof ticket.queueKey !== 'string') return;

    const snapshot = await db
      .collection('queueTickets')
      .where('queueKey', '==', ticket.queueKey)
      .get();
    const positions = calculateTurnsAhead(
      snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() })),
    );
    const batch = db.batch();
    const notify = ticketsApproachingTurn(positions);
    let hasPositionUpdates = false;

    for (const position of positions) {
      const current = snapshot.docs.find((doc) => doc.id === position.id);
      if (!current) continue;
      if (current.data().turnsAhead !== position.turnsAhead) {
        batch.update(current.ref, { turnsAhead: position.turnsAhead });
        hasPositionUpdates = true;
      }
    }

    if (hasPositionUpdates) await batch.commit();
    await Promise.all(
      notify.map((position) =>
        sendApproachingTurnNotification(ticket.queueKey, position),
      ),
    );
  },
);

exports.notifyQueueTicketWhenDeviceRegisters = onDocumentCreated(
  {
    document: 'users/{uid}/pushTokens/{tokenId}',
    region: 'us-central1',
  },
  async (event) => {
    const patientId =
      typeof event.data?.data().token === 'string' ? event.params.uid : null;
    if (!patientId) return;
    const snapshot = await db
      .collection('queueTickets')
      .where('patientId', '==', patientId)
      .get();
    await Promise.all(
      snapshot.docs
        .filter(
          (doc) =>
            doc.data().status === 'waiting' &&
            doc.data().turnsAhead === 2 &&
            typeof doc.data().queueKey === 'string',
        )
        .map((doc) =>
          sendApproachingTurnNotification(doc.data().queueKey, {
            id: doc.id,
            patientId,
            number: doc.data().number,
          }),
        ),
    );
  },
);

async function sendApproachingTurnNotification(queueKey, ticket) {
  const deliveryId = `${queueKey}_${ticket.id}`;
  const delivery = db.collection('notificationDeliveries').doc(deliveryId);
  const claimed = await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(delivery);
    const data = snapshot.data();
    if (data?.status === 'sent' || data?.status === 'skipped') return false;
    if (data?.status === 'sending') {
      const claimedAt = data.claimedAt?.toDate?.().getTime() ?? 0;
      if (Date.now() - claimedAt < 5 * 60 * 1000) return false;
    }
    transaction.set(delivery, {
      status: 'sending',
      claimedAt: FieldValue.serverTimestamp(),
      ticketId: ticket.id,
      queueKey,
    });
    return true;
  });
  if (!claimed) return;

  try {
    const tokenSnapshot = await db
      .collection('users')
      .doc(ticket.patientId)
      .collection('pushTokens')
      .get();
    const tokenDocs = tokenSnapshot.docs.filter(
      (doc) => typeof doc.data().token === 'string',
    );
    if (tokenDocs.length === 0) {
      await delivery.update({
        status: 'pending',
        completedAt: FieldValue.serverTimestamp(),
      });
      return;
    }

    for (let offset = 0; offset < tokenDocs.length; offset += 500) {
      const tokenBatch = tokenDocs.slice(offset, offset + 500);
      const response = await getMessaging().sendEachForMulticast({
        tokens: tokenBatch.map((doc) => doc.data().token),
        notification: {
          title: 'Próximo turno',
          body: '¡Prepárate! Faltan pocos turnos para que seas atendido.',
        },
        data: {
          type: 'queue_approaching',
          queueKey,
          ticketId: ticket.id,
          number: String(ticket.number),
          turnsAhead: '2',
        },
        android: {
          priority: 'high',
          notification: { channelId: 'queue_alerts' },
        },
        apns: {
          payload: { aps: { sound: 'default' } },
        },
      });

      const invalidTokens = [];
      response.responses.forEach((result, index) => {
        if (
          !result.success &&
          ['messaging/invalid-registration-token', 'messaging/registration-token-not-registered'].includes(
            result.error?.code,
          )
        ) {
          invalidTokens.push(tokenBatch[index].ref.delete());
        }
      });
      await Promise.all(invalidTokens);
      if (response.failureCount > 0) {
        logger.warn('Algunos dispositivos no recibieron la alerta de turno.', {
          ticketId: ticket.id,
          failureCount: response.failureCount,
        });
      }
    }
    await delivery.update({ status: 'sent', completedAt: FieldValue.serverTimestamp() });
  } catch (error) {
    await delivery.update({
      status: 'failed',
      completedAt: FieldValue.serverTimestamp(),
      error: String(error),
    });
    logger.error('No se pudo enviar la alerta push del turno.', {
      ticketId: ticket.id,
      error,
    });
    throw error;
  }
}
