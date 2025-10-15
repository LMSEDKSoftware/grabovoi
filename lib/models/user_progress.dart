class UserProgress {
  final int diasConsecutivos;
  final int totalSesiones;
  final int nivelVibracional;
  final Map<String, int> frecuenciaPorCategoria;
  final List<String> categoriasUsadas;
  
  UserProgress(
    this.diasConsecutivos, 
    this.totalSesiones, {
    this.nivelVibracional = 1,
    Map<String, int>? frecuenciaPorCategoria,
    List<String>? categoriasUsadas,
  }) : frecuenciaPorCategoria = frecuenciaPorCategoria ?? {},
       categoriasUsadas = categoriasUsadas ?? [];
}