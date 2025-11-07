import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glow_background.dart';
import '../../services/admin_service.dart';
import '../../services/supabase_service.dart';
import 'report_detail_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewReportsScreen extends StatefulWidget {
  const ViewReportsScreen({super.key});

  @override
  State<ViewReportsScreen> createState() => _ViewReportsScreenState();
}

class _ViewReportsScreenState extends State<ViewReportsScreen> {
  List<Map<String, dynamic>> _reportes = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  String? _error;
  String _filtroTipo = 'todos'; // todos, codigo_incorrecto, descripcion_incorrecta, categoria_incorrecta

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

      await _cargarReportes();
    } catch (e) {
      setState(() {
        _error = 'Error verificando permisos: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _cargarReportes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Usar el servicio de Supabase para obtener los reportes
      final reportes = await SupabaseService.getReportesCodigos(
        tipoReporte: _filtroTipo != 'todos' ? _filtroTipo : null,
      );
      
      setState(() {
        _reportes = reportes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error cargando reportes: $e';
        _isLoading = false;
      });
    }
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
          'Reportes de Códigos',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFD700),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFFD700)),
            onPressed: _cargarReportes,
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
              ElevatedButton(
                onPressed: _cargarReportes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: const Color(0xFF0B132B),
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Filtros
        Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Todos', 'todos'),
                const SizedBox(width: 8),
                _buildFilterChip('Código incorrecto', 'codigo_incorrecto'),
                const SizedBox(width: 8),
                _buildFilterChip('Descripción incorrecta', 'descripcion_incorrecta'),
                const SizedBox(width: 8),
                _buildFilterChip('Categoría incorrecta', 'categoria_incorrecta'),
              ],
            ),
          ),
        ),
        // Lista de reportes
        Expanded(
          child: _reportes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.report_outlined,
                          size: 64,
                          color: Color(0xFF4CAF50),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay reportes',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No se han realizado reportes aún',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarReportes,
                  color: const Color(0xFFFFD700),
                  backgroundColor: const Color(0xFF1C2541),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reportes.length,
                    itemBuilder: (context, index) {
                      final reporte = _reportes[index];
                      return _buildReporteCard(reporte);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filtroTipo == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filtroTipo = value;
        });
        _cargarReportes();
      },
      selectedColor: const Color(0xFFFFD700),
      backgroundColor: Colors.white.withOpacity(0.08),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF0B132B) : Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildReporteCard(Map<String, dynamic> reporte) {
    final tipo = reporte['tipo_reporte'] as String;
    final tipoColor = _getTipoReporteColor(tipo);
    final tipoTexto = _getTipoReporteTexto(tipo);
    final codigoId = reporte['codigo_id'] as String;
    final email = reporte['email'] as String;
    final createdAt = DateTime.parse(reporte['created_at'] as String);
    final estatus = reporte['estatus'] as String? ?? 'pendiente';

    return GestureDetector(
      onTap: () async {
        // Navegar a la pantalla de detalle
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportDetailScreen(reporte: reporte),
          ),
        );

        // Si el estatus cambió, recargar la lista
        if (result == true) {
          _cargarReportes();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: tipoColor,
                    ),
                  ),
                ),
                const Spacer(),
                // Estatus
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _getEstatusColor(estatus).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getEstatusColor(estatus).withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getEstatusTexto(estatus),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getEstatusColor(estatus),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.tag,
                  size: 16,
                  color: Color(0xFFFFD700),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Código: $codigoId',
                    style: GoogleFonts.spaceMono(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFD700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.email,
                  size: 16,
                  color: Colors.white70,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    email,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.white54,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDate(createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.white54,
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

