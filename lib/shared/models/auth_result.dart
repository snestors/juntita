class AuthResult {
  final bool isSuccess;
  final String message;
  final String? errorCode;

  AuthResult.success(this.message) : isSuccess = true, errorCode = null;

  AuthResult.error(this.message, [this.errorCode]) : isSuccess = false;

  @override
  String toString() => message;
}
