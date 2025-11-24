# 🔍 Análisis: Múltiples Consultas a `user_code_history`

## 📊 Problema Identificado

La aplicación está realizando **demasiadas consultas** a la tabla `user_code_history`, lo cual puede:
- ⚠️ Consumir recursos innecesarios
- ⚠️ Ralentizar la aplicación
- ⚠️ Generar costos innecesarios en Supabase
- ⚠️ Causar problemas de rendimiento

## 🔍 Ubicaciones de las Consultas

### 1. **Pantalla de Evolución** (`lib/screens/evolucion/evolucion_screen.dart`)

#### Problema Principal: `FutureBuilder` sin Caché

**Línea 346:** Se usa un `FutureBuilder` que ejecuta la consulta cada vez que el widget se reconstruye:

```dart
FutureBuilder<int>(
  future: _getExploredCodesCount(),
  builder: (context, snapshot) {
    final count = snapshot.data ?? 0;
    return _buildProgressRow('Códigos Explorados', '$count', Icons.explore);
  },
),
```

**Problemas:**
1. ❌ El `FutureBuilder` se ejecuta en CADA rebuild del widget
2. ❌ No hay caché del resultado
3. ❌ La consulta se ejecuta incluso cuando no es necesario
4. ❌ Si el usuario navega y vuelve a esta pantalla, se ejecuta de nuevo

#### Consulta Ineficiente

**Línea 106-109:** La consulta trae TODOS los registros y luego cuenta en el cliente:

```dart
final response = await supabase
    .from('user_code_history')
    .select('code_id')
    .eq('user_id', userId);

// Obtener códigos únicos
final uniqueCodes = <String>{};
for (final row in response) {
  final codeId = row['code_id'] as String?;
  if (codeId != null && codeId.isNotEmpty) {
    uniqueCodes.add(codeId);
  }
}
return uniqueCodes.length;
```

**Problemas:**
1. ❌ Trae TODOS los registros del usuario (pueden ser cientos o miles)
2. ❌ Hace el conteo en el cliente en lugar de en la base de datos
3. ❌ No usa agregación SQL (COUNT DISTINCT)
4. ❌ Consume más ancho de banda y memoria

### 2. **Servicio de Progreso** (`lib/services/user_progress_service.dart`)

#### Consulta de Códigos Más Usados

**Línea 410-414:** Consulta para obtener códigos más usados:

```dart
final response = await _supabase
    .from('user_code_history')
    .select()
    .eq('user_id', _authService.currentUser!.id)
    .order('usage_count', ascending: false)
    .limit(limit);
```

**Esta consulta está bien optimizada:**
- ✅ Usa `limit` para limitar resultados
- ✅ Usa `order` para ordenar
- ✅ Solo trae los datos necesarios

## 📋 Para Qué se Usa Cada Consulta

### 1. `_getExploredCodesCount()` - Contar Códigos Explorados

**Propósito:** Mostrar cuántos códigos únicos ha explorado/usado el usuario

**Dónde se muestra:** Pantalla de Evolución, en la tarjeta "Progreso General"

**Frecuencia de uso:**
- Cada vez que se abre la pantalla de Evolución
- Cada vez que el widget se reconstruye (puede ser muy frecuente)
- Cuando la app vuelve al primer plano (`didChangeAppLifecycleState`)

**Problema:** Se ejecuta demasiado frecuentemente sin necesidad

### 2. `getMostUsedCodes()` - Códigos Más Usados

**Propósito:** Obtener los códigos que el usuario ha usado más veces

**Dónde se usa:** Probablemente en estadísticas o recomendaciones

**Frecuencia de uso:** Menos frecuente, solo cuando se necesita mostrar esta información

**Estado:** ✅ Optimizada correctamente

### 3. `_updateCodeHistory()` - Actualizar Historial

**Propósito:** Registrar cuando un usuario usa un código

**Dónde se usa:** Cuando se completa una sesión de pilotaje o repetición

**Frecuencia de uso:** Solo cuando el usuario usa un código (acción del usuario)

**Estado:** ✅ Normal, es una escritura necesaria

## 🔄 Revisión del Schema Completo

### Tablas Relacionadas con Historial de Códigos

#### 1. `user_code_history` ✅ (La que acabamos de crear)
```sql
CREATE TABLE public.user_code_history (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  code_id text NOT NULL,
  code_name text NOT NULL,
  usage_count integer DEFAULT 1,
  last_used timestamp with time zone DEFAULT now(),
  total_time_minutes integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  ...
);
```
**Propósito:** Historial detallado de códigos usados por usuario
**Estado:** ✅ Existe y está correcta

#### 2. `user_actions` ✅ (Ya existe)
```sql
CREATE TABLE public.user_actions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  challenge_id uuid,
  action_type text NOT NULL,
  action_data jsonb DEFAULT '{}'::jsonb,
  recorded_at timestamp with time zone DEFAULT now(),
  ...
);
```
**Propósito:** Registro general de acciones del usuario (incluyendo uso de códigos)
**Relación:** Puede contener información de códigos en `action_data` como JSON
**Estado:** ✅ Existe, no es duplicado, es complementario

#### 3. `usuario_progreso` ✅ (Ya existe)
```sql
CREATE TABLE public.usuario_progreso (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE,
  dias_consecutivos integer DEFAULT 0,
  total_pilotajes integer DEFAULT 0,
  nivel_energetico integer DEFAULT 1,
  ultimo_pilotaje timestamp with time zone DEFAULT now(),
  ...
);
```
**Propósito:** Progreso general del usuario (agregado)
**Relación:** No es duplicado, es un resumen agregado
**Estado:** ✅ Existe, no es duplicado

### Conclusión del Schema

✅ **No hay duplicados:** Cada tabla tiene un propósito específico:
- `user_code_history` = Historial detallado por código
- `user_actions` = Log general de acciones
- `usuario_progreso` = Resumen agregado del progreso

## ✅ Soluciones Recomendadas

### Solución 1: Optimizar la Consulta de Conteo

**Cambiar de:** Traer todos los registros y contar en cliente
**A:** Usar agregación SQL en la base de datos

```dart
// ❌ ACTUAL (Ineficiente)
final response = await supabase
    .from('user_code_history')
    .select('code_id')
    .eq('user_id', userId);
// ... contar en cliente

// ✅ OPTIMIZADO (Eficiente)
final response = await supabase
    .from('user_code_history')
    .select('code_id')
    .eq('user_id', userId);
    
// Usar COUNT DISTINCT en SQL (si Supabase lo soporta)
// O mejor aún, usar una función agregada
```

**Mejor solución:** Crear una función en Supabase o usar RPC:

```sql
CREATE OR REPLACE FUNCTION get_explored_codes_count(p_user_id uuid)
RETURNS integer AS $$
  SELECT COUNT(DISTINCT code_id) 
  FROM user_code_history 
  WHERE user_id = p_user_id;
$$ LANGUAGE sql SECURITY DEFINER;
```

Luego en Dart:
```dart
final response = await supabase.rpc('get_explored_codes_count', {
  'p_user_id': userId
});
final count = response as int;
```

### Solución 2: Implementar Caché

**Agregar caché en memoria** para evitar consultas repetidas:

```dart
class _EvolucionScreenState extends State<EvolucionScreen> {
  int? _cachedExploredCodesCount;
  DateTime? _cacheTimestamp;
  static const _cacheDuration = Duration(minutes: 5);

  Future<int> _getExploredCodesCount() async {
    // Usar caché si está disponible y no ha expirado
    if (_cachedExploredCodesCount != null && 
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
      return _cachedExploredCodesCount!;
    }

    // ... consulta a Supabase ...
    
    // Guardar en caché
    _cachedExploredCodesCount = uniqueCodes.length;
    _cacheTimestamp = DateTime.now();
    
    return _cachedExploredCodesCount!;
  }
}
```

### Solución 3: Cargar una Sola Vez en `initState`

**En lugar de usar `FutureBuilder`**, cargar el dato una vez:

```dart
@override
void initState() {
  super.initState();
  _loadExploredCodesCount();
}

int _exploredCodesCount = 0;

Future<void> _loadExploredCodesCount() async {
  final count = await _getExploredCodesCount();
  if (mounted) {
    setState(() {
      _exploredCodesCount = count;
    });
  }
}
```

Y en el build:
```dart
_buildProgressRow('Códigos Explorados', '$_exploredCodesCount', Icons.explore),
```

### Solución 4: Usar `StreamBuilder` con Realtime (Opcional)

Si necesitas actualizaciones en tiempo real, usar Supabase Realtime:

```dart
StreamBuilder<List<Map<String, dynamic>>>(
  stream: supabase
      .from('user_code_history')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('last_used', ascending: false),
  builder: (context, snapshot) {
    // ... procesar datos
  },
)
```

## 📊 Comparación de Rendimiento

### Consulta Actual (Ineficiente)
- **Datos transferidos:** Todos los `code_id` del usuario (pueden ser 100-1000+ registros)
- **Procesamiento:** En el cliente (Dart)
- **Frecuencia:** Cada rebuild del widget
- **Tiempo estimado:** 100-500ms dependiendo de la cantidad de registros

### Consulta Optimizada
- **Datos transferidos:** Solo un número (COUNT)
- **Procesamiento:** En la base de datos (PostgreSQL)
- **Frecuencia:** Una vez con caché
- **Tiempo estimado:** 10-50ms

**Mejora estimada:** 10-50x más rápido

## 🎯 Recomendaciones Prioritarias

1. **URGENTE:** Implementar caché para `_getExploredCodesCount()`
2. **IMPORTANTE:** Optimizar la consulta usando COUNT DISTINCT en SQL
3. **RECOMENDADO:** Cambiar `FutureBuilder` por carga única en `initState`
4. **OPCIONAL:** Crear función RPC en Supabase para conteo optimizado

## 📝 Resumen

**Problema:** La consulta a `user_code_history` se ejecuta demasiado frecuentemente y de forma ineficiente.

**Causa:** `FutureBuilder` sin caché + consulta que trae todos los registros.

**Solución:** Caché + optimización de consulta + carga única.

**Schema:** ✅ No hay duplicados, todas las tablas tienen propósito específico.

---

**Fecha del Análisis:** Noviembre 2025  
**Versión del Documento:** 1.0

