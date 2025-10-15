import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OpenAICodesService {
  final String apiKey;

  OpenAICodesService({required this.apiKey});

  /// Busca sugerencias de códigos sagrados relacionadas a una intención dada
  /// Retorna una lista de strings (códigos sugeridos o descripciones breves)
  Future<List<String>> sugerirCodigosPorIntencion(String consulta) async {
    try {
      final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };

      final prompt =
          'Eres un asistente experto en códigos sagrados de Grabovoi. '
          'El usuario busca códigos relacionados con: "$consulta". '
          'Devuelve únicamente una lista JSON de hasta 5 elementos, '
          'cada elemento debe ser un objeto con campos numero (cadena) '
          'y descripcion (cadena breve). No incluyas texto extra.';

      final body = jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'temperature': 0.2,
      });

      final resp = await http.post(uri, headers: headers, body: body);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final content = (data['choices']?[0]?['message']?['content'] ?? '').toString();
        // Intentar parsear como JSON (el modelo devuelve sólo la lista por instrucción)
        final parsed = jsonDecode(content);
        if (parsed is List) {
          return parsed
              .map<String>((e) =>
                  (e is Map && e['numero'] != null) ? e['numero'].toString() : e.toString())
              .where((e) => e.trim().isNotEmpty)
              .cast<String>()
              .toList();
        }
        return const [];
      } else {
        debugPrint('OpenAI error: ${resp.statusCode} ${resp.body}');
        return const [];
      }
    } catch (e) {
      debugPrint('Error consultando OpenAI: $e');
      return const [];
    }
  }
}


