// ============================================================================
// 3. ROUTER PROVIDER - lib/routes/router_provider.dart
// ============================================================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:junta/features/auth/providers/auth_provider.dart';
import 'package:junta/features/auth/screens/email_auth_screen.dart';
import 'package:junta/features/auth/screens/splash_screen.dart';
import 'package:junta/features/auth/screens/create_profile_screen.dart';
import 'package:junta/features/groups/screens/create_group_screen.dart';
import 'package:junta/features/groups/screens/dashboard_screen.dart';
import '../shared/models/auth_state.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) => _handleRedirect(ref, state.fullPath ?? '/'),
    refreshListenable: RouterRefreshNotifier(ref),
    routes: [
      GoRoute(path: '/', builder: (context, state) => SplashScreen()),
      GoRoute(path: '/auth', builder: (context, state) => const EmailAuthScreen()),
      GoRoute(
        path: '/create-profile',
        builder: (context, state) => CreateProfileScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => DashboardScreen(),
        routes: [
          GoRoute(
            path: 'create-group',
            builder: (context, state) => CreateGroupScreen(),
          ),
        ],
      ),
    ],
  );
});

String? _handleRedirect(Ref ref, String path) {
  final authState = ref.read(authStateProvider);

  switch (authState.status) {
    case AuthStatus.initial:
      return path == '/' ? null : '/';
    case AuthStatus.unauthenticated:
    case AuthStatus.error:
      return path == '/auth' ? null : '/auth';
    case AuthStatus.creatingProfile:
      return path == '/create-profile' ? null : '/create-profile';
    case AuthStatus.authenticated:
      return path.startsWith('/dashboard') ? null : '/dashboard';
    default:
      return null;
  }
}

class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (previous, next) {
      if (previous?.status != next.status) {
        notifyListeners();
      }
    });
  }
}
