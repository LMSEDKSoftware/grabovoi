# 📋 Implementación: Sistema de Títulos Relacionados

## ✅ Solución Implementada: Opción 1 - Tabla de Títulos Relacionados

### 🎯 Objetivo
Permitir que un mismo código tenga múltiples títulos/descripciones sin modificar la estructura de `codigos_grabovoi`.

---

## 📁 Archivos Creados/Modificados

### 1. **Script SQL: `crear_tabla_codigos_titulos_relacionados.sql`**
   - Crea la tabla `codigos_titulos_relacionados`
   - Índices para optimizar búsquedas
   - RLS (Row Level Security) configurado
   - Triggers para actualización automática

### 2. **Modelo: `lib/models/codigo_titulo_relacionado_model.dart`**
   - Modelo de datos para títulos relacionados
   - Métodos `fromJson()` y `toJson()`

### 3. **Servicio: `lib/services/supabase_service.dart`**
   - ✅ `agregarTituloRelacionado()` - Agregar nuevo título relacionado
   - ✅ `getTitulosRelacionados()` - Obtener todos los títulos de un código
   - ✅ `buscarCodigosPorTitulo()` - Buscar códigos incluyendo títulos relacionados

### 4. **Pantalla de Admin: `lib/screens/admin/approve_suggestions_screen.dart`**
   - ✅ Modificado `_aprobarSugerencia()` para insertar en `codigos_titulos_relacionados`
   - Ya no modifica `codigos_grabovoi`

### 5. **Pantalla de Detalle: `lib/screens/codes/code_detail_screen.dart`**
   - ✅ Muestra títulos relacionados cuando se busca un código
   - ✅ Sección visual para mostrar todos los títulos alternativos

### 6. **Búsquedas:**
   - ✅ `lib/screens/pilotaje/quantum_pilotage_screen.dart` - Búsqueda incluye títulos relacionados
   - ✅ `lib/screens/biblioteca/static_biblioteca_screen.dart` - Búsqueda incluye títulos relacionados

---

## 🔄 Flujo de Funcionamiento

### **Escenario A: Búsqueda por Tema**

1. Usuario busca: "Desarrollo de habilidades educativas"
2. Sistema busca en:
   - `codigos_grabovoi.nombre` y `codigos_grabovoi.descripcion`
   - `codigos_titulos_relacionados.titulo` y `codigos_titulos_relacionados.descripcion`
3. Si encuentra coincidencia en títulos relacionados → propone el código relacionado
4. Resultado: Usuario ve código "148_596_481"

### **Escenario B: Búsqueda por Código**

1. Usuario busca: "148_596_481"
2. Sistema:
   - Obtiene el código principal de `codigos_grabovoi`
   - Obtiene todos los títulos relacionados de `codigos_titulos_relacionados`
3. Muestra:
   - Título principal: "Desarrollo de habilidades educativas"
   - Títulos relacionados:
     - "Éxito en exámenes"
     - (otros títulos si existen)

### **Escenario C: Aprobar Sugerencia**

1. Administrador aprueba una sugerencia
2. Sistema:
   - Inserta registro en `codigos_titulos_relacionados` con:
     - `codigo_existente`: código original
     - `titulo`: título sugerido
     - `descripcion`: descripción sugerida
     - `sugerencia_id`: referencia a la sugerencia aprobada
   - Marca sugerencia como "aprobada"
3. **NO modifica** `codigos_grabovoi`

---

## 📊 Estructura de la Base de Datos

### Tabla: `codigos_titulos_relacionados`
```sql
- id (UUID, PK)
- codigo_existente (TEXT, FK → codigos_grabovoi.codigo)
- titulo (TEXT)
- descripcion (TEXT)
- categoria (TEXT)
- fuente (TEXT, default: 'sugerencia_aprobada')
- sugerencia_id (INTEGER, FK → sugerencias_codigos.id)
- usuario_id (UUID, FK → auth.users.id)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)
```

---

## 🚀 Pasos para Implementar

### 1. Ejecutar Script SQL
```sql
-- Ejecutar en Supabase SQL Editor:
crear_tabla_codigos_titulos_relacionados.sql
```

### 2. Verificar que la tabla se creó
```sql
SELECT * FROM codigos_titulos_relacionados LIMIT 1;
```

### 3. Probar el flujo completo
- Aprobar una sugerencia → Verificar que se inserta en `codigos_titulos_relacionados`
- Buscar por tema → Verificar que encuentra códigos con títulos relacionados
- Buscar por código → Verificar que muestra todos los títulos

---

## ✅ Ventajas de esta Solución

1. ✅ **No modifica estructura existente** - `codigos_grabovoi` permanece intacta
2. ✅ **Mantiene integridad referencial** - Foreign keys funcionan correctamente
3. ✅ **Rastreable** - Puedes saber qué títulos vienen de sugerencias aprobadas
4. ✅ **Escalable** - Fácil agregar más títulos sin problemas
5. ✅ **Búsquedas eficientes** - Índices optimizados para búsquedas rápidas
6. ✅ **Seguro** - RLS configurado para proteger datos

---

## 📝 Notas Importantes

- La tabla `codigos_grabovoi` mantiene su estructura original con UNIQUE en `codigo`
- Los títulos relacionados se almacenan en una tabla separada
- Las búsquedas ahora consideran tanto códigos principales como títulos relacionados
- La visualización muestra todos los títulos cuando se busca un código específico

