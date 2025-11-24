# 🚨 PASOS PARA SOLUCIONAR LOS ERRORES 401 Y 42501

## ⚠️ PROBLEMA ACTUAL

Los errores en la consola muestran:
- `401 (Unauthorized)` 
- `new row violates row-level security policy for table "user_actions"`

**Esto significa que las políticas RLS NO están configuradas en Supabase.**

## ✅ SOLUCIÓN: Ejecutar Script SQL en Supabase

### Paso 1: Abrir Supabase Dashboard
1. Ve a https://app.supabase.com
2. Inicia sesión con tu cuenta
3. Selecciona tu proyecto

### Paso 2: Abrir SQL Editor
1. En el menú lateral izquierdo, busca **"SQL Editor"**
2. Haz clic en **"SQL Editor"**
3. Haz clic en **"New Query"** (botón verde en la parte superior)

### Paso 3: Copiar y Pegar el Script
1. Abre el archivo: `politicas_rls_completas.sql`
2. **Copia TODO el contenido** del archivo (desde `-- ============================================` hasta el final)
3. Pégalo en el editor SQL de Supabase

### Paso 4: Ejecutar el Script
1. Haz clic en el botón **"Run"** (o presiona `Ctrl+Enter` en Windows/Linux o `Cmd+Enter` en Mac)
2. Espera a que termine la ejecución (debería tomar menos de 1 segundo)
3. Verifica que aparezca un mensaje de éxito: **"Success. No rows returned"**

### Paso 5: Verificar que Funcionó
Ejecuta esta consulta en el SQL Editor para verificar:

```sql
SELECT 
    tablename,
    policyname,
    cmd
FROM pg_policies 
WHERE tablename IN ('user_rewards', 'user_actions')
ORDER BY tablename, cmd;
```

**Deberías ver 6 políticas:**
- 3 para `user_rewards` (INSERT, UPDATE, SELECT)
- 3 para `user_actions` (INSERT, UPDATE, SELECT)

### Paso 6: Probar la Aplicación
1. Recarga la página de la aplicación en Chrome (F5)
2. Los errores 401 y 42501 deberían desaparecer
3. Las acciones deberían guardarse correctamente

## 📋 Script a Ejecutar

El archivo `politicas_rls_completas.sql` contiene todo lo necesario. Solo cópialo y pégalo en Supabase.

## 🔍 Si Aún Hay Errores

1. **Verifica que el usuario esté autenticado:**
   - Debes estar logueado en la aplicación
   - Verifica en la consola que no haya errores de autenticación

2. **Verifica que RLS esté habilitado:**
   ```sql
   SELECT tablename, rowsecurity 
   FROM pg_tables 
   WHERE schemaname = 'public' 
   AND tablename IN ('user_rewards', 'user_actions');
   ```
   Debería mostrar `true` para `rowsecurity` en ambas tablas.

3. **Verifica las políticas:**
   ```sql
   SELECT * FROM pg_policies 
   WHERE tablename = 'user_actions';
   ```
   Deberías ver las 3 políticas creadas.

## ⚡ IMPORTANTE

**El código Dart está correcto.** El problema es solo la configuración de Supabase. Una vez que ejecutes el script SQL, los errores desaparecerán automáticamente.

