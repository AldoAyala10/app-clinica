import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../state/app_state.dart';

/// Error de autenticación con un mensaje listo para mostrar al usuario.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Envuelve Firebase Auth y el perfil del usuario en Firestore (`users/{uid}`).
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  /// Inicia sesión y devuelve el rol guardado en el perfil del usuario.
  Future<UserRole> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return await getRole(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  /// Crea la cuenta (siempre como paciente) y su perfil en Firestore.
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(name.trim());
      await _userDoc(user.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'role': UserRole.patient.name,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Ficha clínica visible para el doctor; usa el mismo id que la cuenta.
      await _db.collection('patients').doc(user.uid).set({
        'userId': user.uid,
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'treatment': '',
        'lastVisit': FieldValue.serverTimestamp(),
        'avatarColor': 0xFF3B82F6,
        'medicalAlerts': <String>[],
      });
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  /// Lee el rol del perfil. Si no existe el documento, se asume paciente.
  Future<UserRole> getRole(String uid) async {
    final snapshot = await _userDoc(uid).get();
    final role = snapshot.data()?['role'];
    return role == UserRole.doctor.name ? UserRole.doctor : UserRole.patient;
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;
    final snapshot = await _userDoc(user.uid).get();
    return snapshot.data();
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  Future<void> signOut() => _auth.signOut();

  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo.';
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta de nuevo más tarde.';
      case 'network-request-failed':
        return 'Sin conexión a internet. Revisa tu red.';
      case 'operation-not-allowed':
        return 'El inicio de sesión con correo no está habilitado en Firebase.';
      default:
        return 'Ocurrió un error (${e.code}). Intenta de nuevo.';
    }
  }
}
