# 🔍 Guía de Monitoreo de Logs

## Chrome está lanzado en: http://localhost:8080

## Pasos para Monitorear los Logs

### 1. Abre la Consola de Chrome
- Presiona **F12** o **Cmd+Option+I** (Mac) / **Ctrl+Shift+I** (Windows)
- Ve a la pestaña **"Console"**

### 2. Filtra los Logs Importantes

En la consola, busca estos mensajes clave:

#### ✅ Mensajes de Éxito (Verde)
- `✅ [DIAGNÓSTICO] Usuario autenticado verificado`
- `✅ [DIAGNÓSTICO] Recompensas GUARDADAS en Supabase`
- `✅ Precarga completada: 5/5 archivos`
- `✅ Usuario cargado desde tabla users`

#### ❌ Errores Críticos (Rojo) - A REVISAR
- `401 (Unauthorized)` - Problema de autenticación o RLS
- `42501` - Violación de política RLS
- `Error guardando acción en Supabase`
- `Error guardando recompensas en Supabase`
- `Usuario no autenticado`

#### ⚠️ Advertencias (Amarillo) - Normal en Web
- `NotificationService: Web no soporta notificaciones locales` - Normal, no es error
- `Notificaciones locales no disponibles en web` - Normal, no es error

#### 🔍 Logs de Debug (Azul/Gris)
- `🔍 [CAMPO ENERGÉTICO] Recompensas obtenidas`
- `🔍 [CAMPO ENERGÉTICO] Valores pasados al modal`
- `💾 [DIAGNÓSTICO] saveUserRewards llamado`
- `[CAMPO ENERGÉTICO] Iniciando temporizador`

## Puntos Críticos a Monitorear

### 1. Autenticación
**Busca:**
```
✅ Usuario autenticado verificado: [userId]
❌ ERROR: Usuario no autenticado en Supabase
```

**Si ves el error:**
- El usuario no está logueado
- El token de autenticación expiró
- Necesitas hacer login nuevamente

### 2. Guardado de Acciones (user_actions)
**Busca:**
```
✅ POST .../user_actions ... 200 (OK)
❌ POST .../user_actions ... 401 (Unauthorized)
❌ Error guardando acción en Supabase: PostgrestException
```

**Si ves errores 401 o 42501:**
- Las políticas RLS no están configuradas correctamente
- Verifica que ejecutaste el script SQL
- Verifica que el usuario esté autenticado

### 3. Guardado de Recompensas (user_rewards)
**Busca:**
```
✅ [DIAGNÓSTICO] Recompensas GUARDADAS en Supabase
❌ ERROR guardando recompensas en Supabase
❌ userId no coincide con usuario autenticado
```

**Si ves errores:**
- Verifica que las políticas RLS estén configuradas
- Verifica que el userId coincida con auth.uid()
- Revisa los logs de `saveUserRewards`

### 4. Obtención de Recompensas
**Busca:**
```
🔍 [CAMPO ENERGÉTICO] Recompensas obtenidas:
   cristalesGanados: 3
   luzCuanticaAnterior: X
   luzCuanticaActual: Y
```

**Si ves `null` o valores incorrectos:**
- El servicio de recompensas no está funcionando
- Hay un error al leer de Supabase
- Revisa los logs de `getUserRewards`

### 5. Modal de Finalización
**Busca:**
```
🔍 [CAMPO ENERGÉTICO] Valores pasados al modal:
   cristalesGanados: 3
   luzCuanticaAnterior: X
   luzCuanticaActual: Y
```

**Si los valores son `null`:**
- Las recompensas no se obtuvieron correctamente
- Revisa los logs anteriores para encontrar el error

## Comandos Útiles en la Consola

### Filtrar solo errores:
En el filtro de la consola, escribe: `error|Error|ERROR|❌`

### Filtrar solo recompensas:
Escribe: `recompensa|reward|cristal|DIAGNÓSTICO`

### Filtrar solo autenticación:
Escribe: `auth|autenticado|usuario|user_id`

### Limpiar la consola:
Presiona el icono de "limpiar" o escribe `clear()` en la consola

## Qué Hacer Si Encuentras Errores

### Error 401 o 42501:
1. Verifica que ejecutaste el script SQL en Supabase
2. Verifica que las políticas RLS estén activas
3. Verifica que el usuario esté autenticado
4. Recarga la página (F5)

### Error de autenticación:
1. Cierra sesión y vuelve a iniciar sesión
2. Verifica que el token no haya expirado
3. Revisa la configuración de Supabase

### Error al guardar recompensas:
1. Revisa los logs de `saveUserRewards`
2. Verifica que el userId coincida con auth.uid()
3. Verifica que las políticas RLS permitan INSERT

## Estado Actual Esperado

Después de ejecutar el script SQL, deberías ver:
- ✅ Sin errores 401 o 42501
- ✅ Mensajes de éxito al guardar acciones
- ✅ Mensajes de éxito al guardar recompensas
- ✅ Los cristales ganados se muestran en el modal

