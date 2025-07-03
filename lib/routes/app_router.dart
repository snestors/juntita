import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/phone_auth_screen.dart';
import '../features/auth/screens/create_profile_screen.dart';
import '../features/groups/screens/dashboard_screen.dart';
import '../features/groups/screens/create_group_screen.dart';
import '../features/auth/controllers/auth_controller.dart';

import 'package:junta/shared/models/auth_state.dart';

// Provider del estado de navegación
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final currentLocation = state.uri.path;

      // Rutas que no requieren redirección
      final isOnSplash = currentLocation == '/';
      final isOnAuth = currentLocation == '/phone-auth';
      final isOnProfile = currentLocation == '/create-profile';

      // Si está en splash, dejar que el splash maneje la navegación
      if (isOnSplash) return null;

      switch (authState.status) {
        case AuthStatus.initial:
        case AuthStatus.sendingCode:
        case AuthStatus.codeSent:
        case AuthStatus.verifyingCode:
        case AuthStatus.unauthenticated:
          return isOnAuth ? null : '/phone-auth';

        case AuthStatus.creatingProfile:
          return isOnProfile ? null : '/create-profile';

        case AuthStatus.authenticated:
          return (isOnAuth || isOnProfile) ? '/dashboard' : null;

        case AuthStatus.error:
          return isOnAuth ? null : '/phone-auth';
      }
    },
    refreshListenable: _AuthChangeNotifier(ref),
    routes: [
      // Splash
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => SplashScreen(),
      ),

      // Auth
      GoRoute(
        path: '/phone-auth',
        name: 'phone-auth',
        builder: (context, state) => PhoneAuthScreen(),
      ),

      // Create Profile
      GoRoute(
        path: '/create-profile',
        name: 'create-profile',
        builder: (context, state) => CreateProfileScreen(),
      ),

      // Dashboard
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => DashboardScreen(),
        routes: [
          // Create Group como subruta
          GoRoute(
            path: 'create-group',
            name: 'create-group',
            builder: (context, state) => CreateGroupScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Página no encontrada', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text(
              state.error?.toString() ?? 'Error desconocido',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: Text('Ir al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
});

// Clase helper para notificar cambios de auth a GoRouter
class _AuthChangeNotifier extends ChangeNotifier {
  final Ref _ref;

  _AuthChangeNotifier(this._ref) {
    _ref.listen(authControllerProvider, (previous, next) {
      notifyListeners();
    });
  }
}
