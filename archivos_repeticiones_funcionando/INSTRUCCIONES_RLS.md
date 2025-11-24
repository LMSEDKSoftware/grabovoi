# Instrucciones para Configurar Políticas RLS en Supabase

## Problema Identificado

Los errores en la consola muestran que las tablas `user_rewards` y `user_actions` están bloqueando operaciones debido a políticas de Row-Level Security (RLS) mal configuradas o ausentes.

### Errores Comunes:
- `401 (Unauthorized)` - Usuario no autenticado o política RLS bloqueando
- `42501` - Violación de política RLS: `new row violates row-level security policy`

## Solución

Ejecutar los scripts SQL en Supabase para configurar las políticas RLS correctamente.

## Scripts Disponibles

### 1. `politicas_rls_completas.sql` ⭐ **RECOMENDADO**
**Ejecuta este script para configurar ambas tablas de una vez.**

Este script configura las políticas RLS para:
- ✅ `user_rewards` (recompensas de cristales y luz cuántica)
- ✅ `user_actions` (acciones del usuario como pilotajes, repeticiones, etc.)

### 2. `politicas_rls_supabase.sql`
**Solo para la tabla `user_rewards`**

Si solo necesitas configurar las recompensas.

### 3. `politicas_rls_user_actions.sql`
**Solo para la tabla `user_actions`**

Si solo necesitas configurar las acciones del usuario.

## Pasos para Ejecutar

### Opción 1: Script Completo (Recomendado)

1. Abre tu proyecto en **Supabase Dashboard**
2. Ve a **SQL Editor** (menú lateral izquierdo)
3. Haz clic en **New Query**
4. Copia y pega el contenido completo de `politicas_rls_completas.sql`
5. Haz clic en **Run** o presiona `Ctrl+Enter` (Windows/Linux) o `Cmd+Enter` (Mac)
6. Verifica que no haya errores en la consola

### Opción 2: Scripts Individuales

Si prefieres ejecutar los scripts por separado:

1. Ejecuta primero `politicas_rls_supabase.sql` para `user_rewards`
2. Luego ejecuta `politicas_rls_user_actions.sql` para `user_actions`

## Verificación

Después de ejecutar los scripts, verifica que las políticas estén activas:

```sql
-- Ver todas las políticas de ambas tablas
SELECT 
    tablename,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename IN ('user_rewards', 'user_actions')
ORDER BY tablename, cmd;
```

Deberías ver:

**Para `user_rewards`:**
- ✅ "Usuarios pueden insertar sus propias recompensas" (INSERT)
- ✅ "Usuarios pueden actualizar sus propias recompensas" (UPDATE)
- ✅ "Usuarios pueden leer sus propias recompensas" (SELECT)

**Para `user_actions`:**
- ✅ "Usuarios pueden insertar sus propias acciones" (INSERT)
- ✅ "Usuarios pueden leer sus propias acciones" (SELECT)
- ✅ "Usuarios pueden actualizar sus propias acciones" (UPDATE)

## Qué Solucionan Estas Políticas

### Tabla `user_rewards`
- ✅ Permite guardar cristales ganados después de completar sesiones
- ✅ Permite actualizar la luz cuántica del usuario
- ✅ Permite leer las recompensas del usuario autenticado

### Tabla `user_actions`
- ✅ Permite registrar acciones como pilotajes, repeticiones, tiempo en app
- ✅ Permite leer el historial de acciones del usuario
- ✅ Permite actualizar acciones si es necesario

## Notas Importantes

1. **Autenticación Requerida**: Las políticas requieren que el usuario esté autenticado (`TO authenticated`)
2. **Seguridad**: Solo el usuario autenticado puede insertar/leer/actualizar sus propios registros (`user_id = auth.uid()`)
3. **Sin Errores**: Después de ejecutar los scripts, los errores 401 y 42501 deberían desaparecer

## Si Aún Hay Errores

1. Verifica que el usuario esté autenticado en la aplicación
2. Verifica que el `user_id` en los datos coincida con `auth.uid()`
3. Revisa los logs de la consola del navegador para más detalles
4. Asegúrate de que RLS esté habilitado en ambas tablas:
   ```sql
   SELECT tablename, rowsecurity 
   FROM pg_tables 
   WHERE schemaname = 'public' 
   AND tablename IN ('user_rewards', 'user_actions');
   ```
   Debería mostrar `true` para `rowsecurity` en ambas tablas.

