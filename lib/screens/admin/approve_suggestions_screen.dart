import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../models/sugerencia_codigo_model.dart';
import '../../services/sugerencias_codigos_service.dart';
import '../../services/admin_service.dart';
import '../../services/supabase_service.dart';

class ApproveSuggestionsScreen extends StatefulWidget {
  const ApproveSuggestionsScreen({super.key});

  @override
  State<ApproveSuggestionsScreen> createState() => _ApproveSuggestionsScreenState();
}

class _ApproveSuggestionsScreenState extends State<ApproveSuggestionsScreen> {
  List<SugerenciaCodigo> _sugerenciasPendientes = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _verificarAdminYCargar();
  }

  Future<void> _verificarAdminYCargar() async {
    try {
      final esAdmin = await AdminService.esAdmin();
      
      if (!esAdmin) {
        setState(() {
          _isAdmin = false;
          _isLoading = false;
          _error = 'No tienes permisos de administrador para ver esta sección';
        });
        return;
      }

      setState(() {
        _isAdmin = true;
      });

      await _cargarSugerencias();
    } catch (e) {
      setState(() {
        _error = 'Error verificando permisos: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _cargarSugerencias() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sugerencias = await SugerenciasCodigosService.getSugerenciasPendientes();
      setState(() {
        _sugerenciasPendientes = sugerencias;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error cargando sugerencias: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _aprobarSugerencia(SugerenciaCodigo sugerencia) async {
    try {
      // Actualizar el código existente con el nuevo tema/descripción
      await SupabaseService.actualizarCodigo(
        sugerencia.codigoExistente,
        nombre: sugerencia.temaSugerido,
        descripcion: sugerencia.descripcionSugerida ?? '',
      );

      // Marcar sugerencia como aprobada
      await SugerenciasCodigosService.actualizarEstadoSugerencia(
        sugerencia.id!,
        'aprobada',
        comentario: 'Aprobada por administrador',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Sugerencia aprobada: ${sugerencia.temaSugerido}'),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      await _cargarSugerencias();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error aprobando sugerencia: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _rechazarSugerencia(SugerenciaCodigo sugerencia, String? comentario) async {
    try {
      await SugerenciasCodigosService.actualizarEstadoSugerencia(
        sugerencia.id!,
        'rechazada',
        comentario: comentario,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Sugerencia rechazada'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      await _cargarSugerencias();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error rechazando sugerencia: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _mostrarDialogoRechazo(SugerenciaCodigo sugerencia) {
    final comentarioController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2541),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
        ),
        title: Row(
          children: [
            const Icon(Icons.close, color: Color(0xFFFF6B6B), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Rechazar Sugerencia',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Por qué rechazas esta sugerencia?',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: comentarioController,
              maxLines: 3,
              style: GoogleFonts.inter(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Comentario (opcional)',
                hintStyle: GoogleFonts.inter(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(color: Colors.white70),
            ),
          ),
          CustomButton(
            text: 'Rechazar',
            onPressed: () {
              Navigator.pop(context);
              _rechazarSugerencia(sugerencia, comentarioController.text.isNotEmpty ? comentarioController.text : null);
            },
            color: const Color(0xFFFF6B6B),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFD700)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Aprobar Sugerencias',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFD700),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFFD700)),
            onPressed: _cargarSugerencias,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: GlowBackground(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFD700)),
      );
    }

    if (!_isAdmin) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock,
                size: 64,
                color: Color(0xFFFF6B6B),
              ),
              const SizedBox(height: 16),
              Text(
                'Acceso Restringido',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Solo los administradores pueden acceder a esta sección',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFFFF6B6B),
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Reintentar',
                onPressed: _cargarSugerencias,
                color: const Color(0xFFFFD700),
              ),
            ],
          ),
        ),
      );
    }

    if (_sugerenciasPendientes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Color(0xFF4CAF50),
              ),
              const SizedBox(height: 16),
              Text(
                'No hay sugerencias pendientes',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Todas las sugerencias han sido revisadas',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarSugerencias,
      color: const Color(0xFFFFD700),
      backgroundColor: const Color(0xFF1C2541),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sugerenciasPendientes.length,
        itemBuilder: (context, index) {
          final sugerencia = _sugerenciasPendientes[index];
          return _buildSugerenciaCard(sugerencia);
        },
      ),
    );
  }

  Widget _buildSugerenciaCard(SugerenciaCodigo sugerencia) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2541).withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Código
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFD700)),
                ),
                child: Text(
                  sugerencia.codigoExistente,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFFD700),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'PENDIENTE',
                  style: GoogleFonts.inter(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Tema actual vs sugerido
          _buildComparisonRow(
            'En DB',
            sugerencia.temaEnDb ?? 'Sin tema',
            Icons.info_outline,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildComparisonRow(
            'Sugerido',
            sugerencia.temaSugerido,
            Icons.lightbulb_outline,
            const Color(0xFFFFD700),
          ),
          
          if (sugerencia.descripcionSugerida != null && sugerencia.descripcionSugerida!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Descripción sugerida:',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sugerencia.descripcionSugerida!,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Información adicional
          Row(
            children: [
              Icon(Icons.source, size: 14, color: Colors.white54),
              const SizedBox(width: 4),
              Text(
                'Fuente: ${sugerencia.fuente}',
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                _formatFecha(sugerencia.fechaSugerencia),
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Botones de acción
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Rechazar',
                  onPressed: () => _mostrarDialogoRechazo(sugerencia),
                  color: const Color(0xFFFF6B6B),
                  icon: Icons.close,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Aprobar',
                  onPressed: () => _aprobarSugerencia(sugerencia),
                  color: const Color(0xFF4CAF50),
                  icon: Icons.check,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  String _formatFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inDays > 0) {
      return 'Hace ${diferencia.inDays} día${diferencia.inDays > 1 ? 's' : ''}';
    } else if (diferencia.inHours > 0) {
      return 'Hace ${diferencia.inHours} hora${diferencia.inHours > 1 ? 's' : ''}';
    } else if (diferencia.inMinutes > 0) {
      return 'Hace ${diferencia.inMinutes} minuto${diferencia.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Hace unos momentos';
    }
  }
}

