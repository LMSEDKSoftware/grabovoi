import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../config/env.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/golden_sphere.dart';
import '../../widgets/streamed_music_controller.dart';
import '../../widgets/illuminated_code_text.dart';
import '../../widgets/quantum_pilotage_modal.dart';
import '../../utils/code_formatter.dart';
import '../../services/supabase_service.dart';
import '../../models/supabase_models.dart';
import '../../repositories/codigos_repository.dart';
import '../../config/supabase_config.dart';
import '../../models/busqueda_profunda_model.dart';
import '../../services/busquedas_profundas_service.dart';
import '../../services/audio_manager_service.dart';
import '../../services/sugerencias_codigos_service.dart';
import '../../services/pilotage_state_service.dart';
import '../../models/sugerencia_codigo_model.dart';

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
  List<bool> _stepCompleted = [false, false, false, false, false, false];
  
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
  
  // Modo de concentración (pantalla completa)
  bool _isConcentrationMode = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCodigos();
    _loadFavoritos();
    
    if (widget.codigoInicial != null) {
      _codigoSeleccionado = widget.codigoInicial!;
    }
    
    // El modal de pilotaje cuántico se mostrará cuando el usuario navegue a esta pantalla
  }
  
  // Método público para mostrar el modal cuando el usuario navega a esta pantalla
  void showQuantumPilotageModal() {
    _checkQuantumPilotageModal();
  }

  // Método para mostrar información sobre Pilotaje Cuántico
  void _showQuantumPilotageInfo() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const QuantumPilotageModal(),
    );
  }

  Future<void> _checkQuantumPilotageModal() async {
    final prefs = await SharedPreferences.getInstance();
    final quantumModalShown = prefs.getBool('quantum_pilotage_modal_shown') ?? false;

    // Verifica que no se haya mostrado antes y que el widget esté montado
    if (!quantumModalShown && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const QuantumPilotageModal(),
        );
        prefs.setBool('quantum_pilotage_modal_shown', true);
      });
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
      final codigos = CodigosRepository().codigos;
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
        promptSystem: 'Eres un asistente experto en códigos de Grigori Grabovoi. Tu tarea es ayudar a encontrar códigos reales y verificados.\n\nIMPORTANTE: Solo puedes sugerir códigos que realmente existan en las fuentes oficiales de Grabovoi. NO inventes códigos nuevos.\n\nSi el usuario busca algo específico y no existe un código exacto, sugiere códigos relacionados REALES del tema más cercano.\n\nPara búsquedas de relaciones familiares (como hermanos), sugiere códigos reales como:\n- 519_7148_21 — Armonía familiar\n- 619_734_218 — Armonización de relaciones\n- 814_418_719 — Comprensión y perdón\n- 714_319 — Amor y relaciones\n\nIMPORTANTE: Usa guiones bajos (_) en lugar de espacios en los códigos.\n\nResponde SOLO con el formato de lista numerada, sin explicaciones adicionales.',
        promptUser: 'Necesito un código Grabovoi para: $codigo',
        fechaBusqueda: _inicioBusqueda!,
        modeloIa: 'gpt-3.5-turbo',
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
        
        // Si el código ya existe, considerarlo como "guardado" exitosamente
        if (codigoId == null) {
          // Verificar si el código ya existe en la base de datos
          final existe = await SupabaseService.codigoExiste(resultado.codigo);
          if (existe) {
            print('ℹ️ El código ya existe en la base de datos, considerando como guardado');
            codigoGuardado = true;
          }
        }
        
              // Actualizar registro de búsqueda con resultado exitoso
              if (_busquedaActualId != null) {
                try {
                  final busquedaActualizada = busqueda.copyWith(
                    respuestaIa: '{"nombre": "${resultado.nombre}", "descripcion": "${resultado.descripcion}", "categoria": "${resultado.categoria}", "codigo_id": "$codigoId"}',
                    codigoEncontrado: true,
                    codigoGuardado: codigoGuardado,
                    duracionMs: duracion,
                    tokensUsados: _tokensUsadosOpenAI,
                    costoEstimado: _costoEstimadoOpenAI,
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
            tokensUsados: _tokensUsadosOpenAI,
            costoEstimado: _costoEstimadoOpenAI,
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

  // Variables para almacenar métricas de OpenAI
  int _tokensUsadosOpenAI = 0;
  double _costoEstimadoOpenAI = 0.0;

  Future<CodigoGrabovoi?> _buscarConOpenAI(String codigo) async {
    try {
      print('🔍 Buscando código $codigo con OpenAI...');
      
      // PRIMERO: Buscar con OpenAI (prioridad)
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Env.openAiKey}',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'Eres un asistente experto en códigos de Grigori Grabovoi. Tu tarea es ayudar a encontrar códigos reales y verificados.\n\nIMPORTANTE: Solo puedes sugerir códigos que realmente existan en las fuentes oficiales de Grabovoi. NO inventes códigos nuevos.\n\nSi el usuario busca algo específico y no existe un código exacto, sugiere códigos relacionados REALES del tema más cercano.\n\nPara búsquedas de relaciones familiares (como hermanos), sugiere códigos reales como:\n- 519_7148_21 — Armonía familiar\n- 619_734_218 — Armonización de relaciones\n- 814_418_719 — Comprensión y perdón\n- 714_319 — Amor y relaciones\n\nIMPORTANTE: Usa guiones bajos (_) en lugar de espacios en los códigos.\n\nResponde SOLO con el formato de lista numerada, sin explicaciones adicionales.'
            },
            {
              'role': 'user',
              'content': 'Necesito un código Grabovoi para: $codigo'
            }
          ],
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        // Extraer métricas de uso de OpenAI
        if (data['usage'] != null) {
          final usage = data['usage'];
          _tokensUsadosOpenAI = (usage['total_tokens'] ?? 0) as int;
          
          // Calcular costo estimado (GPT-3.5-turbo: $0.0015 por 1K prompt tokens, $0.002 por 1K completion tokens)
          final promptTokens = usage['prompt_tokens'] ?? 0;
          final completionTokens = usage['completion_tokens'] ?? 0;
          _costoEstimadoOpenAI = ((promptTokens / 1000) * 0.0015) + ((completionTokens / 1000) * 0.002);
          
          print('📊 Métricas de OpenAI:');
          print('   Tokens totales: $_tokensUsadosOpenAI');
          print('   Tokens prompt: $promptTokens');
          print('   Tokens completion: $completionTokens');
          print('   Costo estimado: \$${_costoEstimadoOpenAI.toStringAsFixed(4)}');
        }
        
        print('🤖 Respuesta de OpenAI: $content');
        
        if (content != 'null' && content.isNotEmpty && content.toLowerCase() != 'null') {
          try {
            String cleanedContent = content.trim();
            
            // Verificar si es formato de lista numerada (nuevo formato)
            if (cleanedContent.contains('1.') && cleanedContent.contains('—')) {
              print('📋 Detectado formato de lista numerada');
              final codigosEncontrados = await _parsearListaNumerada(cleanedContent);
              
              if (codigosEncontrados.isNotEmpty) {
                print('✅ Códigos extraídos de lista: ${codigosEncontrados.length}');
                
                // Mostrar selección de códigos
                setState(() {
                  _codigosEncontrados = codigosEncontrados;
                  _mostrarSeleccionCodigos = true;
                  _showOptionsModal = false;
                });
                
                return null; // No devolver código individual, mostrar selección
              } else {
                print('❌ No se pudieron extraer códigos de la lista');
                _mostrarMensajeNoEncontrado();
              }
              return null;
            }
            
            // Intentar parsear como JSON (formato anterior)
            // Limpiar y reparar JSON si es necesario
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
              
              for (var codigoData in codigosList) {
                // Validar que el código tenga los campos necesarios
                if (codigoData['codigo'] != null && codigoData['codigo'].toString().isNotEmpty) {
                  final codigoNumero = codigoData['codigo'].toString().replaceAll(' ', '');
                  
                  // VALIDAR que el código existe en la base de datos real
                  final codigoExiste = await _validarCodigoEnBaseDatos(codigoNumero);
                  if (!codigoExiste) {
                    print('❌ CÓDIGO INVENTADO RECHAZADO: $codigoNumero - No existe en la base de datos');
                    continue;
                  }
                  
                  print('✅ CÓDIGO VÁLIDO CONFIRMADO: $codigoNumero');
                  
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
                // Mostrar mensaje de que no se encontraron códigos válidos
                _mostrarMensajeNoEncontrado();
              }
            } else {
              print('❌ Formato de respuesta inesperado: $responseData');
            }
          } catch (e) {
            print('❌ Error parseando respuesta de OpenAI: $e');
            print('📄 Contenido recibido: $content');
            print('📄 Longitud del contenido: ${content.length} caracteres');
            
            // Intentar extraer códigos manualmente del texto
            await _extraerCodigosDelTexto(content);
            return null;
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

  // Parsear lista numerada de códigos
  Future<List<CodigoGrabovoi>> _parsearListaNumerada(String contenido) async {
    final codigosEncontrados = <CodigoGrabovoi>[];
    
    try {
      // Dividir por líneas y procesar cada una
      final lineas = contenido.split('\n');
      
      for (String linea in lineas) {
        linea = linea.trim();
        
        // Buscar patrón: "1. 91919481891 - Sanación de animales" o "1. 519_7148_21 — Armonía familiar"
        final regex = RegExp(r'^\d+\.\s+([0-9_\s]+)\s*[-—]\s*(.+)$');
        final match = regex.firstMatch(linea);
        
        if (match != null) {
          final codigoConEspacios = match.group(1)!.trim();
          final codigoConGuiones = codigoConEspacios.replaceAll(' ', '_');
          final nombre = match.group(2)!.trim();
          
          print('🔍 Procesando línea: $linea');
          print('📋 Código con espacios: $codigoConEspacios');
          print('📋 Código con guiones: $codigoConGuiones');
          print('📋 Nombre extraído: $nombre');
          
          // Validar código con lógica de sugerencias
          final validacion = await _validarCodigoConSugerencia(
            codigoConGuiones, 
            nombre, 
            'Código sugerido para relaciones familiares'
          );
          
          if (validacion['existe'] == true) {
            if (validacion['necesitaSugerencia'] == true) {
              print('⚠️ Código existe pero con tema diferente - Creando sugerencia');
              
              // Crear sugerencia
              await _crearSugerencia(
                validacion['codigoExistente'] as CodigoGrabovoi,
                validacion['temaSugerido'] as String,
                validacion['descripcionSugerida'] as String,
              );
              
              // Mostrar el código existente pero con indicación de sugerencia
              codigosEncontrados.add(CodigoGrabovoi(
                id: DateTime.now().millisecondsSinceEpoch.toString() + '_${codigosEncontrados.length}',
                codigo: codigoConGuiones,
                nombre: nombre,
                descripcion: 'Código sugerido para relaciones familiares (sugerencia creada)',
                categoria: 'Relaciones familiares',
                color: '#FFD700',
              ));
            } else {
              print('✅ Código válido confirmado: $codigoConGuiones');
              
              codigosEncontrados.add(CodigoGrabovoi(
                id: DateTime.now().millisecondsSinceEpoch.toString() + '_${codigosEncontrados.length}',
                codigo: codigoConGuiones,
                nombre: nombre,
                descripcion: 'Código sugerido para relaciones familiares',
                categoria: 'Relaciones familiares',
                color: '#FFD700',
              ));
            }
          } else {
            // CASO 3: Código NO existe - Agregarlo como opción nueva para el usuario
            print('⚠️ Código NO existe en BD - Agregando como opción para el usuario: $codigoConGuiones');
            
            // Determinar la categoría correcta
            final categoria = _determinarCategoria(nombre);
            
            codigosEncontrados.add(CodigoGrabovoi(
              id: DateTime.now().millisecondsSinceEpoch.toString() + '_${codigosEncontrados.length}',
              codigo: codigoConGuiones,
              nombre: nombre,
              descripcion: nombre, // Usar el nombre como descripción
              categoria: categoria, // Categoría determinada inteligentemente
              color: '#32CD32', // Verde para indicar que es nuevo
            ));
          }
        }
      }
      
      print('📊 Total de códigos válidos extraídos: ${codigosEncontrados.length}');
      return codigosEncontrados;
    } catch (e) {
      print('❌ Error parseando lista numerada: $e');
      return [];
    }
  }

  // Mostrar mensaje cuando no se encuentran códigos válidos
  void _mostrarMensajeNoEncontrado() {
    setState(() {
      _showOptionsModal = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'No se encontraron códigos válidos para tu búsqueda. '
          'Dado que no existe uno "oficial" para tu consulta específica, '
          'puedes utilizar códigos de relaciones generales como:\n'
          '• 619 734 218 — Armonización de relaciones\n'
          '• 814 418 719 — Comprensión y perdón\n'
          '• 714 319 — Amor y relaciones',
          style: TextStyle(fontSize: 14),
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 8),
        action: SnackBarAction(
          label: 'Entendido',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Validar si un código existe en la base de datos real
  Future<bool> _validarCodigoEnBaseDatos(String codigo) async {
    try {
      // Buscar en la lista de códigos cargados
      final codigoExiste = _codigos.any((c) => c.codigo == codigo);
      if (codigoExiste) {
        print('✅ Código $codigo encontrado en la base de datos local');
        return true;
      }
      
      // Si no está en local, buscar en Supabase
      final response = await SupabaseService.client
          .from('codigos_grabovoi')
          .select('codigo')
          .eq('codigo', codigo)
          .limit(1);
      
      final existe = response.isNotEmpty;
      print('${existe ? "✅" : "❌"} Código $codigo ${existe ? "existe" : "NO existe"} en Supabase');
      return existe;
    } catch (e) {
      print('❌ Error validando código $codigo: $e');
      return false; // En caso de error, rechazar el código
    }
  }

  // Validar código y detectar si necesita sugerencia
  Future<Map<String, dynamic>> _validarCodigoConSugerencia(String codigo, String temaSugerido, String descripcionSugerida) async {
    try {
      print('🔍 Validando código con sugerencia: $codigo');
      
      // Verificar si el código existe
      final codigoExiste = await _validarCodigoEnBaseDatos(codigo);
      
      if (!codigoExiste) {
        print('❌ Código $codigo NO existe en la base de datos');
        return {
          'existe': false,
          'necesitaSugerencia': false,
          'codigoExistente': null,
        };
      }
      
      // Obtener información del código existente
      final codigoExistente = await SupabaseService.getCodigoExistente(codigo);
      
      if (codigoExistente == null) {
        print('❌ No se pudo obtener información del código existente');
        return {
          'existe': true,
          'necesitaSugerencia': false,
          'codigoExistente': null,
        };
      }
      
      // Comparar temas
      final temaExistente = codigoExistente.nombre.toLowerCase();
      final temaNuevo = temaSugerido.toLowerCase();
      
      print('🔍 Comparando temas:');
      print('   Existente: "$temaExistente"');
      print('   Sugerido: "$temaNuevo"');
      
      // Verificar si los temas son diferentes
      final temasDiferentes = temaExistente != temaNuevo;
      
      if (temasDiferentes) {
        print('⚠️ Temas diferentes detectados - Creando sugerencia');
        return {
          'existe': true,
          'necesitaSugerencia': true,
          'codigoExistente': codigoExistente,
          'temaExistente': temaExistente,
          'temaSugerido': temaSugerido,
          'descripcionSugerida': descripcionSugerida,
        };
      } else {
        print('✅ Temas coinciden - No se necesita sugerencia');
        return {
          'existe': true,
          'necesitaSugerencia': false,
          'codigoExistente': codigoExistente,
        };
      }
    } catch (e) {
      print('❌ Error validando código con sugerencia: $e');
      return {
        'existe': false,
        'necesitaSugerencia': false,
        'codigoExistente': null,
      };
    }
  }


  // Crear sugerencia para código existente con tema diferente
  Future<void> _crearSugerencia(CodigoGrabovoi codigoExistente, String temaSugerido, String descripcionSugerida) async {
    try {
      print('💾 Creando sugerencia para código: ${codigoExistente.codigo}');
      
      // Verificar si ya existe una sugerencia similar (con control de duplicados)
      final existeSimilar = await SugerenciasCodigosService.existeSugerenciaSimilar(
        _busquedaActualId ?? 0,
        codigoExistente.codigo,
        temaSugerido,
        _getCurrentUserId(),
      );
      
      if (existeSimilar) {
        print('ℹ️ Ya existe una sugerencia similar para este código');
        return;
      }
      
      // Crear nueva sugerencia
      final sugerencia = SugerenciaCodigo(
        busquedaId: _busquedaActualId ?? 0,
        codigoExistente: codigoExistente.codigo,
        temaEnDb: codigoExistente.nombre,
        temaSugerido: temaSugerido,
        descripcionSugerida: descripcionSugerida,
        usuarioId: _getCurrentUserId(),
        fuente: 'IA',
        estado: 'pendiente',
        fechaSugerencia: DateTime.now(),
      );
      
      final sugerenciaId = await SugerenciasCodigosService.crearSugerencia(sugerencia);
      print('✅ Sugerencia creada con ID: $sugerenciaId');
      
      // Mostrar notificación al usuario
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✨ Se ha creado una sugerencia para el código ${codigoExistente.codigo}',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error creando sugerencia: $e');
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
      return CodigosRepository().getDescripcionByCode(_codigoSeleccionado);
    } catch (e) {
      print('Error al obtener descripción del código: $e');
      return 'Código sagrado para la manifestación y transformación energética.';
    }
  }

  // Función helper para obtener el título del código desde la base de datos
  Future<String> _getCodigoTitulo() async {
    if (_codigoSeleccionado.isEmpty) return 'Campo Energético';
    
    try {
      return CodigosRepository().getTituloByCode(_codigoSeleccionado);
    } catch (e) {
      print('Error al obtener título del código: $e');
      return 'Campo Energético';
    }
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

    // Modo de concentración (pantalla completa)
    if (_isConcentrationMode) {
      return _buildConcentrationMode();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          GlowBackground(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, _showAudioController ? 120 : 20),
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
                 
               ],
             ),
           );
         }

  Widget _buildDynamicHeader() {
    // Estructura estándar: el padding externo ya lo aplica el contenedor padre.
    return Column(
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
          ),
          const SizedBox(height: 8),
          
          // Descripción inspiradora
          Text(
            'Tu conciencia es la tecnología más avanzada del Universo.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          
          // Botón para mostrar información sobre Pilotaje Cuántico
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _showQuantumPilotageInfo();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0).withOpacity(0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  side: const BorderSide(color: Color(0xFF9C27B0), width: 1),
                ),
                elevation: 0,
              ),
              child: Text(
                '¿Qué es el Pilotaje Cuántico?',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
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
                    
                    const SizedBox(width: 16),
                    
                    // Botón de modo concentración
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isConcentrationMode = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getColorSeleccionado().withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _getColorSeleccionado().withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.fullscreen,
                          color: _getColorSeleccionado(),
                          size: 20,
                        ),
                      ),
                    ),
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
                    
                    const SizedBox(width: 16),
                    
                    // Botón de modo concentración (también en modo colapsado)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isConcentrationMode = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getColorSeleccionado().withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _getColorSeleccionado().withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.fullscreen,
                          color: _getColorSeleccionado(),
                          size: 20,
                        ),
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
              onPressed: _isPilotageActive ? _detenerPilotaje : (_codigoSeleccionado.isNotEmpty ? _startQuantumPilotage : null),
              icon: _isPilotageActive ? Icons.stop : Icons.auto_awesome,
              color: _isPilotageActive ? Colors.red : (_codigoSeleccionado.isNotEmpty ? _colorVibracional : Colors.grey),
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
                        // Reproductor de audio integrado
                        if (_showAudioController) ...[
                          const SizedBox(height: 16),
                          StreamedMusicController(
                            autoPlay: true,
                            isActive: true,
                          ),
                        ],
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

        // Indicador de categoría movido aquí - Solo mostrar si hay código seleccionado
        if (_codigoSeleccionado.isNotEmpty) ...[
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
        ],
        
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
            child: Text(
              'No se encontraron resultados para "$_queryBusqueda". Presiona Enter o el botón de búsqueda para confirmar.',
              style: GoogleFonts.inter(
                color: Colors.orange,
                fontSize: 14,
              ),
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
                    child: _buildAutoSizedCodeText(),
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

  // Método para construir el texto del código con tamaño automático en modo luz
  Widget _buildAutoSizedCodeText() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular el tamaño máximo disponible (ancho del contenedor menos padding)
        final maxWidth = constraints.maxWidth - 40; // 20px de padding a cada lado
        final maxFontSize = 50.0; // Tamaño máximo
        final minFontSize = 12.0; // Tamaño mínimo
        
        // Calcular el tamaño de fuente óptimo
        double fontSize = _calculateOptimalFontSize(
          _codigoSeleccionado,
          maxWidth,
          maxFontSize,
          minFontSize,
        );
        
        return IlluminatedCodeText(
          code: _codigoSeleccionado,
          fontSize: fontSize,
          color: _colorVibracional,
          letterSpacing: 6,
          isAnimated: false,
        );
      },
    );
  }

  // Método para calcular el tamaño óptimo de fuente
  double _calculateOptimalFontSize(
    String text,
    double maxWidth,
    double maxFontSize,
    double minFontSize,
  ) {
    // Empezar con el tamaño máximo y reducir hasta que quepa
    double fontSize = maxFontSize;
    
    while (fontSize > minFontSize) {
      // Calcular el ancho aproximado del texto con el tamaño actual
      final textWidth = _estimateTextWidth(text, fontSize);
      
      if (textWidth <= maxWidth) {
        break; // El texto cabe, usar este tamaño
      }
      
      // Reducir el tamaño de fuente
      fontSize -= 2.0;
    }
    
    // Asegurar que no sea menor al mínimo
    return fontSize.clamp(minFontSize, maxFontSize);
  }

  // Método para estimar el ancho del texto
  double _estimateTextWidth(String text, double fontSize) {
    // Aproximación del ancho del texto basada en el número de caracteres y tamaño de fuente
    // Esto es una estimación, pero funciona bien para la mayoría de casos
    final charWidth = fontSize * 0.6; // Aproximación del ancho por carácter
    final letterSpacing = 6.0; // El letterSpacing usado
    final totalLetterSpacing = (text.length - 1) * letterSpacing;
    
    return (text.length * charWidth) + totalLetterSpacing;
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
      {
        'title': 'Intención Personal',
        'description': '¿Qué deseas armonizar con este código?',
        'icon': Icons.edit,
        'color': Colors.amber,
        'hasTextField': true,
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
                        
                        // Campo de texto para el paso de intención
                        if (currentStepData['hasTextField'] == true) ...[
                          TextField(
                            onChanged: (value) {
                              setState(() {
                                _intencionPersonal = value;
                              });
                            },
                            style: GoogleFonts.inter(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Escribe tu intención aquí...',
                              hintStyle: GoogleFonts.inter(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            maxLines: 3,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                        ],
                        
                        // Botón de acción
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Indicador de progreso
                            Row(
                              children: List.generate(6, (index) {
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
      _stepCompleted = [false, false, false, false, false, false];
      _currentStep = QuantumPilotageStep.preparacion;
      _repeticionesRealizadas = 0;
      _nivelResonancia = 0.0;
    });
    
    // Mantener la barra de colores siempre abierta
  }

  void _nextStep() {
    if (_currentStepIndex < 5) {
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

    // Notificar al servicio global
    PilotageStateService().setQuantumPilotageActive(true);

    // Iniciar temporizador de 2 minutos
    _pilotageTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _pilotageDuration++;
      });

      // Auto-detener después de 2 minutos (120 segundos)
      if (_pilotageDuration >= 120) {
        _completarPilotajeAutomatico();
      }
    });
  }

  void _detenerPilotaje() {
    // Mostrar diálogo de confirmación antes de detener
    _mostrarConfirmacionDetener();
  }

  void _mostrarConfirmacionDetener() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C2541),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFFFD700), width: 2),
          ),
          title: Row(
            children: [
              const Icon(Icons.music_off, color: Color(0xFFFFD700), size: 24),
              const SizedBox(width: 12),
              Text(
                'Detener Pilotaje',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de que deseas detener el pilotaje cuántico y la música?',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo sin hacer nada
              },
              child: Text(
                'Cancelar',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo
                _confirmarDetenerPilotaje(); // Proceder con la detención
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Sí, Detener',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmarDetenerPilotaje() {
    _pilotageTimer?.cancel();
    
    setState(() {
      _isPilotageActive = false;
      _isAudioPlaying = false;
      _showAudioController = false;
      _isColorBarExpanded = true; // Restaurar la barra de colores
    });
    
    // Notificar al servicio global
    PilotageStateService().setQuantumPilotageActive(false);
    
    // Detener el audio usando el AudioManagerService
    final audioManager = AudioManagerService();
    audioManager.stop();
    
    // Restaurar la posición de la barra de colores
    _colorBarController.reverse();

    // Mostrar mensaje de cancelación (no de finalización)
    _mostrarMensajeCancelacion();
  }

  void _completarPilotajeAutomatico() {
    _pilotageTimer?.cancel();
    
    setState(() {
      _isPilotageActive = false;
      _isAudioPlaying = false;
      _showAudioController = false;
      _isColorBarExpanded = true; // Restaurar la barra de colores
    });
    
    // Notificar al servicio global
    PilotageStateService().setQuantumPilotageActive(false);
    
    // Detener el audio usando el AudioManagerService
    final audioManager = AudioManagerService();
    audioManager.stop();
    
    // Restaurar la posición de la barra de colores
    _colorBarController.reverse();

    // Mostrar mensaje de finalización (completado exitosamente)
    _mostrarMensajeFinalizacion();
  }

  void _mostrarMensajeCancelacion() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2541),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
        ),
        title: Row(
          children: [
            Icon(
              Icons.pause_circle,
              color: const Color(0xFFFF6B6B),
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Pilotaje Cancelado',
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
              'Has cancelado la sesión de pilotaje cuántico.',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF6B6B).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '⚠️ Sesión interrumpida',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFF6B6B),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Para obtener mejores resultados, se recomienda completar la sesión completa de 2 minutos.',
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
            text: 'Entendido',
            onPressed: () {
              Navigator.of(context).pop();
            },
            color: const Color(0xFFFF6B6B),
          ),
        ],
      ),
    );
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
  }
  
  void _onColorChanged() {
    // Ya no ocultamos la barra automáticamente durante el pilotaje
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
        content: SingleChildScrollView(
          child: Column(
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
              const SizedBox(height: 20),
              // Sección de códigos sincrónicos
              _buildSincronicosSection(),
            ],
          ),
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

  Future<void> _extraerCodigosDelTexto(String content) async {
    print('🔍 Intentando extraer códigos del texto...');
    
    try {
      final codigosEncontrados = <CodigoGrabovoi>[];
      final lineas = content.split('\n');
      
      for (String linea in lineas) {
        linea = linea.trim();
        if (linea.isEmpty) continue;
        
        print('🔍 Procesando línea: $linea');
        
        // Buscar patrón numérico al inicio
        final match = RegExp(r'^\d+\.\s+(.+)$').firstMatch(linea);
        if (match == null) continue;
        
        final contenido = match.group(1)!.trim();
        
        // Buscar separador: guión normal o largo
        Match? codeMatch;
        
        // Intentar con guión normal: "codigo - nombre"
        codeMatch = RegExp(r'^([0-9_\s]+?)\s+-\s+(.+)$').firstMatch(contenido);
        if (codeMatch == null) {
          // Intentar con guión largo
          codeMatch = RegExp(r'^([0-9_\s]+?)\s+—\s+(.+)$').firstMatch(contenido);
        }
        if (codeMatch == null) {
          // Intentar sin espacios
          codeMatch = RegExp(r'^([0-9_\s]+?)\s*[-—]\s*(.+)$').firstMatch(contenido);
        }
        
        if (codeMatch != null) {
          var codigoStr = codeMatch.group(1)!.trim();
          final nombre = codeMatch.group(2)!.trim();
          
          // Convertir espacios a guiones bajos
          codigoStr = codigoStr.replaceAll(' ', '_').replaceAll('__', '_');
          
          print('📋 Código procesado: $codigoStr');
          print('📋 Nombre extraído: $nombre');
          
          // Verificar si el código existe en la base de datos
          final codigoExiste = await _validarCodigoEnBaseDatos(codigoStr);
          
          if (codigoExiste) {
            // CASO 1: Código existe en BD con tema diferente
            print('✅ Código existe en BD: $codigoStr');
            
            // Obtener información del código existente
            final codigoExistente = await SupabaseService.getCodigoExistente(codigoStr);
            
            if (codigoExistente != null) {
              // Comparar temas
              final temaExistente = codigoExistente.nombre.toLowerCase();
              final temaNuevo = nombre.toLowerCase();
              
              print('🔍 Comparando temas:');
              print('   Existente: "$temaExistente"');
              print('   Sugerido por IA: "$temaNuevo"');
              
              if (temaExistente != temaNuevo) {
                print('⚠️ Código existe pero con tema diferente - Agregando a sugerencias');
                
                // Agregar código con marcador de que es una sugerencia
                final categoria = _determinarCategoria(nombre);
                codigosEncontrados.add(CodigoGrabovoi(
                  id: DateTime.now().millisecondsSinceEpoch.toString() + '_${codigosEncontrados.length}',
                  codigo: codigoStr,
                  nombre: nombre,
                  descripcion: 'Código sugerido para $nombre (sugerencia creada)',
                  categoria: categoria,
                  color: '#FFD700',
                ));
              } else {
                // Temas coinciden, usar la categoría original de la base de datos
                codigosEncontrados.add(CodigoGrabovoi(
                  id: DateTime.now().millisecondsSinceEpoch.toString() + '_${codigosEncontrados.length}',
                  codigo: codigoStr,
                  nombre: nombre,
                  descripcion: 'Código encontrado en la base de datos',
                  categoria: codigoExistente.categoria, // Usar categoría original
                  color: '#FFD700',
                ));
              }
            }
          } else {
            // CASO 2: Código NO existe en BD - Agregarlo para que el usuario lo seleccione
            print('⚠️ Código NO existe en BD pero es válido de IA: $codigoStr');
            
            // Determinar la categoría correcta para el código
            final categoria = _determinarCategoria(nombre);
            
            codigosEncontrados.add(CodigoGrabovoi(
              id: DateTime.now().millisecondsSinceEpoch.toString() + '_${codigosEncontrados.length}',
              codigo: codigoStr,
              nombre: nombre,
              descripcion: nombre, // Usar el nombre como descripción
              categoria: categoria, // Categoría determinada inteligentemente
              color: '#32CD32', // Verde para indicar que es nuevo
            ));
          }
        }
      }
      
      print('📊 Total de códigos válidos extraídos: ${codigosEncontrados.length}');
      
      if (codigosEncontrados.isNotEmpty) {
        print('✅ Mostrando ${codigosEncontrados.length} códigos al usuario');
        setState(() {
          _codigosEncontrados = codigosEncontrados;
          _mostrarSeleccionCodigos = true;
          _showOptionsModal = false;
        });
      } else {
        print('❌ No se pudieron extraer códigos válidos');
        _mostrarMensajeNoEncontrado();
      }
    } catch (e) {
      print('❌ Error extrayendo códigos del texto: $e');
    }
  }

  // Determinar la categoría basándose en el tema del código
  String _determinarCategoria(String tema) {
    // Mapeo de palabras clave del tema a categorías existentes
    final temaLower = tema.toLowerCase();
    
    // Lista de categorías comunes en el sistema
    final categoriasExistentes = ['Sanación', 'Abundancia', 'Amor', 'Protección', 'Paz', 
                                  'Relaciones', 'Espiritualidad', 'Curación', 'Armonía', 
                                  'Prosperidad', 'Éxito', 'Vitalidad', 'Salud', 'Energía'];
    
    // Buscar coincidencias con las categorías existentes
    for (var categoria in categoriasExistentes) {
      final categoriaLower = categoria.toLowerCase();
      if (temaLower.contains(categoriaLower) || categoriaLower.contains(temaLower.split(' ').first)) {
        print('✅ Categoría encontrada: $categoria');
        return categoria;
      }
    }
    
    // Si no hay coincidencias, usar la primera palabra del tema como categoría
    final primeraPalabra = tema.split(' ').first;
    final categoriaNueva = primeraPalabra.isEmpty ? 'IA' : primeraPalabra[0].toUpperCase() + primeraPalabra.substring(1);
    
    print('🆕 Nueva categoría creada: $categoriaNueva');
    return categoriaNueva;
  }

  // Actualizar la lista de códigos después de guardar uno nuevo
  Future<void> _actualizarListaCodigos() async {
    try {
      print('🔄 Actualizando lista de códigos después del guardado...');
      
      // Recargar códigos desde Supabase
      final nuevosCodigos = await SupabaseService.getCodigos();
      if (nuevosCodigos.isNotEmpty) {
        setState(() {
          _codigos = nuevosCodigos;
        });
        print('✅ Lista de códigos actualizada: ${nuevosCodigos.length} códigos');
        
        // También actualizar el repositorio para que esté disponible en otras pantallas
        await CodigosRepository().refreshCodigos();
        print('✅ Repositorio de códigos actualizado');
      }
    } catch (e) {
      print('⚠️ Error al actualizar lista de códigos: $e');
    }
  }

  void _seleccionarCodigo(CodigoGrabovoi codigo) async {
    print('🎯 Código seleccionado: ${codigo.codigo} - ${codigo.nombre}');
    
    // Verificar si es un código nuevo o una sugerencia
    final codigoExiste = await _validarCodigoEnBaseDatos(codigo.codigo);
    
    if (!codigoExiste) {
      // CASO 2: Código NO existe - Agregarlo a la BD
      print('💾 Agregando código nuevo a la BD: ${codigo.codigo}');
      try {
        final codigoId = await _guardarCodigoEnBaseDatos(codigo);
        if (codigoId != null) {
          print('✅ Código nuevo guardado con ID: $codigoId');
          await _actualizarListaCodigos();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Código agregado y guardado: ${codigo.nombre}'),
              backgroundColor: const Color(0xFF4CAF50),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        print('⚠️ Error al guardar código nuevo: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar código: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      // CASO 1: Código EXISTE - Verificar si es una sugerencia
      print('🔍 Código existe en BD, verificando tema...');
      
      final codigoExistente = await SupabaseService.getCodigoExistente(codigo.codigo);
      if (codigoExistente != null) {
        final temaExistente = codigoExistente.nombre.toLowerCase();
        final temaNuevo = codigo.nombre.toLowerCase();
        
        if (temaExistente != temaNuevo) {
          // Crear sugerencia para aprobación
          print('⚠️ Creando sugerencia para código con tema diferente');
          
          try {
            await _crearSugerencia(codigoExistente, codigo.nombre, codigo.descripcion);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✨ Sugerencia creada para: ${codigo.nombre}'),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 3),
              ),
            );
          } catch (e) {
            print('⚠️ Error al crear sugerencia: $e');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Código seleccionado: ${codigo.nombre}'),
              backgroundColor: const Color(0xFF4CAF50),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
    
    // Actualizar estado
    setState(() {
      _codigoSeleccionado = codigo.codigo;
      _categoriaActual = codigo.categoria;
      _colorVibracional = _getCategoryColor(codigo.categoria);
      _coloresDisponibles['categoria'] = _colorVibracional;
      _mostrarSeleccionCodigos = false;
      _codigosEncontrados = [];
      _searchController.clear();
      _mostrarResultados = false;
    });
  }


  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Modo de concentración - pantalla completa con solo la esfera
  Widget _buildConcentrationMode() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Esfera centrada con animaciones
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulseAnimation, _expansionAnimation]),
              builder: (context, child) {
                final pulseScale = _isAudioPlaying ? 
                  _pulseAnimation.value * 1.3 : 
                  _pulseAnimation.value;
                
                if (_isSphereMode) {
                  // Modo Esfera - Esfera dorada con código
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Esfera con código centrado
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Esfera con animaciones
                          Transform.scale(
                            scale: _isPilotageActive ? pulseScale : 1.0,
                            child: GoldenSphere(
                              size: 320, // Más grande para pantalla completa
                              color: _getColorSeleccionado(),
                              glowIntensity: _isPilotageActive ? 0.9 : 0.7,
                              isAnimated: true,
                            ),
                          ),
                          // Código centrado en la esfera
                          if (_codigoSeleccionado.isNotEmpty)
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _isPilotageActive ? pulseScale : 1.0,
                                  child: IlluminatedCodeText(
                                    code: CodeFormatter.formatCodeForDisplay(_codigoSeleccionado),
                                    fontSize: CodeFormatter.calculateFontSize(_codigoSeleccionado, baseSize: 40),
                                    color: _getColorSeleccionado(),
                                    letterSpacing: 6,
                                    isAnimated: false,
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                  );
                } else {
                  // Modo Luz - Código con ajuste automático
                  return _buildAutoSizedCodeText();
                }
              },
            ),
          ),
          
          // Botón para salir del modo concentración
          Positioned(
            top: 50,
            right: 20,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isConcentrationMode = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.fullscreen_exit,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          
          // Indicador de tiempo en la esquina superior izquierda
          if (_isPilotageActive)
            Positioned(
              top: 50,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
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
                      Icons.timer,
                      color: _colorVibracional,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(_pilotageDuration),
                      style: GoogleFonts.inter(
                        color: _colorVibracional,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Método para construir la sección de códigos sincrónicos
  Widget _buildSincronicosSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _getSincronicosForCurrentCode(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFD700),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final codigosSincronicos = snapshot.data!;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
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
                  const Icon(
                    Icons.sync_alt,
                    color: Color(0xFFFFD700),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Se potencia con...',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFFD700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Estos códigos complementarios pueden potenciar el poder de tu código actual:',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: codigosSincronicos.map((codigo) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamed(
                        context,
                        '/code-detail',
                        arguments: codigo['codigo'],
                      );
                    },
                    child: Container(
                      width: 160,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFD700).withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            codigo['codigo'] ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFFFD700),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            codigo['nombre'] ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              codigo['categoria'] ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                color: const Color(0xFFFFD700),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // Método para obtener códigos sincrónicos del código actual
  Future<List<Map<String, dynamic>>> _getSincronicosForCurrentCode() async {
    try {
      // Obtener la categoría del código actual
      final categoria = await _getCodeCategory(_codigoSeleccionado);
      if (categoria.isEmpty) return [];
      
      // Obtener códigos sincrónicos
      return await CodigosRepository().getSincronicosByCategoria(categoria);
    } catch (e) {
      print('⚠️ Error al obtener códigos sincrónicos: $e');
      return [];
    }
  }

  // Método helper para obtener la categoría del código
  Future<String> _getCodeCategory(String codigo) async {
    try {
      final codigoData = await SupabaseService.client
          .from('codigos_grabovoi')
          .select('categoria')
          .eq('codigo', codigo)
          .single();
      return codigoData['categoria'] ?? 'General';
    } catch (e) {
      print('⚠️ Error al obtener categoría del código: $e');
      return 'General';
    }
  }
}

enum QuantumPilotageStep {
  preparacion,
  visualizacion,
  emision,
  repeticion,
  cierre,
  intencion,
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
      case QuantumPilotageStep.intencion:
        return 'Intención Personal';
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
      case QuantumPilotageStep.intencion:
        return '¿Qué deseas armonizar con este código?';
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
      case QuantumPilotageStep.intencion:
        return Icons.edit;
    }
  }
}
