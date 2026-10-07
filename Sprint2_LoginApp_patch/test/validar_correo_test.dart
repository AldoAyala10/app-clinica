import 'package:flutter_test/flutter_test.dart';
import 'package:login_app/validar_correo.dart';

void main() {
  group('validarCorreo', () {
    test('acepta correos válidos', () {
      expect(validarCorreo('paciente@test.com'), isTrue);
      expect(validarCorreo('admin@clinicadental.com'), isTrue);
    });

    test('rechaza correos inválidos', () {
      expect(validarCorreo(''), isFalse);
      expect(validarCorreo('correo'), isFalse);
      expect(validarCorreo('correo@'), isFalse);
      expect(validarCorreo('correo@@correo.com'), isFalse);
    });
  });
}
