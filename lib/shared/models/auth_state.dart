import 'package:junta/shared/models/user_model.dart';

enum AuthStatus {
  initial,
  sendingCode,
  codeSent,
  verifyingCode,
  creatingProfile,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final String? message;
  final String? verificationId;
  final AppUser? user;

  AuthState({
    this.status = AuthStatus.initial,
    this.message,
    this.verificationId,
    this.user,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? message,
    String? verificationId,
    AppUser? user,
  }) {
    return AuthState(
      status: status ?? this.status,
      message: message ?? this.message,
      verificationId: verificationId ?? this.verificationId,
      user: user ?? this.user,
    );
  }
}
