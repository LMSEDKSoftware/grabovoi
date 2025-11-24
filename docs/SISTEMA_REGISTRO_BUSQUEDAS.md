# 📊 Sistema de Registro de Búsquedas Profundas

## 🗄️ Nueva Tabla: `busquedas_profundas`

### **Estructura de la Tabla:**
```sql
CREATE TABLE busquedas_profundas (
    id SERIAL PRIMARY KEY,
    codigo_buscado VARCHAR(50) NOT NULL,
    usuario_id UUID REFERENCES auth.users(id),
    prompt_system TEXT NOT NULL,
    prompt_user TEXT NOT NULL,
    respuesta_ia TEXT,
    codigo_encontrado BOOLEAN DEFAULT FALSE,
    codigo_guardado BOOLEAN DEFAULT FALSE,
    error_message TEXT,
    fecha_busqueda TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    duracion_ms INTEGER,
    modelo_ia VARCHAR(50) DEFAULT 'gpt-3.5-turbo',
    tokens_usados INTEGER,
    costo_estimado DECIMAL(10, 6)
);
```

### **Campos Explicados:**
- **`codigo_buscado`**: El código numérico que el usuario buscó (ej: "52183", "111", "888")
- **`usuario_id`**: ID del usuario que realizó la búsqueda (conectado con auth.users)
- **`prompt_system`**: Prompt del sistema enviado a la IA
- **`prompt_user`**: Prompt específico del usuario enviado a la IA
- **`respuesta_ia`**: Respuesta completa de la IA (JSON)
- **`codigo_encontrado`**: Si la IA encontró información del código
- **`codigo_guardado`**: Si el código se guardó en la base de datos
- **`error_message`**: Mensaje de error si algo falló
- **`fecha_busqueda`**: Fecha y hora exacta de la búsqueda
- **`duracion_ms`**: Duración de la búsqueda en milisegundos
- **`modelo_ia`**: Modelo de IA utilizado (gpt-3.5-turbo, etc.)
- **`tokens_usados`**: Número de tokens utilizados (estimado)
- **`costo_estimado`**: Costo estimado de la búsqueda en USD

## 🔧 Archivos Creados/Modificados

### 1. **`busquedas_profundas_schema.sql`** ✅
- Script SQL para crear la tabla
- Índices para optimizar consultas
- Políticas RLS para seguridad
- Comentarios explicativos

### 2. **`lib/models/busqueda_profunda_model.dart`** ✅
- Modelo de datos para búsquedas profundas
- Métodos `fromJson()` y `toJson()`
- Método `copyWith()` para actualizaciones
- Validaciones y tipos de datos

### 3. **`lib/services/busquedas_profundas_service.dart`** ✅
- Servicio para manejar búsquedas profundas
- Métodos para guardar, actualizar y consultar
- Estadísticas y análisis de búsquedas
- Códigos más buscados

### 4. **`lib/screens/pilotaje/quantum_pilotage_screen.dart`** ✅
- Integración del sistema de registro
- Registro automático de cada búsqueda
- Cálculo de duración, tokens y costos
- Manejo de errores y actualizaciones

## 🔍 Flujo de Registro de Búsquedas

### **Paso 1: Inicio de Búsqueda** 🚀
```dart
// Usuario busca código "52183"
_inicioBusqueda = DateTime.now();

// Crear registro inicial
final busqueda = BusquedaProfunda(
  codigoBuscado: "52183",
  usuarioId: "uuid-del-usuario",
  promptSystem: "Eres un experto en códigos...",
  promptUser: "Analiza el código numérico de Grabovoi: 52183...",
  fechaBusqueda: DateTime.now(),
  modeloIa: "gpt-3.5-turbo",
);

// Guardar en BD
_busquedaActualId = await BusquedasProfundasService.guardarBusquedaProfunda(busqueda);
```

### **Paso 2: Búsqueda con IA** 🤖
```dart
// Llamar a OpenAI
final resultado = await _buscarConOpenAI(codigo);

// Calcular métricas
final duracion = DateTime.now().difference(_inicioBusqueda!).inMilliseconds;
final tokens = _calcularTokensEstimados(codigo, resultado);
final costo = _calcularCostoEstimado(codigo, resultado);
```

### **Paso 3: Actualización del Registro** ✅
```dart
// Actualizar con resultado
final busquedaActualizada = busqueda.copyWith(
  respuestaIa: '{"nombre": "Transformación Personal", ...}',
  codigoEncontrado: true,
  codigoGuardado: true,
  duracionMs: duracion,
  tokensUsados: tokens,
  costoEstimado: costo,
);

await BusquedasProfundasService.actualizarBusquedaProfunda(_busquedaActualId!, busquedaActualizada);
```

## 📊 Funcionalidades del Sistema

### **1. Registro Automático** ✅
- Cada búsqueda profunda se registra automáticamente
- Se guarda el usuario, fecha, hora y prompts
- Se calculan métricas de rendimiento

### **2. Seguimiento de Resultados** ✅
- Si la IA encontró el código
- Si el código se guardó en la base de datos
- Mensajes de error si algo falló

### **3. Métricas de Rendimiento** ✅
- Duración de cada búsqueda
- Tokens utilizados (estimado)
- Costo estimado por búsqueda
- Tasa de éxito de búsquedas

### **4. Análisis de Datos** ✅
- Códigos más buscados
- Estadísticas por usuario
- Análisis de costos
- Patrones de uso

## 🔍 Consultas Útiles

### **Búsquedas por Usuario:**
```sql
SELECT * FROM busquedas_profundas 
WHERE usuario_id = 'uuid-del-usuario' 
ORDER BY fecha_busqueda DESC;
```

### **Códigos Más Buscados:**
```sql
SELECT codigo_buscado, COUNT(*) as frecuencia 
FROM busquedas_profundas 
GROUP BY codigo_buscado 
ORDER BY frecuencia DESC;
```

### **Estadísticas de Éxito:**
```sql
SELECT 
  COUNT(*) as total_busquedas,
  SUM(CASE WHEN codigo_encontrado THEN 1 ELSE 0 END) as encontrados,
  SUM(CASE WHEN codigo_guardado THEN 1 ELSE 0 END) as guardados,
  AVG(duracion_ms) as duracion_promedio
FROM busquedas_profundas;
```

### **Análisis de Costos:**
```sql
SELECT 
  SUM(costo_estimado) as costo_total,
  AVG(costo_estimado) as costo_promedio,
  SUM(tokens_usados) as tokens_totales
FROM busquedas_profundas;
```

## 🚀 Cómo Usar el Sistema

### **1. Ejecutar Script SQL:**
```bash
# En Supabase SQL Editor
psql -f busquedas_profundas_schema.sql
```

### **2. Verificar Registros:**
```dart
// Obtener búsquedas del usuario actual
final busquedas = await BusquedasProfundasService.getBusquedasPorUsuario(userId);

// Obtener estadísticas
final stats = await BusquedasProfundasService.getEstadisticas();

// Obtener códigos más buscados
final masBuscados = await BusquedasProfundasService.getCodigosMasBuscados();
```

### **3. Monitorear en Tiempo Real:**
- Los registros se crean automáticamente
- Se pueden consultar en Supabase Dashboard
- Se pueden exportar para análisis

## 🎯 Beneficios del Sistema

### **Para el Usuario:**
- Historial de búsquedas realizadas
- Seguimiento de códigos encontrados
- Transparencia en el uso de IA

### **Para el Administrador:**
- Análisis de uso de la aplicación
- Control de costos de OpenAI
- Identificación de códigos populares
- Optimización del sistema

### **Para el Desarrollo:**
- Debug de problemas de búsqueda
- Optimización de prompts
- Mejora de la experiencia de usuario
- Análisis de rendimiento

## 📝 Notas Importantes

1. **RLS Habilitado**: Los usuarios solo ven sus propias búsquedas
2. **Datos Sensibles**: Los prompts contienen información del usuario
3. **Costo Estimado**: Es una aproximación, no el costo real
4. **Tokens Estimados**: Cálculo simple basado en caracteres
5. **Privacidad**: Los datos se almacenan de forma segura en Supabase

**Fecha de implementación:** 19 de Octubre de 2025
**Estado:** ✅ SISTEMA COMPLETO Y FUNCIONAL
