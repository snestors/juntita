// lib/features/auth/screens/phone_auth_screen_fixed.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:junta/core/providers/app_provider.dart';
import '../../../shared/models/auth_state.dart';
import 'package:junta/features/auth/providers/auth_provider.dart';

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
  void initState() {
    super.initState();

    // Escuchar cambios de estado para navegación manual si es necesario
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToAuthChanges();
    });
  }

  void _listenToAuthChanges() {
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      print('📱 Auth state en phone screen: ${next.status.name}');

      if (!mounted) return;

      switch (next.status) {
        case AuthStatus.codeSent:
          setState(() => _isCodeSent = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.message ?? 'Código enviado')),
          );
          break;

        case AuthStatus.error:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.message ?? 'Error'),
              backgroundColor: Colors.red,
            ),
          );
          break;

        case AuthStatus.creatingProfile:
          print('📝 Navegando a create-profile desde phone screen');
          context.go('/create-profile');
          break;

        case AuthStatus.authenticated:
          print('✅ Navegando a dashboard desde phone screen');
          context.go('/dashboard');
          break;
        case AuthStatus.initial:
          // TODO: Handle this case.
          throw UnimplementedError();
        case AuthStatus.sendingCode:
          // TODO: Handle this case.
          throw UnimplementedError();
        case AuthStatus.verifyingCode:
          // TODO: Handle this case.
          throw UnimplementedError();
        case AuthStatus.unauthenticated:
          // TODO: Handle this case.
          throw UnimplementedError();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

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

                // Debug info
                if (!const bool.fromEnvironment('dart.vm.product'))
                  Container(
                    padding: EdgeInsets.all(8),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Debug: ${authState.status.name}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ),

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
                      ref.read(authStateProvider.notifier).clearError();
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
    ref.read(authStateProvider.notifier).sendVerificationCode(phoneNumber);
  }

  void _verifyCode() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(authStateProvider.notifier).verifyCode(_codeController.text);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }
}

// ============================================================================
// CREATE PROFILE SCREEN CON NAVEGACIÓN MANUAL
// ============================================================================

class CreateProfileScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<CreateProfileScreen> createState() =>
      _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToAuthChanges();
    });
  }

  void _listenToAuthChanges() {
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      print('👤 Auth state en create profile: ${next.status.name}');

      if (!mounted) return;

      switch (next.status) {
        case AuthStatus.authenticated:
          print('✅ Navegando a dashboard desde create profile');
          context.go('/dashboard');
          break;

        case AuthStatus.unauthenticated:
          print('🚪 Navegando a auth desde create profile');
          context.go('/auth');
          break;

        case AuthStatus.error:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.message ?? 'Error'),
              backgroundColor: Colors.red,
            ),
          );
          break;
        case AuthStatus.initial:
          // TODO: Handle this case.
          throw UnimplementedError();
        case AuthStatus.sendingCode:
          // TODO: Handle this case.
          throw UnimplementedError();
        case AuthStatus.codeSent:
          // TODO: Handle this case.
          throw UnimplementedError();
        case AuthStatus.verifyingCode:
          // TODO: Handle this case.
          throw UnimplementedError();
        case AuthStatus.creatingProfile:
          // TODO: Handle this case.
          throw UnimplementedError();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Spacer(),

                // Título
                Column(
                  children: [
                    Icon(
                      Icons.person_add,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Completa tu perfil',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ayúdanos a conocerte mejor',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),

                Spacer(),

                // Debug info
                if (!const bool.fromEnvironment('dart.vm.product'))
                  Container(
                    padding: EdgeInsets.all(8),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Debug: ${authState.status.name}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Avatar (opcional por ahora)
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey[600],
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: IconButton(
                            icon: Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Función de foto próximamente'),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32),

                // Campo de nombre
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Nombre completo',
                    hintText: 'Ej: Juan Pérez',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Ingresa tu nombre';
                    }
                    if (value!.length < 2) {
                      return 'Nombre muy corto';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 32),

                // Botón crear perfil
                ElevatedButton(
                  onPressed:
                      authState.status == AuthStatus.creatingProfile &&
                          authState.message?.contains('creando') == true
                      ? null
                      : _createProfile,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      authState.status == AuthStatus.creatingProfile &&
                          authState.message?.contains('creando') == true
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Creando perfil...'),
                          ],
                        )
                      : Text('Crear perfil', style: TextStyle(fontSize: 16)),
                ),

                Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _createProfile() {
    if (!_formKey.currentState!.validate()) return;

    ref
        .read(authStateProvider.notifier)
        .createProfile(_nameController.text);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
