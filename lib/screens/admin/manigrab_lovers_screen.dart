import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/admin_service.dart';
import '../../widgets/glow_background.dart';
import 'package:intl/intl.dart';

/// Pantalla para que los administradores otorguen suscripciones ManiGrabLovers
/// (accesos premium mensuales o anuales sin necesidad de compra en Play Store)
class ManiGrabLoversScreen extends StatefulWidget {
  const ManiGrabLoversScreen({super.key});

  @override
  State<ManiGrabLoversScreen> createState() => _ManiGrabLoversScreenState();
}

class _ManiGrabLoversScreenState extends State<ManiGrabLoversScreen> {
  final TextEditingController _emailController = TextEditingController();
  String? _selectedTipo = 'monthly'; // 'monthly' o 'yearly'
  bool _isLoading = false;
  bool _isAdmin = false;
  String? _error;
  List<Map<String, dynamic>> _suscripcionesActivas = [];
  bool _isLoadingSuscripciones = false;

  @override
  void initState() {
    super.initState();
    _verificarAdminYCargar();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _verificarAdminYCargar() async {
    try {
      final esAdmin = await AdminService.esAdmin();
      if (!esAdmin) {
        setState(() {
          _isAdmin = false;
          _error = 'No tienes permisos de administrador para ver esta sección';
        });
        return;
      }

      setState(() {
        _isAdmin = true;
        _error = null;
      });

      await _cargarSuscripcionesActivas();
    } catch (e) {
      setState(() {
        _isAdmin = false;
        _error = 'Error verificando permisos: $e';
      });
    }
  }

  Future<void> _cargarSuscripcionesActivas() async {
    setState(() {
      _isLoadingSuscripciones = true;
    });

    try {
      final suscripciones = await AdminService.listarManiGrabLovers();
      setState(() {
        _suscripcionesActivas = suscripciones;
        _isLoadingSuscripciones = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error cargando accesos: $e';
        _isLoadingSuscripciones = false;
      });
    }
  }

  Future<void> _otorgarSuscripcion() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un email válido'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validar formato de email básico
    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un email válido'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await AdminService.otorgarManiGrabLovers(email, _selectedTipo!);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Acceso de cortesía ${_selectedTipo == 'monthly' ? 'mensual' : 'anual'} asignado a $email',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        _emailController.clear();
        await _cargarSuscripcionesActivas();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
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

  Future<void> _revocarSuscripcion(String email) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Revocar acceso?'),
        content: Text('¿Estás seguro de que deseas revocar el acceso de cortesía de $email?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Revocar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await AdminService.revocarManiGrabLovers(email);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Acceso revocado para $email'),
            backgroundColor: Colors.green,
          ),
        );
        
        await _cargarSuscripcionesActivas();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFFFFD700)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ManiGrabLovers',
                            style: GoogleFonts.spaceMono(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFFD700),
                            ),
                          ),
                          Text(
                            'Accesos promocionales de cortesía',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (!_isAdmin)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            size: 64,
                            color: Colors.white38,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _error ?? 'Solo los administradores pueden acceder a esta sección',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Leyenda obligatoria (Apple-Safe)
                        _buildLeyendaCortesia(),
                        const SizedBox(height: 20),
                        // Formulario para asignar acceso de cortesía
                        _buildFormularioOtorgar(),
                        const SizedBox(height: 24),
                        // Lista de accesos promocionales activos
                        _buildListaSuscripciones(),
                        const SizedBox(height: 24),
                        _buildNotaFinal(),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeyendaCortesia() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        'Esta sección permite otorgar accesos promocionales de cortesía, asignados manualmente por el desarrollador de ManiGrab, como beneficio excepcional en eventos presenciales, colaboraciones o pruebas internas.\n'
        'Estos accesos no están disponibles para su compra ni sustituyen las suscripciones ofrecidas dentro de la app.',
        style: GoogleFonts.inter(
          fontSize: 13,
          color: Colors.white70,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildNotaFinal() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        'Los accesos promocionales son otorgados de forma discrecional y pueden ser revocados en cualquier momento.',
        style: GoogleFonts.inter(
          fontSize: 11,
          color: Colors.white54,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFormularioOtorgar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Asignar acceso de cortesía',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFD700),
            ),
          ),
          const SizedBox(height: 16),
          
          // Campo de email
          TextField(
            controller: _emailController,
            style: GoogleFonts.inter(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Email del usuario invitado',
              labelStyle: GoogleFonts.inter(color: Colors.white70),
              hintText: 'usuario@ejemplo.com',
              hintStyle: GoogleFonts.inter(color: Colors.white38),
              prefixIcon: const Icon(Icons.email, color: Color(0xFFFFD700)),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          
          // Duración del acceso
          Text(
            'Duración del acceso',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTipoButton('monthly', 'Mensual', Icons.calendar_month),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTipoButton('yearly', 'Anual', Icons.calendar_today),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Botón de otorgar
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _otorgarSuscripcion,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : Text(
                      'Asignar acceso de cortesía',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipoButton(String tipo, String label, IconData icon) {
    final isSelected = _selectedTipo == tipo;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTipo = tipo;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFD700).withOpacity(0.2) : Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFD700) : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFFFD700) : Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? const Color(0xFFFFD700) : Colors.white70,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaSuscripciones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Accesos promocionales activos',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFD700),
          ),
        ),
        const SizedBox(height: 12),
        
        if (_isLoadingSuscripciones)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: Color(0xFFFFD700)),
            ),
          )
        else if (_suscripcionesActivas.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'No hay accesos promocionales activos',
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          ..._suscripcionesActivas.map((suscripcion) {
            final email = suscripcion['user_email'] ?? 'N/A';
            final nombre = suscripcion['user_name'] ?? 'Usuario';
            final productId = suscripcion['product_id'] as String;
            final expiresAt = DateTime.parse(suscripcion['expires_at']);
            final tipo = productId.contains('monthly') ? 'Mensual' : 'Anual';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tipo,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFFD700),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.white54),
                      const SizedBox(width: 8),
                      Text(
                        'Expira: ${DateFormat('dd/MM/yyyy').format(expiresAt)}',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _revocarSuscripcion(email),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Revocar acceso'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[300],
                        side: BorderSide(color: Colors.red[300]!),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
