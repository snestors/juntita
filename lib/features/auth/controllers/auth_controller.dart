import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:junta/shared/models/auth_state.dart';
import 'package:junta/shared/models/user_model.dart';
import '../services/auth_service.dart';

class AuthController extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthController(this._authService) : super(AuthState()) {
    _checkAuthState();
  }

  // Verificar estado inicial
  void _checkAuthState() {
    _authService.authStateChanges.listen((user) async {
      if (user != null) {
        final userData = await _authService.getCurrentUserData();
        if (userData != null) {
          state = state.copyWith(
            status: AuthStatus.authenticated,
            user: userData,
          );
        } else {
          // Usuario autenticado pero sin perfil completo
          state = state.copyWith(status: AuthStatus.creatingProfile);
        }
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated, user: null);
      }
    });
  }

  // Enviar código de verificación
  Future<void> sendVerificationCode(String phoneNumber) async {
    state = state.copyWith(status: AuthStatus.sendingCode);

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
    state = state.copyWith(status: AuthStatus.verifyingCode);

    final result = await _authService.verifyCode(
      smsCode: smsCode,
      verificationId: state.verificationId,
    );

    if (result.isSuccess) {
      // La verificación fue exitosa, AuthStateChanges se encargará del resto
      state = state.copyWith(message: 'Verificación exitosa');
    } else {
      state = state.copyWith(status: AuthStatus.error, message: result.message);
    }
  }

  // Crear perfil de usuario
  Future<void> createUserProfile(String name, [String? photoUrl]) async {
    state = state.copyWith(status: AuthStatus.creatingProfile);

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
    state = state.copyWith(status: AuthStatus.initial, message: null);
  }
}

// Provider del AuthController
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(AuthService());
  },
);

// Provider del AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

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
