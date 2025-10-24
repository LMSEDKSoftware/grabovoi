# INSTRUCCIONES PARA CHATGPT

## 🎯 PROBLEMA A RESOLVER

**El botón de copiar en las pantallas está causando parseo recursivo de todos los códigos (376 códigos) cada vez que se presiona, cuando ya no debería ser necesario.**

## 📋 CONTEXTO TÉCNICO

### **Arquitectura actual**:
- ✅ **CodigosRepository**: Singleton con caché en memoria, precarga en main.dart
- ❌ **SupabaseService**: Sin caché, hace query completa cada vez
- ✅ **Solución implementada**: Ya funciona en 3 pantallas, falta en 2

### **Pantallas afectadas**:
1. **`repetition_session_screen.dart`** - Botón copiar (línea 196)
2. **`code_detail_screen.dart`** - Método `_copyToClipboard()` (línea 170)

### **Pantallas ya corregidas**:
- ✅ `home_screen.dart`
- ✅ `quantum_pilotage_screen.dart` 
- ✅ `pilotaje_screen.dart`

## 🔧 SOLUCIÓN REQUERIDA

### **Cambio específico en `repetition_session_screen.dart`**:

**Línea 196** - Cambiar:
```dart
// ❌ PROBLEMÁTICO:
final codigos = await SupabaseService.getCodigos();
final codigoEncontrado = codigos.firstWhere(
  (c) => c.codigo == widget.codigo,
  orElse: () => CodigoGrabovoi(...),
);
```

**Por:**
```dart
// ✅ SOLUCIONADO:
final descripcion = CodigosRepository().getDescripcionByCode(widget.codigo);
final titulo = CodigosRepository().getTituloByCode(widget.codigo);
final codigoEncontrado = CodigoGrabovoi(
  id: '',
  codigo: widget.codigo,
  nombre: titulo,
  descripcion: descripcion,
  categoria: 'General',
  color: '#FFD700',
);
```

### **Cambio específico en `code_detail_screen.dart`**:

**Línea 170** - Cambiar:
```dart
// ❌ PROBLEMÁTICO:
final codigos = await SupabaseService.getCodigos();
final codigoEncontrado = codigos.firstWhere(
  (c) => c.codigo == widget.codigo,
  orElse: () => CodigoGrabovoi(...),
);
```

**Por:**
```dart
// ✅ SOLUCIONADO:
final descripcion = CodigosRepository().getDescripcionByCode(widget.codigo);
final titulo = CodigosRepository().getTituloByCode(widget.codigo);
final codigoEncontrado = CodigoGrabovoi(
  id: '',
  codigo: widget.codigo,
  nombre: titulo,
  descripcion: descripcion,
  categoria: 'General',
  color: '#FFD700',
);
```

## 📁 ARCHIVOS DISPONIBLES

- `repetition_session_screen.dart` - Archivo a corregir
- `code_detail_screen.dart` - Archivo a corregir
- `codigos_repository.dart` - Solución implementada
- `supabase_service.dart` - Servicio problemático
- `CONTEXTO_COMPLETO.md` - Análisis detallado

## 🎯 RESULTADO ESPERADO

Después de la corrección:
1. ✅ Botón de copiar funcionará sin parseo recursivo
2. ✅ Información se copiará correctamente
3. ✅ Rendimiento mejorado (sin queries a Supabase)
4. ✅ UX más fluida (respuesta instantánea)

## 🔍 VERIFICACIÓN

Para verificar que funciona:
1. Presionar botón de copiar
2. Verificar que NO aparezcan mensajes "Parseado: ..." en consola
3. Verificar que se copie la información correcta
4. Verificar que la respuesta sea instantánea

