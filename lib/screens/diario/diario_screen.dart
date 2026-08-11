import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../widgets/glow_background.dart';
import '../../services/diario_service.dart';
import '../../services/diario_refresh_bridge.dart';
import '../../repositories/codigos_repository.dart';

class DiarioScreen extends StatefulWidget {
  const DiarioScreen({super.key});

  @override
  State<DiarioScreen> createState() => _DiarioScreenState();
}

class _DiarioScreenState extends State<DiarioScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _entradas = [];
  String? _filtroCodigo;
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  Map<String, List<Map<String, dynamic>>> _secuenciasEnSeguimiento = {};
  final TextEditingController _searchController = TextEditingController();
  Map<String, List<Map<String, dynamic>>> _secuenciasFiltradas = {};

  @override
  void initState() {
    super.initState();
    _loadDiario();
    _searchController.addListener(_filtrarSecuencias);
    DiarioRefreshBridge.refreshRequested.addListener(_onRefreshRequested);
  }

  @override
  void dispose() {
    DiarioRefreshBridge.refreshRequested.removeListener(_onRefreshRequested);
    _searchController.dispose();
    super.dispose();
  }

  void _onRefreshRequested() {
    if (mounted) _loadDiario();
  }

  /// Filtra un mapa código->entradas por texto libre (código o título).
  /// Se reutiliza tanto para la búsqueda en vivo del encabezado como para el
  /// filtro por código del diálogo "Filtrar Diario".
  Map<String, List<Map<String, dynamic>>> _filtrarPorTexto(
    Map<String, List<Map<String, dynamic>>> secuencias,
    String texto,
  ) {
    final query = texto.toLowerCase().trim();
    if (query.isEmpty) return secuencias;

    final filtradas = <String, List<Map<String, dynamic>>>{};
    for (final entry in secuencias.entries) {
      final codigo = entry.key.toLowerCase();
      final nombreCodigo = CodigosRepository().getTituloByCode(entry.key).toLowerCase();
      if (codigo.contains(query) || nombreCodigo.contains(query)) {
        filtradas[entry.key] = entry.value;
      }
    }
    return filtradas;
  }

  /// Agrupa entradas del diario por código, igual que hacía
  /// DiarioService.getSecuenciasEnSeguimiento(), pero en memoria a partir de
  /// las entradas ya traídas con los filtros de fecha aplicados.
  Map<String, List<Map<String, dynamic>>> _agruparPorCodigo(
    List<Map<String, dynamic>> entradas,
  ) {
    final agrupadas = <String, List<Map<String, dynamic>>>{};
    for (final entrada in entradas) {
      final codigo = entrada['codigo'] as String?;
      if (codigo != null && codigo.isNotEmpty) {
        agrupadas.putIfAbsent(codigo, () => []).add(entrada);
      }
    }
    return agrupadas;
  }

  void _filtrarSecuencias() {
    setState(() {
      _secuenciasFiltradas = _filtrarPorTexto(_secuenciasEnSeguimiento, _searchController.text);
    });
  }

  Future<void> _loadDiario() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final diarioService = DiarioService();
      // El filtro por código se aplica en memoria (ver _agruparPorCodigo +
      // _filtrarPorTexto) porque acepta coincidencias parciales por nombre,
      // no solo el código exacto que soporta la consulta a Supabase.
      _entradas = await diarioService.getEntradas(
        fechaDesde: _fechaDesde,
        fechaHasta: _fechaHasta,
      );
      var agrupadas = _agruparPorCodigo(_entradas);
      if (_filtroCodigo != null && _filtroCodigo!.trim().isNotEmpty) {
        agrupadas = _filtrarPorTexto(agrupadas, _filtroCodigo!);
      }
      _secuenciasEnSeguimiento = agrupadas;
    } catch (e) {
      debugPrint('Error cargando diario: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando diario: $e'),
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
    // Reaplica la búsqueda en vivo activa (si la hay) sobre los datos recién
    // cargados/filtrados.
    _filtrarSecuencias();
  }

  @override
  Widget build(BuildContext context) {
    return GlowBackground(
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
            : Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Diario de Secuencias',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFFD700),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Visualiza todas las secuencias que estás siguiendo. Cada una muestra la secuencia activada y el detalle de cada día con tus intenciones, sensaciones y resultados.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white70,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Total de secuencias en seguimiento
                        Text(
                          'Secuencias en seguimiento: ${_secuenciasFiltradas.length}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFFD700),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Búsqueda + filtro por código/fecha
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Buscar por secuencia, título o palabra clave...',
                                  hintStyle: GoogleFonts.inter(color: Colors.white54),
                                  prefixIcon: const Icon(Icons.search, color: Color(0xFFFFD700)),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, color: Colors.white70),
                                          onPressed: () {
                                            _searchController.clear();
                                          },
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.1),
                                  border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
                                          ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        ),
                                style: GoogleFonts.inter(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                            _buildFiltroButton(),
                          ],
                        ),
                        if (_hayFiltrosActivos) ...[
                          const SizedBox(height: 10),
                          _buildFiltrosActivosChip(),
                        ],
                      ],
                    ),
                  ),

                  // Grid de secuencias agrupadas por secuencia
                              Expanded(
                    child: _secuenciasFiltradas.isEmpty
                        ? _buildEmptyState()
                        : _buildSecuenciasGrid(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSecuenciasGrid() {
    final codigos = _secuenciasFiltradas.keys.toList()
      ..sort((a, b) {
        // Ordenar por fecha más reciente primero
        final entradasA = _secuenciasFiltradas[a]!;
        final entradasB = _secuenciasFiltradas[b]!;
        if (entradasA.isEmpty) return 1;
        if (entradasB.isEmpty) return -1;
        final fechaA = DateTime.parse(entradasA.first['fecha']);
        final fechaB = DateTime.parse(entradasB.first['fecha']);
        return fechaB.compareTo(fechaA);
      });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: codigos.length,
      itemBuilder: (context, index) {
        final codigo = codigos[index];
        final entradas = _secuenciasFiltradas[codigo]!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildSecuenciaCard(codigo: codigo, entradas: entradas),
        );
      },
    );
  }

  Widget _buildSecuenciaCard({
    required String codigo,
    required List<Map<String, dynamic>> entradas,
  }) {
    // Obtener el nombre de la secuencia desde el repositorio
    final nombreCodigo = CodigosRepository().getTituloByCode(codigo);
    final diasUnicos = entradas.map((e) => e['fecha']).toSet().length;

    return GestureDetector(
      onTap: () => _mostrarDetalleSecuencia(codigo: codigo, entradas: entradas),
      child: Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFD700).withOpacity(0.15),
              const Color(0xFFFFD700).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFFFFD700).withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.2),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              // Secuencia destacada
              Container(
                constraints: const BoxConstraints(maxWidth: 120),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                child: Text(
                  codigo,
                  style: GoogleFonts.spaceMono(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD700),
                    letterSpacing: 1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 16),
              // Título e información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Título de la secuencia (abajo de la secuencia visualmente)
                    Text(
                      nombreCodigo.isNotEmpty && nombreCodigo != 'Campo Energético'
                          ? nombreCodigo
                          : 'Secuencia activa',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Información de entradas
                    Row(
                      children: [
                        const Icon(
                          Icons.repeat_one,
                          size: 14,
                          color: Color(0xFFFFD700),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${entradas.length} ${entradas.length == 1 ? 'activación' : 'activaciones'}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (diasUnicos > 1) ...[
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '$diasUnicos días',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                          ],
                        ),
                      ],
                    ),
                  ),
              // Icono de flecha
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFFFFD700),
              ),
            ],
          ),
              ),
      ),
    );
  }

  void _mostrarDetalleSecuencia({
    required String codigo,
    required List<Map<String, dynamic>> entradas,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDetalleSecuenciaModal(
        codigo: codigo,
        entradas: entradas,
      ),
    );
  }

  Widget _buildDetalleSecuenciaModal({
    required String codigo,
    required List<Map<String, dynamic>> entradas,
  }) {
    // Validar que hay entradas
    if (entradas.isEmpty) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: const Color(0xFF1C2541),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            'No hay entradas para esta secuencia',
              style: GoogleFonts.inter(
              fontSize: 16,
                color: Colors.white70,
              ),
          ),
        ),
      );
    }

    // Agrupar entradas por fecha
    final entradasPorFecha = <String, List<Map<String, dynamic>>>{};
    for (final entrada in entradas) {
      String fecha;
      if (entrada['fecha'] == null) {
        fecha = 'sin_fecha';
      } else {
        // Manejar diferentes formatos de fecha
        final fechaValue = entrada['fecha'];
        if (fechaValue is DateTime) {
          fecha = fechaValue.toIso8601String().split('T')[0];
        } else if (fechaValue is String) {
          // Si ya es string, intentar parsearlo para normalizarlo
          try {
            final parsed = DateTime.parse(fechaValue);
            fecha = parsed.toIso8601String().split('T')[0];
          } catch (e) {
            fecha = fechaValue;
          }
        } else {
          fecha = fechaValue.toString();
        }
      }
      
      if (!entradasPorFecha.containsKey(fecha)) {
        entradasPorFecha[fecha] = [];
      }
      entradasPorFecha[fecha]!.add(entrada);
    }

    final fechas = entradasPorFecha.keys.toList()
      ..sort((a, b) {
        if (a == 'sin_fecha') return 1;
        if (b == 'sin_fecha') return -1;
        try {
          return DateTime.parse(b).compareTo(DateTime.parse(a));
        } catch (e) {
          return b.compareTo(a);
        }
      }); // Más reciente primero

    debugPrint('🔍 [DIARIO] Mostrando detalle de secuencia: $codigo');
    debugPrint('🔍 [DIARIO] Total de entradas: ${entradas.length}');
    for (var i = 0; i < entradas.length; i++) {
      debugPrint('🔍 [DIARIO] Entrada $i: ${entradas[i]}');
    }
    debugPrint('🔍 [DIARIO] Fechas agrupadas: ${entradasPorFecha.keys.toList()}');

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: const Color(0xFF1C2541),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFFD700).withOpacity(0.15),
                  const Color(0xFFFFD700).withOpacity(0.05),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  width: 1,
                ),
                ),
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
                          // Secuencia completa
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              codigo,
                              style: GoogleFonts.spaceMono(
                                fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFD700),
                                letterSpacing: 1.5,
                    ),
                  ),
                          ),
                          const SizedBox(height: 8),
                          // Título completo
                  Text(
                            CodigosRepository().getTituloByCode(codigo),
                    style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                  ),
                ],
              ),
            ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white70),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                children: [
                    const Icon(
                      Icons.repeat_one,
                      size: 14,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${entradas.length} ${entradas.length == 1 ? 'activación registrada' : 'activaciones registradas'}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Lista de entradas por fecha
          Expanded(
            child: fechas.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 64,
                            color: const Color(0xFFFFD700).withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay entradas registradas',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total de entradas recibidas: ${entradas.length}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: fechas.length,
      itemBuilder: (context, index) {
                      try {
                        final fecha = fechas[index];
                        final entradasDelDia = entradasPorFecha[fecha] ?? [];
                        if (entradasDelDia.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return _buildEntradaPorFechaCard(
          fecha: fecha,
                          entradas: entradasDelDia,
                        );
                      } catch (e) {
                        debugPrint('❌ [DIARIO] Error construyendo tarjeta de fecha: $e');
    return Container(
      padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Text(
                            'Error mostrando entrada: $e',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        );
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntradaPorFechaCard({
    required String fecha,
    required List<Map<String, dynamic>> entradas,
  }) {
    String fechaFormateada;
    String diaSemanaCapitalizado;
    
    if (fecha == 'sin_fecha') {
      fechaFormateada = 'Sin fecha';
      diaSemanaCapitalizado = '';
    } else {
      try {
        final fechaObj = DateTime.parse(fecha);
        fechaFormateada = DateFormat('dd/MM/yyyy').format(fechaObj);
        final diaSemana = DateFormat('EEEE', 'es').format(fechaObj);
        diaSemanaCapitalizado = diaSemana[0].toUpperCase() + diaSemana.substring(1);
      } catch (e) {
        debugPrint('Error parseando fecha: $fecha - $e');
        fechaFormateada = fecha;
        diaSemanaCapitalizado = '';
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFD700).withOpacity(0.1),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Header de fecha
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Color(0xFFFFD700),
                  ),
                ),
          const SizedBox(width: 12),
                Expanded(
                  child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fechaFormateada,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFD700),
                ),
              ),
              Text(
                        diaSemanaCapitalizado,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
                  ),
                ),
                if (entradas.length > 1)
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                        const Icon(
                          Icons.repeat,
                          size: 14,
                          color: Color(0xFFFFD700),
                        ),
                      const SizedBox(width: 4),
                      Text(
                          '${entradas.length}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD700),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
            const SizedBox(height: 16),
            // Entradas del día
            if (entradas.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
              child: Text(
                  'No hay detalles para este día',
                style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
          ...entradas.asMap().entries.map((entry) {
            final idx = entry.key;
            final entrada = entry.value;
            
            return Column(
              children: [
                    if (idx > 0) ...[
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                    height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFFFFD700).withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                    _buildSingleEntryContent(entrada, idx: idx > 0 ? idx : null),
              ],
            );
          }),
        ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 80,
              color: const Color(0xFFFFD700).withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Tu Diario está vacío',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Comienza a registrar tus prácticas para ver tu progreso',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Propuesta de Valor',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFD700),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'El diario transforma el uso de estas secuencias de una práctica pasiva a una experiencia activa y consciente, permitiendo a los usuarios comprender mejor su cuerpo, mente y espíritu a través del registro sistemático y la reflexión personal.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFFFD700), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Para crear una nueva entrada, completa una sesión de repetición o pilotaje y selecciona "Sí, Dar Seguimiento" al finalizar.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleEntryContent(Map<String, dynamic> entrada, {int? idx}) {
    final hasContent = entrada['intencion'] != null ||
        entrada['estado_animo'] != null ||
        (entrada['sensaciones'] != null && entrada['sensaciones'].toString().isNotEmpty) ||
        entrada['horas_sueno'] != null ||
        entrada['hizo_ejercicio'] == true ||
        (entrada['gratitud'] != null && entrada['gratitud'].toString().isNotEmpty);

    if (!hasContent && idx == null) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
                  ),
                  child: Row(
                    children: [
            const Icon(Icons.info_outline, size: 16, color: Colors.white70),
            const SizedBox(width: 8),
                      Text(
              'Entrada registrada sin detalles adicionales',
                        style: GoogleFonts.inter(
                          fontSize: 12,
              color: Colors.white70,
                fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        if (idx != null && idx > 0) ...[
            Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
              'Repetición ${idx + 1}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                color: const Color(0xFFFFD700),
                ),
              ),
            ),
          const SizedBox(height: 12),
        ],
        // Intención (siempre mostrar si existe)
        if (entrada['intencion'] != null && entrada['intencion'].toString().isNotEmpty) ...[
          _buildInfoRow(
            icon: Icons.flag,
            label: 'Intención',
            value: entrada['intencion'].toString(),
            isMultiline: true,
                  ),
                  const SizedBox(height: 12),
                ],
        // Sensaciones
        if (entrada['sensaciones'] != null && entrada['sensaciones'].toString().isNotEmpty) ...[
          _buildInfoRow(
            icon: Icons.wb_sunny,
            label: 'Sensaciones y resultados',
            value: entrada['sensaciones'].toString(),
            isMultiline: true,
          ),
          const SizedBox(height: 12),
        ],
        // Estado de ánimo, Sueño y Ejercicio en una fila (siempre mostrar las tres columnas)
        // Siempre mostrar esta fila para todas las entradas
        ...[
          Row(
            children: [
              // Estado de ánimo
              Expanded(
                child: entrada['estado_animo'] != null && entrada['estado_animo'].toString().isNotEmpty
                    ? _buildInfoChip(
                        icon: Icons.mood,
                        label: 'Estado',
                        value: entrada['estado_animo'].toString(),
                      )
                    : _buildInfoChip(
                        icon: Icons.mood,
                        label: 'Estado',
                        value: '-',
                        isEmpty: true,
                      ),
              ),
              const SizedBox(width: 8),
              // Sueño
              Expanded(
                child: entrada['horas_sueno'] != null
                    ? _buildInfoChip(
                        icon: Icons.bedtime,
                        label: 'Sueño',
                        value: '${entrada['horas_sueno']}h',
                      )
                    : _buildInfoChip(
                        icon: Icons.bedtime,
                        label: 'Sueño',
                        value: '-',
                        isEmpty: true,
                      ),
              ),
              const SizedBox(width: 8),
              // Ejercicio (siempre mostrar "Sí" o "No")
              Expanded(
                child: entrada['hizo_ejercicio'] == true
                    ? _buildInfoChip(
                        icon: Icons.fitness_center,
                        label: 'Ejercicio',
                        value: 'Sí',
                      )
                    : _buildInfoChip(
                        icon: Icons.fitness_center,
                        label: 'Ejercicio',
                        value: 'No',
                        isEmpty: true,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        // Gratitud
        if (entrada['gratitud'] != null && entrada['gratitud'].toString().isNotEmpty) ...[
          _buildInfoRow(
            icon: Icons.favorite,
            label: 'Gratitud',
            value: entrada['gratitud'].toString(),
            isMultiline: true,
            isSpecial: true,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isMultiline,
    bool isSpecial = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSpecial
            ? const Color(0xFFFFD700).withOpacity(0.1)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSpecial
              ? const Color(0xFFFFD700).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Container(
            padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
            child: Icon(
              icon,
              size: 16,
                      color: const Color(0xFFFFD700),
                    ),
                  ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Text(
                  label,
            style: GoogleFonts.inter(
                    fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
                    letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
                  value,
            style: GoogleFonts.inter(
              fontSize: 13,
                    color: isSpecial ? const Color(0xFFFFD700) : Colors.white,
                    fontStyle: isSpecial ? FontStyle.italic : FontStyle.normal,
                    height: isMultiline ? 1.4 : 1.2,
                  ),
                  maxLines: isMultiline ? 3 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    bool isEmpty = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isEmpty 
            ? Colors.white.withOpacity(0.03)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isEmpty
              ? const Color(0xFFFFD700).withOpacity(0.1)
              : const Color(0xFFFFD700).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: isEmpty
                ? Colors.white54
                : const Color(0xFFFFD700),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isEmpty
                        ? Colors.white54
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _hayFiltrosActivos =>
      _filtroCodigo != null || _fechaDesde != null || _fechaHasta != null;

  Widget _buildFiltroButton() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: _hayFiltrosActivos
            ? const Color(0xFFFFD700).withOpacity(0.25)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hayFiltrosActivos
              ? const Color(0xFFFFD700)
              : Colors.white.withOpacity(0.3),
          width: _hayFiltrosActivos ? 1.5 : 1,
        ),
      ),
      child: IconButton(
        onPressed: _mostrarFiltros,
        icon: Icon(
          Icons.filter_list,
          color: _hayFiltrosActivos ? const Color(0xFFFFD700) : Colors.white70,
        ),
        tooltip: 'Filtrar por código o fecha',
      ),
    );
  }

  Widget _buildFiltrosActivosChip() {
    final partes = <String>[];
    if (_filtroCodigo != null) partes.add('"$_filtroCodigo"');
    if (_fechaDesde != null) {
      partes.add('desde ${DateFormat('dd/MM/yyyy').format(_fechaDesde!)}');
    }
    if (_fechaHasta != null) {
      partes.add('hasta ${DateFormat('dd/MM/yyyy').format(_fechaHasta!)}');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 14, color: Color(0xFFFFD700)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Filtrando ${partes.join(' · ')}',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: _limpiarFiltros,
            child: Text(
              'Limpiar',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFFD700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarFiltros() async {
    // Variables temporales para el diálogo
    DateTime? tmpFechaDesde = _fechaDesde;
    DateTime? tmpFechaHasta = _fechaHasta;
    String? tmpCodigo = _filtroCodigo;
    final codigoCtrl = TextEditingController(text: tmpCodigo ?? '');

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1C2541),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: const Color(0xFFFFD700).withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              title: Row(
                children: [
                  const Icon(Icons.filter_list, color: Color(0xFFFFD700), size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Filtrar Diario',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Filtro por código ──────────────────────────
                    Text(
                      'Secuencia / Código',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: codigoCtrl,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Ej: 8888 o nombre del código',
                        hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.07),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: const Color(0xFFFFD700).withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: const Color(0xFFFFD700).withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
                        ),
                        suffixIcon: codigoCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                                onPressed: () {
                                  codigoCtrl.clear();
                                  setLocalState(() => tmpCodigo = null);
                                },
                              )
                            : null,
                      ),
                      onChanged: (v) => setLocalState(() => tmpCodigo = v.trim().isEmpty ? null : v.trim()),
                    ),

                    const SizedBox(height: 20),

                    // ── Rango de fechas ────────────────────────────
                    Text(
                      'Rango de Fechas',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Desde
                    _buildDatePickerRow(
                      label: 'Desde',
                      date: tmpFechaDesde,
                      icon: Icons.calendar_today,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: tmpFechaDesde ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (c, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFFFFD700),
                                surface: Color(0xFF1C2541),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) setLocalState(() => tmpFechaDesde = picked);
                      },
                      onClear: tmpFechaDesde != null
                          ? () => setLocalState(() => tmpFechaDesde = null)
                          : null,
                    ),

                    const SizedBox(height: 8),

                    // Hasta
                    _buildDatePickerRow(
                      label: 'Hasta',
                      date: tmpFechaHasta,
                      icon: Icons.calendar_month,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: tmpFechaHasta ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (c, child) => Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFFFFD700),
                                surface: Color(0xFF1C2541),
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) setLocalState(() => tmpFechaHasta = picked);
                      },
                      onClear: tmpFechaHasta != null
                          ? () => setLocalState(() => tmpFechaHasta = null)
                          : null,
                    ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                // Limpiar filtros
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _filtroCodigo = null;
                      _fechaDesde = null;
                      _fechaHasta = null;
                    });
                    Navigator.of(ctx).pop();
                    _loadDiario();
                  },
                  icon: const Icon(Icons.clear_all, size: 18, color: Colors.white54),
                  label: Text(
                    'Limpiar',
                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                  ),
                ),
                // Aplicar filtros
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _filtroCodigo = (codigoCtrl.text.trim().isEmpty) ? null : codigoCtrl.text.trim();
                      _fechaDesde = tmpFechaDesde;
                      _fechaHasta = tmpFechaHasta;
                    });
                    Navigator.of(ctx).pop();
                    _loadDiario();
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: Text('Aplicar', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: const Color(0xFF0B132B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Fila reutilizable de selector de fecha con ícono, label y botón de limpiar.
  Widget _buildDatePickerRow({
    required String label,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final formatted = date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Sin seleccionar';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: date != null
                ? const Color(0xFFFFD700).withOpacity(0.6)
                : const Color(0xFFFFD700).withOpacity(0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFFFFD700)),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                formatted,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: date != null ? Colors.white : Colors.white38,
                  fontWeight: date != null ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 16, color: Colors.white54),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _limpiarFiltros() {
    setState(() {
      _filtroCodigo = null;
      _fechaDesde = null;
      _fechaHasta = null;
    });
    _loadDiario();
  }
}
