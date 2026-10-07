import '../state/app_state.dart';

/// Credenciales de demostración. No sustituye autenticación de servidor.
class MockAuthRepository {
  const MockAuthRepository();

  UserRole? authenticate(String email, String password) {
    final normalized = email.trim().toLowerCase();
    if (normalized == 'admin@test.com' && password == 'admin123') {
      return UserRole.doctor;
    }
    if (normalized == 'paciente@test.com' && password == 'paciente123') {
      return UserRole.patient;
    }
    return null;
  }
}
