class CodeFormatter {
  /// Formatea un código Grabovoi para mostrarlo en múltiples líneas
  /// Solo divide por guiones bajos (_), mantiene códigos sin _ en una línea
  static String formatCodeForDisplay(String codigo) {
    // Si contiene guiones bajos, dividir por cada _
    if (codigo.contains('_')) {
      List<String> partes = codigo.split('_');
      return partes.join('\n');
    }
    
    // Si no tiene guiones bajos, mantener en una línea
    return codigo;
  }
  
  /// Verifica si un código necesita ser formateado en múltiples líneas
  static bool needsMultilineFormat(String codigo) {
    return codigo.contains('_');
  }
  
  /// Calcula el tamaño de fuente apropiado basado en la longitud del código
  static double calculateFontSize(String codigo, {double baseSize = 36, double minSize = 20}) {
    // Si tiene guiones bajos, usar tamaño base
    if (codigo.contains('_')) {
      return baseSize;
    }
    
    // Para códigos sin guiones bajos, ajustar según longitud
    int longitud = codigo.length;
    
    if (longitud <= 8) {
      return baseSize; // 36px
    } else if (longitud <= 12) {
      return baseSize * 0.9; // ~32px
    } else if (longitud <= 16) {
      return baseSize * 0.8; // ~29px
    } else if (longitud <= 20) {
      return baseSize * 0.7; // ~25px
    } else {
      return baseSize * 0.6; // ~22px
    }
  }
}
