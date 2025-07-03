// ============================================================================
// 3. ROUTING SIMPLIFICADO - lib/routes/app_router.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/phone_auth_screen.dart';
import '../features/auth/screens/create_profile_screen.dart';
import '../features/groups/screens/dashboard_screen.dart';
import '../features/groups/screens/create_group_screen.dart';

// Router simplificado sin redirect complejo
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
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
            Text('Página no encontrada'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: Text('Ir al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
});
