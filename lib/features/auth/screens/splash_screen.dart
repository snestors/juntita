// ============================================================================
// 3. SPLASH SCREEN - lib/features/auth/screens/splash_screen.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';

import 'package:junta/shared/models/auth_state.dart';

class SplashScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();

    // Esperar 3 segundos antes de verificar el estado de auth
    Future.delayed(Duration(seconds: 3), () {
      _checkAuthAndNavigate();
    });
  }

  void _checkAuthAndNavigate() {
    final authState = ref.read(authControllerProvider);

    switch (authState.status) {
      case AuthStatus.authenticated:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case AuthStatus.creatingProfile:
        Navigator.pushReplacementNamed(context, '/create-profile');
        break;
      default:
        Navigator.pushReplacementNamed(context, '/phone-auth');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios de estado durante el splash
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      // Solo navegar si el splash ya terminó
      if (_animationController.isCompleted) {
        switch (next.status) {
          case AuthStatus.authenticated:
            Navigator.pushReplacementNamed(context, '/dashboard');
            break;
          case AuthStatus.creatingProfile:
            Navigator.pushReplacementNamed(context, '/create-profile');
            break;
          case AuthStatus.unauthenticated:
            Navigator.pushReplacementNamed(context, '/phone-auth');
            break;
          default:
            break;
        }
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.groups,
                        size: 60,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),

                    SizedBox(height: 24),

                    // Título
                    Text(
                      'Juntas App',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 8),

                    // Subtítulo
                    Text(
                      'Ahorro en grupo, fácil y seguro',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),

                    SizedBox(height: 40),

                    // Loading indicator
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
