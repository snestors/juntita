// ============================================================================
// 1. AUTH PROVIDER REACTIVO - lib/features/auth/providers/auth_provider.dart
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:junta/features/auth/controllers/auth_controller.dart';
import 'package:junta/shared/models/auth_state.dart';
import '../services/auth_service.dart';

// Stream provider reactivo para el estado de auth
final authProvider = StreamProvider<AuthState?>((ref) async* {
  final authService = ref.read(authServiceProvider);

  // Escuchar cambios de Firebase Auth
  await for (final firebaseUser in FirebaseAuth.instance.authStateChanges()) {
    if (firebaseUser == null) {
      // Usuario no autenticado
      yield AuthState(status: AuthStatus.unauthenticated);
    } else {
      // Usuario autenticado, verificar perfil
      try {
        final userData = await authService.getCurrentUserData();
        if (userData != null) {
          // Perfil completo
          yield AuthState(status: AuthStatus.authenticated, user: userData);
        } else {
          // Usuario sin perfil completo
          yield AuthState(status: AuthStatus.creatingProfile);
        }
      } catch (e) {
        print('Error obteniendo datos del usuario: $e');
        yield AuthState(
          status: AuthStatus.error,
          message: 'Error verificando perfil',
        );
      }
    }
  }
});

// Notifier para acciones de auth
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<AuthState?>>((ref) {
      return AuthNotifier(ref.read(authServiceProvider));
    });

class AuthNotifier extends StateNotifier<AsyncValue<AuthState?>> {
  final AuthService _authService;
  String? _verificationId;

  AuthNotifier(this._authService) : super(const AsyncValue.loading());

  // Enviar código de verificación
  Future<void> sendVerificationCode(String phoneNumber) async {
    state = const AsyncValue.loading();

    try {
      await _authService.sendVerificationCode(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId) {
          _verificationId = verificationId;
          state = AsyncValue.data(
            AuthState(
              status: AuthStatus.codeSent,
              verificationId: verificationId,
              message: 'Código enviado a $phoneNumber',
            ),
          );
        },
        onError: (error) {
          state = AsyncValue.data(
            AuthState(status: AuthStatus.error, message: error),
          );
        },
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Verificar código SMS
  Future<void> verifyCode(String smsCode) async {
    state = const AsyncValue.loading();

    try {
      final result = await _authService.verifyCode(
        smsCode: smsCode,
        verificationId: _verificationId,
      );

      if (result.isSuccess) {
        // Firebase Auth se encargará de actualizar el stream
        state = AsyncValue.data(
          AuthState(
            status: AuthStatus.verifyingCode,
            message: 'Verificación exitosa',
          ),
        );
      } else {
        state = AsyncValue.data(
          AuthState(status: AuthStatus.error, message: result.message),
        );
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Crear perfil de usuario
  Future<void> createUserProfile(String name, [String? photoUrl]) async {
    state = const AsyncValue.loading();

    try {
      final result = await _authService.createUserProfile(
        name: name,
        photoUrl: photoUrl,
      );

      if (result.isSuccess) {
        // El stream provider se actualizará automáticamente
        state = AsyncValue.data(
          AuthState(
            status: AuthStatus.creatingProfile,
            message: 'Perfil creado exitosamente',
          ),
        );
      } else {
        state = AsyncValue.data(
          AuthState(status: AuthStatus.error, message: result.message),
        );
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      state = AsyncValue.data(AuthState(status: AuthStatus.unauthenticated));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Limpiar estado
  void clearState() {
    state = AsyncValue.data(AuthState(status: AuthStatus.initial));
  }
}
