import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart' as app_models;
import 'auth_service_simple.dart';

class UserProgressService {
  static final UserProgressService _instance = UserProgressService._internal();
  factory UserProgressService() => _instance;
  UserProgressService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthServiceSimple _authService = AuthServiceSimple();

  // ===== PROGRESO DEL USUARIO =====

  /// Obtener progreso del usuario actual
  Future<Map<String, dynamic>?> getUserProgress() async {
    if (!_authService.isLoggedIn) return null;

    try {
      final response = await _supabase
          .from('user_progress')
          .select()
          .eq('user_id', _authService.currentUser!.id)
          .single();

      return response;
    } catch (e) {
      print('Error obteniendo progreso del usuario: $e');
      return null;
    }
  }

  /// Actualizar progreso del usuario
  Future<void> updateUserProgress({
    int? totalSessions,
    int? consecutiveDays,
    DateTime? lastSessionDate,
    int? totalPilotageTime,
    int? totalMeditationTime,
    List<String>? favoriteCategories,
    int? energyLevel,
    int? currentStreak,
    int? longestStreak,
    List<String>? achievements,
    Map<String, dynamic>? preferences,
  }) async {
    if (!_authService.isLoggedIn) return;

    try {
      final data = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (totalSessions != null) data['total_sessions'] = totalSessions;
      if (consecutiveDays != null) data['consecutive_days'] = consecutiveDays;
      if (lastSessionDate != null) data['last_session_date'] = lastSessionDate.toIso8601String();
      if (totalPilotageTime != null) data['total_pilotage_time'] = totalPilotageTime;
      if (totalMeditationTime != null) data['total_meditation_time'] = totalMeditationTime;
      if (favoriteCategories != null) data['favorite_categories'] = favoriteCategories;
      if (energyLevel != null) data['energy_level'] = energyLevel;
      if (currentStreak != null) data['current_streak'] = currentStreak;
      if (longestStreak != null) data['longest_streak'] = longestStreak;
      if (achievements != null) data['achievements'] = achievements;
      if (preferences != null) data['preferences'] = preferences;

      await _supabase
          .from('user_progress')
          .update(data)
          .eq('user_id', _authService.currentUser!.id);

      print('✅ Progreso del usuario actualizado');
    } catch (e) {
      print('Error actualizando progreso: $e');
    }
  }

  /// Registrar una nueva sesión
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
      // Registrar sesión
      await _supabase.from('user_sessions').insert({
        'user_id': _authService.currentUser!.id,
        'session_type': sessionType,
        'code_id': codeId,
        'code_name': codeName,
        'duration_minutes': durationMinutes,
        'category': category,
        'energy_before': energyBefore,
        'energy_after': energyAfter,
        'notes': notes,
        'session_data': sessionData ?? {},
      });

      // Actualizar progreso
      final progress = await getUserProgress();
      if (progress != null) {
        final newTotalSessions = (progress['total_sessions'] ?? 0) + 1;
        final newTotalPilotageTime = progress['total_pilotage_time'] ?? 0;
        final newTotalMeditationTime = progress['total_meditation_time'] ?? 0;

        await updateUserProgress(
          totalSessions: newTotalSessions,
          totalPilotageTime: sessionType == 'pilotage' 
              ? newTotalPilotageTime + durationMinutes 
              : newTotalPilotageTime,
          totalMeditationTime: sessionType == 'meditation' 
              ? newTotalMeditationTime + durationMinutes 
              : newTotalMeditationTime,
          lastSessionDate: DateTime.now(),
        );
      }

      // Actualizar historial de códigos si aplica
      if (codeId != null) {
        await _updateCodeHistory(codeId, codeName ?? '', durationMinutes);
      }

      print('✅ Sesión registrada: $sessionType');
    } catch (e) {
      print('Error registrando sesión: $e');
    }
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
  Future<Map<String, dynamic>?> getUserStatistics() async {
    if (!_authService.isLoggedIn) return null;

    try {
      final response = await _supabase
          .from('user_statistics')
          .select()
          .eq('user_id', _authService.currentUser!.id)
          .single();

      return response;
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      return null;
    }
  }

  /// Obtener historial de sesiones
  Future<List<Map<String, dynamic>>> getSessionHistory({
    int limit = 50,
    String? sessionType,
  }) async {
    if (!_authService.isLoggedIn) return [];

    try {
      var query = _supabase
          .from('user_sessions')
          .select()
          .eq('user_id', _authService.currentUser!.id);

      if (sessionType != null) {
        query = query.eq('session_type', sessionType);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error obteniendo historial de sesiones: $e');
      return [];
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

  /// Calcular nivel del usuario basado en experiencia
  Future<int> calculateUserLevel() async {
    final progress = await getUserProgress();
    if (progress == null) return 1;

    final totalSessions = progress['total_sessions'] ?? 0;
    final totalTime = (progress['total_pilotage_time'] ?? 0) + (progress['total_meditation_time'] ?? 0);
    
    // Fórmula simple: cada 10 sesiones o 100 minutos = 1 nivel
    final level = ((totalSessions / 10) + (totalTime / 100)).floor() + 1;
    return level.clamp(1, 100); // Máximo nivel 100
  }

  /// Guardar evaluación inicial del usuario
  Future<void> saveUserAssessment(Map<String, dynamic> assessmentData) async {
    if (!_authService.isLoggedIn) return;

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

      print('✅ Evaluación del usuario guardada');
    } catch (e) {
      print('Error guardando evaluación: $e');
      // Si falla la base de datos, guardar localmente
      await _saveAssessmentLocally(assessmentData);
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

  /// Obtener evaluación del usuario - SIMPLIFICADO
  Future<Map<String, dynamic>?> getUserAssessment() async {
    if (!_authService.isLoggedIn) {
      print('❌ Usuario no autenticado');
      return null;
    }

    print('🔍 Buscando evaluación para usuario: ${_authService.currentUser!.id}');

    try {
      // Buscar en la tabla de evaluaciones
      final response = await _supabase
          .from('user_assessments')
          .select()
          .eq('user_id', _authService.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        print('✅ Evaluación encontrada en base de datos');
        return response['assessment_data'];
      } else {
        print('❌ No se encontró evaluación en base de datos');
        return null;
      }
    } catch (e) {
      print('❌ Error obteniendo evaluación: $e');
      return null;
    }
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
