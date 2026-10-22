class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String clinic;

  /// Consultorio donde atiende; cada doctor tiene el suyo, así que un horario
  /// del doctor también aparta su consultorio.
  final String office;
  final double rating;
  final String experience;
  final String avatarAsset;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.clinic,
    this.office = '',
    this.rating = 4.9,
    this.experience = '8 años',
    this.avatarAsset = '',
  });
}

/// Odontólogos de la clínica (compartido por la app y el panel web).
final List<Doctor> kClinicDoctors = [
  Doctor(
    id: 'd1',
    name: 'Dr. Carlos Sandoval',
    specialty: 'Odontología General',
    clinic: 'Clínica Dental',
    office: 'Consultorio 1',
    rating: 4.9,
    experience: '10 años exp.',
  ),
  Doctor(
    id: 'd2',
    name: 'Dra. Sofía Vega',
    specialty: 'Ortodoncia & Estética',
    clinic: 'Clínica Dental',
    office: 'Consultorio 2',
    rating: 5.0,
    experience: '8 años exp.',
  ),
  Doctor(
    id: 'd3',
    name: 'Dr. Roberto Mendoza',
    specialty: 'Endodoncia & Cirugía',
    clinic: 'Clínica Dental',
    office: 'Consultorio 3',
    rating: 4.8,
    experience: '12 años exp.',
  ),
];

Doctor? doctorById(String? id) {
  for (final doctor in kClinicDoctors) {
    if (doctor.id == id) return doctor;
  }
  return null;
}

/// Horarios de atención en que se puede agendar una cita.
const List<String> kTimeSlots = [
  '09:00 AM',
  '10:30 AM',
  '12:00 PM',
  '03:00 PM',
  '04:30 PM',
  '06:00 PM',
];

/// Tratamientos que se pueden agendar.
const List<String> kTreatments = [
  'Limpieza',
  'Ortodoncia',
  'Endodoncia',
  'Extracción',
  'Blanqueamiento',
];
