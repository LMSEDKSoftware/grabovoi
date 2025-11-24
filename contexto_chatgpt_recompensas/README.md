# Carpeta de Contexto para ChatGPT - Problema de Recompensas

## Contenido de esta carpeta

Esta carpeta contiene todos los archivos relevantes para entender y solucionar el problema de que las recompensas (cristales ganados y luz cuántica) no se muestran en el modal de finalización de la sección "Campo Energético".

## Archivos incluidos

1. **CONTEXTO_PROBLEMA.md**: Descripción detallada del problema, flujo actual, errores y posibles causas
2. **rewards_service.dart**: Servicio que maneja las recompensas (otorgar, guardar, leer)
3. **code_detail_screen.dart**: Pantalla de campo energético (NO FUNCIONA - no muestra cristales)
4. **repetition_session_screen.dart**: Pantalla de repeticiones (FUNCIONA CORRECTAMENTE - muestra cristales)
5. **sequencia_activada_modal.dart**: Modal que muestra la información de finalización
6. **reward_notification.dart**: Widget que muestra los cristales ganados
7. **rewards_model.dart**: Modelo de datos de recompensas

## Cómo usar esta información con ChatGPT

1. **Lee primero CONTEXTO_PROBLEMA.md** para entender el problema completo
2. Compara `code_detail_screen.dart` (campo energético) con `repetition_session_screen.dart` (repeticiones)
3. Revisa `rewards_service.dart` para entender cómo se guardan las recompensas
4. El error principal es: `PostgrestException (message: new row violates row-level security policy for table "user_rewards", code: 42501)`

## Preguntas clave para ChatGPT

1. ¿Por qué el mismo código funciona en repeticiones pero no en campo energético?
2. ¿Cómo solucionar el error de Row-Level Security (RLS) en Supabase?
3. ¿Por qué `cristalesGanados` llega como `null` al modal?
4. ¿Hay alguna diferencia en el contexto de ejecución entre ambas pantallas?

## Información técnica

- **Framework**: Flutter/Dart
- **Backend**: Supabase (PostgreSQL)
- **Problema**: Row-Level Security (RLS) bloqueando escrituras en tabla `user_rewards`
- **Síntoma**: Modal no muestra cristales ganados ni luz cuántica
- **Comportamiento esperado**: Debería mostrar 3 cristales ganados al completar sesión de 2 minutos

## Notas importantes

- El código de campo energético es **idéntico** al de repeticiones
- El problema parece estar en la capa de persistencia (Supabase), no en la lógica de negocio
- Se agregaron logs de depuración que muestran que `cristalesGanados` llega como `null`
- El error ocurre al intentar guardar en Supabase, no al leer

