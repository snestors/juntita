// ============================================================================
// 2. AUTH PROVIDERS - lib/features/auth/providers/auth_providers.dart
// ============================================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../shared/models/auth_state.dart';
import '../../../core/providers/service_providers.dart';

// Stream del usuario de Firebase
final firebaseUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Estado de autenticación
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  String? _verificationId;

  AuthNotifier(this._ref) : super(AuthState()) {
    _initAuth();
  }

  void _initAuth() {
    // Escuchar cambios del usuario de Firebase
    _ref.listen(firebaseUserProvider, (previous, next) {
      next.whenData((user) => _handleUserChange(user));
    });
  }

  Future<void> _handleUserChange(User? user) async {
    if (user == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated, user: null);
      return;
    }

    // Usuario existe, verificar perfil
    final authService = _ref.read(authServiceProvider);
    final userData = await authService.getCurrentUserData();

    if (userData != null) {
      state = state.copyWith(status: AuthStatus.authenticated, user: userData);
    } else {
      state = state.copyWith(status: AuthStatus.creatingProfile);
    }
  }

  Future<void> sendVerificationCode(String phoneNumber) async {
    state = state.copyWith(status: AuthStatus.sendingCode);

    final authService = _ref.read(authServiceProvider);
    await authService.sendVerificationCode(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId) {
        _verificationId = verificationId;
        state = state.copyWith(
          status: AuthStatus.codeSent,
          verificationId: verificationId,
        );
      },
      onError: (error) {
        state = state.copyWith(status: AuthStatus.error, message: error);
      },
    );
  }

  Future<void> verifyCode(String code) async {
    state = state.copyWith(status: AuthStatus.verifyingCode);

    final authService = _ref.read(authServiceProvider);
    final result = await authService.verifyCode(
      smsCode: code,
      verificationId: _verificationId,
    );

    if (!result.isSuccess) {
      state = state.copyWith(status: AuthStatus.error, message: result.message);
    }
  }

  Future<void> createProfile(String name) async {
    state = state.copyWith(status: AuthStatus.creatingProfile);

    final authService = _ref.read(authServiceProvider);
    final result = await authService.createUserProfile(name: name);

    if (!result.isSuccess) {
      state = state.copyWith(status: AuthStatus.error, message: result.message);
    }
  }

  Future<void> signOut() async {
    final authService = _ref.read(authServiceProvider);
    await authService.signOut();
  }

  void clearError() {
    if (state.status == AuthStatus.error) {
      state = state.copyWith(status: AuthStatus.initial, message: null);
    }
  }
}
