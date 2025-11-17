import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glow_background.dart';
import '../../models/supabase_models.dart';
import '../codes/repetition_session_screen.dart';
import '../../services/biblioteca_supabase_service.dart';
import '../../services/ai/openai_codes_service.dart';
import '../../services/ai_codes_service.dart';
import '../diag/diag_screen.dart';
import '../../widgets/illuminated_code_text.dart';
import '../../config/env.dart';
import '../../config/supabase_config.dart';

class BibliotecaScreen extends StatefulWidget {
  const BibliotecaScreen({super.key});

  @override
  State<BibliotecaScreen> createState() => _BibliotecaScreenState();
}

class _BibliotecaScreenState extends State<BibliotecaScreen> {
  List<CodigoGrabovoi> codigos = [];
  List<CodigoGrabovoi> filtrados = [];
  List<UsuarioFavorito> favoritos = [];
  List<CodigoPopularidad> popularidad = [];
  bool isLoading = true;
  String _query = '';
  String _filtroCategoria = 'Todos';
  String _tab = 'Todos'; // Todos | Favoritos
  List<String> _categorias = ['Todos'];

  Set<String> _favoritosSet = {};

  late final OpenAICodesService _openai;

  @override
  void initState() {
    super.initState();
    _openai = OpenAICodesService(
      apiKey: const String.fromEnvironment('OPENAI_API_KEY', defaultValue: ''),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    print('🔄 [BIBLIOTECA] ===========================================');
    print('🔄 [BIBLIOTECA] INICIANDO CARGA DE DATOS');
    print('🔄 [BIBLIOTECA] ===========================================');
    print('🔄 [BIBLIOTECA] Timestamp: ${DateTime.now()}');
    print('🔄 [BIBLIOTECA] Estado actual: isLoading=$isLoading');
    print('🔄 [BIBLIOTECA] Códigos actuales: ${codigos.length}');
    print('🔄 [BIBLIOTECA] Filtrados actuales: ${filtrados.length}');
    print('🔄 [BIBLIOTECA] ===========================================');
    
    try {
      setState(() => isLoading = true);
      print('🔄 [BIBLIOTECA] setState: isLoading = true');
      print('🔄 [BIBLIOTECA] Iniciando carga de datos via API...');
      
      // Cargar códigos desde API
      print('🔄 [BIBLIOTECA] Llamando BibliotecaSupabaseService.getTodosLosCodigos()...');
      final codigosData = await BibliotecaSupabaseService.getTodosLosCodigos();
      
      print('📚 [BIBLIOTECA] ===========================================');
      print('📚 [BIBLIOTECA] DATOS OBTENIDOS DE API');
      print('📚 [BIBLIOTECA] ===========================================');
      print('📚 [BIBLIOTECA] Códigos cargados: ${codigosData.length}');
      print('📚 [BIBLIOTECA] Primer código: ${codigosData.isNotEmpty ? codigosData.first.nombre : 'N/A'}');
      print('📚 [BIBLIOTECA] Último código: ${codigosData.isNotEmpty ? codigosData.last.nombre : 'N/A'}');
      print('📚 [BIBLIOTECA] Categorías en datos: ${codigosData.map((c) => c.categoria).toSet().toList()}');
      print('📚 [BIBLIOTECA] Primeros 3 códigos: ${codigosData.take(3).map((c) => '${c.codigo} - ${c.nombre}').toList()}');
      print('📚 [BIBLIOTECA] ===========================================');
      
      // Cargar categorías desde API
      final categoriasData = await BibliotecaSupabaseService.getCategorias();
      print('🏷️ Categorías cargadas: ${categoriasData.length}');
      print('🏷️ Categorías: $categoriasData');
      
      // Cargar favoritos desde API
      final favoritosData = await BibliotecaSupabaseService.getFavoritos();
      print('❤️ Favoritos cargados: ${favoritosData.length}');
      
      // Popularidad se maneja por separado
      print('📊 Popularidad: Se maneja individualmente');

      setState(() {
        codigos = codigosData;
        _categorias = ['Todos', ...categoriasData];
        favoritos = favoritosData;
        popularidad = []; // Se carga dinámicamente
        // Inicializar _favoritosSet con los códigos (strings) de los favoritos
        _favoritosSet = {};
        for (final favorito in favoritos) {
          final codigo = codigos.firstWhere((c) => c.id == favorito.codigoId);
          _favoritosSet.add(codigo.codigo);
        }
        filtrados = List.from(codigos);
        isLoading = false;
      });
      
      print('📚 [BIBLIOTECA] ===========================================');
      print('📚 [BIBLIOTECA] DESPUÉS DE setState');
      print('📚 [BIBLIOTECA] ===========================================');
      print('📚 [BIBLIOTECA] codigos.length: ${codigos.length}');
      print('📚 [BIBLIOTECA] filtrados.length: ${filtrados.length}');
      print('📚 [BIBLIOTECA] isLoading: $isLoading');
      print('📚 [BIBLIOTECA] _categorias: $_categorias');
      print('📚 [BIBLIOTECA] ===========================================');
      
      // Aplicar filtros iniciales después de cargar los datos
      _aplicarFiltros();
      
      print('✅ Datos cargados exitosamente via API. Total códigos: ${codigos.length}');
      print('✅ Categorías finales: $_categorias');
      print('✅ Filtrados iniciales: ${filtrados.length}');
    } catch (e) {
      setState(() => isLoading = false);
      print('❌ Error cargando datos via API: $e');
      debugPrint('Error cargando datos via API: $e');
      
      // Mostrar mensaje de error amigable al usuario
      if (mounted) {
        String mensajeError = 'Error al cargar los códigos';
        String tituloError = 'Error de Conexión';
        
        if (e.toString().contains('Error DNS')) {
          tituloError = 'Problema de Red';
          mensajeError = 'No se pudo conectar al servidor.\nVerifica tu conexión a internet o cambia de red.';
        } else if (e.toString().contains('TimeoutException')) {
          tituloError = 'Conexión Lenta';
          mensajeError = 'La conexión está muy lenta.\nIntenta de nuevo en unos momentos.';
        } else if (e.toString().contains('SocketException')) {
          tituloError = 'Sin Conexión';
          mensajeError = 'No hay conexión a internet.\nVerifica tu conexión de red.';
        }
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1C2541),
            title: Row(
              children: [
                const Icon(Icons.wifi_off, color: Color(0xFFFFD700)),
                const SizedBox(width: 8),
                Text(
                  tituloError,
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFFFFD700),
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            content: Text(
              mensajeError,
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadData(); // Reintentar
                },
                child: Text(
                  'Reintentar',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cerrar',
                  style: GoogleFonts.inter(color: Colors.white70),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  void _aplicarFiltros() async {
    print('🔍 [FILTROS] ===========================================');
    print('🔍 [FILTROS] APLICANDO FILTROS');
    print('🔍 [FILTROS] ===========================================');
    print('🔍 [FILTROS] Timestamp: ${DateTime.now()}');
    print('🔍 [FILTROS] Tab actual: $_tab');
    print('🔍 [FILTROS] Categoría: $_filtroCategoria');
    print('🔍 [FILTROS] Query: "$_query"');
    print('🔍 [FILTROS] Códigos disponibles: ${codigos.length}');
    print('🔍 [FILTROS] Favoritos disponibles: ${favoritos.length}');
    print('🔍 [FILTROS] Filtrados ANTES: ${filtrados.length}');
    print('🔍 [FILTROS] ===========================================');
    
    List<CodigoGrabovoi> base = [];
    
    if (_tab == 'Favoritos') {
      base = List.from(favoritos);
      print('🔍 [FILTROS] Usando favoritos como base: ${base.length}');
      print('🔍 [FILTROS] Favoritos: ${favoritos.map((f) => f.codigoId).toList()}');
    } else {
      base = List.from(codigos);
      print('🔍 [FILTROS] Usando todos los códigos como base: ${base.length}');
      print('🔍 [FILTROS] Primeros 3 códigos: ${base.take(3).map((c) => c.nombre).toList()}');
      
      if (_filtroCategoria != 'Todos') {
        base = base.where((c) => c.categoria.toLowerCase() == _filtroCategoria.toLowerCase()).toList();
      }

      if (_query.trim().isNotEmpty) {
        try {
          // Usar búsqueda de Supabase si hay query
          base = await SimpleApiService.getCodigos(search: _query.trim());
          
          // Si no se encontraron resultados, usar el sistema de 3 niveles
          if (base.isEmpty) {
            await _buscarConIA(_query.trim());
            // Recargar datos después de la búsqueda inteligente
            await _loadData();
            // Aplicar filtros nuevamente
            base = await SimpleApiService.getCodigos(search: _query.trim());
          }
        } catch (e) {
          // Fallback a búsqueda local
          final q = _query.trim().toLowerCase();
          base = base.where((c) =>
            c.codigo.toLowerCase().contains(q) ||
            c.nombre.toLowerCase().contains(q) ||
            c.descripcion.toLowerCase().contains(q)
          ).toList();
          
          // Si no hay resultados locales, usar el sistema de 3 niveles
          if (base.isEmpty) {
            await _buscarConIA(_query.trim());
            await _loadData();
            // Intentar búsqueda local nuevamente
            base = codigos.where((c) =>
              c.codigo.toLowerCase().contains(q) ||
              c.nombre.toLowerCase().contains(q) ||
              c.descripcion.toLowerCase().contains(q)
            ).toList();
          }
        }
      }
    }

    print('🔍 [FILTROS] ===========================================');
    print('🔍 [FILTROS] RESULTADO FINAL DE FILTROS');
    print('🔍 [FILTROS] ===========================================');
    print('🔍 [FILTROS] Códigos filtrados: ${base.length}');
    print('🔍 [FILTROS] Primeros 3 códigos: ${base.take(3).map((c) => c.nombre).toList()}');
    print('🔍 [FILTROS] Últimos 3 códigos: ${base.length > 3 ? base.skip(base.length - 3).map((c) => c.nombre).toList() : base.map((c) => c.nombre).toList()}');
    print('🔍 [FILTROS] Categorías en filtrados: ${base.map((c) => c.categoria).toSet().toList()}');
    print('🔍 [FILTROS] ===========================================');
    
    setState(() {
      filtrados = base;
    });
    
    print('🔍 [FILTROS] ===========================================');
    print('🔍 [FILTROS] setState COMPLETADO');
    print('🔍 [FILTROS] ===========================================');
    print('🔍 [FILTROS] Filtrados DESPUÉS: ${filtrados.length}');
    print('🔍 [FILTROS] UI actualizada con ${filtrados.length} códigos');
    print('🔍 [FILTROS] ===========================================');
  }

  Future<void> _buscarConIA(String consulta) async {
    try {
      setState(() => isLoading = true);
      
      // Mostrar mensaje de búsqueda
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔍 Buscando códigos relacionados con "$consulta"...'),
            backgroundColor: const Color(0xFFFFD700),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      // Buscar códigos siguiendo el sistema de 3 niveles
      final resultado = await AICodesService.buscarYCrearCodigos(consulta);
      
      if (mounted) {
        switch (resultado['tipo']) {
          case 'oficiales':
            final codigos = resultado['codigos'] as List<CodigoGrabovoi>;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ ${resultado['mensaje']} (${codigos.length} códigos encontrados)'),
                backgroundColor: const Color(0xFF4CAF50),
                duration: const Duration(seconds: 4),
              ),
            );
            break;
            
          case 'adicionales':
            final codigos = resultado['codigos'] as List<CodigoGrabovoi>;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ ${resultado['mensaje']} (${codigos.length} códigos agregados)'),
                backgroundColor: const Color(0xFF2196F3),
                duration: const Duration(seconds: 4),
              ),
            );
            break;
            
          case 'personalizado':
            _mostrarDialogoCodigoPersonalizado(consulta);
            break;
            
          case 'error':
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ${resultado['mensaje']}'),
                backgroundColor: const Color(0xFFF44336),
                duration: const Duration(seconds: 4),
              ),
            );
            break;
        }
      }
    } catch (e) {
      debugPrint('Error en búsqueda: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error en la búsqueda: $e'),
            backgroundColor: const Color(0xFFF44336),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _mostrarDialogoCodigoPersonalizado(String consulta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2541),
        title: Text(
          'Crear Código Personalizado',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFFFD700),
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No se encontraron códigos oficiales o auténticos para "$consulta".',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Puedes crear tu propio código siguiendo la metodología de Grabovoi:',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 Metodología Grabovoi:',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFFD700),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Visualiza tu intención claramente\n'
                    '• Conecta con la frecuencia numérica\n'
                    '• Crea una secuencia numérica personal\n'
                    '• Practica la concentración y meditación',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '🚧 Esta funcionalidad está en desarrollo',
                style: GoogleFonts.inter(
                  color: const Color(0xFFFF9800),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Entendido',
              style: GoogleFonts.inter(
                color: const Color(0xFFFFD700),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFavorito(String codigo) async {
    try {
      final codigoCompleto = codigos.firstWhere((c) => c.codigo == codigo);
      await BibliotecaSupabaseService.toggleFavorito(codigoCompleto.id);
      
      // Actualizar estado local
      setState(() {
        if (_favoritosSet.contains(codigoCompleto.id)) {
          _favoritosSet.remove(codigoCompleto.id);
        } else {
          _favoritosSet.add(codigoCompleto.id);
        }
      });
      
      // Mostrar mensaje de confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _favoritosSet.contains(codigoCompleto.id) 
              ? '❤️ Agregado a favoritos' 
              : '💔 Removido de favoritos',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          backgroundColor: _favoritosSet.contains(codigoCompleto.id) 
            ? Colors.green 
            : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Aplicar filtros si estamos en la pestaña de favoritos
      if (_tab == 'Favoritos') {
        _aplicarFiltros();
      }
    } catch (e) {
      debugPrint('Error al toggle favorito: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _sumarPopularidad(String codigo) async {
    try {
      await BibliotecaSupabaseService.incrementarPopularidad(codigo);
    } catch (e) {
      debugPrint('Error al incrementar popularidad: $e');
    }
  }

  void _mostrarInfoDebug() {
    final supabaseBase = Env.supabaseUrl.isNotEmpty ? Env.supabaseUrl : SupabaseConfig.url;
    final supabaseDisplay = supabaseBase.isNotEmpty ? supabaseBase : 'No configurada';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2541),
        title: Text(
          'Debug Avanzado - Supabase',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFFFD700),
            fontSize: 20,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información de conexión
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E90FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF1E90FF).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🌐 Información de Conexión',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1E90FF),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
              _buildDebugInfoItem('URL Supabase', supabaseDisplay),
                    _buildDebugInfoItem('Estado conexión', 'Conectado (anon key)'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Estado de datos
              _buildDebugInfoItem('Estado de carga', isLoading ? 'Cargando...' : 'Completado'),
              const SizedBox(height: 8),
              _buildDebugInfoItem('Total códigos', '${codigos.length}'),
              _buildDebugInfoItem('Códigos filtrados', '${filtrados.length}'),
              _buildDebugInfoItem('Categorías disponibles', '${_categorias.length}'),
              _buildDebugInfoItem('Favoritos', '${favoritos.length}'),
              _buildDebugInfoItem('Popularidad registros', '${popularidad.length}'),
              const SizedBox(height: 12),
              _buildDebugInfoItem('Filtro activo', _filtroCategoria),
              _buildDebugInfoItem('Tab activo', _tab),
              _buildDebugInfoItem('Búsqueda actual', _query.isEmpty ? '(vacía)' : '"$_query"'),
              
              // Diagnóstico
              if (codigos.isEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🚨 DIAGNÓSTICO - No hay códigos',
                        style: GoogleFonts.inter(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Posibles causas:',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• Tabla vacía en Supabase\n'
                        '• Error de RLS (Row Level Security)\n'
                        '• Problema de conectividad\n'
                        '• Credenciales incorrectas\n'
                        '• Error en la consulta SQL',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔧 Acciones de Debug:',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFFFD700),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _loadData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Datos recargados'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      child: Text(
                        '🔄 Recargar datos',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          _query = '';
                          _filtroCategoria = 'Todos';
                          _tab = 'Todos';
                          filtrados = List.from(codigos);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Filtros reiniciados'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      },
                      child: Text(
                        '🔄 Reiniciar filtros',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _testSupabaseConnection();
                      },
                      child: Text(
                        '🧪 Probar conexión Supabase',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '💡 Si no ves códigos, prueba recargar los datos o reiniciar los filtros.',
                  style: GoogleFonts.inter(
                    color: Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cerrar',
              style: GoogleFonts.inter(
                color: const Color(0xFFFFD700),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testSupabaseConnection() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2541),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFFFFD700),
            ),
            const SizedBox(height: 16),
            Text(
              'Probando conexión con Supabase...',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      print('🧪 INICIANDO PRUEBA DE CONEXIÓN SUPABASE');
      
      // Probar conexión básica
      final testResult = await SimpleApiService.getCodigos();
      
      Navigator.of(context).pop(); // Cerrar loading dialog
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1C2541),
          title: Text(
            'Resultado de Prueba',
            style: GoogleFonts.playfairDisplay(
              color: const Color(0xFFFFD700),
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDebugInfoItem('Conexión', '✅ Exitosa'),
              _buildDebugInfoItem('Códigos obtenidos', '${testResult.length}'),
              _buildDebugInfoItem('Estado', testResult.isEmpty ? '⚠️ Lista vacía' : '✅ Con datos'),
              
              if (testResult.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '✅ La conexión funciona correctamente. El problema puede estar en el filtrado o visualización.',
                    style: GoogleFonts.inter(
                      color: Colors.green,
                      fontSize: 11,
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '❌ La conexión funciona pero no hay datos. Revisar:\n• Tabla vacía\n• RLS configurado\n• Permisos de anon key',
                    style: GoogleFonts.inter(
                      color: Colors.red,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cerrar',
                style: GoogleFonts.inter(
                  color: const Color(0xFFFFD700),
                ),
              ),
            ),
          ],
        ),
      );
      
    } catch (e) {
      Navigator.of(context).pop(); // Cerrar loading dialog
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1C2541),
          title: Text(
            'Error de Conexión',
            style: GoogleFonts.playfairDisplay(
              color: Colors.red,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDebugInfoItem('Estado', '❌ Falló'),
              _buildDebugInfoItem('Error', e.toString()),
              
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '❌ No se pudo conectar con Supabase. Verificar:\n• Conectividad a internet\n• URL y credenciales\n• Estado del servidor',
                  style: GoogleFonts.inter(
                    color: Colors.red,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cerrar',
                style: GoogleFonts.inter(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Biblioteca Cuántica',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFD700),
                        shadows: [
                          Shadow(
                            color: const Color(0xFFFFD700).withOpacity(0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${codigos.length} códigos disponibles',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            // Botón de debug
                            IconButton(
                              onPressed: _mostrarInfoDebug,
                              icon: const Icon(
                                Icons.bug_report,
                                color: Color(0xFFFFD700),
                                size: 20,
                              ),
                              tooltip: 'Información de debug',
                            ),
                            // Botón de diagnóstico de red
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const DiagScreen()),
                                );
                              },
                              icon: const Icon(
                                Icons.network_check,
                                color: Color(0xFFFFD700),
                                size: 20,
                              ),
                              tooltip: 'Diagnóstico de red',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Códigos numéricos de manifestación',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (v) {
                        _query = v;
                        _aplicarFiltros();
                      },
                      onSubmitted: (_) {
                        _aplicarFiltros();
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar código, intención o categoría...',
                        hintStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                          borderSide: BorderSide(color: Color(0xFFFFD700)),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final t in const ['Todos', 'Favoritos'])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(t, style: GoogleFonts.inter()),
                              selected: _tab == t,
                              onSelected: (_) {
                                setState(() => _tab = t);
                                _aplicarFiltros();
                              },
                              selectedColor: const Color(0xFFFFD700),
                              backgroundColor: Colors.white.withOpacity(0.08),
                              labelStyle: TextStyle(
                                color: _tab == t ? const Color(0xFF0B132B) : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categorias.map((cat) {
                          final selected = _filtroCategoria == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(cat),
                              selected: selected,
                              onSelected: (_) {
                                setState(() => _filtroCategoria = cat);
                                _aplicarFiltros();
                              },
                              selectedColor: const Color(0xFFFFD700),
                              backgroundColor: Colors.white.withOpacity(0.08),
                              labelStyle: TextStyle(
                                color: selected ? const Color(0xFF0B132B) : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFFD700),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filtrados.length,
                        itemBuilder: (context, index) {
                          final codigo = filtrados[index];
                          return _buildCodigoCard(codigo);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodigoCard(CodigoGrabovoi codigo) {
    final cardColor = _getCodigoColor(codigo.color);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cardColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            _sumarPopularidad(codigo.codigo);
            _showCodigoDetail(codigo);
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        codigo.categoria,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: cardColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                  codigo.nombre,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          onPressed: () => _toggleFavorito(codigo.codigo),
                          icon: Icon(
                            _favoritosSet.contains(codigo.codigo) ? Icons.favorite : Icons.favorite_border,
                            color: _favoritosSet.contains(codigo.codigo) ? const Color(0xFFFFD700) : Colors.white70,
                          ),
                        ),
                        Text(
                          'Popularidad: ${popularidad.firstWhere((p) => p.codigoId == codigo.codigo, orElse: () => CodigoPopularidad(id: '', codigoId: codigo.codigo, contador: 0, ultimoUso: DateTime.now(), createdAt: DateTime.now(), updatedAt: DateTime.now())).contador}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  codigo.codigo,
                  style: GoogleFonts.spaceMono(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: cardColor,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  codigo.descripcion,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCodigoColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceAll('#', '0xFF')));
    } catch (e) {
      return const Color(0xFFFFD700); // Color dorado por defecto
    }
  }

  Color _getCategoryColor(String categoria) {
    // Buscar el color en la lista de códigos filtrados
    final codigo = filtrados.firstWhere(
      (c) => c.categoria.toLowerCase() == categoria.toLowerCase(),
      orElse: () => CodigoGrabovoi(
        id: '',
        codigo: '',
        nombre: '',
        descripcion: '',
        categoria: categoria,
        color: '#FFD700', // Color por defecto
      ),
    );
    
    return _getCodigoColor(codigo.color);
  }

  void _showCodigoDetail(CodigoGrabovoi codigo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1C2541),
              Color(0xFF0B132B),
            ],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(30, 30, 30, 50), // Padding inferior para evitar el menú
        child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              codigo.nombre,
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFFFD700),
              ),
            ),
            const SizedBox(height: 20),
            IlluminatedCodeText(
              code: codigo.codigo,
              fontSize: 40,
              color: _getCodigoColor(codigo.color),
              letterSpacing: 4,
            ),
            const SizedBox(height: 20),
            // Descripción del código con formato estándar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getCodigoColor(codigo.color).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    codigo.nombre.isNotEmpty ? codigo.nombre : 'Campo Energético',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getCodigoColor(codigo.color),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    codigo.descripcion,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _sumarPopularidad(codigo.codigo);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RepetitionSessionScreen(
                            codigo: codigo.codigo,
                            nombre: codigo.nombre,
                          ),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: const Color(0xFF0B132B),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Iniciar sesión de repetición',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF0B132B), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.diamond, color: Color(0xFF0B132B), size: 16),
                              const SizedBox(width: 4),
                              const Text(
                                '+3',
                                style: TextStyle(
                                  color: Color(0xFF0B132B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Nota de descargo de responsabilidad
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C2541).withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF9800).withOpacity(0.3),
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
                        color: const Color(0xFFFF9800),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Importante',
                style: GoogleFonts.inter(
                          color: const Color(0xFFFF9800),
                          fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Los códigos numéricos de Grabovoi son herramientas de manifestación y no sustituyen el consejo, diagnóstico o tratamiento médico profesional. Siempre consulta con profesionales de la salud calificados para cualquier condición médica.',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

