import 'package:flutter/foundation.dart';

/// Puente para avisarle a DiarioScreen que debe recargar sus datos.
/// Necesario porque MainNavigation mantiene las pestañas vivas con
/// IndexedStack: DiarioScreen no se reconstruye al cambiar de pestaña, así
/// que sin esto una entrada nueva guardada en NuevaEntradaDiarioScreen nunca
/// aparecería hasta reiniciar la app. Mismo patrón que BibliotecaNavigationBridge.
class DiarioRefreshBridge {
  static final ValueNotifier<int> refreshRequested = ValueNotifier<int>(0);

  static void requestRefresh() {
    refreshRequested.value++;
  }
}
