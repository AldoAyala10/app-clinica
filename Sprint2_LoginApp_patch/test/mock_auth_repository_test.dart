import 'package:flutter_test/flutter_test.dart';
import 'package:login_app/data/mock_auth_repository.dart';
import 'package:login_app/models/app_user.dart';

void main() {
  const repository = MockAuthRepository();

  group('MockAuthRepository', () {
    test('autentica la cuenta de paciente con su rol', () {
      final user = repository.authenticate(
        email: 'paciente@test.com',
        password: 'Paciente123',
      );

      expect(user?.role, UserRole.patient);
      expect(user?.email, 'paciente@test.com');
    });

    test('autentica la cuenta de administrador con su rol', () {
      final user = repository.authenticate(
        email: 'admin@test.com',
        password: 'Admin123',
      );

      expect(user?.role, UserRole.administrator);
    });

    test('rechaza cuentas desconocidas y contraseñas incorrectas', () {
      expect(
        repository.authenticate(email: 'otro@test.com', password: 'Admin123'),
        isNull,
      );
      expect(
        repository.authenticate(
          email: 'admin@test.com',
          password: 'incorrecta',
        ),
        isNull,
      );
    });

    test('normaliza mayúsculas y espacios del correo', () {
      final user = repository.authenticate(
        email: '  PACIENTE@TEST.COM ',
        password: 'Paciente123',
      );

      expect(user?.role, UserRole.patient);
    });
  });
}
