import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glow_background.dart';
import '../../services/supabase_service.dart';
import '../../models/notification_history_item.dart';
import '../../services/notification_count_service.dart';

class ReportDetailScreen extends StatefulWidget {
  final Map<String, dynamic> reporte;

  const ReportDetailScreen({
    super.key,
    required this.reporte,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  bool _isLoading = false;
  String? _error;
  String _estatusActual = 'pendiente';
  bool _estatusCambiado = false;

  @override
  void initState() {
    super.initState();
    _estatusActual = widget.reporte['estatus'] as String? ?? 'pendiente';
  }

  String _getTipoReporteTexto(String tipo) {
    switch (tipo) {
      case 'codigo_incorrecto':
        return 'Código incorrecto';
      case 'descripcion_incorrecta':
        return 'Descripción incorrecta';
      case 'categoria_incorrecta':
        return 'Categoría incorrecta';
      default:
        return tipo;
    }
  }

  Color _getTipoReporteColor(String tipo) {
    switch (tipo) {
      case 'codigo_incorrecto':
        return Colors.red;
      case 'descripcion_incorrecta':
        return Colors.orange;
      case 'categoria_incorrecta':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _getEstatusTexto(String estatus) {
    switch (estatus) {
      case 'pendiente':
        return 'Pendiente';
      case 'revisado':
        return 'Revisado';
      case 'aceptado':
        return 'Aceptado';
      case 'rechazado':
        return 'Rechazado';
      case 'resuelto':
        return 'Resuelto';
      default:
        return estatus;
    }
  }

  Color _getEstatusColor(String estatus) {
    switch (estatus) {
      case 'pendiente':
        return Colors.grey;
      case 'revisado':
        return Colors.blue;
      case 'aceptado':
        return Colors.green;
      case 'rechazado':
        return Colors.red;
      case 'resuelto':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  Future<void> _actualizarEstatus(String nuevoEstatus) async {
    if (_estatusActual == nuevoEstatus) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Actualizar el estatus en la base de datos
      await SupabaseService.actualizarEstatusReporte(
        reporteId: widget.reporte['id'] as String,
        nuevoEstatus: nuevoEstatus,
      );

      // Obtener información del usuario para notificar
      final usuarioId = widget.reporte['usuario_id'] as String;
      final codigoId = widget.reporte['codigo_id'] as String;
      final tipoReporte = widget.reporte['tipo_reporte'] as String;

      // Notificar al usuario (solo si es diferente de pendiente)
      if (nuevoEstatus != 'pendiente') {
        await _notificarUsuario(usuarioId, codigoId, tipoReporte, nuevoEstatus);
      }

      setState(() {
        _estatusActual = nuevoEstatus;
        _estatusCambiado = true;
        _isLoading = false;
      });

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Estatus actualizado a: ${_getEstatusTexto(nuevoEstatus)}',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Error al actualizar el estatus: $e';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al actualizar el estatus: $e',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _notificarUsuario(
    String usuarioId,
    String codigoId,
    String tipoReporte,
    String nuevoEstatus,
  ) async {
    try {
      // Crear mensaje de notificación según el estatus
      String titulo = '';
      String cuerpo = '';

      switch (nuevoEstatus) {
        case 'revisado':
          titulo = '📋 Reporte Revisado';
          cuerpo = 'Tu reporte del código $codigoId ha sido revisado por un administrador.';
          break;
        case 'aceptado':
          titulo = '✅ Reporte Aceptado';
          cuerpo = 'Tu reporte del código $codigoId ha sido aceptado. Se realizarán los cambios correspondientes.';
          break;
        case 'rechazado':
          titulo = '❌ Reporte Rechazado';
          cuerpo = 'Tu reporte del código $codigoId ha sido revisado, pero no se aplicarán cambios en este momento.';
          break;
        case 'resuelto':
          titulo = '🎉 Reporte Resuelto';
          cuerpo = 'Tu reporte del código $codigoId ha sido resuelto. Los cambios han sido aplicados.';
          break;
        default:
          return;
      }

      // Guardar notificación en el historial del usuario
      // Nota: Esto solo funcionará si el usuario está usando la app
      // Para una solución más robusta, se podría usar una tabla de notificaciones en Supabase
      await NotificationHistory.addNotification(
        title: titulo,
        body: cuerpo,
        type: 'reporte_estatus',
      );
      
      // Actualizar conteo inmediatamente
      await NotificationCountService().updateCount();

      // También intentar notificar usando el sistema de notificaciones locales
      // (solo si el usuario está activo en ese momento)
      // NotificationService se encargará de mostrar la notificación si está disponible

      print('📧 Notificación enviada al usuario $usuarioId sobre cambio de estatus');
    } catch (e) {
      print('⚠️ Error al notificar al usuario: $e');
      // No lanzar error, solo registrar en logs
    }
  }

  @override
  Widget build(BuildContext context) {
    final tipo = widget.reporte['tipo_reporte'] as String;
    final tipoColor = _getTipoReporteColor(tipo);
    final tipoTexto = _getTipoReporteTexto(tipo);
    final codigoId = widget.reporte['codigo_id'] as String;
    final email = widget.reporte['email'] as String;
    final createdAt = DateTime.parse(widget.reporte['created_at'] as String);
    final updatedAt = widget.reporte['updated_at'] != null
        ? DateTime.parse(widget.reporte['updated_at'] as String)
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFD700)),
          onPressed: () {
            // Pasar el resultado de vuelta si el estatus cambió
            Navigator.pop(context, _estatusCambiado);
          },
        ),
        title: Text(
          'Detalle del Reporte',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFD700),
          ),
        ),
      ),
      body: GlowBackground(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFD700)),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card principal con información del reporte
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1a1a2e).withOpacity(0.8),
                            const Color(0xFF16213e).withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: tipoColor.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tipo de reporte
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: tipoColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: tipoColor.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  tipoTexto,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: tipoColor,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              // Estatus actual
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getEstatusColor(_estatusActual)
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getEstatusColor(_estatusActual)
                                        .withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _getEstatusTexto(_estatusActual),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _getEstatusColor(_estatusActual),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Código reportado
                          _buildInfoRow(
                            icon: Icons.tag,
                            label: 'Código Reportado',
                            value: codigoId,
                            iconColor: const Color(0xFFFFD700),
                          ),
                          const SizedBox(height: 16),
                          // Email del usuario
                          _buildInfoRow(
                            icon: Icons.email,
                            label: 'Usuario',
                            value: email,
                            iconColor: Colors.white70,
                          ),
                          const SizedBox(height: 16),
                          // Fecha de creación
                          _buildInfoRow(
                            icon: Icons.calendar_today,
                            label: 'Fecha de Reporte',
                            value: _formatDate(createdAt),
                            iconColor: Colors.white70,
                          ),
                          if (updatedAt != null) ...[
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              icon: Icons.update,
                              label: 'Última Actualización',
                              value: _formatDate(updatedAt),
                              iconColor: Colors.white70,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Sección de cambio de estatus
                    Text(
                      'Cambiar Estatus',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Botones de estatus
                    ...['pendiente', 'revisado', 'aceptado', 'rechazado', 'resuelto']
                        .map((estatus) => _buildEstatusButton(estatus))
                        ,
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red, width: 1),
                        ),
                        child: Text(
                          _error!,
                          style: GoogleFonts.inter(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEstatusButton(String estatus) {
    final isSelected = _estatusActual == estatus;
    final estatusColor = _getEstatusColor(estatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _actualizarEstatus(estatus),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? estatusColor.withOpacity(0.3)
              : Colors.white.withOpacity(0.08),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? estatusColor
                  : Colors.white.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: estatusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _getEstatusTexto(estatus),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFFFFD700),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Hace unos momentos';
        }
        return 'Hace ${difference.inMinutes} min';
      }
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}

