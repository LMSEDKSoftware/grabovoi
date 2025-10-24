# ANÁLISIS DEL PROBLEMA DE PARSEO RECURSIVO

## 🚨 PROBLEMA IDENTIFICADO

**El botón de copiar está disparando parseo recursivo de todos los códigos cada vez que se presiona, cuando ya no debería ser necesario.**

## 📱 PANTALLAS AFECTADAS Y SU FUNCIONAMIENTO

### 1. **Sesión de Repetición** (`repetition_session_screen.dart`)
- **Función**: Pantalla para repetir códigos Grabovoi
- **Botón problemático**: Línea 192-236 - Botón de copiar (IconButton con Icons.copy)
- **Problema**: Llama a `SupabaseService.getCodigos()` directamente en el onPressed
- **Código problemático**:
```dart
onPressed: () async {
  try {
    // ❌ PROBLEMA: Llama directamente a SupabaseService.getCodigos()
    final codigos = await SupabaseService.getCodigos();
    final codigoEncontrado = codigos.firstWhere(...);
  }
}
```

### 2. **Campo Energético** (`code_detail_screen.dart`)
- **Función**: Pantalla de pilotaje cuántico de códigos
- **Botón problemático**: Línea 167-186 - Método `_copyToClipboard()`
- **Problema**: Llama a `SupabaseService.getCodigos()` directamente
- **Código problemático**:
```dart
void _copyToClipboard() async {
  try {
    // ❌ PROBLEMA: Llama directamente a SupabaseService.getCodigos()
    final codigos = await SupabaseService.getCodigos();
    final codigoEncontrado = codigos.firstWhere(...);
  }
}
```

### 3. **Pantalla de Inicio** (`home_screen.dart`)
- **Función**: Pantalla principal con código recomendado
- **Problema**: Líneas 231-238 - FutureBuilder que llama a `_getCodigoTitulo()` y `_getCodigoDescription()`
- **Estado**: ✅ YA CORREGIDO - Usa CodigosRepository

### 4. **Pilotaje Cuántico** (`quantum_pilotage_screen.dart`)
- **Función**: Búsqueda avanzada de códigos con IA
- **Problema**: Líneas 884-905 - Métodos `_getCodigoDescription()` y `_getCodigoTitulo()`
- **Estado**: ✅ YA CORREGIDO - Usa CodigosRepository

### 5. **Pilotaje Simple** (`pilotaje_screen.dart`)
- **Función**: Pilotaje básico de códigos
- **Problema**: Líneas 322-341 - Métodos `_getCodigoDescription()` y `_getCodigoTitulo()`
- **Estado**: ✅ YA CORREGIDO - Usa CodigosRepository

## 🔄 FLUJO ACTUAL DEL PARSEO RECURSIVO

### **ANTES (Problemático)**:
1. Usuario presiona botón de copiar
2. Se ejecuta `SupabaseService.getCodigos()`
3. Se hace query a Supabase
4. Se parsean TODOS los códigos (376 códigos)
5. Se busca el código específico
6. Se copia al clipboard

### **DESPUÉS (Solución)**:
1. Usuario presiona botón de copiar
2. Se ejecuta `CodigosRepository().getDescripcionByCode(codigo)`
3. Se busca en caché en memoria (sin query a Supabase)
4. Se obtiene la información
5. Se copia al clipboard

## 🏗️ ARQUITECTURA ACTUAL

### **CodigosRepository** (Singleton con caché):
- ✅ **Caché en memoria**: `List<CodigoGrabovoi>? _codigos`
- ✅ **Precarga**: Se ejecuta en `main.dart` al inicio
- ✅ **Métodos optimizados**: `getDescripcionByCode()`, `getTituloByCode()`
- ✅ **Sin queries repetidas**: Una sola carga al inicio

### **SupabaseService** (Problema):
- ❌ **Sin caché**: Cada llamada hace query a Supabase
- ❌ **Parseo completo**: Siempre parsea los 376 códigos
- ❌ **Lento**: Query de red + parseo completo

## 🎯 SOLUCIÓN REQUERIDA

### **Archivos que necesitan corrección**:

1. **`repetition_session_screen.dart`** (Líneas 192-236):
   - Cambiar `SupabaseService.getCodigos()` por `CodigosRepository().getDescripcionByCode()`

2. **`code_detail_screen.dart`** (Líneas 167-186):
   - Cambiar `SupabaseService.getCodigos()` por `CodigosRepository().getDescripcionByCode()`

### **Código de corrección**:

```dart
// ❌ ANTES (Problemático):
final codigos = await SupabaseService.getCodigos();
final codigoEncontrado = codigos.firstWhere(...);

// ✅ DESPUÉS (Solucionado):
final descripcion = CodigosRepository().getDescripcionByCode(widget.codigo);
final titulo = CodigosRepository().getTituloByCode(widget.codigo);
```

## 📊 IMPACTO DEL PROBLEMA

- **Rendimiento**: Cada clic en copiar = 376 códigos parseados
- **Red**: Query innecesaria a Supabase
- **UX**: Lentitud en la respuesta del botón
- **Recursos**: CPU y memoria desperdiciados

## 🔧 ARCHIVOS EN ESTA CARPETA

1. `repetition_session_screen.dart` - Pantalla con botón problemático
2. `code_detail_screen.dart` - Pantalla con botón problemático  
3. `home_screen.dart` - Pantalla ya corregida
4. `quantum_pilotage_screen.dart` - Pantalla ya corregida
5. `pilotaje_screen.dart` - Pantalla ya corregida
6. `supabase_service.dart` - Servicio problemático
7. `codigos_repository.dart` - Solución implementada
8. `main.dart` - Precarga de códigos

## 🎯 PRÓXIMOS PASOS

1. Corregir `repetition_session_screen.dart` línea 196
2. Corregir `code_detail_screen.dart` línea 170
3. Probar que el botón de copiar funcione sin parseo recursivo
4. Verificar que la información se copie correctamente

