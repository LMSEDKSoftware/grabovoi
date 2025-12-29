import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/golden_sphere.dart';
import '../../widgets/subscription_welcome_modal.dart';
import '../../services/auth_service_simple.dart';
import '../../services/biometric_auth_service.dart';
import 'register_screen.dart';
import '../../widgets/auth_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthServiceSimple _authService = AuthServiceSimple();
  final BiometricAuthService _biometricService = BiometricAuthService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _saveForBiometric = false;
  bool _biometricAvailable = false;
  bool _hasBiometricCredentials = false;
  String _biometricTypeName = 'Biometría';
  String? _errorMessage;
  String _appVersion = 'v.2.1.1';

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = 'v.${packageInfo.version}';
        });
      }
    } catch (e) {
      print('Error cargando versión: $e');
      // Mantener versión por defecto si falla
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final isSupported = await _biometricService.isDeviceSupported();
      final canCheck = await _biometricService.canCheckBiometrics();
      final hasCredentials = await _authService.hasBiometricCredentials();
      
      String biometricTypeName = 'Biometría';
      if (isSupported && canCheck) {
        biometricTypeName = await _biometricService.getBiometricTypeName();
      }
      
      if (mounted) {
        setState(() {
          _biometricAvailable = isSupported && canCheck;
          _hasBiometricCredentials = hasCredentials;
          _biometricTypeName = biometricTypeName;
        });
        
        // Si hay credenciales guardadas, intentar autenticación biométrica automática
        if (_hasBiometricCredentials && _biometricAvailable) {
          // Esperar un momento antes de mostrar el diálogo
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            _signInWithBiometric();
          }
        }
      }
    } catch (e) {
      print('Error verificando disponibilidad biométrica: $e');
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        saveForBiometric: _saveForBiometric && _biometricAvailable,
      );

      if (mounted) {
        // Verificar si debe mostrar el modal de bienvenida de suscripción (para usuarios nuevos)
        final shouldShowModal = await SubscriptionWelcomeModal.shouldShowModal();
        
        if (shouldShowModal) {
          // Mostrar modal de bienvenida de suscripción antes de navegar
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const SubscriptionWelcomeModal(),
          );
        }
        
        // Navegar de vuelta a AuthWrapper para que detecte el login exitoso
        // y muestre la pantalla correcta (MainNavigation o UserAssessmentScreen)
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthWrapper()),
            (route) => false, // Eliminar todas las rutas anteriores
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithBiometric() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithBiometric();

      if (mounted) {
        // Verificar si debe mostrar el modal de bienvenida de suscripción (para usuarios nuevos)
        final shouldShowModal = await SubscriptionWelcomeModal.shouldShowModal();
        
        if (shouldShowModal) {
          // Mostrar modal de bienvenida de suscripción
          // El modal navegará a MainNavigation después de cerrarse
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const SubscriptionWelcomeModal(),
          );
          // No navegar aquí, el modal se encarga de navegar
        } else {
          // Si no se muestra el modal, navegar directamente a AuthWrapper
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthWrapper()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithGoogle();
      
      if (mounted) {
        // Verificar si debe mostrar el modal de bienvenida de suscripción (para usuarios nuevos)
        final shouldShowModal = await SubscriptionWelcomeModal.shouldShowModal();
        
        if (shouldShowModal) {
          // Mostrar modal de bienvenida de suscripción antes de navegar
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const SubscriptionWelcomeModal(),
          );
        }
        
        // Navegar de vuelta a AuthWrapper para que detecte el login exitoso
        // y muestre la pantalla correcta (MainNavigation o UserAssessmentScreen)
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthWrapper()),
            (route) => false, // Eliminar todas las rutas anteriores
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Credenciales inválidas. Verifica tu email y contraseña.';
    } else if (error.contains('Email not confirmed')) {
      return 'Por favor confirma tu email antes de iniciar sesión.';
    } else if (error.contains('Too many requests')) {
      return 'Demasiados intentos. Espera un momento antes de intentar nuevamente.';
    } else if (error.contains('not enabled') || error.contains('Unsupported provider')) {
      return 'Google OAuth no está habilitado. Por favor, contacta al administrador.';
    } else {
      return 'Error al iniciar sesión. Inténtalo nuevamente.';
    }
  }

  Future<void> _handleForgotPassword() async {
    // Mostrar diálogo para ingresar email
    final emailController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: Text(
          'Recuperar Contraseña',
          style: GoogleFonts.inter(
            color: const Color(0xFFFFD700),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ingresa tu email y te enviaremos un enlace para restablecer tu contraseña.',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'tu@email.com',
                hintStyle: GoogleFonts.inter(color: Colors.white54),
                prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFFFD700)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(
                color: Colors.white54,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Enviar',
              style: GoogleFonts.inter(
                color: const Color(0xFF1a1a2e),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true && emailController.text.isNotEmpty) {
      final email = emailController.text.trim();
      
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Por favor ingresa un email válido'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        await _authService.resetPassword(email: email);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Código OTP enviado. Revisa tu correo electrónico.'),
              backgroundColor: Color(0xFFFFD700),
              duration: Duration(seconds: 4),
            ),
          );
          
          // Mostrar diálogo para ingresar el código OTP
          await _showResetPasswordDialog(email);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getErrorMessage(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Diálogo para ingresar código OTP y verificar
  Future<void> _showResetPasswordDialog(String email) async {
    final tokenController = TextEditingController();
    bool isLoading = false;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1a1a2e),
          title: Text(
            'Verificar Código',
            style: GoogleFonts.inter(
              color: const Color(0xFFFFD700),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Paso 1: Ingresa el código de 6 dígitos que recibiste por email.',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Puedes copiar y pegar el código desde tu correo.',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Campo para el código/token
                TextField(
                  controller: tokenController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  autofocus: true,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 28,
                    letterSpacing: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: 'Código OTP',
                    labelStyle: GoogleFonts.inter(color: Colors.white70),
                    hintText: '123456',
                    hintStyle: GoogleFonts.inter(
                      color: Colors.white30,
                      fontSize: 28,
                      letterSpacing: 10,
                    ),
                    prefixIcon: const Icon(Icons.vpn_key, color: Color(0xFFFFD700)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
                    ),
                    counterText: '',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: GoogleFonts.inter(
                  color: isLoading ? Colors.white30 : Colors.white54,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (tokenController.text.isEmpty || tokenController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor ingresa el código de 6 dígitos'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                setDialogState(() {
                  isLoading = true;
                });
                
                try {
                  // Verificar el código OTP
                  final recoveryLink = await _authService.verifyOTPAndGetRecoveryLink(
                    email: email,
                    token: tokenController.text,
                  );
                  
                  if (context.mounted) {
                    // PASO 2: Mostrar mensaje de éxito "OTP correcto" EN EL DIÁLOGO
                    setDialogState(() {
                      isLoading = false;
                    });
                    
                    // Mostrar diálogo de éxito antes de cerrar
                    Navigator.of(context).pop(); // Cerrar diálogo de entrada de OTP
                    
                    // Mostrar diálogo de éxito
                    await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1a1a2e),
                        title: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 32),
                            const SizedBox(width: 12),
                            Text(
                              'OTP Correcto',
                              style: GoogleFonts.inter(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                        content: Text(
                          'Tu código de verificación es válido. Te redirigiremos al siguiente paso para cambiar tu contraseña.',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        actions: [
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD700),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Continuar',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF1a1a2e),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                    
                    // Esperar un momento antes de abrir el link
                    await Future.delayed(const Duration(milliseconds: 500));
                    
                    // PASO 3: Abrir el link para cambiar contraseña
                    final uri = Uri.parse(recoveryLink);
                    
                    print('🔗 Abriendo continue URL (página PHP): ${uri.toString().substring(0, 100)}...');
                    
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                      
                      // Mostrar mensaje final
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Abre tu navegador para cambiar tu contraseña'),
                            backgroundColor: Color(0xFFFFD700),
                            duration: Duration(seconds: 4),
                          ),
                        );
                      }
                    } else {
                      throw Exception('No se pudo abrir el enlace de recuperación');
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_getErrorMessage(e.toString())),
                        backgroundColor: Colors.red,
                      ),
                    );
                    setDialogState(() {
                      isLoading = false;
                    });
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF1a1a2e),
                      ),
                    )
                  : Text(
                      'Verificar',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1a1a2e),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  
                  // Logo y título con diseño mejorado
                  Column(
                    children: [
                      // Esfera dorada reducida para compactar
                      const GoldenSphere(
                        size: 120,
                        color: Color(0xFFFFD700),
                        glowIntensity: 0.9,
                        isAnimated: true,
                      ),
                      // Letrero semitransparente con el título (superpuesto)
                      Transform.translate(
                        offset: const Offset(0, -120),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1a1a2e).withOpacity(0.75),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Título principal
                              Text(
                                'ManiGrab',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFFD700),
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              // Subtítulo (marca)
                              Text(
                                'Manifestaciones Cuánticas Grabovoi',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 2),
                              // Lema
                              Text(
                                'Tu viaje de transformación personal',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -80),
                        child: Column(
                          children: [
                            // "Bienvenid@ de Vuelta" en dorado, reducido
                            Text(
                              'Bienvenid@ de Vuelta',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFFD700),
                                letterSpacing: 1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Formulario de login
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'tu@email.com',
                          hintStyle: GoogleFonts.inter(color: Colors.white54),
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFFFFD700)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Por favor ingresa un email válido';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contraseña',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Tu contraseña',
                          hintStyle: GoogleFonts.inter(color: Colors.white54),
                          prefixIcon: const Icon(Icons.lock_outlined, color: Color(0xFFFFD700)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white54,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu contraseña';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Checkbox para guardar credenciales biométricas
                  if (_biometricAvailable)
                    Row(
                      children: [
                        Checkbox(
                          value: _saveForBiometric,
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _saveForBiometric = value ?? false;
                                  });
                                },
                          activeColor: const Color(0xFFFFD700),
                          checkColor: const Color(0xFF1a1a2e),
                        ),
                        Expanded(
                          child: Text(
                            'Usar $_biometricTypeName para iniciar sesión',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  
                  // Olvidé mi contraseña
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _handleForgotPassword,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        '¿Olvidaste tu contraseña?',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFFD700),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Mensaje de error
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.inter(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Botón de login
                  CustomButton(
                    text: _isLoading ? 'Iniciando Sesión...' : 'Iniciar Sesión',
                    onPressed: _isLoading ? null : _signIn,
                    isLoading: _isLoading,
                    icon: Icons.login,
                  ),
                  
                  // Botón de autenticación biométrica (si hay credenciales guardadas)
                  if (_biometricAvailable && _hasBiometricCredentials && !_isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        children: [
                          // Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'O',
                                  style: GoogleFonts.inter(
                                    color: Colors.white54,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Botón biométrico
                          OutlinedButton.icon(
                            onPressed: _signInWithBiometric,
                            icon: Icon(
                              _biometricTypeName.toLowerCase().contains('face')
                                  ? Icons.face
                                  : Icons.fingerprint,
                              color: const Color(0xFFFFD700),
                              size: 24,
                            ),
                            label: Text(
                              'Iniciar con $_biometricTypeName',
                              style: GoogleFonts.inter(
                                color: const Color(0xFFFFD700),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              side: const BorderSide(color: Color(0xFFFFD700), width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: const Color(0xFFFFD700).withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'O continúa con',
                          style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.white.withOpacity(0.3))),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Botón de Google
                  CustomButton(
                    text: 'Continuar con Google',
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    isOutlined: true,
                    icon: Icons.g_mobiledata,
                    color: Colors.white,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Enlace a registro
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿No tienes cuenta? ',
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Regístrate aquí',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFFD700),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Versión y crédito
                  Column(
                    children: [
                      Text(
                        _appVersion,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFFFFD700),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'creado por Iván Fernández Almaguer',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
