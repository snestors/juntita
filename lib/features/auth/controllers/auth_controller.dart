// ============================================================================
// 1. AUTH CONTROLLER CORREGIDO - lib/features/auth/controllers/auth_controller.dart
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:junta/shared/models/auth_state.dart';
import 'package:junta/shared/models/user_model.dart';
import '../services/auth_service.dart';

class AuthController extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthController(this._authService) : super(AuthState()) {
    _initializeAuth();
  }

  // Inicializar estado de autenticación
  Future<void> _initializeAuth() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        // Usuario no autenticado
        state = state.copyWith(status: AuthStatus.unauthenticated);
      } else {
        // Usuario autenticado, verificar si tiene perfil completo
        final userData = await _authService.getCurrentUserData();
        if (userData != null) {
          // Perfil completo
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: userData,
          );
          // Actualizar estado online
          await _authService.updateOnlineStatus(true);
        } else {
          // Usuario autenticado pero sin perfil
          state = state.copyWith(status: AuthStatus.creatingProfile);
        }
      }
    } catch (e) {
      print('Error inicializando auth: $e');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        message: 'Error verificando autenticación',
      );
    }

    // Escuchar cambios de autenticación
    _listenToAuthChanges();
  }

  // Escuchar cambios de estado de Firebase Auth
  void _listenToAuthChanges() {
    _authService.authStateChanges.listen((user) async {
      if (user == null) {
        // Usuario se deslogueó
        state = state.copyWith(status: AuthStatus.unauthenticated, user: null);
      } else {
        // Usuario se logueó, verificar perfil
        final userData = await _authService.getCurrentUserData();
        if (userData != null) {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: userData,
          );
          await _authService.updateOnlineStatus(true);
        } else {
          state = state.copyWith(status: AuthStatus.creatingProfile);
        }
      }
    });
  }

  // Enviar código de verificación
  Future<void> sendVerificationCode(String phoneNumber) async {
    state = state.copyWith(status: AuthStatus.sendingCode, message: null);

    final result = await _authService.sendVerificationCode(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId) {
        state = state.copyWith(
          status: AuthStatus.codeSent,
          verificationId: verificationId,
          message: 'Código enviado a $phoneNumber',
        );
      },
      onError: (error) {
        state = state.copyWith(status: AuthStatus.error, message: error);
      },
    );

    if (!result.isSuccess) {
      state = state.copyWith(status: AuthStatus.error, message: result.message);
    }
  }

  // Verificar código SMS
  Future<void> verifyCode(String smsCode) async {
    state = state.copyWith(status: AuthStatus.verifyingCode, message: null);

    final result = await _authService.verifyCode(
      smsCode: smsCode,
      verificationId: state.verificationId,
    );

    if (result.isSuccess) {
      // El listener de authStateChanges manejará la actualización del estado
      state = state.copyWith(message: 'Verificación exitosa');
    } else {
      state = state.copyWith(status: AuthStatus.error, message: result.message);
    }
  }

  // Crear perfil de usuario
  Future<void> createUserProfile(String name, [String? photoUrl]) async {
    state = state.copyWith(status: AuthStatus.creatingProfile, message: null);

    final result = await _authService.createUserProfile(
      name: name,
      photoUrl: photoUrl,
    );

    if (result.isSuccess) {
      // Obtener datos actualizados del usuario
      final userData = await _authService.getCurrentUserData();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: userData,
        message: 'Perfil creado exitosamente',
      );
    } else {
      state = state.copyWith(status: AuthStatus.error, message: result.message);
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    final result = await _authService.signOut();
    if (result.isSuccess) {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  // Limpiar errores
  void clearError() {
    if (state.status == AuthStatus.error) {
      state = state.copyWith(status: AuthStatus.initial, message: null);
    }
  }
}

// Providers
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(ref.read(authServiceProvider));
  },
);

// Provider del usuario actual
final currentUserProvider = StreamProvider<AppUser?>((ref) async* {
  final authService = ref.read(authServiceProvider);

  await for (final user in authService.authStateChanges) {
    if (user != null) {
      final userData = await authService.getCurrentUserData();
      yield userData;
    } else {
      yield null;
    }
  }
});
