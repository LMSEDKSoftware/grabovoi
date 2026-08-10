import 'package:flutter/foundation.dart';

/// Puente simple para pedir "ve a Biblioteca y busca este código" desde
/// cualquier pantalla, sin tener que encadenar callbacks a través de varios
/// niveles de navegación (MainNavigation -> HomeScreen -> CodeDetailScreen).
/// Mismo patrón que RewardsService.rewardsUpdated.
///
/// Uso:
/// - Quien quiere navegar: hace pop hasta la raíz y luego
///   BibliotecaNavigationBridge.request(codigo).
/// - MainNavigation escucha este notifier, cambia a la pestaña Biblioteca y
///   llama setExternalSearchQuery(codigo) en StaticBibliotecaScreen vía su
///   GlobalKey.
class BibliotecaNavigationBridge {
  static final ValueNotifier<String?> pendingSearchQuery = ValueNotifier<String?>(null);

  static void request(String codigo) {
    pendingSearchQuery.value = codigo;
  }

  static void consume() {
    pendingSearchQuery.value = null;
  }
}
