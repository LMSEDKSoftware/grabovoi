# 🔍 Diagnóstico del Error 42501

## Error Actual
```
PostgrestException (message: new row violates row-level security policy for table "user_actions", code: 42501)
```

## Payload Enviado
```json
{
  "user_id": "cd005147-55f2-49c7-830c-b1464acb68c7",
  "challenge_id": null,
  "action_type": "sesionPilotaje",
  "action_data": {
    "codeId": "714_813_819",
    "codeName": "714_813_819",
    "duration": 5,
    "metadata": {},
    "timestamp": "2025-11-13T07:43:39.078"
  },
  "recorded_at": "2025-11-13T07:43:39.078"
}
```

## Posibles Causas

### 1. El `user_id` no coincide con `auth.uid()`
**Problema:** El `user_id` en el payload (`cd005147-55f2-49c7-830c-b1464acb68c7`) puede no ser igual al `auth.uid()` del usuario autenticado en Supabase.

**Solución:**
- Verifica en la consola de Chrome qué `user_id` tiene el usuario autenticado
- Compara con el `user_id` que se está enviando en el payload
- Deben ser idénticos

### 2. El usuario no está autenticado correctamente
**Problema:** Aunque el código dice que el usuario está autenticado, Supabase puede no reconocerlo.

**Solución:**
- Verifica que el token de autenticación sea válido
- Cierra sesión y vuelve a iniciar sesión
- Verifica que `auth.uid()` retorne un valor en Supabase

### 3. Las políticas RLS no están aplicadas correctamente
**Problema:** Aunque las políticas existen, pueden no estar activas o tener la condición incorrecta.

**Solución:**
- Ejecuta el script `verificar_politicas_rls.sql` en Supabase
- Verifica que las políticas tengan `WITH CHECK (user_id = auth.uid())`
- Verifica que RLS esté habilitado en la tabla

## Pasos para Diagnosticar

### Paso 1: Verificar el usuario autenticado
En la consola de Chrome, busca:
```javascript
// El usuario autenticado debería tener este ID
console.log('User ID:', Supabase.instance.client.auth.currentUser?.id);
```

### Paso 2: Verificar las políticas RLS
Ejecuta en Supabase SQL Editor:
```sql
SELECT tablename, policyname, cmd, with_check
FROM pg_policies 
WHERE tablename = 'user_actions';
```

Deberías ver:
- `cmd`: `INSERT`
- `with_check`: `(user_id = auth.uid())`

### Paso 3: Verificar que el user_id coincida
En la consola de Chrome, agrega este log temporal en el código:
```dart
print('🔍 [DEBUG] user_id enviado: ${_authService.currentUser!.id}');
print('🔍 [DEBUG] auth.uid() en Supabase: ${SupabaseConfig.client.auth.currentUser?.id}');
```

Ambos deben ser iguales.

## Solución Temporal para Testing

Si necesitas hacer pruebas rápidas, puedes crear una política más permisiva temporalmente:

```sql
-- SOLO PARA TESTING - NO USAR EN PRODUCCIÓN
DROP POLICY IF EXISTS "Usuarios pueden insertar sus propias acciones" ON public.user_actions;

CREATE POLICY "Usuarios pueden insertar sus propias acciones TEMP"
ON public.user_actions
FOR INSERT
TO authenticated
WITH CHECK (true);  -- Permite insertar a cualquier usuario autenticado
```

**⚠️ IMPORTANTE:** Esta política es insegura y solo debe usarse para testing. Después de identificar el problema, vuelve a crear la política correcta.

## Verificación Final

Después de aplicar las correcciones, verifica:

1. ✅ El `user_id` en el payload coincide con `auth.uid()`
2. ✅ Las políticas RLS tienen la condición correcta
3. ✅ El usuario está autenticado en Supabase
4. ✅ No hay errores 401 o 42501 en la consola

