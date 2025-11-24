# DIAGNÓSTICO: Flujo de Datos de Recompensas

## Flujo Actual de Lectura de Datos

### 1. EnergyStatsTab (Widget que muestra los datos)
- **Ubicación**: `lib/widgets/energy_stats_tab.dart`
- **Método**: `_loadRewards()`
- **Línea 88**: Llama a `_rewardsService.getUserRewards(forceRefresh: true)`
- **Qué muestra**: `rewards.cristalesEnergia` y `rewards.luzCuantica`

### 2. RewardsService.getUserRewards()
- **Ubicación**: `lib/services/rewards_service.dart`
- **Líneas 34-103**: Método principal
- **Flujo**:
  1. Obtiene `userId` de `_authService.currentUser?.id`
  2. Intenta leer de **Supabase** (tabla `user_rewards`)
  3. Si encuentra datos en Supabase → los retorna
  4. Si NO encuentra datos → crea un registro nuevo con valores en 0
  5. Si hay ERROR al leer Supabase → hace fallback a **SharedPreferences**

### 3. RewardsService.saveUserRewards()
- **Ubicación**: `lib/services/rewards_service.dart`
- **Líneas 139-178**: Método de guardado
- **Flujo**:
  1. Guarda en **Supabase** usando `upsert` con `onConflict: 'user_id'`
  2. También guarda en **SharedPreferences** como backup

### 4. RewardsService.recompensarPorPilotajeCuantico()
- **Ubicación**: `lib/services/rewards_service.dart`
- **Líneas 255-285**: Método que otorga recompensas
- **Flujo**:
  1. Lee recompensas actuales con `getUserRewards(forceRefresh: true)`
  2. Suma 5 cristales
  3. Guarda con `saveUserRewards()`

## Posibles Problemas

### Problema 1: Lectura desde SharedPreferences en lugar de Supabase
- Si hay un error al leer Supabase, el código hace fallback a SharedPreferences
- SharedPreferences podría tener datos antiguos
- **Solución**: Verificar logs para ver si está leyendo de SharedPreferences

### Problema 2: Error silencioso al guardar en Supabase
- El `upsert` podría estar fallando pero el error se está capturando
- **Solución**: Verificar logs de "Error guardando recompensas en Supabase"

### Problema 3: userId incorrecto o null
- Si `_authService.currentUser?.id` es null, lanza excepción
- **Solución**: Verificar que el usuario esté autenticado

### Problema 4: Query de Supabase con cache
- Aunque usamos `forceRefresh: true`, Supabase podría estar usando cache
- **Solución**: Agregar timestamp o usar método diferente

## Puntos de Verificación

1. **¿De dónde se lee?**
   - Log: `📊 Recompensas leídas de Supabase para usuario...` → Lee de Supabase ✅
   - Log: `⚠️ Error obteniendo recompensas de Supabase...` → Lee de SharedPreferences ⚠️

2. **¿Se guarda correctamente?**
   - Log: `✅ Recompensas guardadas en Supabase...` → Se guardó ✅
   - Log: `⚠️ Error guardando recompensas en Supabase...` → Error al guardar ❌

3. **¿Se otorgan los cristales?**
   - Log: `💎 Otorgando 5 cristales por pilotaje cuántico...` → Se están otorgando ✅
   - Log: `💎 Guardando X cristales totales...` → Se está guardando ✅

