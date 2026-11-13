const assert = require('node:assert/strict');
const {
  calculateTurnsAhead,
  ticketsApproachingTurn,
} = require('../queue_logic');

const positions = calculateTurnsAhead([
  { id: 'five', number: 5, status: 'waiting', patientId: 'patient-5' },
  { id: 'two', number: 2, status: 'waiting', patientId: 'patient-2' },
  { id: 'three', number: 3, status: 'waiting', patientId: 'patient-3' },
  { id: 'one', number: 1, status: 'inService', patientId: 'patient-1' },
  { id: 'four', number: 4, status: 'cancelled', patientId: 'patient-4' },
]);

assert.deepEqual(
  positions.map(({ id, turnsAhead }) => ({ id, turnsAhead })),
  [
    { id: 'two', turnsAhead: 0 },
    { id: 'three', turnsAhead: 1 },
    { id: 'five', turnsAhead: 2 },
  ],
);
assert.equal(positions[2].patientId, 'patient-5');
assert.deepEqual(
  ticketsApproachingTurn(positions).map((ticket) => ticket.id),
  ['five'],
);
console.log('queue_logic tests passed');
