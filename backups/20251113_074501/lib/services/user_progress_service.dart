import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart' as app_models;
import 'auth_service_simple.dart';
import 'rewards_service.dart';

class UserProgressService {
  static final UserProgressService _instance = UserProgressService._internal();
  factory UserProgressService() => _instance;
  UserProgressService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthServiceSimple _authService = AuthServiceSimple();

  // ===== PROGRESO DEL USUARIO =====

  /// Obtener progreso del usuario actual (tabla: usuario_progreso)
  Future<Map<String, dynamic>?> getUserProgress() async {
    if (!_authService.isLoggedIn) return null;

    try {
      final response = await _supabase
          .from('usuario_progreso')
          .select()
          .eq('user_id', _authService.currentUser!.id)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error obteniendo progreso del usuario: $e');
      return null;
    }
  }

  /// Actualizar progreso del usuario (tabla: usuario_progreso)
  Future<void> updateUserProgress({
    int? diasConsecutivos,
    int? totalPilotajes,
    DateTime? ultimoPilotaje,
    int? energyLevel,
  }) async {
    if (!_authService.isLoggedIn) return;

    try {
      final data = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (diasConsecutivos != null) data['dias_consecutivos'] = diasConsecutivos;
      if (totalPilotajes != null) data['total_pilotajes'] = totalPilotajes;
      if (ultimoPilotaje != null) data['ultimo_pilotaje'] = ultimoPilotaje.toIso8601String();
      if (energyLevel != null) data['nivel_energetico'] = energyLevel;

      await _supabase
          .from('usuario_progreso')
          .update(data)
          .eq('user_id', _authService.currentUser!.id);

      print('✅ Progreso del usuario actualizado');
    } catch (e) {
      print('Error actualizando progreso: $e');
    }
  }

  /// Registrar una nueva sesión y actualizar usuario_progreso (mínimo viable)
  Future<void> recordSession({
    required String sessionType,
    String? codeId,
    String? codeName,
    int durationMinutes = 0,
    String? category,
    int? energyBefore,
    int? energyAfter,
    String? notes,
    Map<String, dynamic>? sessionData,
  }) async {
    if (!_authService.isLoggedIn) return;

    try {
      final now = DateTime.now();

      // Registrar sesión en user_actions PRIMERO
      final String actionType = _mapSessionTypeToAction(sessionType);
      await _supabase.from('user_actions').insert({
        'user_id': _authService.currentUser!.id,
        'challenge_id': null,
        'action_type': actionType,
        'action_data': {
          'codeId': codeId,
          'codeName': codeName,
          'duration': durationMinutes,
          'metadata': sessionData ?? {},
          'timestamp': now.toIso8601String(),
        },
        'recorded_at': now.toIso8601String(),
      });

      // Ahora obtener estadísticas COMPLETAS desde user_actions y recalcular
      final estadisticas = await _obtenerEstadisticasCompletas();
      
      // Obtener progreso actual para días consecutivos
      final progress = await getUserProgress();
      int diasConsecutivos = 1;
      
      if (progress != null) {
        final ultimo = progress['ultimo_pilotaje'] != null
            ? DateTime.parse(progress['ultimo_pilotaje']).toLocal()
            : now.subtract(const Duration(days: 2));
        final today = DateTime(now.year, now.month, now.day);
        final lastDay = DateTime(ultimo.year, ultimo.month, ultimo.day);
        final diffDays = today.difference(lastDay).inDays;
        diasConsecutivos = diffDays == 1
            ? (progress['dias_consecutivos'] ?? 0) + 1
            : (diffDays == 0 ? (progress['dias_consecutivos'] ?? 0) : 1);
            
        // Fallback correctivo
        try {
          if (diffDays == 0 && diasConsecutivos == 1 && progress['created_at'] != null) {
            final createdAt = DateTime.parse(progress['created_at']).toLocal();
            final createdDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
            if (createdDay.isBefore(today)) {
              diasConsecutivos = 2;
            }
          }
        } catch (_) {}
      }

      // Calcular nivel energético desde estadísticas completas
      final nivel = _calcularNivelEnergeticoDesdeAcciones(
        diasConsecutivos: diasConsecutivos,
        totalRepeticiones: estadisticas['total_repeticiones'] ?? 0,
        totalPilotajes: estadisticas['total_pilotajes'] ?? 0,
        totalCompartidos: estadisticas['total_compartidos'] ?? 0,
        totalMinutos: estadisticas['total_minutos'] ?? 0,
      );

      // Actualizar usuario_progreso con el nivel recalculado
      if (progress == null) {
        await _supabase.from('usuario_progreso').insert({
          'user_id': _authService.currentUser!.id,
          'dias_consecutivos': diasConsecutivos,
          'total_pilotajes': estadisticas['total_pilotajes'] ?? 0,
          'nivel_energetico': nivel,
          'ultimo_pilotaje': now.toIso8601String(),
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });
        print('✅ Progreso inicial creado');
      } else {
        await updateUserProgress(
          diasConsecutivos: diasConsecutivos,
          totalPilotajes: estadisticas['total_pilotajes'] ?? 0,
          ultimoPilotaje: now,
          energyLevel: nivel,
        );
      }

      print('✅ Sesión registrada y progreso actualizado. Nivel: $nivel');
      
      // Verificar y otorgar recompensas por racha
      try {
        final rewardsService = RewardsService();
        await rewardsService.verificarRecompensasPorRacha(diasConsecutivos);
        
        // Actualizar luz cuántica basada en la racha de días
        await rewardsService.actualizarLuzCuanticaPorRacha(diasConsecutivos);
      } catch (e) {
        print('⚠️ Error verificando recompensas por racha: $e');
      }
    } catch (e) {
      print('Error registrando sesión: $e');
    }
  }
  
  /// Obtener estadísticas completas desde user_actions
  Future<Map<String, int>> _obtenerEstadisticasCompletas() async {
    try {
      final response = await _supabase
          .from('user_actions')
          .select('action_type, action_data')
          .eq('user_id', _authService.currentUser!.id);

      int totalRepeticiones = 0;
      int totalPilotajes = 0;
      int totalCompartidos = 0;
      int totalMinutos = 0;

      for (final row in response as List) {
        final String type = row['action_type'] as String? ?? '';
        final Map<String, dynamic>? data = (row['action_data'] as Map?)?.cast<String, dynamic>();
        
        switch (type) {
          case 'codigoRepetido':
            totalRepeticiones++;
            break;
          case 'sesionPilotaje':
            totalPilotajes++;
            break;
          case 'pilotajeCompartido':
            totalCompartidos++;
            break;
          case 'tiempoEnApp':
            totalMinutos += (data?['duration'] as num?)?.toInt() ?? 0;
            break;
        }
      }

      return {
        'total_repeticiones': totalRepeticiones,
        'total_pilotajes': totalPilotajes,
        'total_compartidos': totalCompartidos,
        'total_minutos': totalMinutos,
      };
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      return {};
    }
  }
  
  /// Calcular nivel energético desde estadísticas completas de acciones
  int _calcularNivelEnergeticoDesdeAcciones({
    required int diasConsecutivos,
    required int totalRepeticiones,
    required int totalPilotajes,
    required int totalCompartidos,
    required int totalMinutos,
  }) {
    int nivel = 1;
    
    // Por días consecutivos (base de uso continuo)
    if (diasConsecutivos >= 21) nivel += 4;
    else if (diasConsecutivos >= 14) nivel += 3;
    else if (diasConsecutivos >= 7) nivel += 2;
    else if (diasConsecutivos >= 3) nivel += 1;
    
    // Por total de pilotajes (práctica profunda)
    if (totalPilotajes >= 100) nivel += 3;
    else if (totalPilotajes >= 50) nivel += 2;
    else if (totalPilotajes >= 20) nivel += 1;
    else if (totalPilotajes >= 5) nivel += 1;
    
    // Por total de repeticiones (disciplina y constancia)
    if (totalRepeticiones >= 200) nivel += 2;
    else if (totalRepeticiones >= 100) nivel += 1;
    else if (totalRepeticiones >= 50) nivel += 1;
    
    // Por pilotajes compartidos (impacto y difusión)
    if (totalCompartidos >= 100) nivel += 2;
    else if (totalCompartidos >= 50) nivel += 1;
    else if (totalCompartidos >= 20) nivel += 1;
    else if (totalCompartidos >= 5) nivel += 1;
    
    // Por minutos de uso en la app (tiempo invertido)
    if (totalMinutos >= 300) nivel += 2; // 5 horas
    else if (totalMinutos >= 180) nivel += 1; // 3 horas
    else if (totalMinutos >= 60) nivel += 1; // 1 hora

    // Nivel mínimo de 3 para usuarios activos, máximo 10
    if (diasConsecutivos > 0 || totalPilotajes > 0 || totalRepeticiones > 0) {
      nivel = nivel.clamp(3, 10);
    }
    
    return nivel.clamp(1, 10);
  }

  /// Actualizar historial de códigos
  Future<void> _updateCodeHistory(String codeId, String codeName, int durationMinutes) async {
    try {
      // Verificar si el código ya existe en el historial
      final existing = await _supabase
          .from('user_code_history')
          .select()
          .eq('user_id', _authService.currentUser!.id)
          .eq('code_id', codeId)
          .maybeSingle();

      if (existing != null) {
        // Actualizar registro existente
        await _supabase
            .from('user_code_history')
            .update({
              'usage_count': (existing['usage_count'] ?? 0) + 1,
              'last_used': DateTime.now().toIso8601String(),
              'total_time_minutes': (existing['total_time_minutes'] ?? 0) + durationMinutes,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', _authService.currentUser!.id)
            .eq('code_id', codeId);
      } else {
        // Crear nuevo registro
        await _supabase.from('user_code_history').insert({
          'user_id': _authService.currentUser!.id,
          'code_id': codeId,
          'code_name': codeName,
          'usage_count': 1,
          'total_time_minutes': durationMinutes,
        });
      }
    } catch (e) {
      print('Error actualizando historial de códigos: $e');
    }
  }

  /// Obtener estadísticas del usuario
  Future<List<Map<String, dynamic>>> getUserStatistics() async {
    if (!_authService.isLoggedIn) return [];

    try {
      final response = await _supabase
          .from('user_actions')
          .select()
          .eq('user_id', _authService.currentUser!.id);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      return [];
    }
  }

  /// Obtener historial de sesiones
  Future<List<Map<String, dynamic>>> getSessionHistory({
    int limit = 50,
    String? sessionType,
  }) async {
    if (!_authService.isLoggedIn) return [];

    try {
      // Filtrar sólo acciones de sesión con duración
      final actionTypes = ['sesionPilotaje', 'codigoRepetido', 'pilotajeCompartido'];
      var query = _supabase
          .from('user_actions')
          .select()
          .eq('user_id', _authService.currentUser!.id)
          .inFilter('action_type', actionTypes)
          .order('recorded_at', ascending: false)
          .limit(limit);

      final response = await query;
      final List data = List<Map<String, dynamic>>.from(response);

      // Normalizar a estructura con duration_minutes
      final normalized = data.map<Map<String, dynamic>>((row) {
        final ad = row['action_data'] as Map<String, dynamic>?;
        final dur = (ad?['duration'] as num?)?.toInt() ?? 0;
        return {
          'id': row['id'],
          'action_type': row['action_type'],
          'duration_minutes': dur,
          'code_id': ad?['codeId'],
          'code_name': ad?['codeName'],
          'created_at': row['recorded_at'],
        };
      }).toList();

      return normalized;
    } catch (e) {
      print('Error obteniendo historial de sesiones (user_actions): $e');
      return [];
    }
  }

  String _mapSessionTypeToAction(String sessionType) {
    switch (sessionType) {
      case 'pilotage':
        return 'sesionPilotaje';
      case 'repetition':
        return 'codigoRepetido';
      case 'share':
        return 'pilotajeCompartido';
      default:
        return 'tiempoEnApp';
    }
  }

  /// Obtener códigos más usados
  Future<List<Map<String, dynamic>>> getMostUsedCodes({int limit = 10}) async {
    if (!_authService.isLoggedIn) return [];

    try {
      final response = await _supabase
          .from('user_code_history')
          .select()
          .eq('user_id', _authService.currentUser!.id)
          .order('usage_count', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error obteniendo códigos más usados: $e');
      return [];
    }
  }

  /// Obtener progreso de días consecutivos
  Future<int> getConsecutiveDays() async {
    final progress = await getUserProgress();
    if (progress == null) return 0;

    final lastSessionDate = progress['last_session_date'];
    if (lastSessionDate == null) return 0;

    final lastSession = DateTime.parse(lastSessionDate);
    final now = DateTime.now();
    final difference = now.difference(lastSession).inDays;

    if (difference == 0) {
      return progress['consecutive_days'] ?? 0;
    } else if (difference == 1) {
      return (progress['consecutive_days'] ?? 0) + 1;
    } else {
      return 0; // Se rompió la racha
    }
  }

  /// Calcular nivel energético (1-10) basado en días y totales
  int _calcularNivelEnergetico(int diasConsecutivos, int totalPilotajes) {
    int nivel = 1;
    if (diasConsecutivos >= 21) nivel += 4;
    else if (diasConsecutivos >= 14) nivel += 3;
    else if (diasConsecutivos >= 7) nivel += 2;
    else if (diasConsecutivos >= 3) nivel += 1;

    if (totalPilotajes >= 100) nivel += 3;
    else if (totalPilotajes >= 50) nivel += 2;
    else if (totalPilotajes >= 20) nivel += 1;
    else if (totalPilotajes >= 5) nivel += 1;

    if (diasConsecutivos > 0 || totalPilotajes > 0) {
      nivel = nivel.clamp(3, 10);
    }
    return nivel.clamp(1, 10);
  }

  /// Guardar evaluación inicial del usuario
  Future<void> saveUserAssessment(Map<String, dynamic> assessmentData) async {
    if (!_authService.isLoggedIn) return;

    // SIEMPRE guardar en SharedPreferences como respaldo para evitar mostrar evaluación de nuevo
    await _saveAssessmentLocally(assessmentData);

    try {
      // Guardar en la tabla de evaluaciones
      await _supabase.from('user_assessments').insert({
        'user_id': _authService.currentUser!.id,
        'assessment_data': assessmentData,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Actualizar preferencias del usuario basadas en la evaluación
      final preferences = <String, dynamic>{
        'knowledge_level': assessmentData['knowledge_level'],
        'goals': assessmentData['goals'],
        'experience_level': assessmentData['experience_level'],
        'time_available': assessmentData['time_available'],
        'preferences': assessmentData['preferences'],
        'motivation': assessmentData['motivation'],
        'assessment_completed': true,
        'assessment_date': assessmentData['completed_at'],
      };

      // Actualizar o crear progreso del usuario
      await _supabase.from('user_progress').upsert({
        'user_id': _authService.currentUser!.id,
        'preferences': preferences,
        'energy_level': _calculateInitialEnergyLevel(assessmentData),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('✅ Evaluación del usuario guardada en Supabase');
    } catch (e) {
      print('⚠️ Error guardando evaluación en Supabase (pero guardada localmente): $e');
    }
  }

  /// Calcular nivel energético inicial basado en la evaluación
  int _calculateInitialEnergyLevel(Map<String, dynamic> assessmentData) {
    int level = 1;
    
    // Ajustar según nivel de conocimiento
    switch (assessmentData['knowledge_level']) {
      case 'principiante':
        level = 1;
        break;
      case 'intermedio':
        level = 3;
        break;
      case 'avanzado':
        level = 5;
        break;
    }
    
    // Ajustar según experiencia
    switch (assessmentData['experience_level']) {
      case 'nunca':
        level = level.clamp(1, 2);
        break;
      case 'poco':
        level = level.clamp(2, 4);
        break;
      case 'regular':
        level = level.clamp(3, 6);
        break;
      case 'experto':
        level = level.clamp(5, 7);
        break;
    }
    
    return level;
  }

  /// Guardar evaluación localmente como fallback
  Future<void> _saveAssessmentLocally(Map<String, dynamic> assessmentData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_assessment', jsonEncode(assessmentData));
      print('✅ Evaluación guardada localmente');
    } catch (e) {
      print('Error guardando evaluación localmente: $e');
    }
  }

  /// Obtener evaluación del usuario - SIMPLIFICADO con fallback a SharedPreferences
  Future<Map<String, dynamic>?> getUserAssessment() async {
    if (!_authService.isLoggedIn) {
      print('❌ Usuario no autenticado');
      return null;
    }

    print('🔍 Buscando evaluación para usuario: ${_authService.currentUser!.id}');

    // Primero intentar en Supabase
    try {
      final response = await _supabase
          .from('user_assessments')
          .select()
          .eq('user_id', _authService.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null && response['assessment_data'] != null) {
        print('✅ Evaluación encontrada en Supabase');
        final assessmentData = response['assessment_data'] as Map<String, dynamic>;
        // Asegurarse de que tiene el flag is_complete
        assessmentData['is_complete'] = true;
        return assessmentData;
      }
    } catch (e) {
      print('⚠️ Error obteniendo evaluación de Supabase: $e');
      // Continuar con fallback a SharedPreferences
    }

    // Fallback: buscar en SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final assessmentJson = prefs.getString('user_assessment');
      if (assessmentJson != null) {
        final assessmentData = jsonDecode(assessmentJson) as Map<String, dynamic>;
        // Asegurarse de que tiene el flag is_complete
        assessmentData['is_complete'] = true;
        print('✅ Evaluación encontrada en SharedPreferences (fallback)');
        return assessmentData;
      }
    } catch (e) {
      print('⚠️ Error obteniendo evaluación de SharedPreferences: $e');
    }

    print('❌ No se encontró evaluación ni en Supabase ni localmente');
    return null;
  }

  /// Verificar si la evaluación está completa
  bool _isAssessmentComplete(Map<String, dynamic> assessment) {
    // Verificar que todos los campos requeridos estén presentes
    final requiredFields = [
      'knowledge_level',
      'goals',
      'experience_level', 
      'time_available',
      'preferences',
      'motivation'
    ];
    
    for (final field in requiredFields) {
      if (!assessment.containsKey(field) || assessment[field] == null) {
        print('❌ Campo faltante en evaluación: $field');
        return false;
      }
      
      // Verificar que los campos de lista no estén vacíos
      if (field == 'goals' || field == 'preferences') {
        final value = assessment[field];
        if (value is! List || value.isEmpty) {
          print('❌ Lista vacía en evaluación: $field');
          return false;
        }
      }
      
      // Verificar que los campos de string no estén vacíos
      if (field == 'knowledge_level' || field == 'experience_level' || 
          field == 'time_available' || field == 'motivation') {
        final value = assessment[field];
        if (value is! String || value.isEmpty) {
          print('❌ String vacío en evaluación: $field');
          return false;
        }
      }
    }
    
    // Verificar que tenga el flag de completado
    if (assessment['is_complete'] != true) {
      print('❌ Evaluación no marcada como completa');
      return false;
    }
    
    print('✅ Evaluación completa y válida');
    return true;
  }
}
