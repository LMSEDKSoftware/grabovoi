# Contexto del Problema: Recompensas no se muestran en Campo Energético

## Problema Principal

Al completar una sesión de campo energético de 2 minutos, el modal de finalización **NO muestra**:
- Los cristales ganados (deberían ser 3 cristales)
- La luz cuántica obtenida

El modal debería mostrar el mismo diseño y la misma información que se muestra en la sección de "Sesión de Repeticiones", pero actualmente solo muestra el mensaje de felicitación y los códigos sincrónicos, sin las recompensas.

## Error en Consola

El error principal que aparece en la consola del navegador es:

```
PostgrestException (message: new row violates row-level security policy for table "user_rewards", code: 42501)
```

También aparece un error 401 (Unauthorized) al intentar hacer POST a Supabase.

## Flujo Actual

1. Usuario completa sesión de campo energético de 2 minutos
2. Se llama a `_registrarRepeticionYMostrarRecompensas()` en `code_detail_screen.dart`
3. Se registra la repetición en Supabase
4. Se llama a `rewardsService.recompensarPorRepeticion()`
5. Este método intenta:
   - Leer recompensas actuales con `getUserRewards(forceRefresh: true)`
   - Sumar 3 cristales
   - Guardar con `saveUserRewards()`
6. **PROBLEMA**: `saveUserRewards()` falla por RLS (Row-Level Security) en Supabase
7. Como falla el guardado, el método retorna valores pero el error hace que `cristalesGanados` llegue como `null`
8. El modal se muestra sin los cristales porque `cristalesGanados` es `null`

## Archivos Involucrados

1. **lib/services/rewards_service.dart**: Servicio que maneja las recompensas
   - Método `recompensarPorRepeticion()`: Otorga 3 cristales por repetición
   - Método `saveUserRewards()`: Guarda recompensas en Supabase (falla por RLS)
   - Método `getUserRewards()`: Lee recompensas de Supabase

2. **lib/screens/codes/code_detail_screen.dart**: Pantalla de campo energético
   - Método `_registrarRepeticionYMostrarRecompensas()`: Registra repetición y obtiene recompensas
   - Método `_mostrarMensajeFinalizacion()`: Muestra el modal con las recompensas

3. **lib/screens/codes/repetition_session_screen.dart**: Pantalla de repeticiones (FUNCIONA CORRECTAMENTE)
   - Mismo flujo que campo energético pero funciona correctamente
   - Muestra los cristales ganados correctamente

4. **lib/widgets/sequencia_activada_modal.dart**: Modal que muestra la información
   - Solo muestra `RewardNotification` si `cristalesGanados != null && cristalesGanados! > 0`

5. **lib/widgets/reward_notification.dart**: Widget que muestra los cristales ganados
   - Solo se muestra si hay cristales ganados

## Comparación: Repeticiones vs Campo Energético

### Repeticiones (FUNCIONA)
- Mismo código que campo energético
- Muestra correctamente los cristales ganados
- El guardado en Supabase funciona

### Campo Energético (NO FUNCIONA)
- Mismo código que repeticiones
- NO muestra los cristales ganados
- El guardado en Supabase falla por RLS

## Posibles Causas

1. **Row-Level Security (RLS) en Supabase**: La política de seguridad de la tabla `user_rewards` puede estar bloqueando las operaciones de escritura desde campo energético pero permitiéndolas desde repeticiones.

2. **Autenticación**: Puede haber un problema con el token de autenticación cuando se ejecuta desde campo energético.

3. **Contexto de ejecución**: Puede haber alguna diferencia en cómo se ejecuta el código desde campo energético vs repeticiones.

## Lo que se necesita

1. Identificar por qué el guardado falla en campo energético pero funciona en repeticiones
2. Solucionar el problema de RLS o autenticación
3. Asegurar que los cristales ganados se muestren correctamente en el modal

## Logs de Depuración

Se agregaron logs de depuración en:
- `code_detail_screen.dart`: Líneas 214-217 y 244-248
- Estos logs muestran los valores obtenidos y pasados al modal

## Notas Adicionales

- Se comentó la columna `anclas_continuidad` porque no existe en Supabase (esto causaba otro error)
- El código de campo energético es idéntico al de repeticiones
- El problema parece estar en la capa de persistencia (Supabase) más que en la lógica de negocio

