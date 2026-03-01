/// Tokens para reproducción de voz numérica (dígito a dígito).
/// Preserva "_" como micro-pausa; no usa codigoSoloDigitos.
library;

/// Convierte un código/secuencia en lista de tokens para voz:
/// - Dígitos '0'-'9' → un token por dígito.
/// - Espacios y '_' → un único token '_' (micro-sausa).
/// - Guiones '-' eliminados; múltiples _ colapsados a uno.
///
/// Ejemplos:
/// - "520 741 8" => ['5','2','0','_','7','4','1','_','8']
/// - "520_741_8" => ['5','2','0','_','7','4','1','_','8']
/// - "5207418" => ['5','2','0','7','4','1','8']
List<String> voiceTokensFromCode(String code) {
  if (code.isEmpty) return [];
  String s = code.trim();
  s = s.replaceAll(' ', '_').replaceAll('-', '');
  s = s.replaceAll(RegExp(r'[^0-9_]'), '');
  s = s.replaceAll(RegExp(r'_+'), '_');
  if (s.isEmpty) return [];
  final list = <String>[];
  for (int i = 0; i < s.length; i++) {
    list.add(s[i]);
  }
  return list;
}
