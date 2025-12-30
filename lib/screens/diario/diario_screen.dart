import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../widgets/glow_background.dart';
import '../../services/diario_service.dart';
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrarSecuencias() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        _secuenciasFiltradas = _secuenciasEnSeguimiento;
      });
      return;
    }

    final filtradas = <String, List<Map<String, dynamic>>>{};
    for (final entry in _secuenciasEnSeguimiento.entries) {
      final codigo = entry.key.toLowerCase();
      final nombreCodigo = CodigosRepository().getTituloByCode(entry.key).toLowerCase();
      
      // Buscar en código, título o palabras clave
      if (codigo.contains(query) || 
          nombreCodigo.contains(query) ||
          entry.key.contains(query)) {
        filtradas[entry.key] = entry.value;
      }
    }

    setState(() {
      _secuenciasFiltradas = filtradas;
    });
  }

  Future<void> _loadDiario() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final diarioService = DiarioService();
      _entradas = await diarioService.getEntradas(
        codigo: _filtroCodigo,
        fechaDesde: _fechaDesde,
        fechaHasta: _fechaHasta,
      );
      _secuenciasEnSeguimiento = await diarioService.getSecuenciasEnSeguimiento();
      _secuenciasFiltradas = _secuenciasEnSeguimiento;
    } catch (e) {
      print('Error cargando diario: $e');
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
  }

  // Método público para recargar el diario desde fuera (ej. desde MainNavigation)
  void reloadDiario() {
    if (mounted) {
      _loadDiario();
    }
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
                              'Seguimiento de tus activaciones',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Texto explicativo
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFFD700).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: const Color(0xFFFFD700),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '¿Qué puedes ver aquí?',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFFFD700),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Visualiza todas las secuencias que estás siguiendo. Cada una muestra el código activado y el detalle de cada día con tus intenciones, sensaciones y resultados.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.white70,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
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
                        
                        // Búsqueda
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar por código, título o palabra clave...',
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
                      ],
                    ),
                  ),
                  
                  // Grid de secuencias agrupadas por código
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
    // Obtener el nombre del código desde el repositorio
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
              // Código destacado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  codigo,
                  style: GoogleFonts.spaceMono(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD700),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Título e información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título del código
                    Text(
                      nombreCodigo.isNotEmpty && nombreCodigo != 'Campo Energético'
                          ? nombreCodigo
                          : 'Secuencia activa',
                      style: GoogleFonts.inter(
                        fontSize: 15,
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
                        Icon(
                          Icons.repeat_one,
                          size: 14,
                          color: const Color(0xFFFFD700),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${entradas.length} ${entradas.length == 1 ? 'activación' : 'activaciones'}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        if (diasUnicos > 1) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$diasUnicos días',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Icono de flecha
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: const Color(0xFFFFD700),
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
    // Agrupar entradas por fecha
    final entradasPorFecha = <String, List<Map<String, dynamic>>>{};
    for (final entrada in entradas) {
      final fecha = entrada['fecha']?.toString() ?? 'sin_fecha';
      if (!entradasPorFecha.containsKey(fecha)) {
        entradasPorFecha[fecha] = [];
      }
      entradasPorFecha[fecha]!.add(entrada);
    }

    final fechas = entradasPorFecha.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Más reciente primero

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
                          // Código completo
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
                    Icon(
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
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: fechas.length,
              itemBuilder: (context, index) {
                final fecha = fechas[index];
                final entradasDelDia = entradasPorFecha[fecha]!;
                return _buildEntradaPorFechaCard(
                  fecha: fecha,
                  entradas: entradasDelDia,
                );
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
    final fechaFormateada = fecha != 'sin_fecha'
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(fecha))
        : 'Sin fecha';
    
    final fechaObj = fecha != 'sin_fecha' ? DateTime.parse(fecha) : DateTime.now();
    final diaSemana = DateFormat('EEEE', 'es').format(fechaObj);
    final diaSemanaCapitalizado = diaSemana[0].toUpperCase() + diaSemana.substring(1);

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
                  child: Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: const Color(0xFFFFD700),
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
                        Icon(
                          Icons.repeat,
                          size: 14,
                          color: const Color(0xFFFFD700),
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
            }).toList(),
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
                    'El diario transforma el uso de códigos de Grabovoi de una práctica pasiva a una experiencia activa y consciente, permitiendo a los usuarios comprender mejor su cuerpo, mente y espíritu a través del registro sistemático y la reflexión personal.',
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
                  Icon(Icons.info_outline, color: const Color(0xFFFFD700), size: 20),
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
            Icon(Icons.info_outline, size: 16, color: Colors.white70),
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
        // Estado de ánimo
        if (entrada['estado_animo'] != null && entrada['estado_animo'].toString().isNotEmpty) ...[
          _buildInfoRow(
            icon: Icons.mood,
            label: 'Estado de ánimo',
            value: entrada['estado_animo'].toString(),
            isMultiline: false,
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
        // Horas de sueño y ejercicio en una fila
        if (entrada['horas_sueno'] != null || entrada['hizo_ejercicio'] == true) ...[
          Row(
            children: [
              if (entrada['horas_sueno'] != null)
                Expanded(
                  child: _buildInfoChip(
                    icon: Icons.bedtime,
                    label: 'Sueño',
                    value: '${entrada['horas_sueno']}h',
                  ),
                ),
              if (entrada['horas_sueno'] != null && entrada['hizo_ejercicio'] == true)
                const SizedBox(width: 8),
              if (entrada['hizo_ejercicio'] == true)
                Expanded(
                  child: _buildInfoChip(
                    icon: Icons.fitness_center,
                    label: 'Ejercicio',
                    value: 'Sí',
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color(0xFFFFD700),
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
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarFiltros() {
    // TODO: Implementar diálogo de filtros
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2541),
        title: Text(
          'Filtros',
          style: GoogleFonts.inter(
            color: const Color(0xFFFFD700),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Los filtros estarán disponibles próximamente',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
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
