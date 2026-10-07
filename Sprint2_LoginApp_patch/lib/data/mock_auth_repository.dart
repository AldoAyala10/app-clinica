import '../models/app_user.dart';

/// Autenticación local para la demostración del Sprint 2.
/// Se reemplazará por el servicio de backend en un sprint posterior.
class MockAuthRepository {
  const MockAuthRepository();

  static const Map<String, _DemoAccount> _accounts = {
    'admin@test.com': _DemoAccount(
      password: 'Admin123',
      user: AppUser(
        email: 'admin@test.com',
        name: 'Administración',
        role: UserRole.administrator,
      ),
    ),
    'paciente@test.com': _DemoAccount(
      password: 'Paciente123',
      user: AppUser(
        email: 'paciente@test.com',
        name: 'Paciente de prueba',
        role: UserRole.patient,
      ),
    ),
  };

  AppUser? authenticate({required String email, required String password}) {
    final normalizedEmail = email.trim().toLowerCase();
    final account = _accounts[normalizedEmail];

    if (account == null || account.password != password) {
      return null;
    }

    return account.user;
  }
}

class _DemoAccount {
  const _DemoAccount({required this.password, required this.user});

  final String password;
  final AppUser user;
}
