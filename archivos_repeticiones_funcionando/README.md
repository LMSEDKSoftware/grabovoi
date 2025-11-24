# Archivos de Repeticiones que FUNCIONAN CORRECTAMENTE

Esta carpeta contiene todos los archivos relacionados con la sección de **Sesión de Repeticiones** que **SÍ muestran correctamente** los cristales ganados y la luz cuántica al finalizar una sesión de 2 minutos.

## ✅ Estado: FUNCIONA CORRECTAMENTE

Esta implementación muestra correctamente:
- ✅ Los cristales ganados (3 cristales por repetición)
- ✅ La luz cuántica anterior y actual
- ✅ El modal con toda la información de recompensas

## Archivos incluidos

### 1. **repetition_session_screen.dart** (61 KB)
**Pantalla principal de repeticiones**

**Métodos clave:**
- `_registrarRepeticionYMostrarRecompensas()` (líneas 1395-1424)
  - Registra la repetición en Supabase
  - Obtiene las recompensas del servicio
  - Muestra el modal con los cristales ganados
  
- `_mostrarMensajeFinalizacion()` (líneas 1426-1448)
  - Muestra el modal `SequenciaActivadaModal`
  - Pasa los valores de cristales y luz cuántica
  - Usa `tipoAccion: 'repeticion'`

**Flujo:**
1. Usuario completa sesión de 2 minutos
2. Se llama a `_registrarRepeticionYMostrarRecompensas()`
3. Se registra la repetición con `BibliotecaSupabaseService.registrarRepeticion()`
4. Se obtienen recompensas con `rewardsService.recompensarPorRepeticion()`
5. Se muestra el modal con `_mostrarMensajeFinalizacion()` pasando los valores obtenidos

### 2. **rewards_service.dart** (22 KB)
**Servicio que maneja las recompensas**

**Métodos clave:**
- `recompensarPorRepeticion()` (líneas 208-245)
  - Otorga 3 cristales por completar una repetición
  - Actualiza la luz cuántica basada en la racha
  - Retorna un mapa con: `cristalesGanados`, `luzCuanticaAnterior`, `luzCuanticaActual`

- `saveUserRewards()` (líneas 152-206)
  - Guarda las recompensas en Supabase
  - También guarda en SharedPreferences como backup
  - **Nota**: La columna `anclas_continuidad` está comentada porque no existe en Supabase

- `getUserRewards()` (líneas 33-117)
  - Lee las recompensas de Supabase
  - Si no existen, crea un registro nuevo con valores en 0
  - Tiene fallback a SharedPreferences si falla Supabase

### 3. **sequencia_activada_modal.dart** (15 KB)
**Modal que muestra la información de finalización**

**Características:**
- Muestra el título "SECUENCIA ACTIVADA"
- Muestra el mensaje de completado
- **Muestra `RewardNotification` si hay cristales ganados** (líneas 233-239)
  - Condición: `if (widget.cristalesGanados != null && widget.cristalesGanados! > 0)`
- Muestra la sección "Es importante mantener la vibración"
- Muestra los códigos sincrónicos relacionados
- Botón "Continuar"

### 4. **reward_notification.dart** (6.4 KB)
**Widget que muestra los cristales ganados**

**Características:**
- Muestra "¡Felicitaciones!" con icono de celebración
- Muestra "Has recibido X cristales de energía"
- Muestra "Has incrementado a X% tu Luz cuántica" (si aplica)
- Diseño con gradiente dorado y bordes brillantes

### 5. **rewards_model.dart** (4.4 KB)
**Modelo de datos de recompensas**

**Clase `UserRewards`:**
- `cristalesEnergia`: Cristales de energía acumulados
- `restauradoresArmonia`: Restauradores disponibles
- `anclasContinuidad`: Anclas de continuidad (no se guarda en Supabase)
- `luzCuantica`: Porcentaje de luz cuántica (0.0 a 100.0)
- `mantrasDesbloqueados`: Lista de mantras desbloqueados
- `codigosPremiumDesbloqueados`: Lista de códigos premium desbloqueados
- `ultimaActualizacion`: Fecha de última actualización
- `logros`: Map con logros adicionales

### 6. **biblioteca_supabase_service.dart**
**Servicio para registrar repeticiones en Supabase**

**Método clave:**
- `registrarRepeticion()` (líneas 260-284)
  - Registra la sesión de repetición en Supabase
  - Actualiza el progreso del usuario
  - Notifica al scheduler de notificaciones

## Flujo completo que funciona

```
Usuario completa sesión de 2 minutos
    ↓
_re registrarRepeticionYMostrarRecompensas()
    ↓
BibliotecaSupabaseService.registrarRepeticion()
    ↓
RewardsService.recompensarPorRepeticion()
    ├─→ getUserRewards(forceRefresh: true)
    ├─→ Suma 3 cristales
    ├─→ saveUserRewards() → Supabase ✅
    └─→ Retorna: {cristalesGanados: 3, luzCuanticaAnterior: X, luzCuanticaActual: Y}
    ↓
_mostrarMensajeFinalizacion(cristalesGanados: 3, ...)
    ↓
SequenciaActivadaModal
    ├─→ Recibe cristalesGanados: 3
    └─→ Muestra RewardNotification ✅
```

## Comparación con Campo Energético

**Repeticiones (ESTE CÓDIGO - FUNCIONA):**
- ✅ Guarda correctamente en Supabase
- ✅ Retorna valores correctos
- ✅ Muestra cristales en el modal

**Campo Energético (NO FUNCIONA):**
- ❌ Falla al guardar en Supabase (error RLS)
- ❌ Retorna valores null
- ❌ No muestra cristales en el modal

## Notas importantes

1. **El código es idéntico** entre repeticiones y campo energético
2. **La diferencia está en el contexto de ejecución** o en las políticas de Supabase
3. **Este código funciona**, así que puede usarse como referencia para corregir campo energético
4. El servicio `rewards_service.dart` es compartido entre ambas secciones

## Cómo usar estos archivos

Estos archivos pueden usarse como referencia para:
1. Comparar con el código de campo energético
2. Identificar diferencias en el flujo
3. Verificar que el código de campo energético sea idéntico
4. Solucionar el problema de RLS en Supabase

