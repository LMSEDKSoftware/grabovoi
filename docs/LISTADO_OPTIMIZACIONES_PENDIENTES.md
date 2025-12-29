# 📋 Listado Completo de Optimizaciones Pendientes

## 🎯 Objetivo
Reducir requests a Supabase, mejorar rendimiento y reducir costos.

---

## ✅ Optimizaciones YA Implementadas

1. ✅ **CacheService** - Caché centralizado con TTL
2. ✅ **UserDataService** - Servicio centralizado para datos del usuario
3. ✅ **Batch Queries para Títulos Relacionados** - De 50+ requests → 1 request
4. ✅ **Optimización de LegalLinksService** - Caché estático para evitar reintentos
5. ✅ **Optimización de Biblioteca** - Batch queries en `_precargarTitulosRelacionados()`

---

## 🔴 CRÍTICAS - Implementar PRIMERO

### 1. Migrar Pantallas a UserDataService
**Impacto**: Reducir ~20-30 requests duplicados por sesión

**Archivos a modificar**:
- `lib/screens/home/home_screen.dart`
  - Reemplazar consultas individuales a `users`, `user_subscriptions`, `user_challenges`, `usuario_progreso`
  - Usar `UserDataService().loadUserData()` una vez al inicio
  
- `lib/screens/profile/profile_screen.dart`
  - Línea 97: `getUserProgress()` → Usar `UserDataService`
  - Línea 98: `AdminService.esAdmin()` → Puede usar caché
  
- `lib/screens/evolucion/evolucion_screen.dart`
  - Línea 209: `getUserProgress()` → Usar `UserDataService`
  - Línea 214: `initializeChallenges()` → Ya carga `user_challenges`, evitar duplicado
  
- `lib/screens/desafios/desafios_screen.dart`
  - Usar `UserDataService` en lugar de cargar `user_challenges` individualmente

**Código de ejemplo**:
```dart
// ANTES (múltiples requests):
final progress = await _progressService.getUserProgress();
final subscriptions = await _subscriptionService.getUserSubscriptions();
final challenges = await _challengeService.getUserChallenges();

// DESPUÉS (1 request batch):
final userDataService = UserDataService();
final data = await userDataService.loadUserData();
final progress = data['progress'];
final subscriptions = data['subscriptions'];
final challenges = data['challenges'];
```

---

### 2. Implementar Debouncing en Servicios Frecuentes
**Impacto**: Evitar múltiples llamadas simultáneas

**Servicios a modificar**:
- `lib/services/subscription_service.dart`
  - Método `checkSubscriptionStatus()` - Agregar debouncing (2 segundos)
  
- `lib/services/user_progress_service.dart`
  - Método `getUserProgress()` - Usar `UserDataService` o agregar debouncing
  
- `lib/services/challenge_service.dart`
  - Método `initializeChallenges()` - Usar `UserDataService` o agregar debouncing

**Código de ejemplo**:
```dart
class SubscriptionService {
  Future<SubscriptionStatus>? _loadingFuture;
  DateTime? _lastCheck;
  static const Duration _debounceDuration = Duration(seconds: 2);
  
  Future<SubscriptionStatus> checkSubscriptionStatus({bool forceRefresh = false}) async {
    if (_loadingFuture != null && !forceRefresh) {
      return await _loadingFuture!;
    }
    
    if (!forceRefresh && 
        _lastCheck != null && 
        DateTime.now().difference(_lastCheck!) < _debounceDuration) {
      return _cachedStatus;
    }
    
    _loadingFuture = _checkStatusInternal();
    try {
      final result = await _loadingFuture!;
      _lastCheck = DateTime.now();
      return result;
    } finally {
      _loadingFuture = null;
    }
  }
}
```

---

### 3. Optimizar Consultas a `daily_code_assignments`
**Impacto**: Reducir ~4-5 requests duplicados

**Problema**: Se consulta múltiples veces con los mismos parámetros

**Archivos a modificar**:
- `lib/services/daily_code_service.dart`
  - Agregar caché con TTL de 1 hora (código diario cambia una vez al día)
  - Invalidar caché solo cuando cambia la fecha

**Código de ejemplo**:
```dart
class DailyCodeService {
  static Map<String, dynamic>? _cachedDailyCode;
  static DateTime? _cacheDate;
  
  Future<Map<String, dynamic>?> getDailyCode() async {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    
    if (_cachedDailyCode != null && 
        _cacheDate != null && 
        _cacheDate!.day == today.day) {
      return _cachedDailyCode;
    }
    
    // Cargar desde Supabase
    final code = await _loadDailyCodeFromSupabase();
    _cachedDailyCode = code;
    _cacheDate = today;
    return code;
  }
}
```

---

### 4. Optimizar Consultas a `user_actions`
**Impacto**: Reducir ~3-5 requests duplicados

**Problema**: Se consulta `user_actions` múltiples veces con los mismos filtros

**Archivos a modificar**:
- `lib/services/challenge_progress_tracker.dart`
  - Línea 288: `_loadProgressFromSupabase()` - Agregar caché con TTL de 1 minuto
  
- `lib/services/user_progress_service.dart`
  - Método `getSessionHistory()` - Agregar caché

**Código de ejemplo**:
```dart
// En CacheService, agregar método:
Future<List<Map<String, dynamic>>> getUserActionsBatch(
  String userId,
  List<String> actionTypes,
  {DateTime? startDate, DateTime? endDate}
) async {
  final cacheKey = 'user_actions_${userId}_${actionTypes.join("_")}';
  // Verificar caché...
  // Si no está en caché, hacer consulta batch
}
```

---

## 🟡 IMPORTANTES - Implementar DESPUÉS

### 5. Caché Persistente con SharedPreferences
**Impacto**: Reducir requests en inicio de app

**Datos a cachear**:
- Configuraciones de la app (`app_config`)
- Links legales (ya implementado parcialmente)
- Códigos estáticos (si no cambian frecuentemente)
- Estado de suscripción (última verificación)

**Implementación**:
```dart
class PersistentCacheService {
  static Future<void> saveUserData(String userId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'user_data_$userId';
    await prefs.setString(key, jsonEncode(data));
    await prefs.setString('${key}_timestamp', DateTime.now().toIso8601String());
  }
  
  static Future<Map<String, dynamic>?> loadUserData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'user_data_$userId';
    final data = prefs.getString(key);
    final timestamp = prefs.getString('${key}_timestamp');
    
    if (data != null && timestamp != null) {
      final lastUpdate = DateTime.parse(timestamp);
      // Si tiene menos de 5 minutos, usar caché
      if (DateTime.now().difference(lastUpdate) < Duration(minutes: 5)) {
        return jsonDecode(data) as Map<String, dynamic>;
      }
    }
    return null;
  }
}
```

---

### 6. Request Queue para Agrupar Llamadas Similares
**Impacto**: Reducir requests simultáneos

**Implementación**:
```dart
class RequestQueue {
  static final Map<String, Completer> _pendingRequests = {};
  
  static Future<T> queueRequest<T>(
    String key,
    Future<T> Function() request,
  ) async {
    if (_pendingRequests.containsKey(key)) {
      return await _pendingRequests[key]!.future as T;
    }
    
    final completer = Completer<T>();
    _pendingRequests[key] = completer;
    
    try {
      final result = await request();
      completer.complete(result);
      return result;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _pendingRequests.remove(key);
    }
  }
}
```

---

### 7. Optimizar Consultas a `usuario_favoritos`
**Impacto**: Reducir ~2-3 requests duplicados

**Problema**: Se consulta `usuario_favoritos` múltiples veces

**Archivos a modificar**:
- `lib/services/user_favorites_service.dart`
  - Agregar caché con invalidación cuando se agrega/elimina favorito
  
- `lib/screens/biblioteca/static_biblioteca_screen.dart`
  - Usar caché de favoritos en lugar de consultar cada vez

---

### 8. Optimizar Consultas a `mensajes_diarios`
**Impacto**: Reducir ~1-2 requests

**Problema**: Se consulta `mensajes_diarios` cada vez que se carga la pantalla

**Solución**: Caché con TTL de 1 día (el mensaje diario no cambia durante el día)

---

### 9. Optimizar Consultas a `codigos_grabovoi`
**Impacto**: Reducir requests en búsquedas

**Problema**: Búsquedas repetidas con los mismos términos

**Solución**: 
- Caché de resultados de búsqueda (TTL: 5 minutos)
- Debouncing en búsquedas mientras el usuario escribe

---

## 🟢 MEJORAS ADICIONALES

### 10. Lazy Loading de Datos
**Impacto**: Cargar solo lo necesario

**Implementación**:
- No cargar todos los datos al inicio
- Cargar datos cuando se necesiten (lazy loading)
- Usar `FutureBuilder` o `StreamBuilder` para cargar bajo demanda

---

### 11. Paginación en Listas Grandes
**Impacto**: Reducir tamaño de respuestas

**Implementación**:
- Usar `limit()` y `offset()` en consultas
- Implementar scroll infinito en lugar de cargar todo

---

### 12. Compresión de Respuestas
**Impacto**: Reducir ancho de banda

**Implementación**:
- Habilitar compresión gzip en Supabase (ya viene por defecto)
- Verificar que el cliente acepta compresión

---

### 13. Monitoreo y Logging
**Impacto**: Identificar problemas futuros

**Implementación**:
```dart
class RequestMonitor {
  static final List<RequestLog> _logs = [];
  
  static void logRequest(String endpoint, Duration duration, int statusCode) {
    _logs.add(RequestLog(
      endpoint: endpoint,
      duration: duration,
      statusCode: statusCode,
      timestamp: DateTime.now(),
    ));
    
    // Si hay más de 100 logs, eliminar los más antiguos
    if (_logs.length > 100) {
      _logs.removeAt(0);
    }
  }
  
  static Map<String, int> getRequestCounts() {
    final counts = <String, int>{};
    for (final log in _logs) {
      counts[log.endpoint] = (counts[log.endpoint] ?? 0) + 1;
    }
    return counts;
  }
}
```

---

## 📊 Priorización

### Fase 1 (Críticas - Esta Semana):
1. ✅ Migrar pantallas a UserDataService
2. ✅ Implementar debouncing en servicios frecuentes
3. ✅ Optimizar `daily_code_assignments`
4. ✅ Optimizar `user_actions`

### Fase 2 (Importantes - Próxima Semana):
5. Caché persistente con SharedPreferences
6. Request Queue
7. Optimizar `usuario_favoritos`
8. Optimizar `mensajes_diarios`

### Fase 3 (Mejoras - Mes Próximo):
9. Optimizar `codigos_grabovoi`
10. Lazy Loading
11. Paginación
12. Monitoreo

---

## 📈 Métricas Esperadas

**Antes de optimizaciones**:
- Requests por sesión: ~50-60
- Tiempo de carga inicial: ~3-5 segundos
- Costo mensual estimado: Alto

**Después de Fase 1**:
- Requests por sesión: ~10-15
- Tiempo de carga inicial: ~1-2 segundos
- Reducción: ~70-75%

**Después de Fase 2**:
- Requests por sesión: ~5-8
- Tiempo de carga inicial: ~0.5-1 segundo
- Reducción: ~85-90%

**Después de Fase 3**:
- Requests por sesión: ~3-5
- Tiempo de carga inicial: ~0.3-0.5 segundos
- Reducción: ~90-95%

---

## 🔍 Cómo Verificar

1. **Supabase Dashboard** → Logs → Ver número de requests
2. **Flutter DevTools** → Network → Ver requests en tiempo real
3. **RequestMonitor** (si se implementa) → Ver estadísticas en app

---

## 📝 Notas

- Todas las optimizaciones deben mantener la funcionalidad actual
- Probar cada cambio antes de pasar al siguiente
- Monitorear errores después de cada implementación
- Invalidar caché cuando sea necesario (ej: logout, cambios de datos)


