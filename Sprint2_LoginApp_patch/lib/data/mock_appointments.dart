class MockAppointment {
  const MockAppointment({
    required this.service,
    required this.professional,
    required this.startsAt,
  });

  final String service;
  final String professional;
  final DateTime startsAt;

  String get dateLabel {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    return '${startsAt.day} de ${months[startsAt.month - 1]} de ${startsAt.year}';
  }

  String get timeLabel =>
      '${startsAt.hour.toString().padLeft(2, '0')}:'
      '${startsAt.minute.toString().padLeft(2, '0')} h';
}

List<MockAppointment> mockAppointments({DateTime? today}) {
  final referenceDate = today ?? DateTime.now();

  return [
    MockAppointment(
      service: 'Limpieza dental',
      professional: 'Dra. Laura Ramos',
      startsAt: DateTime(
        referenceDate.year,
        referenceDate.month,
        referenceDate.day + 2,
        10,
        30,
      ),
    ),
    MockAppointment(
      service: 'Revisión general',
      professional: 'Dr. Miguel Torres',
      startsAt: DateTime(
        referenceDate.year,
        referenceDate.month,
        referenceDate.day + 7,
        12,
      ),
    ),
  ];
}
