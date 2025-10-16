import '../models/supabase_models.dart';
import '../services/supabase_service.dart';
import 'ai/openai_codes_service.dart';

class AICodesService {
  static final OpenAICodesService _openai = OpenAICodesService(
    apiKey: const String.fromEnvironment('OPENAI_API_KEY', defaultValue: ''),
  );

  // Lista de códigos Grabovoi auténticos adicionales (no en la DB oficial)
  // Estos son códigos documentados de fuentes oficiales que pueden agregarse
  static final Set<String> _codigosAutenticosAdicionales = {
    '88888588888', '817992191', '71427321893', '71891871981', '4812412',
    '9187948181', '518491617', '7199719', '719849817', '88899141819',
    '91719871981', '71381921', '19712893', '319817318', '71984981981',
    '591061718489', '49851431918', '12516176', '9788891719', '193751891',
    '1231115015', '548491698719', '48971281948', '71042', '61988184161',
    '12370744', '9788819719', '918197185', '419312819212', '721348192',
    '1489999', '498712891319', '59189171481', '8898', '2194189', '319764',
    '7194718189', '1888948', '548432198', '11179', '88891244819',
    '819489718918', '1487219'
  };

  /// Busca códigos relacionados con una consulta siguiendo el sistema de 3 niveles:
  /// 1. Códigos oficiales de la DB
  /// 2. Códigos auténticos adicionales documentados
  /// 3. Opción de crear código personalizado (fase futura)
  static Future<Map<String, dynamic>> buscarYCrearCodigos(String consulta) async {
    try {
      // PASO 1: Buscar en códigos oficiales de la DB
      final codigosOficiales = await _buscarEnCodigosOficiales(consulta);
      if (codigosOficiales.isNotEmpty) {
        return {
          'tipo': 'oficiales',
          'codigos': codigosOficiales,
          'mensaje': 'Se encontraron códigos oficiales relacionados con tu búsqueda'
        };
      }

      // PASO 2: Buscar códigos auténticos adicionales documentados
      final codigosAdicionales = await _buscarCodigosAutenticosAdicionales(consulta);
      if (codigosAdicionales.isNotEmpty) {
        return {
          'tipo': 'adicionales',
          'codigos': codigosAdicionales,
          'mensaje': 'Se encontraron códigos Grabovoi auténticos adicionales documentados'
        };
      }

      // PASO 3: No se encontraron códigos, ofrecer crear código personalizado
      return {
        'tipo': 'personalizado',
        'codigos': [],
        'mensaje': 'No se encontraron códigos oficiales o auténticos. Puedes crear tu propio código siguiendo la metodología de Grabovoi (en desarrollo)'
      };

    } catch (e) {
      print('❌ Error en búsqueda de códigos: $e');
      return {
        'tipo': 'error',
        'codigos': [],
        'mensaje': 'Error en la búsqueda. Intenta nuevamente.'
      };
    }
  }

  /// Busca códigos en la base de datos oficial
  static Future<List<CodigoGrabovoi>> _buscarEnCodigosOficiales(String consulta) async {
    try {
      final todosLosCodigos = await SupabaseService.getCodigos();
      final consultaLower = consulta.toLowerCase();
      
      return todosLosCodigos.where((codigo) =>
        codigo.codigo.toLowerCase().contains(consultaLower) ||
        codigo.nombre.toLowerCase().contains(consultaLower) ||
        codigo.descripcion.toLowerCase().contains(consultaLower) ||
        codigo.categoria.toLowerCase().contains(consultaLower)
      ).toList();
    } catch (e) {
      print('❌ Error buscando códigos oficiales: $e');
      return [];
    }
  }

  /// Busca códigos auténticos adicionales documentados
  static Future<List<CodigoGrabovoi>> _buscarCodigosAutenticosAdicionales(String consulta) async {
    try {
      // Obtener sugerencias de la IA (solo códigos auténticos adicionales)
      final sugerencias = await _openai.sugerirCodigosPorIntencion(consulta);
      
      final codigosCreados = <CodigoGrabovoi>[];
      
      for (final sugerencia in sugerencias) {
        try {
          final codigoNumero = sugerencia['codigo'] as String;
          
          // VALIDAR QUE EL CÓDIGO SEA AUTÉNTICO ADICIONAL
          if (!_codigosAutenticosAdicionales.contains(codigoNumero)) {
            print('⚠️ Código no auténtico ignorado: $codigoNumero');
            continue;
          }
          
          // Verificar si el código ya existe en la DB
          final codigoExistente = await _verificarCodigoExistente(codigoNumero);
          
          if (codigoExistente == null) {
            // Crear nuevo código auténtico en Supabase
            final nuevoCodigo = CodigoGrabovoi(
              id: '', // Se generará automáticamente
              codigo: codigoNumero,
              nombre: _generarNombreDesdeDescripcion(sugerencia['descripcion'] as String),
              descripcion: sugerencia['descripcion'] as String,
              categoria: sugerencia['categoria'] as String,
              color: sugerencia['color'] as String,
            );
            
            final codigoCreado = await SupabaseService.crearCodigo(nuevoCodigo);
            codigosCreados.add(codigoCreado);
            
            print('✅ Código Grabovoi auténtico adicional creado: ${nuevoCodigo.codigo} - ${nuevoCodigo.categoria}');
          } else {
            // El código ya existe, agregarlo a la lista
            codigosCreados.add(codigoExistente);
            print('ℹ️ Código Grabovoi auténtico ya existe: ${codigoExistente.codigo}');
          }
        } catch (e) {
          print('❌ Error creando código ${sugerencia['codigo']}: $e');
        }
      }
      
      return codigosCreados;
    } catch (e) {
      print('❌ Error buscando códigos auténticos adicionales: $e');
      return [];
    }
  }

  /// Verifica si un código ya existe en la base de datos
  static Future<CodigoGrabovoi?> _verificarCodigoExistente(String codigo) async {
    try {
      final codigos = await SupabaseService.getCodigos();
      return codigos.firstWhere(
        (c) => c.codigo == codigo,
        orElse: () => throw StateError('No encontrado'),
      );
    } catch (e) {
      return null; // El código no existe
    }
  }

  /// Genera un nombre para el código basado en su descripción
  static String _generarNombreDesdeDescripcion(String descripcion) {
    // Tomar las primeras palabras de la descripción como nombre
    final palabras = descripcion.split(' ');
    if (palabras.length <= 3) {
      return descripcion;
    }
    
    // Tomar las primeras 3 palabras y capitalizar
    final nombre = palabras.take(3).join(' ');
    return nombre.split(' ').map((palabra) => 
      palabra.isEmpty ? '' : palabra[0].toUpperCase() + palabra.substring(1)
    ).join(' ');
  }

  /// Valida si un código es auténtico adicional de Grabovoi
  static bool esCodigoAutenticoAdicional(String codigo) {
    return _codigosAutenticosAdicionales.contains(codigo);
  }

  /// Obtiene la lista de códigos auténticos adicionales para referencia
  static Set<String> getCodigosAutenticosAdicionales() {
    return Set.from(_codigosAutenticosAdicionales);
  }

  /// Verifica si un código es oficial (está en la DB)
  static Future<bool> esCodigoOficial(String codigo) async {
    try {
      final codigoExistente = await _verificarCodigoExistente(codigo);
      return codigoExistente != null;
    } catch (e) {
      return false;
    }
  }
}
