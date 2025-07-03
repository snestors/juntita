import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  bool _hasNavigated = false;

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

    // Dar tiempo mínimo para la animación antes de verificar auth
    Future.delayed(Duration(milliseconds: 2500), () {
      _checkAuthState();
    });
  }

  void _checkAuthState() {
    if (!mounted || _hasNavigated) return;

    final authState = ref.read(authControllerProvider);
    _navigateBasedOnAuthState(authState);
  }

  void _navigateBasedOnAuthState(AuthState authState) {
    if (!mounted || _hasNavigated) return;

    _hasNavigated = true;

    switch (authState.status) {
      case AuthStatus.authenticated:
        context.go('/dashboard');
        break;
      case AuthStatus.creatingProfile:
        context.go('/create-profile');
        break;
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
      case AuthStatus.initial:
      default:
        context.go('/phone-auth');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios de estado de autenticación
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      // Solo navegar si la animación terminó y no hemos navegado aún
      if (_animationController.isCompleted && !_hasNavigated) {
        // Dar un pequeño delay para que la UI se estabilice
        Future.delayed(Duration(milliseconds: 500), () {
          _navigateBasedOnAuthState(next);
        });
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

                    SizedBox(height: 16),

                    // Estado de carga
                    Consumer(
                      builder: (context, ref, child) {
                        final authState = ref.watch(authControllerProvider);
                        String loadingText = 'Inicializando...';

                        switch (authState.status) {
                          case AuthStatus.initial:
                            loadingText = 'Verificando autenticación...';
                            break;
                          case AuthStatus.authenticated:
                            loadingText = 'Bienvenido de vuelta!';
                            break;
                          case AuthStatus.unauthenticated:
                            loadingText = 'Preparando login...';
                            break;
                          case AuthStatus.creatingProfile:
                            loadingText = 'Configurando perfil...';
                            break;
                          default:
                            loadingText = 'Cargando...';
                        }

                        return Text(
                          loadingText,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        );
                      },
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
