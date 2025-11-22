# 🔍 Análisis: Error 404 - Tabla `user_code_history` No Encontrada

## 🚨 Error Reportado

```
Request URL: https://whtiazgcxdnemrrgjjqf.supabase.co/rest/v1/user_code_history?select=code_id&user_id=eq.a0914eb8-0e31-4c0e-9ab6-47aa9569fccd
Status Code: 404 Not Found
```

## 📋 Diagnóstico

### Problema Identificado

La aplicación está intentando acceder a la tabla `user_code_history` en Supabase, pero esta tabla **NO EXISTE** en la base de datos. El error 404 indica que el endpoint de la API REST de Supabase no encuentra la tabla.

### Ubicaciones en el Código Donde se Usa Esta Tabla

#### 1. `lib/services/user_progress_service.dart`

**Línea 299-303:** Verificar si un código existe en el historial
```dart
final existing = await _supabase
    .from('user_code_history')
    .select()
    .eq('user_id', _authService.currentUser!.id)
    .eq('code_id', codeId)
    .maybeSingle();
```

**Línea 308-316:** Actualizar registro existente
```dart
await _supabase
    .from('user_code_history')
    .update({...})
    .eq('user_id', _authService.currentUser!.id)
    .eq('code_id', codeId);
```

**Línea 319-326:** Insertar nuevo registro
```dart
await _supabase.from('user_code_history').insert({
  'user_id': _authService.currentUser!.id,
  'code_id': codeId,
  'code_name': codeName,
  'usage_count': 1,
  'total_time_minutes': durationMinutes,
});
```

**Línea 410-414:** Obtener códigos más usados
```dart
final response = await _supabase
    .from('user_code_history')
    .select()
    .eq('user_id', _authService.currentUser!.id)
    .order('usage_count', ascending: false)
    .limit(limit);
```

#### 2. `lib/screens/evolucion/evolucion_screen.dart`

**Línea 107-109:** Contar códigos únicos explorados
```dart
final response = await supabase
    .from('user_code_history')
    .select('code_id')
    .eq('user_id', userId);
```

### Schema SQL Definido

El archivo `user_personalization_schema.sql` contiene la definición de la tabla:

```sql
CREATE TABLE IF NOT EXISTS user_code_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  code_id TEXT NOT NULL,
  code_name TEXT NOT NULL,
  usage_count INTEGER DEFAULT 1,
  last_used TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  total_time_minutes INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, code_id)
);
```

También incluye:
- Índices para optimización (líneas 82-83)
- Políticas RLS para seguridad (líneas 89, 120-127)

## 🔍 Causa Raíz

### Posibles Razones del Error 404

1. **Schema SQL No Ejecutado** ⚠️ (MÁS PROBABLE)
   - El archivo `user_personalization_schema.sql` no se ha ejecutado en Supabase
   - La tabla nunca se creó en la base de datos

2. **Schema Ejecutado Parcialmente**
   - El schema se ejecutó pero falló en la creación de esta tabla específica
   - Puede haber un error de sintaxis o dependencia no resuelta

3. **Tabla Eliminada Accidentalmente**
   - La tabla existía pero fue eliminada manualmente
   - O fue eliminada por un script de migración

4. **Problema con la Referencia a `users`**
   - La tabla `users` no existe o tiene un nombre diferente
   - El foreign key `REFERENCES users(id)` está causando un error

5. **Problema de Permisos**
   - El usuario de la base de datos no tiene permisos para crear tablas
   - Aunque esto normalmente daría un error diferente, no un 404

## 📊 Impacto en la Aplicación

### Funcionalidades Afectadas

1. **Historial de Códigos Usados**
   - ❌ No se puede registrar qué códigos ha usado el usuario
   - ❌ No se puede actualizar el contador de uso
   - ❌ No se puede rastrear el tiempo total usado por código

2. **Estadísticas de Evolución**
   - ❌ No se puede contar códigos explorados únicos
   - ❌ La pantalla de Evolución mostrará 0 códigos explorados
   - ❌ No se pueden mostrar códigos más usados

3. **Progreso del Usuario**
   - ⚠️ El progreso general puede funcionar, pero sin historial detallado
   - ⚠️ Las estadísticas estarán incompletas

### Comportamiento Actual

Cuando la app intenta acceder a `user_code_history`:
- La petición falla con error 404
- El código captura el error y retorna valores por defecto (lista vacía, 0, etc.)
- La app continúa funcionando pero sin esta funcionalidad
- Los logs mostrarán errores pero no crasheará la app

## ✅ Solución

### Paso 1: Verificar si la Tabla Existe

Ejecutar en Supabase SQL Editor:

```sql
SELECT EXISTS (
   SELECT FROM information_schema.tables 
   WHERE table_schema = 'public' 
   AND table_name = 'user_code_history'
);
```

Si retorna `false`, la tabla no existe.

### Paso 2: Verificar Dependencias

Antes de crear la tabla, verificar que existe la tabla `users`:

```sql
SELECT EXISTS (
   SELECT FROM information_schema.tables 
   WHERE table_schema = 'public' 
   AND table_name = 'users'
);
```

### Paso 3: Crear la Tabla

Ejecutar el schema completo en Supabase SQL Editor:

1. Ir a Supabase Dashboard
2. SQL Editor
3. Copiar y pegar el contenido de `user_personalization_schema.sql`
4. Ejecutar el script completo

O ejecutar solo la parte de `user_code_history`:

```sql
-- Crear tabla de historial de códigos usados
CREATE TABLE IF NOT EXISTS user_code_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  code_id TEXT NOT NULL,
  code_name TEXT NOT NULL,
  usage_count INTEGER DEFAULT 1,
  last_used TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  total_time_minutes INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, code_id)
);

-- Crear índices
CREATE INDEX IF NOT EXISTS idx_user_code_history_user_id ON user_code_history(user_id);
CREATE INDEX IF NOT EXISTS idx_user_code_history_last_used ON user_code_history(last_used);

-- Habilitar RLS
ALTER TABLE user_code_history ENABLE ROW LEVEL SECURITY;

-- Crear políticas RLS
CREATE POLICY "Users can view own code history" ON user_code_history
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own code history" ON user_code_history
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own code history" ON user_code_history
  FOR UPDATE USING (auth.uid() = user_id);
```

### Paso 4: Verificar Creación

Después de ejecutar el SQL, verificar:

```sql
-- Verificar que la tabla existe
SELECT * FROM user_code_history LIMIT 1;

-- Verificar políticas RLS
SELECT * FROM pg_policies WHERE tablename = 'user_code_history';

-- Verificar índices
SELECT * FROM pg_indexes WHERE tablename = 'user_code_history';
```

## 🔄 Verificación Adicional

### Otras Tablas Relacionadas

El schema `user_personalization_schema.sql` también define otras tablas que deberían existir:

- `user_favorites` - Favoritos del usuario
- `user_progress` - Progreso del usuario
- `user_sessions` - Sesiones del usuario
- `user_statistics` - Estadísticas del usuario

Verificar si estas tablas también existen:

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
  'user_favorites',
  'user_progress', 
  'user_sessions',
  'user_code_history',
  'user_statistics'
)
ORDER BY table_name;
```

Si alguna de estas tablas también falta, ejecutar el schema completo.

## 📝 Notas Importantes

1. **Backup Antes de Ejecutar**
   - Hacer backup de la base de datos antes de ejecutar scripts SQL
   - Especialmente si hay datos importantes

2. **Orden de Ejecución**
   - Si la tabla `users` no existe, crear primero esa tabla
   - Luego crear las tablas dependientes

3. **Políticas RLS**
   - Las políticas RLS son críticas para seguridad
   - Sin ellas, los usuarios no podrán acceder a sus propios datos
   - O peor, podrían acceder a datos de otros usuarios

4. **Índices**
   - Los índices mejoran el rendimiento de las consultas
   - Especialmente importante para `user_id` que se usa frecuentemente

## 🧪 Pruebas Después de la Solución

1. **Probar Login**
   - Iniciar sesión en la app
   - Verificar que no hay errores 404

2. **Probar Uso de Código**
   - Usar un código en pilotaje
   - Verificar que se registra en `user_code_history`

3. **Probar Pantalla de Evolución**
   - Ir a la pantalla de Evolución
   - Verificar que muestra códigos explorados correctamente

4. **Verificar Logs**
   - Revisar logs de la app para confirmar que no hay más errores 404
   - Verificar que las consultas a `user_code_history` funcionan

## 🚨 Prevención Futura

1. **Documentar Schemas**
   - Mantener un registro de qué schemas se han ejecutado
   - Crear un archivo de migraciones

2. **Scripts de Verificación**
   - Crear scripts SQL para verificar que todas las tablas existen
   - Ejecutar antes de cada deploy

3. **Manejo de Errores Mejorado**
   - Agregar manejo de errores más descriptivo en el código
   - Mostrar mensajes claros cuando falten tablas

---

**Fecha del Análisis:** Noviembre 2025  
**Versión del Documento:** 1.0  
**Estado:** ⚠️ Requiere Acción - Tabla no existe en Supabase

