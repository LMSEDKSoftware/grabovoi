# Análisis: Encuesta Inicial - Funcionamiento Actual

## 📋 RESUMEN EJECUTIVO

La encuesta inicial está implementada y debería funcionar correctamente. El usuario solo debería llenarla una vez y no volver a verla. Sin embargo, hay que verificar que la tabla en la DB exista.

## ✅ SCHEMA DE BASE DE DATOS

### Tabla: `user_assessments`
**Archivo:** `database/user_assessment_schema.sql`

```sql
CREATE TABLE IF NOT EXISTS user_assessments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  assessment_data JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Características:**
- ✅ RLS habilitado
- ✅ Políticas de seguridad configuradas
- ✅ Índices para búsquedas por usuario y fecha
- ✅ Trigger para actualizar `updated_at` automáticamente

### Tabla: `user_progress`
**Archivo:** `database/user_personalization_schema.sql`

También se guarda en `user_progress.preferences` con:
- `assessment_completed: true`
- `assessment_date: fecha`
- Todos los campos de la evaluación

## 🔄 FLUJO DE GUARDADO

### 1. Cuando el usuario completa la encuesta
**Archivo:** `lib/screens/onboarding/user_assessment_screen.dart` (línea 438)

```dart
await _progressService.saveUserAssessment(assessmentData);
```

### 2. Guardado en múltiples lugares
**Archivo:** `lib/services/user_progress_service.dart` (línea 505)

Se guarda en **3 lugares** (en orden de prioridad):

1. **SharedPreferences** (local, siempre)
   - Clave: `'user_assessment'`
   - Formato: JSON stringificado
   - **Propósito:** Fallback local si falla la DB

2. **Tabla `user_assessments`** (Supabase)
   - Campo: `assessment_data` (JSONB)
   - **Propósito:** Almacenamiento principal de la evaluación

3. **Tabla `user_progress.preferences`** (Supabase)
   - Campo: `preferences` (JSONB)
   - Incluye: `assessment_completed: true`
   - **Propósito:** Datos de preferencias del usuario

## 🔍 FLUJO DE VERIFICACIÓN

### 1. Verificación en AuthWrapper
**Archivo:** `lib/widgets/auth_wrapper.dart` (línea 69)

```dart
final assessment = await _progressService.getUserAssessment();
final needsAssessment = assessment == null || !_isAssessmentComplete(assessment);
```

### 2. Búsqueda de la evaluación
**Archivo:** `lib/services/user_progress_service.dart` (línea 600)

Busca en **3 lugares** (en orden de prioridad):

1. **`user_progress.preferences`**
   - Verifica: `preferences['assessment_completed'] == true`
   - Si existe, reconstruye `assessmentData` con `is_complete: true`

2. **Tabla `user_assessments`**
   - Query: `SELECT * FROM user_assessments WHERE user_id = ? ORDER BY created_at DESC LIMIT 1`
   - Si existe, agrega `is_complete: true` al resultado

3. **SharedPreferences** (fallback)
   - Clave: `'user_assessment'`
   - Si existe, agrega `is_complete: true` al resultado

### 3. Validación de completitud
**Archivo:** `lib/widgets/auth_wrapper.dart` (línea 142)

```dart
bool _isAssessmentComplete(Map<String, dynamic> assessment) {
  // 1. Verificar flag is_complete (prioritario)
  if (assessment['is_complete'] == true) {
    return true;
  }
  
  // 2. Verificar que todos los campos requeridos estén presentes
  // - knowledge_level
  // - goals (no vacío)
  // - experience_level
  // - time_available
  // - preferences (no vacío)
  // - motivation
  
  // 3. Verificar que is_complete == true
  if (assessment['is_complete'] != true) {
    return false;
  }
  
  return true;
}
```

## ⚠️ POSIBLES PROBLEMAS

### 1. Tabla `user_assessments` puede no existir
**Ubicación:** `lib/services/user_progress_service.dart` (línea 520)

```dart
catch (e) {
  print('⚠️ No se pudo guardar en user_assessments (tabla puede no existir o error de RLS): $e');
  // Continuar con el guardado en user_progress que es más importante
}
```

**Solución:** El código maneja este caso y continúa guardando en `user_progress`, pero es mejor verificar que la tabla exista.

### 2. Inconsistencia en verificación
**Ubicación:** `lib/services/user_progress_service.dart` (línea 713)

Hay una función `_isAssessmentComplete()` en `user_progress_service.dart` que también verifica, pero `auth_wrapper.dart` tiene su propia versión. Ambas son similares pero deberían ser consistentes.

### 3. Múltiples evaluaciones
**Ubicación:** `lib/services/user_progress_service.dart` (línea 514)

El código hace `INSERT` en `user_assessments`, lo que permite múltiples evaluaciones por usuario. Debería ser `UPSERT` para actualizar si ya existe.

## ✅ RECOMENDACIONES

### 1. Verificar que la tabla existe en Supabase
```sql
-- Ejecutar en Supabase SQL Editor
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'user_assessments'
);
```

### 2. Cambiar INSERT a UPSERT en user_assessments
**Archivo:** `lib/services/user_progress_service.dart` (línea 514)

```dart
// Cambiar de:
await _supabase.from('user_assessments').insert({...});

// A:
await _supabase.from('user_assessments').upsert({
  'user_id': _authService.currentUser!.id,
  'assessment_data': assessmentData,
  'updated_at': DateTime.now().toIso8601String(),
}, onConflict: 'user_id');
```

**Nota:** Esto requiere un constraint UNIQUE en `user_id` en la tabla.

### 3. Agregar constraint UNIQUE en user_id
**Archivo:** `database/user_assessment_schema.sql`

```sql
-- Agregar constraint para evitar múltiples evaluaciones
ALTER TABLE user_assessments 
ADD CONSTRAINT user_assessments_user_id_unique UNIQUE (user_id);
```

## 📊 ESTADO ACTUAL

✅ **Funciona correctamente si:**
- La tabla `user_progress` existe (más importante)
- SharedPreferences funciona (siempre funciona)

⚠️ **Puede fallar si:**
- La tabla `user_assessments` no existe (pero tiene fallback)
- Hay múltiples evaluaciones por usuario (pero se usa la más reciente)

## 🔧 VERIFICACIÓN RÁPIDA

Para verificar si un usuario ya completó la encuesta:

```sql
-- Verificar en user_progress
SELECT preferences->>'assessment_completed' as completed
FROM user_progress
WHERE user_id = 'USER_ID_AQUI';

-- Verificar en user_assessments
SELECT assessment_data->>'is_complete' as completed
FROM user_assessments
WHERE user_id = 'USER_ID_AQUI';
```



