import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_test_service.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AuthTestScreen extends StatefulWidget {
  const AuthTestScreen({super.key});

  @override
  State<AuthTestScreen> createState() => _AuthTestScreenState();
}

class _AuthTestScreenState extends State<AuthTestScreen> {
  final AuthService _authService = AuthService();
  String _testResults = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  void _checkCurrentUser() {
    if (_authService.isLoggedIn) {
      setState(() {
        _testResults = '✅ Usuario autenticado: ${_authService.currentUser?.name} (${_authService.currentUser?.email})';
      });
    } else {
      setState(() {
        _testResults = '❌ No hay usuario autenticado';
      });
    }
  }

  Future<void> _testDatabaseSetup() async {
    setState(() {
      _isLoading = true;
      _testResults = '🔍 Verificando configuración de la base de datos...\n';
    });

    try {
      await AuthTestService.checkDatabaseSetup();
      setState(() {
        _testResults += '\n✅ Verificación completada';
      });
    } catch (e) {
      setState(() {
        _testResults += '\n❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testUserRegistration() async {
    setState(() {
      _isLoading = true;
      _testResults = '🧪 Probando registro de usuario...\n';
    });

    try {
      await AuthTestService.testUserRegistration();
      setState(() {
        _testResults += '\n✅ Prueba de registro completada';
      });
    } catch (e) {
      setState(() {
        _testResults += '\n❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testUserLogin() async {
    setState(() {
      _isLoading = true;
      _testResults = '👥 Verificando usuarios existentes...\n';
    });

    try {
      await AuthTestService.testUserLogin();
      setState(() {
        _testResults += '\n✅ Verificación de usuarios completada';
      });
    } catch (e) {
      setState(() {
        _testResults += '\n❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Título
                Text(
                  'Pruebas de Autenticación',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD700),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                Text(
                  'Verificar configuración de usuarios y base de datos',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Estado actual
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estado Actual:',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD700),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _testResults.isEmpty ? 'Esperando pruebas...' : _testResults,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Botones de prueba
                CustomButton(
                  text: 'Verificar Configuración DB',
                  onPressed: _isLoading ? null : _testDatabaseSetup,
                  icon: Icons.storage,
                ),
                
                const SizedBox(height: 16),
                
                CustomButton(
                  text: 'Probar Registro Usuario',
                  onPressed: _isLoading ? null : _testUserRegistration,
                  icon: Icons.person_add,
                ),
                
                const SizedBox(height: 16),
                
                CustomButton(
                  text: 'Verificar Usuarios Existentes',
                  onPressed: _isLoading ? null : _testUserLogin,
                  icon: Icons.people,
                ),
                
                const SizedBox(height: 24),
                
                // Botón para ir a login
                CustomButton(
                  text: 'Ir a Login',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  isOutlined: true,
                  icon: Icons.login,
                ),
                
                const SizedBox(height: 16),
                
                // Botón para ir a registro
                CustomButton(
                  text: 'Ir a Registro',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    );
                  },
                  isOutlined: true,
                  icon: Icons.person_add,
                ),
                
                if (_isLoading) ...[
                  const SizedBox(height: 24),
                  const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFFD700),
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
