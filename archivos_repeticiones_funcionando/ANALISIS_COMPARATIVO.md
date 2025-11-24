# Análisis Comparativo: Repeticiones vs Campo Energético

## ✅ CONCLUSIÓN: El código es IDÉNTICO

Después de comparar línea por línea ambos archivos, **el código de campo energético es prácticamente idéntico al de repeticiones**. Las únicas diferencias son:

1. **Logs de debug** en campo energético (no afectan funcionalidad)
2. **Mensaje personalizado** ("campo energético" vs "repeticiones")
3. **tipoAccion** diferente ('campo_energetico' vs 'repeticion')

## Comparación Lado a Lado

### Método: _registrarRepeticionYMostrarRecompensas()

| Aspecto | Repeticiones | Campo Energético | ¿Igual? |
|---------|--------------|------------------|---------|
| Llama a `BibliotecaSupabaseService.registrarRepeticion()` | ✅ | ✅ | ✅ SÍ |
| Llama a `rewardsService.recompensarPorRepeticion()` | ✅ | ✅ | ✅ SÍ |
| Pasa valores al modal | ✅ | ✅ | ✅ SÍ |
| Manejo de errores | ✅ | ✅ | ✅ SÍ |
| Logs de debug | ❌ | ✅ | ⚠️ Solo debug |

### Método: _mostrarMensajeFinalizacion()

| Aspecto | Repeticiones | Campo Energético | ¿Igual? |
|---------|--------------|------------------|---------|
| Parámetros del método | ✅ | ✅ | ✅ SÍ |
| showDialog | ✅ | ✅ | ✅ SÍ |
| SequenciaActivadaModal | ✅ | ✅ | ✅ SÍ |
| Pasa cristalesGanados | ✅ | ✅ | ✅ SÍ |
| Pasa luzCuanticaAnterior | ✅ | ✅ | ✅ SÍ |
| Pasa luzCuanticaActual | ✅ | ✅ | ✅ SÍ |
| tipoAccion | 'repeticion' | 'campo_energetico' | ⚠️ Diferente (no afecta) |
| Mensaje | "repeticiones" | "campo energético" | ⚠️ Diferente (no afecta) |

## 🔍 PROBLEMA REAL IDENTIFICADO

Según los logs de la consola del navegador:

### Error Principal:
```
PostgrestException (message: new row violates row-level security policy for table "user_rewards", code: 42501)
```

### Error Secundario:
```
POST https://whtiazgcxdnemrrgjjqf.supabase.co/rest/v1/user_rewards?... 401 (Unauthorized)
```

## 📊 Flujo de Ejecución

### Repeticiones (FUNCIONA):
```
Usuario completa sesión
    ↓
_registrarRepeticionYMostrarRecompensas()
    ↓
BibliotecaSupabaseService.registrarRepeticion() ✅
    ↓
rewardsService.recompensarPorRepeticion()
    ├─→ getUserRewards(forceRefresh: true) ✅
    ├─→ Suma 3 cristales ✅
    ├─→ saveUserRewards() → Supabase ✅ (GUARDA CORRECTAMENTE)
    └─→ Retorna: {cristalesGanados: 3, ...} ✅
    ↓
_mostrarMensajeFinalizacion(cristalesGanados: 3, ...) ✅
    ↓
SequenciaActivadaModal muestra RewardNotification ✅
```

### Campo Energético (NO FUNCIONA):
```
Usuario completa sesión
    ↓
_registrarRepeticionYMostrarRecompensas()
    ↓
BibliotecaSupabaseService.registrarRepeticion() ✅
    ↓
rewardsService.recompensarPorRepeticion()
    ├─→ getUserRewards(forceRefresh: true) ✅
    ├─→ Suma 3 cristales ✅
    ├─→ saveUserRewards() → Supabase ❌ (FALLA POR RLS)
    └─→ Retorna: {cristalesGanados: null, ...} ❌
    ↓
_mostrarMensajeFinalizacion(cristalesGanados: null, ...) ❌
    ↓
SequenciaActivadaModal NO muestra RewardNotification ❌
```

## 🎯 CAUSA RAÍZ

El problema **NO está en el código Dart**, sino en:

1. **Row-Level Security (RLS) en Supabase**: Las políticas de seguridad están bloqueando las operaciones de escritura cuando se ejecuta desde campo energético
2. **Autenticación**: Puede haber un problema con el token de autenticación o el contexto de ejecución

## ✅ VERIFICACIONES NECESARIAS

### 1. Políticas RLS en Supabase
Verificar que las políticas permitan:
- **INSERT**: `(user_id = auth.uid())`
- **UPDATE**: `(user_id = auth.uid())`
- **SELECT**: `(user_id = auth.uid())`

### 2. Autenticación
Verificar que:
- El usuario esté autenticado cuando se ejecuta desde campo energético
- El token de autenticación sea válido
- El `user_id` se esté pasando correctamente

### 3. Contexto de Ejecución
Verificar si hay alguna diferencia en:
- Cómo se inicializa la pantalla
- Cuándo se ejecuta el código
- El estado de autenticación en ese momento

## 💡 SOLUCIÓN PROPUESTA

Como el código es idéntico, el problema está en Supabase. Opciones:

1. **Verificar y corregir las políticas RLS** en Supabase
2. **Verificar la autenticación** antes de guardar recompensas
3. **Agregar manejo de errores** más robusto que permita mostrar los cristales incluso si falla el guardado (usando valores calculados localmente)

## 📝 NOTA IMPORTANTE

El código Dart está **correcto y es idéntico** entre ambas secciones. El problema está en la capa de persistencia (Supabase), no en la lógica de negocio.

