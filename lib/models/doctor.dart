class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String clinic;
  final double rating;
  final String experience;
  final String avatarAsset;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.clinic,
    this.rating = 4.9,
    this.experience = '8 años',
    this.avatarAsset = '',
  });
}
