# Solución Completa: Mostrar Cristales en Campo Energético

## Problema Identificado

El código Dart es **idéntico** entre repeticiones y campo energético, pero campo energético no muestra los cristales ganados debido a un error de **Row-Level Security (RLS)** en Supabase.

## Errores en Consola

1. **Error RLS**: `PostgrestException (message: new row violates row-level security policy for table "user_rewards", code: 42501)`
2. **Error 401**: `POST .../user_rewards?... 401 (Unauthorized)`

## Solución Implementada

### 1. Verificación de Autenticación ✅

Se agregó verificación de autenticación en `rewards_service.dart` antes de guardar:

```dart
// Verificar autenticación antes de guardar
final currentUser = SupabaseConfig.client.auth.currentUser;
if (currentUser == null) {
  print('❌ ERROR: Usuario no autenticado en Supabase. No se puede guardar recompensas.');
  throw Exception('Usuario no autenticado en Supabase');
}

// Verificar que el userId coincida con el usuario autenticado
if (currentUser.id != rewards.userId) {
  print('❌ ERROR: userId no coincide con usuario autenticado.');
  throw Exception('userId no coincide con usuario autenticado');
}
```

### 2. Políticas RLS en Supabase ✅

Se creó el script SQL `politicas_rls_supabase.sql` con las políticas necesarias:

```sql
-- Habilitar RLS
ALTER TABLE public.user_rewards ENABLE ROW LEVEL SECURITY;

-- Política INSERT
CREATE POLICY "Usuarios pueden insertar sus propias recompensas"
ON public.user_rewards
FOR INSERT
WITH CHECK (user_id = auth.uid());

-- Política UPDATE
CREATE POLICY "Usuarios pueden actualizar sus propias recompensas"
ON public.user_rewards
FOR UPDATE
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Política SELECT
CREATE POLICY "Usuarios pueden leer sus propias recompensas"
ON public.user_rewards
FOR SELECT
USING (user_id = auth.uid());
```

## Pasos para Aplicar la Solución

### Paso 1: Ejecutar Script SQL en Supabase

1. Abre el SQL Editor en tu proyecto de Supabase
2. Copia y pega el contenido de `politicas_rls_supabase.sql`
3. Ejecuta el script
4. Verifica que las políticas se crearon correctamente:
   ```sql
   SELECT * FROM pg_policies WHERE tablename = 'user_rewards';
   ```

### Paso 2: Verificar Código Dart

El código ya está actualizado con:
- ✅ Verificación de autenticación antes de guardar
- ✅ Validación de que userId coincida con auth.uid()
- ✅ Logs de depuración mejorados

### Paso 3: Probar

1. Completa una sesión de campo energético de 2 minutos
2. Revisa la consola del navegador (F12 > Console)
3. Deberías ver:
   - ✅ "Usuario autenticado verificado: [userId]"
   - ✅ "Recompensas GUARDADAS en Supabase"
   - ✅ Los cristales ganados en el modal

## Verificación de Políticas RLS

Para verificar que las políticas están correctas en Supabase:

```sql
-- Ver todas las políticas de user_rewards
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'user_rewards';
```

Deberías ver 3 políticas:
1. **INSERT** con `WITH CHECK (user_id = auth.uid())`
2. **UPDATE** con `USING (user_id = auth.uid())` y `WITH CHECK (user_id = auth.uid())`
3. **SELECT** con `USING (user_id = auth.uid())`

## Notas Importantes

1. **El código Dart ya está correcto** - No necesita más cambios
2. **El problema está en Supabase** - Las políticas RLS deben estar configuradas
3. **La autenticación debe estar activa** - El usuario debe estar logueado cuando completa la sesión
4. **El userId debe coincidir** - El `user_id` en la tabla debe ser igual a `auth.uid()`

## Si Aún No Funciona

1. Verifica que el usuario esté autenticado:
   ```dart
   final user = SupabaseConfig.client.auth.currentUser;
   print('Usuario autenticado: ${user?.id}');
   ```

2. Verifica las políticas RLS en Supabase:
   - Ve a Authentication > Policies en el dashboard de Supabase
   - Verifica que las políticas estén activas para `user_rewards`

3. Revisa los logs de la consola:
   - Busca mensajes que empiecen con `[DIAGNÓSTICO]`
   - Verifica si hay errores de autenticación o RLS

