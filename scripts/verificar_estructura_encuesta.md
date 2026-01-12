# Verificación: Estructura de Datos de la Encuesta

## 📋 CONFIRMACIÓN DE DATOS GUARDADOS

### ✅ Datos que se guardan en la encuesta:

**Archivo:** `lib/screens/onboarding/user_assessment_screen.dart` (línea 447)

```dart
final assessmentData = {
  'knowledge_level': _knowledgeLevel,        // Nivel de conocimiento
  'goals': _goals,                          // Objetivos (lista)
  'experience_level': _experienceLevel,     // Nivel de experiencia
  'time_available': _timeAvailable,         // Tiempo disponible
  'preferences': _preferences,              // Preferencias (lista)
  'motivation': _motivation,                // Motivación principal
  'completed_at': DateTime.now().toIso8601String(),  // Fecha de completado
  'is_complete': true,                      // Flag de completado
};
```

### ✅ ID del Usuario:

**Archivo:** `lib/services/user_progress_service.dart` (línea 514)

```dart
await _supabase.from('user_assessments').insert({
  'user_id': _authService.currentUser!.id,  // ✅ ID del usuario
  'assessment_data': assessmentData,         // ✅ Todas las respuestas
  'created_at': DateTime.now().toIso8601String(),
});
```

## 📊 ESTRUCTURA EN LA BASE DE DATOS

### Tabla: `user_assessments`

```sql
CREATE TABLE user_assessments (
  id UUID PRIMARY KEY,                      -- ID único del registro
  user_id UUID NOT NULL,                    -- ✅ ID del usuario (FK a auth.users)
  assessment_data JSONB NOT NULL,            -- ✅ Todas las respuestas en JSON
  created_at TIMESTAMP,                     -- Fecha de creación
  updated_at TIMESTAMP                      -- Fecha de actualización
);
```

### Estructura de `assessment_data` (JSONB):

```json
{
  "knowledge_level": "principiante|intermedio|avanzado",
  "goals": ["amor y relaciones", "salud y bienestar", ...],
  "experience_level": "nunca|poco|regular|experto",
  "time_available": "5-10 minutos|15-30 minutos|...",
  "preferences": ["visualización", "repetición", ...],
  "motivation": "curiosidad|necesidad|crecimiento|bienestar",
  "completed_at": "2025-01-05T08:00:00.000Z",
  "is_complete": true
}
```

## 📈 USO PARA ESTADÍSTICAS

### Queries útiles para estadísticas:

#### 1. Contar total de usuarios que completaron la encuesta:
```sql
SELECT COUNT(DISTINCT user_id) as total_usuarios
FROM user_assessments;
```

#### 2. Distribución por nivel de conocimiento:
```sql
SELECT 
  assessment_data->>'knowledge_level' as nivel,
  COUNT(*) as cantidad
FROM user_assessments
GROUP BY assessment_data->>'knowledge_level'
ORDER BY cantidad DESC;
```

#### 3. Distribución por motivación:
```sql
SELECT 
  assessment_data->>'motivation' as motivacion,
  COUNT(*) as cantidad
FROM user_assessments
GROUP BY assessment_data->>'motivation'
ORDER BY cantidad DESC;
```

#### 4. Objetivos más populares:
```sql
SELECT 
  objetivo,
  COUNT(*) as cantidad
FROM user_assessments,
  jsonb_array_elements_text(assessment_data->'goals') as objetivo
GROUP BY objetivo
ORDER BY cantidad DESC;
```

#### 5. Preferencias más comunes:
```sql
SELECT 
  preferencia,
  COUNT(*) as cantidad
FROM user_assessments,
  jsonb_array_elements_text(assessment_data->'preferences') as preferencia
GROUP BY preferencia
ORDER BY cantidad DESC;
```

#### 6. Encuestas por fecha:
```sql
SELECT 
  DATE(created_at) as fecha,
  COUNT(*) as cantidad
FROM user_assessments
GROUP BY DATE(created_at)
ORDER BY fecha DESC;
```

#### 7. Usuarios con sus respuestas completas:
```sql
SELECT 
  user_id,
  assessment_data,
  created_at
FROM user_assessments
ORDER BY created_at DESC;
```

## ✅ CONFIRMACIÓN FINAL

**SÍ, la encuesta se guarda con:**
- ✅ **ID del usuario** (`user_id`) - Para identificar quién completó la encuesta
- ✅ **Todas las respuestas** (`assessment_data`) - En formato JSONB para fácil consulta
- ✅ **Fecha de creación** (`created_at`) - Para análisis temporal
- ✅ **Flag de completado** (`is_complete`) - Para validación

**Todo está listo para generar estadísticas.**



