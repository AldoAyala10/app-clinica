function calculateTurnsAhead(tickets) {
  const waiting = tickets
    .filter((ticket) => ticket.status === 'waiting')
    .sort((a, b) => a.number - b.number);

  return waiting.map((ticket, index) => ({
    id: ticket.id,
    patientId: ticket.patientId || null,
    number: ticket.number,
    turnsAhead: index,
  }));
}

function ticketsApproachingTurn(positions) {
  return positions.filter(
    (ticket) => ticket.patientId && ticket.turnsAhead === 2,
  );
}

module.exports = { calculateTurnsAhead, ticketsApproachingTurn };
