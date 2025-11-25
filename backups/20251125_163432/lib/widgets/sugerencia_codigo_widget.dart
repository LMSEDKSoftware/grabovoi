import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sugerencia_codigo_model.dart';
import '../services/sugerencias_codigos_service.dart';

class SugerenciaCodigoWidget extends StatefulWidget {
  final SugerenciaCodigo sugerencia;
  final VoidCallback? onSugerenciaAprobada;
  final VoidCallback? onSugerenciaRechazada;

  const SugerenciaCodigoWidget({
    super.key,
    required this.sugerencia,
    this.onSugerenciaAprobada,
    this.onSugerenciaRechazada,
  });

  @override
  State<SugerenciaCodigoWidget> createState() => _SugerenciaCodigoWidgetState();
}

class _SugerenciaCodigoWidgetState extends State<SugerenciaCodigoWidget> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con código y estado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getEstadoColor(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.sugerencia.estado.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Código: ${widget.sugerencia.codigoExistente}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Tema existente vs sugerido
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Tema actual en la base de datos:',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.sugerencia.temaEnDb ?? 'No especificado',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 16, color: Colors.blue[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Nuevo tema sugerido por IA:',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.sugerencia.temaSugerido,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
            ),
            
            if (widget.sugerencia.descripcionSugerida != null) ...[
              const SizedBox(height: 8),
              Text(
                'Descripción: ${widget.sugerencia.descripcionSugerida}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Botones de acción (solo si está pendiente)
            if (widget.sugerencia.estado == 'pendiente') ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _aprobarSugerencia,
                      icon: _isLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check, size: 16),
                      label: Text(
                        _isLoading ? 'Procesando...' : 'Aprobar',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _rechazarSugerencia,
                      icon: const Icon(Icons.close, size: 16),
                      label: Text(
                        'Rechazar',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            // Información de fecha
            const SizedBox(height: 8),
            Text(
              'Sugerencia creada: ${_formatDate(widget.sugerencia.fechaSugerencia)}',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEstadoColor() {
    switch (widget.sugerencia.estado) {
      case 'pendiente':
        return Colors.orange;
      case 'aprobada':
        return Colors.green;
      case 'rechazada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _aprobarSugerencia() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await SugerenciasCodigosService.actualizarEstadoSugerencia(
        widget.sugerencia.id!,
        'aprobada',
        comentario: 'Aprobada por el usuario',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Sugerencia aprobada',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      widget.onSugerenciaAprobada?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Error al aprobar sugerencia: $e',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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

  Future<void> _rechazarSugerencia() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await SugerenciasCodigosService.actualizarEstadoSugerencia(
        widget.sugerencia.id!,
        'rechazada',
        comentario: 'Rechazada por el usuario',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Sugerencia rechazada',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      widget.onSugerenciaRechazada?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Error al rechazar sugerencia: $e',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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

