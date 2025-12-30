import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../widgets/glow_background.dart';
import '../../services/diario_service.dart';

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
  int _diasConsecutivos = 0;
  Map<String, int> _codigosMasUsados = {};

  @override
  void initState() {
    super.initState();
    _loadDiario();
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
      _diasConsecutivos = await diarioService.getDiasConsecutivos();
      _codigosMasUsados = await diarioService.getCodigosMasUsados();
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
                        
                        // Estadísticas rápidas
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Días Consecutivos',
                                '$_diasConsecutivos',
                                Icons.calendar_today,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Entradas',
                                '${_entradas.length}',
                                Icons.book,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Filtros
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _mostrarFiltros,
                                icon: const Icon(Icons.filter_list, size: 18),
                                label: const Text('Filtros'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (_filtroCodigo != null || _fechaDesde != null)
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _limpiarFiltros,
                                  icon: const Icon(Icons.clear, size: 18),
                                  label: const Text('Limpiar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF6B6B).withOpacity(0.2),
                                    foregroundColor: const Color(0xFFFF6B6B),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Lista de entradas agrupadas por fecha y código
                  Expanded(
                    child: _entradas.isEmpty
                        ? _buildEmptyState()
                        : _buildGroupedEntries(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFD700), size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFD700),
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
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

  // Agrupar entradas por fecha y código
  Map<String, List<Map<String, dynamic>>> _groupEntriesByDateAndCode() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    
    for (final entrada in _entradas) {
      final fecha = entrada['fecha'] != null 
          ? entrada['fecha'].toString()
          : 'sin_fecha';
      final codigo = entrada['codigo']?.toString() ?? 'sin_codigo';
      final key = '$fecha|$codigo';
      
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(entrada);
    }
    
    return grouped;
  }

  Widget _buildGroupedEntries() {
    final grouped = _groupEntriesByDateAndCode();
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        // Ordenar por fecha (más reciente primero), luego por código
        final fechaA = a.split('|')[0];
        final fechaB = b.split('|')[0];
        final comparacionFecha = fechaB.compareTo(fechaA);
        if (comparacionFecha != 0) return comparacionFecha;
        return a.split('|')[1].compareTo(b.split('|')[1]);
      });
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final key = sortedKeys[index];
        final entradasDelGrupo = grouped[key]!;
        final fecha = key.split('|')[0];
        final codigo = key.split('|')[1];
        
        return _buildGroupedEntryCard(
          fecha: fecha,
          codigo: codigo == 'sin_codigo' ? null : codigo,
          entradas: entradasDelGrupo,
        );
      },
    );
  }

  Widget _buildGroupedEntryCard({
    required String fecha,
    String? codigo,
    required List<Map<String, dynamic>> entradas,
  }) {
    final fechaFormateada = fecha != 'sin_fecha' 
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(fecha))
        : 'Sin fecha';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado: Fecha y Código
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                fechaFormateada,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFD700),
                ),
              ),
              if (codigo != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.tag, size: 14, color: const Color(0xFFFFD700)),
                      const SizedBox(width: 4),
                      Text(
                        codigo,
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
          
          // Contador de repeticiones
          if (entradas.length > 1) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${entradas.length} repeticiones',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFFFFD700).withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Lista de entradas del grupo (expandible)
          ...entradas.asMap().entries.map((entry) {
            final idx = entry.key;
            final entrada = entry.value;
            final isLast = idx == entradas.length - 1;
            
            return Column(
              children: [
                _buildSingleEntryContent(entrada, idx: idx),
                if (!isLast) ...[
                  const SizedBox(height: 12),
                  Divider(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                    height: 1,
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSingleEntryContent(Map<String, dynamic> entrada, {int? idx}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (idx != null && idx > 0) ...[
          Text(
            'Repetición ${idx + 1}',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (entrada['intencion'] != null) ...[
          Text(
            'Intención:',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entrada['intencion'],
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (entrada['estado_animo'] != null) ...[
          Text(
            'Estado de ánimo: ${entrada['estado_animo']}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (entrada['sensaciones'] != null && entrada['sensaciones'].toString().isNotEmpty) ...[
          Text(
            'Sensaciones:',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entrada['sensaciones'],
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (entrada['horas_sueno'] != null) ...[
          Text(
            'Horas de sueño: ${entrada['horas_sueno']}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (entrada['hizo_ejercicio'] == true) ...[
          Row(
            children: [
              Icon(Icons.check_circle, size: 16, color: const Color(0xFFFFD700)),
              const SizedBox(width: 6),
              Text(
                'Ejercicio realizado',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (entrada['gratitud'] != null && entrada['gratitud'].toString().isNotEmpty) ...[
          Text(
            'Gratitud:',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entrada['gratitud'],
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEntradaCard(Map<String, dynamic> entrada) {
    final fecha = entrada['fecha'] != null 
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(entrada['fecha']))
        : 'Sin fecha';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                fecha,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFD700),
                ),
              ),
              if (entrada['codigo'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entrada['codigo'],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFD700),
                    ),
                  ),
                ),
            ],
          ),
          if (entrada['intencion'] != null) ...[
            const SizedBox(height: 12),
            Text(
              'Intención:',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              entrada['intencion'],
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ],
          if (entrada['estado_animo'] != null) ...[
            const SizedBox(height: 8),
            Text(
              'Estado de ánimo: ${entrada['estado_animo']}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ],
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
