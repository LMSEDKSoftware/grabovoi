import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/golden_sphere.dart';
import '../../widgets/streamed_music_controller.dart';
import '../../widgets/illuminated_code_text.dart';
import '../../utils/code_formatter.dart';
import '../../services/supabase_service.dart';
import '../../models/supabase_models.dart';
import '../../config/openai_config.dart';
import '../../config/supabase_config.dart';
import '../../models/busqueda_profunda_model.dart';
import '../../services/busquedas_profundas_service.dart';

class QuantumPilotageScreen extends StatefulWidget {
  final String? codigoInicial;
  
  const QuantumPilotageScreen({super.key, this.codigoInicial});

  @override
  State<QuantumPilotageScreen> createState() => _QuantumPilotageScreenState();
}

class _QuantumPilotageScreenState extends State<QuantumPilotageScreen> 
    with TickerProviderStateMixin {
  
  // Controladores de animación
  late AnimationController _breathingController;
  late AnimationController _pulseController;
  late AnimationController _expansionController;
  late AnimationController _fadeController;
  
  // Animaciones
  late Animation<double> _breathingAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _expansionAnimation;
  late Animation<double> _fadeAnimation;
  
  // Estado de la aplicación
  String _codigoSeleccionado = '';
  String _categoriaActual = 'General';
  Color _colorVibracional = const Color(0xFFFFD700);
  bool _isSphereMode = true;
  bool _isGuidedMode = true;
  String _intencionPersonal = '';
  
  // Estado del pilotaje
  QuantumPilotageStep _currentStep = QuantumPilotageStep.preparacion;
  bool _isPilotageActive = false;
  int _repeticionesRealizadas = 0;
  double _nivelResonancia = 0.0;
  
  // Control de búsquedas profundas
  int? _busquedaActualId;
  DateTime? _inicioBusqueda;
  
  // Códigos encontrados por IA
  List<CodigoGrabovoi> _codigosEncontrados = [];
  bool _mostrarSeleccionCodigos = false;
  
  // Sistema de animación secuencial
  bool _showSequentialSteps = false;
  int _currentStepIndex = 0;
  List<bool> _stepCompleted = [false, false, false, false, false];
  
  // Lista de códigos disponibles
  List<CodigoGrabovoi> _codigos = [];
  bool _isLoading = true;

  // Sistema de búsqueda
  List<CodigoGrabovoi> _codigosFiltrados = [];
  String _queryBusqueda = '';
  bool _mostrarResultados = false;
  TextEditingController _searchController = TextEditingController();
  
  // Selector de colores para la esfera
  String _colorSeleccionado = 'dorado';
  final Map<String, Color> _coloresDisponibles = {
    'dorado': const Color(0xFFFFD700),
    'plateado': const Color(0xFFC0C0C0),
    'azul_celestial': const Color(0xFF87CEEB),
    'categoria': const Color(0xFFFFD700), // Se actualizará dinámicamente
  };
  
  // Variables para la animación de la barra de colores
  bool _isColorBarExpanded = true;
  late AnimationController _colorBarController;
  late Animation<Offset> _colorBarAnimation;

  // Sistema de favoritos
  List<CodigoGrabovoi> _favoritos = [];
  bool _isLoadingFavoritos = true;

  // Modal de opciones
  bool _showOptionsModal = false;
  String _codigoNoEncontrado = '';

  // Pilotaje manual
  bool _showManualPilotage = false;
  TextEditingController _manualCodeController = TextEditingController();
  TextEditingController _manualTitleController = TextEditingController();
  String _manualCategory = 'Abundancia';

  // Control de audio y animaciones
  bool _isAudioPlaying = false;
  bool _showAudioController = false;
  bool _isPilotageCompleted = false;
  int _pilotageDuration = 0; // en segundos
  Timer? _pilotageTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCodigos();
    _loadFavoritos();
    
    if (widget.codigoInicial != null) {
      _codigoSeleccionado = widget.codigoInicial!;
    }
  }

  void _initializeAnimations() {
    // Controlador de respiración (más lento y suave)
    _breathingController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);
    
    // Controlador de pulso (para los números)
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    // Controlador de expansión (para efectos de luz)
    _expansionController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    
    // Controlador de animación de la barra de colores
    _colorBarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _colorBarAnimation = Tween<Offset>(
      begin: const Offset(0, 0), // Posición centrada
      end: const Offset(0.3, 0), // Posición deslizada a la derecha
    ).animate(CurvedAnimation(
      parent: _colorBarController,
      curve: Curves.easeInOut,
    ));
    
    // Controlador de fade (para transiciones)
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Configurar animaciones
    _breathingAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
    
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _expansionAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _expansionController, curve: Curves.easeInOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadCodigos() async {
    try {
      final codigos = await SupabaseService.getCodigos();
      // Eliminar duplicados basándose en el código
      final codigosUnicos = <String, CodigoGrabovoi>{};
      for (final codigo in codigos) {
        codigosUnicos[codigo.codigo] = codigo; // Esto sobrescribe duplicados
      }
      
      setState(() {
        _codigos = codigosUnicos.values.toList();
        _codigosFiltrados = []; // Inicializar vacío para mostrar solo mensaje
        _isLoading = false;
        // No mostrar código por defecto, usar color dorado
        _codigoSeleccionado = '';
        _categoriaActual = 'Abundancia';
        _colorVibracional = const Color(0xFFFFD700); // Dorado por defecto
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _codigoSeleccionado = '88888588888';
        _categoriaActual = 'Abundancia';
        _colorVibracional = _getCategoryColor(_categoriaActual);
      });
    }
  }

  Future<void> _loadFavoritos() async {
    try {
      // TODO: Implementar carga de favoritos desde Supabase
      setState(() {
        _isLoadingFavoritos = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingFavoritos = false;
      });
    }
  }

  void _filtrarCodigos(String query) {
    setState(() {
      _queryBusqueda = query;
      if (query.isEmpty) {
        _codigosFiltrados = [];
        _mostrarResultados = false;
      } else {
        // Primero buscar coincidencias exactas
        final coincidenciasExactas = _codigos.where((codigo) {
          return codigo.codigo.toLowerCase() == query.toLowerCase();
        }).toList();
        
        // Si hay coincidencias exactas, mostrarlas
        if (coincidenciasExactas.isNotEmpty) {
          _codigosFiltrados = coincidenciasExactas;
          _mostrarResultados = true;
          print('✅ Coincidencia exacta encontrada: ${coincidenciasExactas.length} códigos');
        } else {
          // Si no hay coincidencias exactas, buscar coincidencias parciales
          _codigosFiltrados = _codigos.where((codigo) {
            return codigo.codigo.toLowerCase().contains(query.toLowerCase()) ||
                   codigo.nombre.toLowerCase().contains(query.toLowerCase()) ||
                   codigo.categoria.toLowerCase().contains(query.toLowerCase());
          }).toList();
          _mostrarResultados = true;
          print('🔍 Coincidencias parciales encontradas: ${_codigosFiltrados.length} códigos');
        }
        
        // NO mostrar modal automáticamente - esperar confirmación del usuario
        // El modal se mostrará solo cuando el usuario presione Enter o haga clic en buscar
      }
    });
  }

  void _confirmarBusqueda() {
    if (_queryBusqueda.isNotEmpty) {
      print('🔍 Confirmando búsqueda para: $_queryBusqueda');
      
      // 1. PRIMERO: Buscar coincidencias exactas
      final coincidenciasExactas = _codigos.where((codigo) {
        return codigo.codigo.toLowerCase() == _queryBusqueda.toLowerCase();
      }).toList();
      
      if (coincidenciasExactas.isNotEmpty) {
        print('✅ Coincidencias exactas encontradas: ${coincidenciasExactas.length} códigos');
        setState(() {
          _codigosFiltrados = coincidenciasExactas;
          _mostrarResultados = true;
        });
        return;
      }
      
      // 2. SEGUNDO: Buscar coincidencias similares/parciales
      final coincidenciasSimilares = _codigos.where((codigo) {
        final query = _queryBusqueda.toLowerCase();
        return codigo.codigo.toLowerCase().contains(query) ||
               codigo.nombre.toLowerCase().contains(query) ||
               codigo.categoria.toLowerCase().contains(query) ||
               codigo.descripcion.toLowerCase().contains(query) ||
               // Búsqueda por temas comunes
               (query.contains('salud') && codigo.categoria.toLowerCase().contains('salud')) ||
               (query.contains('amor') && codigo.categoria.toLowerCase().contains('amor')) ||
               (query.contains('dinero') && (codigo.categoria.toLowerCase().contains('abundancia') || codigo.categoria.toLowerCase().contains('manifestacion'))) ||
               (query.contains('trabajo') && (codigo.categoria.toLowerCase().contains('abundancia') || codigo.categoria.toLowerCase().contains('manifestacion'))) ||
               (query.contains('sanacion') && codigo.categoria.toLowerCase().contains('salud')) ||
               (query.contains('prosperidad') && codigo.categoria.toLowerCase().contains('abundancia'));
      }).toList();
      
      if (coincidenciasSimilares.isNotEmpty) {
        print('🔍 Coincidencias similares encontradas: ${coincidenciasSimilares.length} códigos');
        setState(() {
          _codigosFiltrados = coincidenciasSimilares;
          _mostrarResultados = true;
        });
        return;
      }
      
      // 3. TERCERO: Si no hay coincidencias exactas ni similares, mostrar modal de búsqueda profunda
      print('❌ No se encontraron coincidencias exactas ni similares para: $_queryBusqueda');
      setState(() {
        _codigoNoEncontrado = _queryBusqueda;
        _showOptionsModal = true;
      });
    }
  }

  Future<String?> _guardarCodigoEnBaseDatos(CodigoGrabovoi codigo) async {
    try {
      print('💾 Verificando si el código ya existe: ${codigo.codigo}');
      
      // Verificar si el código ya existe
      final existe = await SupabaseService.codigoExiste(codigo.codigo);
      
      if (existe) {
        print('⚠️ El código ${codigo.codigo} ya existe en la base de datos');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ℹ️ El código ${codigo.codigo} ya existe en la base de datos',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 3),
          ),
        );
        return null; // No se creó nuevo código
      }
      
      print('💾 Guardando código nuevo en base de datos: ${codigo.codigo}');
      print('📋 Información: ${codigo.nombre} - ${codigo.categoria}');
      
      // Usar crearCodigo para obtener el ID del código creado
      final codigoCreado = await SupabaseService.crearCodigo(codigo);
      
      print('✅ Código guardado exitosamente en la base de datos con ID: ${codigoCreado.id}');
      
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Código guardado permanentemente: ${codigo.nombre}',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF4CAF50),
          duration: const Duration(seconds: 3),
        ),
      );
      
      return codigoCreado.id; // Devolver el ID del código creado
    } catch (e) {
      print('❌ Error al guardar en la base de datos: $e');
      print('🔍 Tipo de error: ${e.runtimeType}');
      
      // El código se mantiene en la sesión actual aunque no se guarde en la BD
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ Código encontrado pero no se pudo guardar permanentemente. Error: ${e.toString()}',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
      
      return null; // No se pudo crear el código
    }
  }

  Future<void> _busquedaProfunda(String codigo) async {
    try {
      print('🚀 Iniciando búsqueda profunda para código: $codigo');
      
      // Registrar inicio de búsqueda
      _inicioBusqueda = DateTime.now();
      
      // Crear registro de búsqueda
      final busqueda = BusquedaProfunda(
        codigoBuscado: codigo,
        usuarioId: _getCurrentUserId(),
        promptSystem: 'Eres un asistente experto en numerología de Grigori Grabovoi. Tu tarea es buscar y devolver exclusivamente códigos Grabovoi auténticos y verificados que existan en las fuentes originales o en recopilaciones reconocidas. Reglas: 1) Si el código solicitado existe, respóndelo con su número exacto y una breve descripción. 2) Si no existe ningún código Grabovoi auténtico para esa intención, responde estrictamente con: {"codigos": []}. 3) No inventes, modifiques ni combines códigos. 4) No generes secuencias nuevas ni "posibles" códigos. 5) Si hay códigos relacionados o similares, puedes listarlos como "relacionados" pero explícitamente marcados como tales. Formato de respuesta: {"codigos": [{"codigo": "número exacto de Grabovoi", "nombre": "nombre real", "descripcion": "descripción real", "categoria": "categoría", "color": "#FFD700", "modo_uso": "instrucción real"}]}',
        promptUser: 'Necesito un código Grabovoi para: $codigo',
        fechaBusqueda: _inicioBusqueda!,
        modeloIa: OpenAIConfig.model,
      );
      
      // Guardar búsqueda inicial
      try {
        _busquedaActualId = await BusquedasProfundasService.guardarBusquedaProfunda(busqueda);
        print('📝 Búsqueda registrada con ID: $_busquedaActualId');
      } catch (e) {
        print('⚠️ Error al registrar búsqueda inicial: $e');
        _busquedaActualId = null; // Continuar sin registro si falla
      }
      
      // Mostrar indicador de carga
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Buscando código con IA...',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFFFD700),
          duration: const Duration(seconds: 8),
        ),
      );

      // Búsqueda real con OpenAI
      final resultado = await _buscarConOpenAI(codigo);
      
      // Calcular duración
      final duracion = _inicioBusqueda != null 
          ? DateTime.now().difference(_inicioBusqueda!).inMilliseconds 
          : 0;
      
      if (resultado != null) {
        print('✅ Código encontrado: ${resultado.nombre}');
        
        // Agregar a la base de datos
        bool codigoGuardado = false;
        String? codigoId = null;
        try {
          codigoId = await _guardarCodigoEnBaseDatos(resultado);
          codigoGuardado = codigoId != null;
        } catch (e) {
          print('⚠️ Error al guardar código: $e');
        }
        
              // Actualizar registro de búsqueda con resultado exitoso
              if (_busquedaActualId != null) {
                try {
                  final busquedaActualizada = busqueda.copyWith(
                    respuestaIa: '{"nombre": "${resultado.nombre}", "descripcion": "${resultado.descripcion}", "categoria": "${resultado.categoria}", "codigo_id": "$codigoId"}',
                    codigoEncontrado: true,
                    codigoGuardado: codigoGuardado,
                    duracionMs: duracion,
                    tokensUsados: _calcularTokensEstimados(codigo, resultado),
                    costoEstimado: _calcularCostoEstimado(codigo, resultado),
                  );

                  await BusquedasProfundasService.actualizarBusquedaProfunda(_busquedaActualId!, busquedaActualizada);
                  print('📝 Búsqueda actualizada con resultado exitoso - Código ID: $codigoId');
                } catch (e) {
                  print('⚠️ Error al actualizar búsqueda: $e');
                }
              }
        
        setState(() {
          _codigoSeleccionado = resultado.codigo; // Usar el código real de Grabovoi
          _categoriaActual = resultado.categoria;
          _colorVibracional = _getCategoryColor(_categoriaActual);
          _showOptionsModal = false;
          _searchController.clear();
          _mostrarResultados = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Código encontrado! ${resultado.nombre}'),
            backgroundColor: const Color(0xFF4CAF50),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        print('❌ Código no encontrado: $codigo');
        
        // Actualizar registro de búsqueda con resultado fallido
        if (_busquedaActualId != null) {
          final busquedaActualizada = busqueda.copyWith(
            respuestaIa: 'null',
            codigoEncontrado: false,
            codigoGuardado: false,
            duracionMs: duracion,
            errorMessage: 'No se encontró información sobre el código',
          );
          
          await BusquedasProfundasService.actualizarBusquedaProfunda(_busquedaActualId!, busquedaActualizada);
          print('📝 Búsqueda actualizada con resultado fallido');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se encontró información sobre el código $codigo'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error en búsqueda profunda: $e');
      
      // Actualizar registro de búsqueda con error
      if (_busquedaActualId != null) {
        final duracion = _inicioBusqueda != null 
            ? DateTime.now().difference(_inicioBusqueda!).inMilliseconds 
            : 0;
            
        final busquedaActualizada = BusquedaProfunda(
          codigoBuscado: codigo,
          usuarioId: _getCurrentUserId(),
          promptSystem: 'Error en búsqueda',
          promptUser: 'Error en búsqueda',
          fechaBusqueda: _inicioBusqueda ?? DateTime.now(),
          codigoEncontrado: false,
          codigoGuardado: false,
          errorMessage: e.toString(),
          duracionMs: duracion,
        );
        
        await BusquedasProfundasService.actualizarBusquedaProfunda(_busquedaActualId!, busquedaActualizada);
        print('📝 Búsqueda actualizada con error');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error en la búsqueda profunda: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      // Limpiar variables de control
      _busquedaActualId = null;
      _inicioBusqueda = null;
    }
  }

  Future<CodigoGrabovoi?> _buscarConOpenAI(String codigo) async {
    try {
      print('🔍 Buscando código $codigo con OpenAI...');
      
      // PRIMERO: Buscar con OpenAI (prioridad)
      final response = await http.post(
        Uri.parse(OpenAIConfig.baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${OpenAIConfig.apiKey}',
        },
        body: jsonEncode({
          'model': OpenAIConfig.model,
          'messages': [
            {
              'role': 'system',
              'content': 'Eres un asistente experto en numerología de Grigori Grabovoi. Tu tarea es buscar y devolver exclusivamente códigos Grabovoi auténticos y verificados que existan en las fuentes originales o en recopilaciones reconocidas. Reglas: 1) Si el código solicitado existe, respóndelo con su número exacto y una breve descripción. 2) Si no existe ningún código Grabovoi auténtico para esa intención, responde estrictamente con: {"codigos": []}. 3) No inventes, modifiques ni combines códigos. 4) No generes secuencias nuevas ni "posibles" códigos. 5) Si hay códigos relacionados o similares, puedes listarlos como "relacionados" pero explícitamente marcados como tales. 6) SIEMPRE devuelve MÚLTIPLES códigos cuando sea posible (2-4 códigos) para que el usuario pueda elegir. Formato de respuesta: {"codigos": [{"codigo": "número exacto de Grabovoi", "nombre": "nombre real", "descripcion": "descripción real", "categoria": "categoría", "color": "#FFD700", "modo_uso": "instrucción real"}]}'
            },
            {
              'role': 'user',
              'content': 'Necesito un código Grabovoi para: $codigo'
            }
          ],
          'max_tokens': OpenAIConfig.maxTokens,
          'temperature': OpenAIConfig.temperature,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        print('🤖 Respuesta de OpenAI: $content');
        
        if (content != 'null' && content.isNotEmpty && content.toLowerCase() != 'null') {
          try {
            // Limpiar y reparar JSON si es necesario
            String cleanedContent = content.trim();
            
            // Intentar reparar JSON malformado
            if (!cleanedContent.endsWith('}') && !cleanedContent.endsWith(']')) {
              print('🔧 Intentando reparar JSON malformado...');
              
              // Buscar el último objeto completo
              int lastCompleteObject = cleanedContent.lastIndexOf('}');
              if (lastCompleteObject > 0) {
                // Encontrar el inicio del array de códigos
                int arrayStart = cleanedContent.indexOf('"codigos": [');
                if (arrayStart > 0) {
                  // Extraer solo la parte válida del JSON
                  String validPart = cleanedContent.substring(0, lastCompleteObject + 1);
                  
                  // Cerrar el array y el objeto principal
                  if (validPart.contains('"codigos": [') && !validPart.contains(']')) {
                    validPart = validPart + ']}';
                  }
                  
                  cleanedContent = validPart;
                  print('🔧 JSON reparado: ${cleanedContent.length} caracteres');
                }
              }
            }
            
            final responseData = jsonDecode(cleanedContent);
            print('✅ Respuesta de OpenAI recibida: $responseData');
            
            // Verificar si hay códigos en la respuesta
            if (responseData['codigos'] != null && responseData['codigos'] is List) {
              final codigosList = responseData['codigos'] as List;
              print('🔍 Códigos encontrados: ${codigosList.length}');
              
              // Convertir cada código a CodigoGrabovoi
              final codigosEncontrados = <CodigoGrabovoi>[];
              final codigosInventados = ['1234567', '123456789', '1485421', '123456', '654321', '111111', '222222', '333333', '444444', '555555', '666666', '777777', '888888', '999999', '000000'];
              
              // Códigos reales de Grabovoi para uñas (de la imagen)
              final codigosRealesUnas = ['817254719', '89147198', '548714218', '1489999', '51961431961', '519614', '31961'];
              
              for (var codigoData in codigosList) {
                // Validar que el código tenga los campos necesarios
                if (codigoData['codigo'] != null && codigoData['codigo'].toString().isNotEmpty) {
                  final codigoNumero = codigoData['codigo'].toString().replaceAll(' ', '');
                  
                  // REJECTAR códigos inventados
                  if (codigosInventados.contains(codigoNumero)) {
                    print('❌ CÓDIGO INVENTADO RECHAZADO: $codigoNumero');
                    continue;
                  }
                  
                  // Permitir códigos reales de uñas
                  if (codigosRealesUnas.contains(codigoNumero)) {
                    print('✅ CÓDIGO REAL DE UÑAS ACEPTADO: $codigoNumero');
                  }
                  
                  // Rechazar códigos con patrones obviamente inventados (excepto códigos reales)
                  if (!codigosRealesUnas.contains(codigoNumero) && 
                      (codigoNumero.length < 3 || 
                       codigoNumero == codigoNumero[0] * codigoNumero.length || // 111, 222, etc.
                       codigoNumero.contains('123456') ||
                       codigoNumero.contains('654321'))) {
                    print('❌ CÓDIGO CON PATRÓN INVENTADO RECHAZADO: $codigoNumero');
                    continue;
                  }
                  
                  final categoria = codigoData['categoria'] ?? 'Abundancia';
                  codigosEncontrados.add(CodigoGrabovoi(
                    id: DateTime.now().millisecondsSinceEpoch.toString() + '_${codigosEncontrados.length}',
                    codigo: codigoNumero,
                    nombre: codigoData['nombre']?.toString() ?? 'Código encontrado por IA',
                    descripcion: codigoData['descripcion']?.toString() ?? 'Código encontrado mediante búsqueda profunda con IA',
                    categoria: categoria,
                    color: codigoData['color']?.toString() ?? _getCategoryColor(categoria).value.toRadixString(16).substring(2).toUpperCase(),
                  ));
                }
              }
              
              if (codigosEncontrados.isNotEmpty) {
                print('✅ Códigos válidos procesados: ${codigosEncontrados.length}');
                
                // Mostrar selección de códigos
                setState(() {
                  _codigosEncontrados = codigosEncontrados;
                  _mostrarSeleccionCodigos = true;
                  _showOptionsModal = false;
                });
                
                return null; // No devolver código individual, mostrar selección
              } else {
                print('❌ No se encontraron códigos válidos en la respuesta');
              }
            } else {
              print('❌ Formato de respuesta inesperado: $responseData');
            }
          } catch (e) {
            print('❌ Error parseando respuesta de OpenAI: $e');
            print('📄 Contenido recibido: $content');
            print('📄 Longitud del contenido: ${content.length} caracteres');
            
            // Intentar extraer códigos manualmente del texto
            _extraerCodigosDelTexto(content);
          }
        }
      } else {
        print('❌ Error en respuesta de OpenAI: ${response.statusCode}');
        print('📄 Respuesta: ${response.body}');
      }
      
      // SEGUNDO: Si OpenAI no encuentra, buscar en base local (respaldo)
      print('🔄 OpenAI no encontró el código, buscando en base local...');
      final codigoConocido = _buscarCodigoConocido(codigo);
      if (codigoConocido != null) {
        print('✅ Código encontrado en base de datos local: $codigo');
        return codigoConocido;
      }
      
      print('❌ Código no encontrado ni en OpenAI ni en base local: $codigo');
      return null;
    } catch (e) {
      print('❌ Error en búsqueda con OpenAI: $e');
      
      // En caso de error, intentar búsqueda local como respaldo
      print('🔄 Error en OpenAI, buscando en base local como respaldo...');
      final codigoConocido = _buscarCodigoConocido(codigo);
      if (codigoConocido != null) {
        print('✅ Código encontrado en base de datos local (respaldo): $codigo');
        return codigoConocido;
      }
      
      return null;
    }
  }

  // Base de datos local de códigos conocidos
  CodigoGrabovoi? _buscarCodigoConocido(String codigo) {
    final codigosConocidos = {
      '520_741_8': CodigoGrabovoi(
        id: '520_741_8',
        codigo: '520_741_8',
        nombre: 'Manifestación Material',
        descripcion: 'Atracción de dinero inesperado o resolución económica rápida',
        categoria: 'Manifestacion',
        color: '#FF8C00',
      ),
      '741': CodigoGrabovoi(
        id: '741',
        codigo: '741',
        nombre: 'Solución Inmediata',
        descripcion: 'Para resolver problemas de manera rápida y efectiva',
        categoria: 'Manifestacion',
        color: '#FF8C00',
      ),
      '520': CodigoGrabovoi(
        id: '520',
        codigo: '520',
        nombre: 'Amor Universal',
        descripcion: 'Para atraer amor verdadero y relaciones armoniosas',
        categoria: 'Amor',
        color: '#FF69B4',
      ),
      '111': CodigoGrabovoi(
        id: '111',
        codigo: '111',
        nombre: 'Manifestación Pura',
        descripcion: 'Código para manifestación y creación consciente',
        categoria: 'Manifestacion',
        color: '#FF8C00',
      ),
      '888': CodigoGrabovoi(
        id: '888',
        codigo: '888',
        nombre: 'Abundancia Universal',
        descripcion: 'Para atraer abundancia en todas las áreas de la vida',
        categoria: 'Abundancia',
        color: '#FFD700',
      ),
      '333': CodigoGrabovoi(
        id: '333',
        codigo: '333',
        nombre: 'Sanación Divina',
        descripcion: 'Para sanación física, emocional y espiritual',
        categoria: 'Salud',
        color: '#32CD32',
      ),
      // Códigos reales de Grabovoi para ventas
      '842_319_361': CodigoGrabovoi(
        id: '842_319_361',
        codigo: '842_319_361',
        nombre: 'Venta Rápida de Propiedades',
        descripcion: 'Para vender una casa muy rápidamente',
        categoria: 'Abundancia',
        color: '#FFD700',
      ),
      '966_9247': CodigoGrabovoi(
        id: '966_9247',
        codigo: '966_9247',
        nombre: 'Venta Sin Obstáculos',
        descripcion: 'Para que un terreno, propiedad, casa, parcela se venda sin dificultades, bloqueos, obstáculos',
        categoria: 'Abundancia',
        color: '#FFD700',
      ),
      '709_724_160': CodigoGrabovoi(
        id: '709_724_160',
        codigo: '709_724_160',
        nombre: 'Venta a Precio Alto',
        descripcion: 'Para vender propiedad por un precio muy alto',
        categoria: 'Abundancia',
        color: '#FFD700',
      ),
      '366_8092': CodigoGrabovoi(
        id: '366_8092',
        codigo: '366_8092',
        nombre: 'Éxito en Bienes Raíces',
        descripcion: 'Para éxito en ventas de bienes raíces',
        categoria: 'Abundancia',
        color: '#FFD700',
      ),
      '194_0454': CodigoGrabovoi(
        id: '194_0454',
        codigo: '194_0454',
        nombre: 'Ventas Instantáneas',
        descripcion: 'Para ventas instantáneas e ingresos en el negocio de bienes raíces',
        categoria: 'Abundancia',
        color: '#FFD700',
      ),
    };

    return codigosConocidos[codigo];
  }

  void _iniciarPilotajeManual() {
    setState(() {
      _showManualPilotage = true;
      _showOptionsModal = false;
    });
  }

  // Función helper para obtener el usuario actual
  String? _getCurrentUserId() {
    try {
      return SupabaseConfig.client.auth.currentUser?.id;
    } catch (e) {
      print('⚠️ No se pudo obtener el ID del usuario actual: $e');
      return null;
    }
  }

  // Función helper para obtener la descripción del código desde la base de datos
  Future<String> _getCodigoDescription() async {
    if (_codigoSeleccionado.isEmpty) return 'Código sagrado para la manifestación y transformación energética.';
    
    try {
      final codigos = await SupabaseService.getCodigos();
      final codigoEncontrado = codigos.where((c) => c.codigo == _codigoSeleccionado).toList();
      if (codigoEncontrado.isNotEmpty) {
        return codigoEncontrado.first.descripcion.isNotEmpty 
            ? codigoEncontrado.first.descripcion 
            : 'Código sagrado para la manifestación y transformación energética.';
      }
    } catch (e) {
      print('Error al obtener descripción del código: $e');
    }
    
    // Descripción por defecto
    return 'Código sagrado para la manifestación y transformación energética.';
  }

  // Función helper para obtener el título del código desde la base de datos
  Future<String> _getCodigoTitulo() async {
    if (_codigoSeleccionado.isEmpty) return 'Campo Energético';
    
    try {
      final codigos = await SupabaseService.getCodigos();
      final codigoEncontrado = codigos.where((c) => c.codigo == _codigoSeleccionado).toList();
      if (codigoEncontrado.isNotEmpty) {
        return codigoEncontrado.first.nombre.isNotEmpty 
            ? codigoEncontrado.first.nombre
            : 'Campo Energético';
      }
    } catch (e) {
      print('Error al obtener título del código: $e');
    }
    
    return 'Campo Energético';
  }

  // Calcular tokens estimados (aproximación simple)
  int _calcularTokensEstimados(String codigo, CodigoGrabovoi resultado) {
    // Aproximación simple: 1 token ≈ 4 caracteres
    final promptLength = codigo.length + resultado.nombre.length + resultado.descripcion.length;
    return (promptLength / 4).round();
  }

  // Calcular costo estimado (aproximación basada en precios de GPT-3.5-turbo)
  double _calcularCostoEstimado(String codigo, CodigoGrabovoi resultado) {
    final tokens = _calcularTokensEstimados(codigo, resultado);
    // Precio aproximado de GPT-3.5-turbo: $0.0015 por 1K tokens
    return (tokens / 1000) * 0.0015;
  }

  Future<void> _guardarCodigoManual() async {
    if (_manualCodeController.text.isEmpty || _manualTitleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final codigoManual = CodigoGrabovoi(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        codigo: _manualCodeController.text,
        nombre: _manualTitleController.text,
        descripcion: 'Código personalizado del usuario',
        categoria: _manualCategory,
        color: _getCategoryColor(_manualCategory).value.toRadixString(16),
      );

      // TODO: Implementar guardado en tabla de favoritos del usuario
      
      setState(() {
        _codigoSeleccionado = codigoManual.codigo;
        _categoriaActual = codigoManual.categoria;
        _colorVibracional = _getCategoryColor(_categoriaActual);
        _showManualPilotage = false;
        _manualCodeController.clear();
        _manualTitleController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código guardado en favoritos'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getCategoryColor(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'salud':
        return const Color(0xFF4CAF50); // Verde esmeralda
      case 'amor':
        return const Color(0xFFFF6B6B); // Rojo coral
      case 'abundancia':
        return const Color(0xFFFFD700); // Dorado
      case 'reprogramación':
      case 'reprogramacion':
        return const Color(0xFF9C27B0); // Violeta
      case 'conciencia':
        return const Color(0xFF2196F3); // Azul
      case 'limpieza':
        return const Color(0xFF00BCD4); // Cian
      default:
        return const Color(0xFFFFD700); // Dorado por defecto
    }
  }


  @override
  void dispose() {
    _breathingController.dispose();
    _pulseController.dispose();
    _expansionController.dispose();
    _fadeController.dispose();
    _colorBarController.dispose();
    _searchController.dispose();
    _manualCodeController.dispose();
    _manualTitleController.dispose();
    _pilotageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B132B),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _colorVibracional),
              const SizedBox(height: 20),
              Text(
                'Preparando el Campo Cuántico...',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          GlowBackground(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado Dinámico
                  _buildDynamicHeader(),
                  const SizedBox(height: 30),
                  
                  // Controles de visualización FUERA del recuadro
                  _buildVisualizationControls(),
                  const SizedBox(height: 20),
                  
                  // Zona Central - Visualización del Código
                  _buildCodeVisualization(),
                  
                  
                           // Integraciones del Sistema
                           _buildSystemIntegrations(),
                           const SizedBox(height: 40),
                ],
              ),
            ),
          ),
                   // Sistema de Steps Secuenciales como Overlay Flotante
                   if (_showSequentialSteps) _buildSequentialStepCard(),
                   
                   // Modal de opciones cuando no se encuentra código
                   if (_showOptionsModal) _buildOptionsModal(),
                   
                   // Modal de selección de códigos encontrados por IA
                   if (_mostrarSeleccionCodigos) _buildSeleccionCodigosModal(),
                   
                   // Modal de pilotaje manual
                   if (_showManualPilotage) _buildManualPilotageModal(),
                   
                   // Reproductor de audio cuando se complete el pilotaje
                   if (_showAudioController) _buildAudioController(),
                 ],
               ),
             );
           }

  Widget _buildDynamicHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título principal
          Text(
            'Pilotaje Consciente Cuántico',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFD700),
              shadows: [
                Shadow(
                  color: const Color(0xFFFFD700).withOpacity(0.5),
                  blurRadius: 20,
                ),
              ],
            ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 8),
          
          // Descripción inspiradora
          Text(
            'Tu conciencia es la tecnología más avanzada del Universo.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white70,
            ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // Método para obtener el color seleccionado
  Color _getColorSeleccionado() {
    if (_colorSeleccionado == 'categoria') {
      return _colorVibracional;
    }
    return _coloresDisponibles[_colorSeleccionado] ?? const Color(0xFFFFD700);
  }

  // Método para construir el selector de colores
  Widget _buildColorSelector() {
    return AnimatedBuilder(
      animation: _colorBarAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: _colorBarAnimation.value,
          child: GestureDetector(
            onTap: _isColorBarExpanded ? null : _showColorBar,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: _getColorSeleccionado().withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isColorBarExpanded) ...[
                    Text(
                      'Color:',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ..._coloresDisponibles.entries.map((entry) {
                      final isSelected = _colorSeleccionado == entry.key;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _colorSeleccionado = entry.key;
                            if (entry.key == 'categoria') {
                              _coloresDisponibles['categoria'] = _colorVibracional;
                            }
                          });
                          _onColorChanged();
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: entry.value,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: entry.value.withOpacity(0.8),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ] : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ] else ...[
                    // Solo mostrar el círculo del color seleccionado
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getColorSeleccionado(),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getColorSeleccionado().withOpacity(0.8),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCodeVisualization() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            _colorVibracional.withOpacity(0.2),
            _colorVibracional.withOpacity(0.05),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _colorVibracional.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Selector de código
          _buildCodeSelector(),
          const SizedBox(height: 20),
          
          // Botón para iniciar pilotaje (centrado)
          Center(
            child: CustomButton(
              text: _isPilotageActive ? 'Detener Pilotaje' : 'Iniciar Pilotaje Cuántico',
              onPressed: _isPilotageActive ? _detenerPilotaje : _startQuantumPilotage,
              icon: _isPilotageActive ? Icons.stop : Icons.auto_awesome,
              color: _isPilotageActive ? Colors.red : _colorVibracional,
            ),
          ),
          const SizedBox(height: 20),
          
          // Visualización del código - SIN contenedor adicional
          Center(
            child: _buildCodeDisplay(),
          ),
          const SizedBox(height: 20),
          
          // Campo Energético - Solo cuando hay código seleccionado
          if (_codigoSeleccionado != null) ...[
            Center(
              child: FutureBuilder<Map<String, String>>(
                future: Future.wait([
                  _getCodigoTitulo(),
                  _getCodigoDescription(),
                ]).then((results) => {
                  'titulo': results[0],
                  'descripcion': results[1],
                }),
                builder: (context, snapshot) {
                  final titulo = snapshot.data?['titulo'] ?? 'Campo Energético';
                  final descripcion = snapshot.data?['descripcion'] ?? 'Código sagrado para la manifestación y transformación energética.';
                  
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _colorVibracional.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          titulo,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _colorVibracional,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          descripcion,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildCodeSelector() {
    return Column(
      children: [
        Text(
          'Código Cuántico Seleccionado',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),

        // Indicador de categoría movido aquí
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _colorVibracional.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _colorVibracional.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Text(
            'Categoría: $_categoriaActual',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: _colorVibracional,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Campo de búsqueda - Solo mostrar si no está reproduciéndose audio
        if (!_isAudioPlaying) ...[
          TextField(
            controller: _searchController,
            onChanged: (value) {
              _filtrarCodigos(value);
            },
            onSubmitted: (value) {
              _confirmarBusqueda();
            },
            decoration: InputDecoration(
              hintText: 'Escribe para buscar...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              suffixIcon: _queryBusqueda.isNotEmpty && _codigosFiltrados.isEmpty
                  ? IconButton(
                      icon: const Icon(Icons.search, color: Color(0xFFFFD700)),
                      onPressed: _confirmarBusqueda,
                      tooltip: 'Buscar código completo',
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _colorVibracional),
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
        const SizedBox(height: 12),
        
        // Mensaje cuando no hay resultados pero no se ha confirmado la búsqueda
        if (_mostrarResultados && _codigosFiltrados.isEmpty && _queryBusqueda.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No se encontraron resultados para "$_queryBusqueda". Presiona Enter o el botón de búsqueda para confirmar.',
                    style: GoogleFonts.inter(
                      color: Colors.orange,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // Dropdown con resultados filtrados
        if (_mostrarResultados && _codigosFiltrados.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _colorVibracional.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: DropdownButton<String>(
              value: _codigosFiltrados.any((codigo) => codigo.codigo == _codigoSeleccionado) 
                  ? _codigoSeleccionado 
                  : null,
              isExpanded: true,
              dropdownColor: const Color(0xFF1C2541),
              style: GoogleFonts.spaceMono(
                color: Colors.white,
                fontSize: 16,
              ),
              underline: const SizedBox(),
              hint: const Text('Selecciona un código...'),
              items: _codigosFiltrados.map((codigo) {
                return DropdownMenuItem<String>(
                  value: codigo.codigo,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(codigo.categoria),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${codigo.codigo} - ${codigo.nombre}',
                          style: GoogleFonts.spaceMono(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _codigoSeleccionado = value;
                    final codigo = _codigos.firstWhere((c) => c.codigo == value);
                    _categoriaActual = codigo.categoria;
                    _colorVibracional = _getCategoryColor(_categoriaActual);
                    _searchController.clear();
                    _mostrarResultados = false;
                  });
                }
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCodeDisplay() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _expansionAnimation]),
      builder: (context, child) {
        // Aplicar animaciones más intensas cuando el audio esté reproduciéndose
        final pulseScale = _isAudioPlaying ? 
          _pulseAnimation.value * 1.3 : 
          _pulseAnimation.value;
        
        if (_isSphereMode) {
          // Modo Esfera - Usando GoldenSphere como en repeticiones
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Esfera con números centrados usando Stack
              Stack(
                alignment: Alignment.center,
                children: [
                  // Esfera con animaciones - SIN contenedor adicional
                  Transform.scale(
                    scale: _isPilotageActive ? pulseScale : 1.0,
                    child: GoldenSphere(
                      size: 260,
                      color: _getColorSeleccionado(),
                      glowIntensity: _isPilotageActive ? 0.8 : 0.6,
                      isAnimated: true,
                    ),
                  ),
                  // Números centrados en la esfera
                  if (_codigoSeleccionado != null)
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isPilotageActive ? pulseScale : 1.0,
                          child: IlluminatedCodeText(
                            code: CodeFormatter.formatCodeForDisplay(_codigoSeleccionado),
                            fontSize: CodeFormatter.calculateFontSize(_codigoSeleccionado, baseSize: 32),
                            color: _getColorSeleccionado(),
                            letterSpacing: 4,
                            isAnimated: false,
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),
              // Selector de colores
              _buildColorSelector(),
            ],
          );
        } else {
          // Modo Luz - Visualización de luz
          return Container(
            width: 400,
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  _colorVibracional.withOpacity(0.3),
                  _colorVibracional.withOpacity(0.6),
                  _colorVibracional.withOpacity(0.3),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _colorVibracional.withOpacity(0.8),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: _colorVibracional.withOpacity(0.4),
                  blurRadius: 80,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: pulseScale,
                        child: IlluminatedCodeText(
                          code: _codigoSeleccionado,
                          fontSize: 36,
                          color: _colorVibracional,
                          letterSpacing: 6,
                          isAnimated: false,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 200,
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          _colorVibracional.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildSequentialStepCard() {
    final steps = [
      {
        'title': 'Preparación de la Conciencia',
        'description': 'Cierra los ojos, respira... conecta con la Norma.',
        'icon': Icons.self_improvement,
        'color': Colors.green,
      },
      {
        'title': 'Visualización Activa',
        'description': 'Visualiza el código dentro de una esfera luminosa.',
        'icon': Icons.visibility,
        'color': Colors.blue,
      },
      {
        'title': 'Emisión del Pensamiento Dirigido',
        'description': 'Enfoca tu intención y emítela al campo cuántico.',
        'icon': Icons.psychology,
        'color': Colors.purple,
      },
      {
        'title': 'Repetición Consciente',
        'description': 'Repite el código 3 veces sintiendo la vibración.',
        'icon': Icons.repeat,
        'color': Colors.orange,
      },
      {
        'title': 'Cierre Energético',
        'description': 'Agradece y sella la intención en el campo cuántico.',
        'icon': Icons.check_circle,
        'color': Colors.teal,
      },
    ];

    final currentStepData = steps[_currentStepIndex];
    final isCompleted = _stepCompleted[_currentStepIndex];

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5), // Fondo semi-transparente
        child: Center(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: -1.0, end: 0.0),
            curve: Curves.easeOutCubic,
            builder: (context, slideValue, child) {
              return Transform.translate(
                offset: Offset(slideValue * MediaQuery.of(context).size.width, 0),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: slideValue > -0.8 ? 1.0 : 0.0,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          currentStepData['color'] as Color,
                          (currentStepData['color'] as Color).withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (currentStepData['color'] as Color).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icono del paso
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            currentStepData['icon'] as IconData,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Título del paso
                        Text(
                          currentStepData['title'] as String,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Descripción del paso
                        Text(
                          currentStepData['description'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Botón de acción
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Indicador de progreso
                            Row(
                              children: List.generate(5, (index) {
                                return Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: index <= _currentStepIndex
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }),
                            ),
                            
                            // Botón de siguiente paso
                            GestureDetector(
                              onTap: _nextStep,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  _currentStepIndex < 4 ? Icons.play_arrow : Icons.check,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVisualizationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Modo Esfera
        GestureDetector(
          onTap: () {
            setState(() {
              _isSphereMode = true;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _isSphereMode ? _colorVibracional.withOpacity(0.3) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _colorVibracional.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.radio_button_checked,
                  color: _isSphereMode ? Colors.white : _colorVibracional,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Modo Esfera',
                  style: GoogleFonts.inter(
                    color: _isSphereMode ? Colors.white : _colorVibracional,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Modo Luz Directa
        GestureDetector(
          onTap: () {
            setState(() {
              _isSphereMode = false;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: !_isSphereMode ? _colorVibracional.withOpacity(0.3) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _colorVibracional.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.wb_sunny,
                  color: !_isSphereMode ? Colors.white : _colorVibracional,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Modo Luz',
                  style: GoogleFonts.inter(
                    color: !_isSphereMode ? Colors.white : _colorVibracional,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepByStepGuide() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Guía Paso a Paso del Pilotaje',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _colorVibracional,
            ),
          ),
          const SizedBox(height: 20),
          
          // Lista de pasos
          ...QuantumPilotageStep.values.map((step) => _buildStepCard(step)).toList(),
        ],
      ),
    );
  }

  Widget _buildStepCard(QuantumPilotageStep step) {
    final isActive = _currentStep == step;
    final isCompleted = step.index < _currentStep.index;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? _colorVibracional.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? _colorVibracional : Colors.white.withOpacity(0.2),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Ícono del paso
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted || isActive ? _colorVibracional : Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : step.icon,
              color: isCompleted || isActive ? Colors.white : Colors.white54,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          
          // Contenido del paso
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isActive ? _colorVibracional : Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemIntegrations() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _colorVibracional.withOpacity(0.1),
            _colorVibracional.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _colorVibracional.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Integraciones del Sistema',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _colorVibracional,
            ),
          ),
          const SizedBox(height: 16),
          
          // Campo de intención personal
          TextField(
            onChanged: (value) {
              setState(() {
                _intencionPersonal = value;
              });
            },
            style: GoogleFonts.inter(color: Colors.white),
            decoration: InputDecoration(
              hintText: '¿Qué deseas armonizar con este código?',
              hintStyle: GoogleFonts.inter(color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _colorVibracional.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _colorVibracional),
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          
          // Indicadores de progreso
          Row(
            children: [
              Expanded(
                child: _buildProgressIndicator(
                  'Nivel de Resonancia',
                  _nivelResonancia,
                  _colorVibracional,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProgressIndicator(
                  'Sesiones Completadas',
                  _repeticionesRealizadas / 10.0,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(String title, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.white.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        const SizedBox(height: 4),
        Text(
          '${(value * 100).toInt()}%',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBonusFeatures() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.withOpacity(0.1),
            Colors.purple.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Características Avanzadas',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 16),
          
          // Huella de Luz
          _buildBonusFeature(
            'Huella de Luz',
            'Energía acumulada: ${(_nivelResonancia * 100).toInt()} unidades',
            Icons.wb_sunny,
            Colors.yellow,
          ),
          
          const SizedBox(height: 12),
          
          // Compartir momento
          _buildBonusFeature(
            'Compartir Resonancia',
            'Genera una imagen de tu momento de resonancia',
            Icons.share,
            Colors.blue,
          ),
          
          const SizedBox(height: 12),
          
          // Desbloqueos
          _buildBonusFeature(
            'Visualizaciones Avanzadas',
            _nivelResonancia > 0.5 ? 'Desbloqueado' : 'Disponible en 50%',
            Icons.auto_awesome,
            _nivelResonancia > 0.5 ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildBonusFeature(String title, String description, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _startQuantumPilotage() {
    setState(() {
      _isPilotageActive = true;
      _showSequentialSteps = true;
      _currentStepIndex = 0;
      _stepCompleted = [false, false, false, false, false];
      _currentStep = QuantumPilotageStep.preparacion;
      _repeticionesRealizadas = 0;
      _nivelResonancia = 0.0;
    });
    
    // Ocultar la barra de colores después de 3 segundos
    _hideColorBarAfterDelay();
  }

  void _nextStep() {
    if (_currentStepIndex < 4) {
      // Animación de salida hacia la izquierda
      setState(() {
        _stepCompleted[_currentStepIndex] = true;
        _currentStepIndex++;
        _currentStep = QuantumPilotageStep.values[_currentStepIndex];
      });
    } else {
      // Completar el último paso y activar audio
      _iniciarPilotaje();
    }
  }

  void _iniciarPilotaje() {
    setState(() {
      _stepCompleted[_currentStepIndex] = true;
      _isPilotageActive = true;
      _showSequentialSteps = false;
      _nivelResonancia += 20.0; // Incrementar resonancia
      _isPilotageCompleted = true;
      _showAudioController = true;
      _isAudioPlaying = true;
      _pilotageDuration = 0;
    });

    // Iniciar temporizador de 2 minutos
    _pilotageTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _pilotageDuration++;
      });

      // Auto-detener después de 2 minutos (120 segundos)
      if (_pilotageDuration >= 120) {
        _detenerPilotaje();
      }
    });
  }

  void _detenerPilotaje() {
    _pilotageTimer?.cancel();
    
    setState(() {
      _isPilotageActive = false;
      _isAudioPlaying = false;
      _showAudioController = false;
      _isColorBarExpanded = true; // Restaurar la barra de colores
    });
    
    // Restaurar la posición de la barra de colores
    _colorBarController.reverse();

    // Mostrar mensaje de finalización
    _mostrarMensajeFinalizacion();
  }
  
  // Métodos para controlar la animación de la barra de colores
  void _hideColorBarAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (_isPilotageActive && mounted) {
        setState(() {
          _isColorBarExpanded = false;
        });
        _colorBarController.forward();
      }
    });
  }
  
  void _showColorBar() {
    setState(() {
      _isColorBarExpanded = true;
    });
    _colorBarController.reverse();
    
    // Ocultar la barra después de 3 segundos si el pilotaje está activo
    if (_isPilotageActive) {
      _hideColorBarAfterDelay();
    }
  }
  
  void _onColorChanged() {
    // Cuando se cambia el color, reiniciar el timer de ocultación
    if (_isPilotageActive) {
      _hideColorBarAfterDelay();
    }
  }

  void _mostrarMensajeFinalizacion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2541),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFFD700), width: 2),
        ),
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: const Color(0xFFFFD700),
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Pilotaje Completado',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¡Excelente trabajo! Has completado tu sesión de pilotaje cuántico.',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
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
                children: [
                  Text(
                    '💫 Es importante mantener la vibración',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFFD700),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Este es un avance significativo en tu proceso de manifestación. Lo ideal es realizar sesiones de 2:00 minutos para reforzar la vibración energética.',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          CustomButton(
            text: 'Continuar',
            onPressed: () {
              Navigator.of(context).pop();
            },
            color: const Color(0xFFFFD700),
          ),
        ],
      ),
    );
  }

  void _executePilotageSequence() async {
    // Paso 1: Preparación
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _currentStep = QuantumPilotageStep.visualizacion;
    });
    
    // Paso 2: Visualización
    await Future.delayed(const Duration(seconds: 3));
    setState(() {
      _currentStep = QuantumPilotageStep.emision;
    });
    
    // Paso 3: Emisión
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _currentStep = QuantumPilotageStep.repeticion;
    });
    
    // Paso 4: Repetición
    await Future.delayed(const Duration(seconds: 5));
    setState(() {
      _currentStep = QuantumPilotageStep.cierre;
      _repeticionesRealizadas += 3;
      _nivelResonancia += 0.1;
    });
    
    // Paso 5: Cierre
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isPilotageActive = false;
      _currentStep = QuantumPilotageStep.preparacion;
    });
    
    // Mostrar resultado
    _showPilotageResult();
  }

  void _showPilotageResult() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2541),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _colorVibracional.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                color: _colorVibracional,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Pilotaje Completado',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _colorVibracional,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'He restablecido la Norma. Gracias.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Nivel de Resonancia: ${(_nivelResonancia * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: _colorVibracional,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Continuar',
                onPressed: () => Navigator.of(context).pop(),
                icon: Icons.check,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsModal() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2541),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Código no encontrado',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No se encontró "$_codigoNoEncontrado" en la biblioteca',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '¿Qué deseas hacer?',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _busquedaProfunda(_codigoNoEncontrado),
                        icon: const Icon(Icons.psychology, color: Colors.white),
                        label: const Text('Búsqueda Profunda'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _iniciarPilotajeManual,
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text('Pilotaje Manual'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: const Color(0xFF0B132B),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showOptionsModal = false;
                      _searchController.clear();
                    });
                  },
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManualPilotageModal() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2541),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pilotaje Manual',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingresa tu código personalizado',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _manualCodeController,
                  decoration: InputDecoration(
                    labelText: 'Código',
                    hintText: 'Ej: 123_456_789',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFFD700)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _manualTitleController,
                  decoration: InputDecoration(
                    labelText: 'Título',
                    hintText: 'Ej: Mi código personalizado',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFFD700)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _manualCategory,
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFFD700)),
                    ),
                  ),
                  items: ['Abundancia', 'Salud', 'Amor', 'Reprogramación'].map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _manualCategory = value ?? 'Abundancia';
                    });
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _guardarCodigoManual,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: const Color(0xFF0B132B),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Guardar y Usar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _showManualPilotage = false;
                            _manualCodeController.clear();
                            _manualTitleController.clear();
                          });
                        },
                        child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeleccionCodigosModal() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2541),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFFD700).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título
              Text(
                'Códigos Encontrados',
                style: GoogleFonts.inter(
                  color: const Color(0xFFFFD700),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selecciona el código que mejor se adapte a tu necesidad:',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              
              // Lista de códigos
              Container(
                height: 400,
                child: ListView.builder(
                  itemCount: _codigosEncontrados.length,
                  itemBuilder: (context, index) {
                    final codigo = _codigosEncontrados[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _seleccionarCodigo(codigo),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C3E50).withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFFD700).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Código y nombre
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(codigo.categoria).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _getCategoryColor(codigo.categoria),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        codigo.codigo,
                                        style: GoogleFonts.inter(
                                          color: _getCategoryColor(codigo.categoria),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        codigo.nombre,
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                
                                // Descripción
                                Text(
                                  codigo.descripcion,
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                
                                // Categoría
                                Row(
                                  children: [
                                    Icon(
                                      Icons.category,
                                      color: _getCategoryColor(codigo.categoria),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      codigo.categoria,
                                      style: GoogleFonts.inter(
                                        color: _getCategoryColor(codigo.categoria),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Botón cancelar
              TextButton(
                onPressed: () {
                  setState(() {
                    _mostrarSeleccionCodigos = false;
                    _codigosEncontrados = [];
                  });
                },
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _extraerCodigosDelTexto(String content) {
    print('🔍 Intentando extraer códigos del texto...');
    
    try {
      // Buscar patrones de códigos en el texto
      RegExp codigoRegex = RegExp(r'"codigo":\s*"([^"]+)"');
      RegExp nombreRegex = RegExp(r'"nombre":\s*"([^"]+)"');
      RegExp descripcionRegex = RegExp(r'"descripcion":\s*"([^"]+)"');
      RegExp categoriaRegex = RegExp(r'"categoria":\s*"([^"]+)"');
      
      List<Match> codigoMatches = codigoRegex.allMatches(content).toList();
      List<Match> nombreMatches = nombreRegex.allMatches(content).toList();
      List<Match> descripcionMatches = descripcionRegex.allMatches(content).toList();
      List<Match> categoriaMatches = categoriaRegex.allMatches(content).toList();
      
      print('🔍 Códigos encontrados en texto: ${codigoMatches.length}');
      print('🔍 Nombres encontrados en texto: ${nombreMatches.length}');
      print('🔍 Descripciones encontradas en texto: ${descripcionMatches.length}');
      print('🔍 Categorías encontradas en texto: ${categoriaMatches.length}');
      
      if (codigoMatches.isNotEmpty) {
        final codigosEncontrados = <CodigoGrabovoi>[];
        
        for (int i = 0; i < codigoMatches.length; i++) {
          String codigo = codigoMatches[i].group(1) ?? '';
          String nombre = i < nombreMatches.length ? (nombreMatches[i].group(1) ?? 'Código encontrado por IA') : 'Código encontrado por IA';
          String descripcion = i < descripcionMatches.length ? (descripcionMatches[i].group(1) ?? 'Código encontrado mediante búsqueda profunda con IA') : 'Código encontrado mediante búsqueda profunda con IA';
          String categoria = i < categoriaMatches.length ? (categoriaMatches[i].group(1) ?? 'Abundancia') : 'Abundancia';
          
          if (codigo.isNotEmpty) {
            codigosEncontrados.add(CodigoGrabovoi(
              id: DateTime.now().millisecondsSinceEpoch.toString() + '_${i}',
              codigo: codigo,
              nombre: nombre,
              descripcion: descripcion,
              categoria: categoria,
              color: _getCategoryColor(categoria).value.toRadixString(16).substring(2).toUpperCase(),
            ));
          }
        }
        
        if (codigosEncontrados.isNotEmpty) {
          print('✅ Códigos extraídos del texto: ${codigosEncontrados.length}');
          
          setState(() {
            _codigosEncontrados = codigosEncontrados;
            _mostrarSeleccionCodigos = true;
            _showOptionsModal = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error extrayendo códigos del texto: $e');
    }
  }

  void _seleccionarCodigo(CodigoGrabovoi codigo) async {
    print('🎯 Código seleccionado: ${codigo.codigo} - ${codigo.nombre}');
    
    // Guardar en base de datos
    try {
      final codigoId = await _guardarCodigoEnBaseDatos(codigo);
      if (codigoId != null) {
        print('✅ Código guardado con ID: $codigoId');
      }
    } catch (e) {
      print('⚠️ Error al guardar código: $e');
    }
    
    // Actualizar estado
    setState(() {
      _codigoSeleccionado = codigo.codigo;
      _categoriaActual = codigo.categoria;
      _colorVibracional = _getCategoryColor(codigo.categoria);
      // Actualizar el color de categoría en el selector
      _coloresDisponibles['categoria'] = _colorVibracional;
      _mostrarSeleccionCodigos = false;
      _codigosEncontrados = [];
      _searchController.clear();
      _mostrarResultados = false;
    });
    
    // Mostrar mensaje de éxito
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Código seleccionado: ${codigo.nombre}'),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildAudioController() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C2541).withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador de tiempo de pilotaje
            if (_isPilotageActive) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer,
                    color: const Color(0xFFFFD700),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tiempo de pilotaje: ${_formatDuration(_pilotageDuration)}',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFFD700),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            StreamedMusicController(
              autoPlay: true,
              isActive: _isAudioPlaying,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

enum QuantumPilotageStep {
  preparacion,
  visualizacion,
  emision,
  repeticion,
  cierre,
}

extension QuantumPilotageStepExtension on QuantumPilotageStep {
  String get title {
    switch (this) {
      case QuantumPilotageStep.preparacion:
        return 'Preparación de la Conciencia';
      case QuantumPilotageStep.visualizacion:
        return 'Visualización Activa';
      case QuantumPilotageStep.emision:
        return 'Emisión del Pensamiento Dirigido';
      case QuantumPilotageStep.repeticion:
        return 'Repetición Consciente';
      case QuantumPilotageStep.cierre:
        return 'Cierre Energético';
    }
  }

  String get description {
    switch (this) {
      case QuantumPilotageStep.preparacion:
        return 'Cierra los ojos, respira... conecta con la Norma.';
      case QuantumPilotageStep.visualizacion:
        return 'Visualiza el código dentro de una esfera luminosa.';
      case QuantumPilotageStep.emision:
        return 'Enfoca tu intención y emítela al campo cuántico.';
      case QuantumPilotageStep.repeticion:
        return 'Repite el código 3 veces sintiendo la vibración.';
      case QuantumPilotageStep.cierre:
        return 'Visualiza la esfera elevándose y disolviéndose.';
    }
  }

  IconData get icon {
    switch (this) {
      case QuantumPilotageStep.preparacion:
        return Icons.self_improvement;
      case QuantumPilotageStep.visualizacion:
        return Icons.visibility;
      case QuantumPilotageStep.emision:
        return Icons.send;
      case QuantumPilotageStep.repeticion:
        return Icons.repeat;
      case QuantumPilotageStep.cierre:
        return Icons.check_circle;
    }
  }
}
