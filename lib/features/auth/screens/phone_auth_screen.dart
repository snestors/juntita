// ============================================================================
// 1. PANTALLA DE LOGIN - lib/features/auth/screens/phone_auth_screen.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';

import 'package:junta/shared/models/auth_state.dart';

class PhoneAuthScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedCountryCode = '+51'; // Perú por defecto
  bool _isCodeSent = false;

  final Map<String, String> _countryCodes = {
    '+51': '🇵🇪 Perú',
    '+58': '🇻🇪 Venezuela',
    '+57': '🇨🇴 Colombia',
    '+34': '🇪🇸 España',
    '+1': '🇺🇸 Estados Unidos',
  };

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    // Escuchar cambios de estado
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.codeSent) {
        setState(() => _isCodeSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message ?? 'Código enviado')),
        );
      } else if (next.status == AuthStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message ?? 'Error'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (next.status == AuthStatus.creatingProfile) {
        // Navegar a pantalla de perfil
        Navigator.pushReplacementNamed(context, '/create-profile');
      } else if (next.status == AuthStatus.authenticated) {
        // Navegar al dashboard
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Spacer(flex: 2),

                // Logo y título
                Column(
                  children: [
                    Icon(
                      Icons.phone_android,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Juntas App',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ingresa tu número de teléfono',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),

                Spacer(),

                // Formulario de teléfono
                if (!_isCodeSent) ...[
                  // Selector de país
                  DropdownButtonFormField<String>(
                    value: _selectedCountryCode,
                    decoration: InputDecoration(
                      labelText: 'País',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _countryCodes.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text('${entry.value} ${entry.key}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCountryCode = value!);
                    },
                  ),

                  SizedBox(height: 16),

                  // Campo de teléfono
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Número de teléfono',
                      hintText: _selectedCountryCode == '+51'
                          ? '987654321'
                          : '1234567890',
                      prefixText: '$_selectedCountryCode ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Ingresa tu número de teléfono';
                      }
                      if (value!.length < 8) {
                        return 'Número muy corto';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 24),

                  // Botón enviar código
                  ElevatedButton(
                    onPressed: authState.status == AuthStatus.sendingCode
                        ? null
                        : _sendVerificationCode,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: authState.status == AuthStatus.sendingCode
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Enviando...'),
                            ],
                          )
                        : Text(
                            'Enviar código de verificación',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ]
                // Formulario de código
                else ...[
                  Text(
                    'Código enviado a:',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$_selectedCountryCode ${_phoneController.text}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),

                  SizedBox(height: 24),

                  // Campo de código
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Código de verificación',
                      hintText: '000000',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      counterText: '',
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Ingresa el código';
                      }
                      if (value!.length != 6) {
                        return 'El código debe tener 6 dígitos';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 24),

                  // Botón verificar
                  ElevatedButton(
                    onPressed: authState.status == AuthStatus.verifyingCode
                        ? null
                        : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: authState.status == AuthStatus.verifyingCode
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Verificando...'),
                            ],
                          )
                        : Text(
                            'Verificar código',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),

                  SizedBox(height: 16),

                  // Botón reenviar código
                  TextButton(
                    onPressed: _sendVerificationCode,
                    child: Text('Reenviar código'),
                  ),

                  // Botón cambiar número
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isCodeSent = false;
                        _codeController.clear();
                      });
                      ref.read(authControllerProvider.notifier).clearError();
                    },
                    child: Text('Cambiar número'),
                  ),
                ],

                Spacer(flex: 2),

                // Términos y condiciones
                Text(
                  'Al continuar, aceptas nuestros Términos de Servicio y Política de Privacidad',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _sendVerificationCode() {
    if (!_formKey.currentState!.validate()) return;

    final phoneNumber = '$_selectedCountryCode${_phoneController.text}';
    ref.read(authControllerProvider.notifier).sendVerificationCode(phoneNumber);
  }

  void _verifyCode() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(authControllerProvider.notifier).verifyCode(_codeController.text);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }
}
