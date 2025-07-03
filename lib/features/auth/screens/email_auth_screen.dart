import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:junta/shared/models/auth_state.dart';
import 'package:junta/features/auth/providers/auth_provider.dart';

class EmailAuthScreen extends ConsumerStatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  ConsumerState<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends ConsumerState<EmailAuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen<AuthState>(authStateProvider, (previous, next) {
        if (!mounted) return;
        switch (next.status) {
          case AuthStatus.creatingProfile:
            context.go('/create-profile');
            break;
          case AuthStatus.authenticated:
            context.go('/dashboard');
            break;
          case AuthStatus.error:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(next.message ?? 'Error'), backgroundColor: Colors.red),
            );
            break;
          default:
            break;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || v.isEmpty ? 'Ingresa tu email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  obscureText: true,
                  validator: (v) => v == null || v.length < 6 ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: authState.status == AuthStatus.verifyingCode ? null : _login,
                  child: const Text('Iniciar sesión'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: authState.status == AuthStatus.sendingCode ? null : _register,
                  child: const Text('Registrarme'),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authStateProvider.notifier).signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
  }

  void _register() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authStateProvider.notifier).signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
