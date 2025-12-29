# Solución de Optimización de Requests a Supabase

## Problema Identificado

Un solo usuario está generando **50+ requests** en pocos segundos, lo que puede:
- Colapsar el servidor
- Generar costos elevados en Supabase
- Degradar el rendimiento de la app

## Análisis de Requests

### Requests más problemáticos:
1. **`codigos_titulos_relacionados`**: ~50 consultas individuales → Debe ser 1 batch query
2. **`users`**: 5+ consultas duplicadas → Debe ser 1 consulta con caché
3. **`user_subscriptions`**: 4+ consultas duplicadas → Debe ser 1 consulta con caché
4. **`user_challenges`**: 3+ consultas duplicadas → Debe ser 1 consulta con caché
5. **`usuario_progreso`**: 5+ consultas duplicadas → Debe ser 1 consulta con caché
6. **`daily_code_assignments`**: 4+ consultas duplicadas → Debe ser 1 consulta con caché
7. **`app_config`**: 3+ consultas que fallan (500) → Debe usar caché y valores por defecto

## Soluciones Implementadas

### 1. ✅ CacheService - Caché Centralizado
**Archivo**: `lib/services/cache_service.dart`

**Funcionalidades**:
- Caché en memoria con TTL (5 min para datos de usuario, 24h para datos estáticos)
- Batch queries para títulos relacionados (50+ requests → 1 request)
- Batch queries para datos del usuario (6+ requests → 1 request)
- Invalidación inteligente de caché

**Uso**:
```dart
// En lugar de múltiples consultas individuales:
final cacheService = CacheService();
final batchData = await cacheService.getUserDataBatch(userId);
// Retorna: user, subscriptions, challenges, progress, rewards, assessment
```

### 2. ✅ UserDataService - Servicio Centralizado
**Archivo**: `lib/services/user_data_service.dart`

**Funcionalidades**:
- Carga todos los datos del usuario de una vez
- Debouncing para evitar múltiples llamadas simultáneas
- Integración con CacheService

**Uso**:
```dart
final userDataService = UserDataService();
final data = await userDataService.loadUserData();
// Usar: data['user'], data['subscriptions'], data['challenges'], etc.
```

### 3. ✅ Optimización de Títulos Relacionados
**Archivo**: `lib/services/supabase_service.dart`

**Cambios**:
- Nuevo método `getTitulosRelacionadosBatch()` para múltiples códigos
- `getTitulosRelacionados()` ahora usa el caché automáticamente

**Uso**:
```dart
// Antes: 50 consultas individuales
for (var codigo in codigos) {
  await SupabaseService.getTitulosRelacionados(codigo);
}

// Ahora: 1 consulta batch
final batchResult = await SupabaseService.getTitulosRelacionadosBatch(codigos);
```

### 4. ✅ Optimización de LegalLinksService
**Archivo**: `lib/services/legal_links_service.dart`

**Cambios**:
- Caché estático para evitar múltiples consultas cuando falla
- Si falla una vez, no reintenta (usa valores por defecto)

### 5. ✅ Optimización de Biblioteca
**Archivo**: `lib/screens/biblioteca/static_biblioteca_screen.dart`

**Cambios**:
- `_precargarTitulosRelacionados()` ahora usa batch queries
- De 50+ requests → 1 request

## Próximos Pasos Recomendados

### 1. Migrar Pantallas a UserDataService
Reemplazar consultas individuales en:
- `lib/screens/home/home_screen.dart`
- `lib/screens/profile/profile_screen.dart`
- `lib/screens/evolucion/evolucion_screen.dart`
- `lib/screens/desafios/desafios_screen.dart`

### 2. Implementar Debouncing Global
Agregar debouncing a servicios que se llaman frecuentemente:
- `SubscriptionService.checkSubscriptionStatus()`
- `UserProgressService.getUserProgress()`
- `ChallengeService.initializeChallenges()`

### 3. Caché Persistente
Usar SharedPreferences para datos que no cambian:
- Configuraciones de la app
- Códigos estáticos
- Links legales

### 4. Request Queue
Implementar cola de requests para agrupar llamadas similares que ocurren en el mismo frame

## Impacto Esperado

**Antes**: ~50-60 requests por sesión de usuario
**Después**: ~5-10 requests por sesión de usuario

**Reducción**: ~80-85% de requests

## Monitoreo

Después de implementar, monitorear:
- Número de requests en Supabase Dashboard
- Tiempo de carga de pantallas
- Uso de memoria (caché)
- Costos de Supabase


