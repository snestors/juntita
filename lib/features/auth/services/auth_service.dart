// ============================================================================
// 1. AUTH SERVICE - lib/features/auth/services/auth_service.dart
// ============================================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:junta/shared/models/auth_result.dart';
import 'package:junta/shared/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _verificationId;
  int? _resendToken;

  // Stream del estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuario actual
  User? get currentUser => _auth.currentUser;

  // Verificar si el usuario está logueado
  bool get isLoggedIn => currentUser != null;

  // 1. ENVIAR CÓDIGO SMS
  Future<AuthResult> sendVerificationCode({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verificación en algunos dispositivos Android
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          String errorMessage = _getErrorMessage(e);
          onError(errorMessage);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        forceResendingToken: _resendToken,
        timeout: Duration(seconds: 60),
      );

      return AuthResult.success('Código enviado correctamente');
    } catch (e) {
      return AuthResult.error('Error enviando código: $e');
    }
  }

  // 2. VERIFICAR CÓDIGO SMS
  Future<AuthResult> verifyCode({
    required String smsCode,
    String? verificationId,
  }) async {
    try {
      final String vId = verificationId ?? _verificationId ?? '';

      if (vId.isEmpty) {
        return AuthResult.error('ID de verificación no válido');
      }

      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: vId,
        smsCode: smsCode,
      );

      final UserCredential result = await _signInWithCredential(credential);

      if (result.user != null) {
        return AuthResult.success('Verificación exitosa');
      } else {
        return AuthResult.error('Error en la verificación');
      }
    } catch (e) {
      return AuthResult.error(_getErrorMessage(e));
    }
  }

  // 3. INICIAR SESIÓN CON CREDENCIAL
  Future<UserCredential> _signInWithCredential(
    PhoneAuthCredential credential,
  ) async {
    return await _auth.signInWithCredential(credential);
  }

  // INICIAR SESIÓN CON EMAIL Y CONTRASEÑA
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AuthResult.success('Sesión iniciada');
    } catch (e) {
      return AuthResult.error(_getErrorMessage(e));
    }
  }

  // REGISTRAR USUARIO CON EMAIL Y CONTRASEÑA
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AuthResult.success('Cuenta creada');
    } catch (e) {
      return AuthResult.error(_getErrorMessage(e));
    }
  }

  // 4. CREAR/ACTUALIZAR PERFIL DE USUARIO
  Future<AuthResult> createUserProfile({
    required String name,
    String? photoUrl,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return AuthResult.error('Usuario no autenticado');
      }

      // Verificar si el usuario ya existe
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      final appUser = AppUser(
        id: user.uid,
        name: name,
        email: user.email ?? '',
        phone: user.phoneNumber,
        photoUrl: photoUrl,
        createdAt: userDoc.exists
            ? DateTime.fromMillisecondsSinceEpoch(userDoc.data()!['createdAt'])
            : DateTime.now(),
        isOnline: true,
      );

      // Guardar en Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(appUser.toMap(), SetOptions(merge: true));

      return AuthResult.success('Perfil creado exitosamente');
    } catch (e) {
      return AuthResult.error('Error creando perfil: $e');
    }
  }

  // 5. OBTENER DATOS DEL USUARIO ACTUAL
  Future<AppUser?> getCurrentUserData() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      return AppUser.fromMap({...doc.data()!, 'id': doc.id});
    } catch (e) {
      print('Error obteniendo datos del usuario: $e');
      return null;
    }
  }

  // 6. ACTUALIZAR ESTADO ONLINE
  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      final user = currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error actualizando estado: $e');
    }
  }

  // 7. CERRAR SESIÓN
  Future<AuthResult> signOut() async {
    try {
      await updateOnlineStatus(false);
      await _auth.signOut();
      return AuthResult.success('Sesión cerrada');
    } catch (e) {
      return AuthResult.error('Error cerrando sesión: $e');
    }
  }

  // 8. ELIMINAR CUENTA
  Future<AuthResult> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) {
        return AuthResult.error('Usuario no autenticado');
      }

      // Eliminar datos de Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Eliminar cuenta de Firebase Auth
      await user.delete();

      return AuthResult.success('Cuenta eliminada');
    } catch (e) {
      return AuthResult.error('Error eliminando cuenta: $e');
    }
  }

  // HELPER: Convertir errores de Firebase a mensajes legibles
  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-phone-number':
          return 'Número de teléfono inválido';
        case 'invalid-email':
          return 'Email inválido';
        case 'user-not-found':
          return 'Usuario no encontrado';
        case 'wrong-password':
          return 'Contraseña incorrecta';
        case 'email-already-in-use':
          return 'El email ya está en uso';
        case 'too-many-requests':
          return 'Demasiados intentos. Intenta más tarde';
        case 'invalid-verification-code':
          return 'Código de verificación inválido';
        case 'invalid-verification-id':
          return 'ID de verificación inválido';
        case 'quota-exceeded':
          return 'Cuota de SMS excedida. Intenta más tarde';
        case 'missing-phone-number':
          return 'Número de teléfono requerido';
        case 'user-disabled':
          return 'Usuario deshabilitado';
        case 'operation-not-allowed':
          return 'Operación no permitida';
        default:
          return error.message ?? 'Error desconocido';
      }
    }
    return error.toString();
  }
}
