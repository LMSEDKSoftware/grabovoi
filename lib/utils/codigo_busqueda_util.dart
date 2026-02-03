/// Utilidad compartida para búsqueda de códigos Grabovoi (flujo B).
///
/// Reglas Biblioteca Cuántica:
/// 1) Si es texto → búsqueda tal cual escribe el usuario.
/// 2) Si la búsqueda comienza con un número → es un código: "333_333" y "333 333"
///    dan el mismo resultado (espacio se interpreta como "_").
/// 3) Si comienza con número: solo dígitos y "_" o espacio. Un espacio en blanco
///    se muestra en el input como "__". No letras, no "-" ni otros símbolos.

/// Normaliza una secuencia de código para comparación y búsqueda.
/// - trim
/// - espacios => "_"
/// - remover todo lo que no sea dígito o "_"
/// - colapsar "__" => "_"
/// - remover "_" al inicio/fin
String normalizarCodigo(String input) {
  if (input.isEmpty) return '';
  String s = input.trim();
  s = s.replaceAll(' ', '_').replaceAll(RegExp(r'[^0-9_]'), '');
  s = s.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
  return s;
}

/// True si la búsqueda comienza con un número (modo código: solo dígitos, _ o espacio).
bool empiezaConNumero(String query) {
  final q = query.trim();
  if (q.isEmpty) return false;
  return RegExp(r'^[0-9]').hasMatch(q);
}

/// True si la query es modo código (empieza con número) y tras normalizar tiene longitud >= 3.
bool esBusquedaPorCodigo(String query) {
  if (!empiezaConNumero(query)) return false;
  final normalized = normalizarCodigo(query);
  return normalized.isNotEmpty;
}

/// True si es consulta por código y tras normalizar tiene longitud >= 3.
bool isNumericQuery(String query) {
  if (!empiezaConNumero(query)) return false;
  final normalized = normalizarCodigo(query);
  return normalized.length >= 3;
}

/// Devuelve el código exacto normalizado si la query empieza con número; si no, null.
/// "333 333" y "333_333" devuelven el mismo código normalizado.
String? exactCodeFromQuery(String query) {
  if (!empiezaConNumero(query)) return null;
  final normalized = normalizarCodigo(query);
  return normalized.length >= 3 ? normalized : null;
}

/// Filtra la entrada cuando está en modo código: solo dígitos y "_".
/// Un espacio en blanco se convierte en "__" en el input. No permite letras ni otros símbolos.
/// Si es texto (no empieza por número), no modifica.
String filtrarEntradaCodigo(String value) {
  if (value.isEmpty) return value;
  if (!empiezaConNumero(value)) return value;
  // Espacio → "__" en secuencia; luego quitar todo lo que no sea dígito o "_"
  final conGuiones = value.replaceAll(' ', '__');
  return conGuiones.replaceAll(RegExp(r'[^0-9_]'), '');
}

/// Para búsqueda en BD por variantes: devuelve la versión con espacios (desde normalizado).
/// Útil para ILIKE cuando la BD puede tener espacios en el campo codigo.
String exactCodeWithSpaces(String exactCode) {
  return exactCode.replaceAll('_', ' ');
}
