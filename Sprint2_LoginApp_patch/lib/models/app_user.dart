enum UserRole {
  patient,
  administrator,
}

class AppUser {
  const AppUser({
    required this.email,
    required this.name,
    required this.role,
  });

  final String email;
  final String name;
  final UserRole role;
}
