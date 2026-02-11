import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

/// Pantalla para establecer nueva contraseña después de verificar OTP
/// Se activa mediante deep link o URL /recovery con access_token y refresh_token
/// O con recoveryToken para procesar directamente en mobile
class RecoverySetPasswordScreen extends StatefulWidget {
  final String? accessToken;
  final String? refreshToken;
  final String? recoveryToken; // Token de recovery para procesar en mobile

  const RecoverySetPasswordScreen({
    super.key,
    this.accessToken,
    this.refreshToken,
    this.recoveryToken,
  });

  @override
  State<RecoverySetPasswordScreen> createState() => _RecoverySetPasswordScreenState();
}

class _RecoverySetPasswordScreenState extends State<RecoverySetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _sessionSet = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // IMPORTANTE: Activar flag de recuperación para evitar redirecciones al tour
    _activateRecoveryMode();
    
    if (widget.recoveryToken != null) {
      // En mobile: procesar recovery token directamente
      _processRecoveryToken();
    } else {
      // En web: usar access_token y refresh_token de la URL
      _setSessionFromTokens();
    }
  }
  
  Future<void> _activateRecoveryMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_recovery_mode', true);
    print('🚩 Flag de recuperación activado desde RecoverySetPasswordScreen');
  }

  Future<void> _processRecoveryToken() async {
    if (widget.recoveryToken == null) {
      setState(() {
        _errorMessage = 'Token de recuperación no encontrado';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔑 Procesando recovery token directamente...');
      print('   Token: ${widget.recoveryToken!.substring(0, 20)}...');
      
      // Intentar usar exchangeCodeForSession
      try {
        final response = await Supabase.instance.client.auth.exchangeCodeForSession(widget.recoveryToken!);
        
        if (response.session != null) {
          print('✅ Sesión de recuperación creada exitosamente con exchangeCodeForSession');
          setState(() {
            _sessionSet = true;
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        print('⚠️ Error con exchangeCodeForSession: $e');
      }
      
      // Si llegamos aquí, no se pudo procesar
      setState(() {
        _errorMessage = 'No se pudo procesar el token de recuperación. Por favor, intenta abrir el enlace desde tu navegador.';
        _isLoading = false;
      });
      
    } catch (e) {
      print('❌ Error procesando recovery token: $e');
      setState(() {
        _errorMessage = 'Error procesando token de recuperación: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _setSessionFromTokens() async {
    if (widget.accessToken == null || widget.refreshToken == null) {
      setState(() {
        _errorMessage = 'Tokens de recuperación no encontrados';
      });
      return;
    }

    try {
      // Establecer sesión de recuperación usando los tokens
      // Supabase Flutter setSession requiere el access token como String
      await Supabase.instance.client.auth.setSession(widget.accessToken!);

      // Verificar que la sesión se estableció correctamente
      final currentSession = Supabase.instance.client.auth.currentSession;
      if (currentSession != null) {
        setState(() {
          _sessionSet = true;
        });
      } else {
        setState(() {
          _errorMessage = 'No se pudo establecer la sesión de recuperación';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error estableciendo sesión: ${e.toString()}';
      });
    }
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_sessionSet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión no establecida. Por favor, solicita un nuevo código.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Actualizar contraseña usando updateUser() con la sesión de recuperación activa
      final response = await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text.trim()),
      );

      if (response.user != null) {
        // IMPORTANTE: Desactivar flag de recuperación antes de cerrar sesión
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_recovery_mode', false);
        print('🚩 Flag de recuperación desactivado');
        
        // Cerrar sesión de recuperación para que el usuario haga login normalmente
        await Supabase.instance.client.auth.signOut();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Contraseña actualizada exitosamente!'),
              backgroundColor: Color(0xFF4CAF50),
              duration: Duration(seconds: 3),
            ),
          );

          // Redirigir a login después de un breve delay
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          }
        }
      } else {
        throw Exception('No se pudo actualizar la contraseña');
      }
    } catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.toString());
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'Error actualizando contraseña'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Credenciales inválidas';
    } else if (error.contains('Token expired')) {
      return 'El enlace de recuperación ha expirado. Solicita un nuevo código.';
    } else if (error.contains('Password')) {
      return 'Error con la contraseña: $error';
    }
    return 'Error: $error';
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f0f1e),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Logo y título
                Text(
                  'ManiGraB',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD700),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Nueva Contraseña',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                if (_errorMessage != null && !_sessionSet)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.inter(
                              color: Colors.red[200],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (!_sessionSet)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(
                        color: Color(0xFFFFD700),
                      ),
                    ),
                  ),

                if (_sessionSet) ...[
                  Text(
                    'Ingresa tu nueva contraseña',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Campo de nueva contraseña
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nueva contraseña',
                      labelStyle: GoogleFonts.inter(color: Colors.white70),
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFFFD700)),
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
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa una contraseña';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo de confirmar contraseña
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Confirmar contraseña',
                      labelStyle: GoogleFonts.inter(color: Colors.white70),
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFFFD700)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white54,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
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
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirma tu contraseña';
                      }
                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Botón de actualizar
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updatePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF0f0f1e),
                            ),
                          )
                        : Text(
                            'Guardar Contraseña',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF0f0f1e),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

