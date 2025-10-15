import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ChallengeService {
  static const String _challengesKey = 'active_challenges';
  static const String _completedKey = 'completed_challenges';

  /// Iniciar un desafío
  static Future<Map<String, dynamic>> startChallenge(String challengeId, String title) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    
    final challenge = {
      'id': challengeId,
      'title': title,
      'startDate': now.toIso8601String(),
      'currentDay': 1,
      'isActive': true,
    };
    
    // Guardar desafío activo
    await prefs.setString(_challengesKey, json.encode(challenge));
    
    return challenge;
  }

  /// Obtener desafío activo
  static Future<Map<String, dynamic>?> getActiveChallenge() async {
    final prefs = await SharedPreferences.getInstance();
    final challengeJson = prefs.getString(_challengesKey);
    
    if (challengeJson != null) {
      return json.decode(challengeJson);
    }
    return null;
  }

  /// Actualizar progreso del desafío
  static Future<void> updateProgress(int currentDay) async {
    final prefs = await SharedPreferences.getInstance();
    final challengeJson = prefs.getString(_challengesKey);
    
    if (challengeJson != null) {
      final challenge = json.decode(challengeJson);
      challenge['currentDay'] = currentDay;
      await prefs.setString(_challengesKey, json.encode(challenge));
    }
  }

  /// Completar un desafío
  static Future<void> completeChallenge() async {
    final prefs = await SharedPreferences.getInstance();
    final challengeJson = prefs.getString(_challengesKey);
    
    if (challengeJson != null) {
      final challenge = json.decode(challengeJson);
      challenge['isActive'] = false;
      challenge['completedDate'] = DateTime.now().toIso8601String();
      
      // Mover a desafíos completados
      final completedChallenges = prefs.getStringList(_completedKey) ?? [];
      completedChallenges.add(json.encode(challenge));
      await prefs.setStringList(_completedKey, completedChallenges);
      
      // Eliminar de activos
      await prefs.remove(_challengesKey);
    }
  }

  /// Obtener desafíos completados
  static Future<List<Map<String, dynamic>>> getCompletedChallenges() async {
    final prefs = await SharedPreferences.getInstance();
    final completedJson = prefs.getStringList(_completedKey) ?? [];
    
    return completedJson.map((jsonString) => Map<String, dynamic>.from(json.decode(jsonString))).toList();
  }

  /// Calcular progreso del desafío
  static double calculateProgress(Map<String, dynamic> challenge, int totalDays) {
    final currentDay = challenge['currentDay'] ?? 1;
    return (currentDay / totalDays).clamp(0.0, 1.0);
  }

  /// Obtener mensaje de progreso
  static String getProgressMessage(Map<String, dynamic> challenge, int totalDays) {
    final progress = calculateProgress(challenge, totalDays);
    
    if (progress >= 1.0) {
      return '¡Desafío completado! 🎉';
    } else if (progress >= 0.75) {
      return '¡Casi terminamos! Últimos días 🌟';
    } else if (progress >= 0.5) {
      return '¡Mitad del camino! Continúa 💪';
    } else if (progress >= 0.25) {
      return 'Buen comienzo, mantén el ritmo ✨';
    } else {
      return '¡Primeros pasos! El viaje comienza 🚀';
    }
  }
}
