// ============================================================================
// 6. MAIN APP PROVIDER - lib/core/providers/app_provider.dart
// ============================================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:junta/features/auth/providers/auth_provider.dart';
import 'package:junta/shared/models/auth_state.dart';

// Re-exportar todos los providers principales para fácil acceso

export '../../../features/groups/providers/group_providers.dart';
export '../../../features/contacts/providers/contact_providers.dart';

export '../../../core/providers/service_providers.dart';

// Provider para verificar si está autenticado
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.status == AuthStatus.authenticated;
});

// Provider para verificar si necesita perfil
final needsProfileProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.status == AuthStatus.creatingProfile;
});
