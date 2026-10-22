import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:app_clinica/services/auth_service.dart';
import 'package:app_clinica/state/app_state.dart';

void main() {
  late FakeFirebaseFirestore fakeDb;
  late MockFirebaseAuth mockAuth;
  late AuthService authService;

  setUp(() {
    fakeDb = FakeFirebaseFirestore();
  });

  group('AuthService Tests con Patrón AAA', () {
    // -------------------------------------------------------------------------
    // CASO 1: Inicio de sesión exitoso con rol de Doctor
    // -------------------------------------------------------------------------
    test('1. signIn exitoso autentica doctor y retorna UserRole.doctor', () async {
      // // ARRANGE (Organizar)
      // Se prepara un usuario en MockFirebaseAuth con uid 'doc-123'
      // y se almacena en Firestore su documento con role: 'doctor'.
      const uid = 'doc-123';
      const email = 'doctor@clinica.com';
      const password = 'Password123!';
      final mockUser = MockUser(uid: uid, email: email);
      mockAuth = MockFirebaseAuth(mockUser: mockUser);
      await fakeDb.collection('users').doc(uid).set({
        'name': 'Dr. Roberto Mendoza',
        'email': email,
        'role': 'doctor',
      });
      authService = AuthService(auth: mockAuth, db: fakeDb);

      // // ACT (Actuar)
      // Se ejecuta la función signIn con las credenciales del doctor.
      final resultRole = await authService.signIn(
        email: email,
        password: password,
      );

      // // ASSERT (Afirmar)
      // Se verifica que el rol devuelto sea UserRole.doctor
      // y que la sesión del usuario actual esté activa.
      expect(resultRole, equals(UserRole.doctor));
      expect(authService.currentUser?.uid, equals(uid));
      expect(authService.currentUser?.email, equals(email));
    });

    // -------------------------------------------------------------------------
    // CASO 2: Inicio de sesión exitoso con rol de Paciente
    // -------------------------------------------------------------------------
    test('2. signIn exitoso autentica paciente y retorna UserRole.patient', () async {
      // // ARRANGE (Organizar)
      // Se inicializa un paciente en Auth y se guarda su perfil con rol 'patient'.
      const uid = 'pac-456';
      const email = 'paciente@gmail.com';
      const password = 'Password456!';
      final mockUser = MockUser(uid: uid, email: email);
      mockAuth = MockFirebaseAuth(mockUser: mockUser);
      await fakeDb.collection('users').doc(uid).set({
        'name': 'Ana Gómez',
        'email': email,
        'role': 'patient',
      });
      authService = AuthService(auth: mockAuth, db: fakeDb);

      // // ACT (Actuar)
      // Se inicia sesión con las credenciales del paciente.
      final resultRole = await authService.signIn(
        email: email,
        password: password,
      );

      // // ASSERT (Afirmar)
      // Se comprueba que retorne UserRole.patient y coincida el usuario activo.
      expect(resultRole, equals(UserRole.patient));
      expect(authService.currentUser?.uid, equals(uid));
    });

    // -------------------------------------------------------------------------
    // CASO 3: Asignación de rol por defecto (fallback a paciente)
    // -------------------------------------------------------------------------
    test('3. getRole asigna por defecto UserRole.patient si el perfil no existe', () async {
      // // ARRANGE (Organizar)
      // Se tiene un usuario autenticado pero cuyo documento no existe en Firestore.
      const uid = 'sin-documento-789';
      mockAuth = MockFirebaseAuth(mockUser: MockUser(uid: uid));
      authService = AuthService(auth: mockAuth, db: fakeDb);

      // // ACT (Actuar)
      // Se consulta el rol para el UID que no posee documento en Firestore.
      final role = await authService.getRole(uid);

      // // ASSERT (Afirmar)
      // La regla de negocio indica que ante ausencia de documento o rol no-doctor,
      // debe retornar de forma segura UserRole.patient.
      expect(role, equals(UserRole.patient));
    });

    // -------------------------------------------------------------------------
    // CASO 4: Registro de nuevo usuario (Crea cuenta, perfil y ficha clínica)
    // -------------------------------------------------------------------------
    test('4. register crea usuario en Auth, perfil en users y ficha en patients', () async {
      // // ARRANGE (Organizar)
      // Se configura un MockFirebaseAuth limpio y datos completos del nuevo paciente.
      mockAuth = MockFirebaseAuth();
      authService = AuthService(auth: mockAuth, db: fakeDb);
      const name = 'Carlos Valenzuela';
      const email = 'carlos@test.com';
      const phone = '5551234567';
      const password = 'PasswordSegura123';

      // // ACT (Actuar)
      // Se ejecuta el registro del nuevo paciente.
      await authService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );

      // // ASSERT (Afirmar)
      // Se verifica que:
      // a) El usuario esté autenticado con su email y displayName asignado.
      final currentUid = authService.currentUser!.uid;
      expect(authService.currentUser?.email, equals(email));
      expect(authService.currentUser?.displayName, equals(name));

      // b) Se haya creado el documento en la colección 'users' con rol 'patient'.
      final userDoc = await fakeDb.collection('users').doc(currentUid).get();
      expect(userDoc.exists, isTrue);
      expect(userDoc.data()?['name'], equals(name));
      expect(userDoc.data()?['email'], equals(email));
      expect(userDoc.data()?['phone'], equals(phone));
      expect(userDoc.data()?['role'], equals('patient'));

      // c) Se haya creado la ficha médica inicial en la colección 'patients'.
      final patientDoc = await fakeDb.collection('patients').doc(currentUid).get();
      expect(patientDoc.exists, isTrue);
      expect(patientDoc.data()?['userId'], equals(currentUid));
      expect(patientDoc.data()?['name'], equals(name));
      expect(patientDoc.data()?['phone'], equals(phone));
    });

    // -------------------------------------------------------------------------
    // CASO 5: Cierre de sesión (signOut) limpia la sesión activa
    // -------------------------------------------------------------------------
    test('5. signOut invalida la sesión activa y currentUser pasa a ser null', () async {
      // // ARRANGE (Organizar)
      // Se inicializa una sesión activa en AuthService con un usuario existente.
      final mockUser = MockUser(uid: 'user-activo-01', email: 'activo@test.com');
      mockAuth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);
      authService = AuthService(auth: mockAuth, db: fakeDb);
      expect(authService.currentUser, isNotNull);

      // // ACT (Actuar)
      // Se ejecuta el método signOut para cerrar sesión.
      await authService.signOut();

      // // ASSERT (Afirmar)
      // Se valida que currentUser sea null tras cerrar la sesión.
      expect(authService.currentUser, isNull);
    });
  });
}
