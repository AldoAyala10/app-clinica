import 'package:app_clinica/models/appointment.dart';
import 'package:app_clinica/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

/// Firebase simulado en memoria para las pruebas: un doctor, una paciente,
/// una administradora y un recepcionista.

const doctorUid = 'doctor-1';
const patientUid = 'paciente-1';
const adminUid = 'admin-1';
const receptionistUid = 'recepcion-1';

/// Firestore en memoria de la prueba actual.
late FakeFirebaseFirestore db;

/// Reemplaza Firebase por versiones en memoria. Si [signedInUid] no es null,
/// arranca con esa sesión abierta; si no, [loginUid] es la cuenta con la que
/// entra el siguiente inicio de sesión.
Future<MockFirebaseAuth> setUpFirebase({
  String? signedInUid,
  String loginUid = patientUid,
}) async {
  db = FakeFirebaseFirestore();
  await db.collection('users').doc(doctorUid).set({
    'name': 'Dr. Carlos Sandoval',
    'email': 'doctor@test.com',
    'role': 'doctor',
  });
  await db.collection('users').doc(patientUid).set({
    'name': 'María Moreno',
    'email': 'paciente@test.com',
    'phone': '4420000000',
    'role': 'patient',
  });
  await db.collection('users').doc(adminUid).set({
    'name': 'Laura Admin',
    'email': 'admin@test.com',
    'role': 'admin',
  });
  await db.collection('users').doc(receptionistUid).set({
    'name': 'Pedro Recepción',
    'email': 'recepcion@test.com',
    'role': 'receptionist',
  });

  final uid = signedInUid ?? loginUid;
  final auth = MockFirebaseAuth(
    signedIn: signedInUid != null,
    mockUser: MockUser(uid: uid, email: _emails[uid] ?? 'paciente@test.com'),
  );
  AuthService.instance = AuthService(auth: auth, db: db);
  return auth;
}

const _emails = {
  doctorUid: 'doctor@test.com',
  patientUid: 'paciente@test.com',
  adminUid: 'admin@test.com',
  receptionistUid: 'recepcion@test.com',
};

Future<void> addAppointment({
  required String patientId,
  required String patientName,
  required DateTime date,
  AppointmentStatus status = AppointmentStatus.confirmada,
  String doctorName = 'Dra. Sofía Vega',
  String time = '10:00 AM',
}) {
  return db.collection('appointments').add({
    'patientId': patientId,
    'patientName': patientName,
    'doctorName': doctorName,
    'specialty': 'Limpieza Dental',
    'date': Timestamp.fromDate(date),
    'time': time,
    'status': status.name,
  });
}
