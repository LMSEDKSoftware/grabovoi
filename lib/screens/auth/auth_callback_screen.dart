import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/auth_wrapper.dart';
import 'recovery_set_password_screen.dart';

/// Pantalla que maneja el callback de autenticación desde Supabase
/// Captura el token de la URL y verifica el email del usuario
class AuthCallbackScreen extends StatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  bool _isProcessing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _handleCallback();
  }

  Future<void> _handleCallback() async {
    try {
      if (kIsWeb) {
        // En web, obtener parámetros de la URL
        final uri = Uri.base;
        final accessToken = uri.queryParameters['access_token'];
        final type = uri.queryParameters['type'];
        final token = uri.queryParameters['token'];
        final error = uri.queryParameters['error'];
        final errorDescription = uri.queryParameters['error_description'];

        print('🔐 Callback recibido - URL completa: ${uri.toString()}');
        print('🔐 Callback recibido - access_token: ${accessToken != null ? "presente" : "ausente"}');
        print('🔐 Callback recibido - type: $type');
        print('🔐 Callback recibido - token: ${token != null ? "presente" : "ausente"}');
        final code = uri.queryParameters['code'];
        print('🔐 Callback recibido - code (PKCE): ${code != null ? "presente" : "ausente"}');
        print('🔐 Callback recibido - error: $error');
        print('🔐 Callback recibido - error_description: $errorDescription');
        
        // Flujo PKCE (OAuth): Supabase redirige con ?code=... en lugar de access_token
        if (code != null && code.isNotEmpty) {
          print('🔐 Intercambiando code por sesión (PKCE)...');
          try {
            await Supabase.instance.client.auth.exchangeCodeForSession(code);
            final session = Supabase.instance.client.auth.currentSession;
            if (session != null && mounted) {
              print('✅ Sesión obtenida correctamente tras PKCE');
              _navigateToApp();
              return;
            }
          } catch (e) {
            print('❌ Error intercambiando code por sesión: $e');
            setState(() {
              _errorMessage = 'No se pudo completar el inicio de sesión. Intenta de nuevo.';
              _isProcessing = false;
            });
            return;
          }
        }
        
        // Si hay un error en la URL, manejarlo apropiadamente
        if (error != null) {
          print('❌ Error en callback: $error - $errorDescription');
          
          // Si es un error de token expirado, ofrecer solución
          final isExpiredError = errorDescription != null && 
            (errorDescription.contains('expired') || errorDescription.contains('otp_expired'));
          
          if (error == 'access_denied' && (isExpiredError || error == 'otp_expired')) {
            setState(() {
              _errorMessage = 'El link de recuperación ha expirado. Por favor, solicita un nuevo link de recuperación de contraseña desde la pantalla de login.';
              _isProcessing = false;
            });
          } else {
            setState(() {
              _errorMessage = 'Error en la activación: ${errorDescription ?? error}';
              _isProcessing = false;
            });
          }
          return;
        }
        
        // También verificar en el fragment (hash) si hay errores
        if (uri.hasFragment) {
          final fragmentParams = Uri.splitQueryString(uri.fragment);
          final fragmentError = fragmentParams['error'];
          final fragmentErrorDescription = fragmentParams['error_description'];
          
          if (fragmentError != null) {
            print('❌ Error en callback (fragment): $fragmentError - $fragmentErrorDescription');
            final isFragmentExpiredError = fragmentErrorDescription != null && 
              (fragmentErrorDescription.contains('expired') || fragmentErrorDescription.contains('otp_expired'));
            
            if (fragmentError == 'access_denied' && isFragmentExpiredError) {
              setState(() {
                _errorMessage = 'El link de recuperación ha expirado. Por favor, solicita un nuevo link de recuperación de contraseña desde la pantalla de login.';
                _isProcessing = false;
              });
            } else {
              setState(() {
                _errorMessage = 'Error en la activación: ${fragmentErrorDescription ?? fragmentError}';
                _isProcessing = false;
              });
            }
            return;
          }
        }

        // Verificar si es recovery link (puede venir con access_token y refresh_token, o con type=recovery)
        final refreshToken = uri.queryParameters['refresh_token'];
        // También verificar en el fragment (hash) para mobile
        final fragmentAccessToken = uri.hasFragment ? Uri.splitQueryString(uri.fragment)['access_token'] : null;
        final fragmentRefreshToken = uri.hasFragment ? Uri.splitQueryString(uri.fragment)['refresh_token'] : null;
        
        final finalAccessToken = accessToken ?? fragmentAccessToken;
        final finalRefreshToken = refreshToken ?? fragmentRefreshToken;
        
        final isRecovery = type == 'recovery' || (finalAccessToken != null && finalRefreshToken != null);
        
        if (finalAccessToken != null && finalRefreshToken != null && isRecovery) {
          // Es un recovery link con tokens - redirigir a RecoverySetPasswordScreen
          print('🔑 Recovery link detectado con tokens, redirigiendo a pantalla de nueva contraseña...');
          print('   Access Token: ${finalAccessToken.substring(0, 20)}...');
          print('   Refresh Token: ${finalRefreshToken.substring(0, 20)}...');
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => RecoverySetPasswordScreen(
                  accessToken: finalAccessToken,
                  refreshToken: finalRefreshToken,
                ),
              ),
            );
          }
          return;
        } else if (accessToken != null && !isRecovery) {
          // Si hay access_token pero NO es recovery, Supabase ya procesó el callback normal
          // Solo necesitamos esperar a que el AuthWrapper detecte el cambio
          print('✅ Token de acceso recibido, esperando verificación...');
          await Future.delayed(const Duration(seconds: 1));
          
          // Verificar si el usuario está autenticado
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            print('✅ Sesión activa detectada');
            _navigateToApp();
            return;
          }
        } else if (token != null && type != null) {
          // Si hay token y type, puede ser verificación de email o recuperación de contraseña
          print('🔐 Token recibido, type: $type');
          
          if (type == 'recovery') {
            // Es un token de recuperación de contraseña - procesarlo directamente sin pasar por /verify
            print('🔑 Token de recuperación detectado - procesando directamente...');
            print('   Token completo: $token');
            print('   Type: $type');
            
            try {
              // IMPORTANTE: Marcar que estamos en modo recuperación para evitar redirecciones
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('is_recovery_mode', true);
              print('   🚩 Flag de recuperación activado para evitar redirecciones');
              
              // Intentar diferentes formatos de exchangeCodeForSession
              // Formato 1: Pasar directamente el token (método más común)
              print('   🔄 Intentando exchangeCodeForSession con token directo...');
              try {
                final exchangeResponse = await Supabase.instance.client.auth.exchangeCodeForSession(token);
                print('   📊 Respuesta de exchangeCodeForSession:');
                print('      Session: ${exchangeResponse.session != null ? "✅ presente" : "❌ ausente"}');
                
                if (mounted) {
                  print('✅ Sesión de recuperación creada exitosamente');
                  final session = exchangeResponse.session;
                  print('   Access Token: ${session.accessToken.substring(0, 30)}...');
                  print('   Refresh Token: ${session.refreshToken?.substring(0, 30) ?? "N/A"}...');
                  
                  // Navegar directamente a RecoverySetPasswordScreen sin pasar por AuthWrapper
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => RecoverySetPasswordScreen(
                        accessToken: session.accessToken,
                        refreshToken: session.refreshToken ?? '',
                      ),
                    ),
                    (route) => false, // Limpiar stack de navegación completamente
                  );
                  return;
                }
              } catch (e1) {
                print('   ⚠️ Error con formato directo: $e1');
                
                // Formato 2: Intentar con objeto { auth_code, type } (algunos SDKs lo requieren)
                print('   🔄 Intentando exchangeCodeForSession con formato objeto...');
                try {
                  // Nota: Esto puede no funcionar en Flutter, pero lo intentamos
                  final exchangeResponse2 = await Supabase.instance.client.auth.exchangeCodeForSession(token);
                  if (mounted) {
                    print('✅ Sesión creada con formato alternativo');
                    final session = exchangeResponse2.session;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => RecoverySetPasswordScreen(
                          accessToken: session.accessToken,
                          refreshToken: session.refreshToken ?? '',
                        ),
                      ),
                      (route) => false,
                    );
                    return;
                  }
                } catch (e2) {
                  print('   ⚠️ Error con formato objeto: $e2');
                }
              }
              
              // Si llegamos aquí, ambos formatos fallaron
              throw Exception('No se pudo crear sesión con el token usando ningún formato');
              
            } catch (e) {
              print('❌ Error intercambiando token: $e');
              print('   Tipo de error: ${e.runtimeType}');
              print('   Stack trace: ${StackTrace.current}');
              setState(() {
                _errorMessage = 'El token de recuperación es inválido o ha expirado. Por favor, solicita un nuevo link de recuperación.';
                _isProcessing = false;
              });
              return;
            }
          } else {
            // Es un token de verificación de email
            // Supabase maneja automáticamente estos callbacks
            print('🔐 Token de verificación recibido, esperando procesamiento automático...');
            await Future.delayed(const Duration(seconds: 2));
            
            // Verificar si el usuario está autenticado después del callback
            final session = Supabase.instance.client.auth.currentSession;
            if (session != null) {
              print('✅ Email verificado correctamente');
              
              // Actualizar campo confirmado-correo en la tabla users
              try {
                await Supabase.instance.client
                    .from('users')
                    .update({'confirmado-correo': true})
                    .eq('id', session.user.id);
                print('✅ Campo confirmado-correo actualizado a TRUE');
              } catch (e) {
                print('⚠️ Error actualizando confirmado-correo: $e');
                // No bloquear el flujo si falla la actualización
              }
              
              _navigateToApp();
              return;
            } else {
              print('⚠️ No se pudo verificar automáticamente, intentando con exchangeCode...');
              try {
                // Intentar usar exchangeCode si está disponible
                await Supabase.instance.client.auth.exchangeCodeForSession(token);
                final sessionAfterExchange = Supabase.instance.client.auth.currentSession;
                if (sessionAfterExchange != null) {
                  print('✅ Email verificado con exchangeCode');
                  
                  // Actualizar campo confirmado-correo en la tabla users
                  try {
                    await Supabase.instance.client
                        .from('users')
                        .update({'confirmado-correo': true})
                        .eq('id', sessionAfterExchange.user.id);
                    print('✅ Campo confirmado-correo actualizado a TRUE');
                  } catch (e) {
                    print('⚠️ Error actualizando confirmado-correo: $e');
                  }
                  
                  _navigateToApp();
                  return;
                }
              } catch (e) {
                print('⚠️ exchangeCode no disponible o falló: $e');
              }
              
              // Si no funcionó, mostrar error
              setState(() {
                _errorMessage = 'No se pudo verificar el email automáticamente';
                _isProcessing = false;
              });
              return;
            }
          }
        }

        // Si no hay token ni access_token, puede ser que Supabase ya procesó el callback
        // Esperar un momento y verificar la sesión
        await Future.delayed(const Duration(seconds: 2));
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          print('✅ Sesión detectada después de esperar');
          _navigateToApp();
          return;
        }

        // Si llegamos aquí, no se pudo procesar el callback
        setState(() {
          _errorMessage = 'No se pudo procesar el callback de autenticación';
          _isProcessing = false;
        });
      } else {
        // En móvil, el deep link ya fue procesado por Supabase
        _navigateToApp();
      }
    } catch (e) {
      print('❌ Error en _handleCallback: $e');
      setState(() {
        _errorMessage = 'Error al procesar el callback: $e';
        _isProcessing = false;
      });
    }
  }

  void _navigateToApp() {
    if (mounted) {
      // Navegar a la app principal (AuthWrapper manejará el estado de autenticación)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AuthWrapper(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isProcessing) ...[
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Verificando autenticación...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ] else if (_errorMessage != null) ...[
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 24),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const AuthWrapper(),
                    ),
                  );
                },
                child: const Text('Volver al inicio'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


