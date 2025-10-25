# 🐛 Problema: Campo Energético - Error de Layout en Diálogo

## 📊 Resumen del Problema

**Error:** `RenderViewport does not support returning intrinsic dimensions`

**Ubicación:** `lib/screens/codes/code_detail_screen.dart` - Línea 146 (método `_showCompletionDialog()`)

**Contexto:** Al finalizar los 2 minutos de Campo Energético, se intenta mostrar un diálogo con:
1. ✅ Mensaje de felicitación
2. ✅ Información sobre mantener la vibración
3. ❌ Códigos sincrónicos (sección que causa el error)

## 🔍 Análisis Técnico

### ¿Qué funciona?
- ✅ El temporizador de 2 minutos funciona correctamente
- ✅ Los códigos sincrónicos se cargan correctamente desde Supabase
- ✅ Se obtienen 2 códigos sincrónicos para la categoría
- ✅ El audio se detiene correctamente
- ✅ La lógica de negocio completa funciona

### ¿Qué falla?
- ❌ El `AlertDialog` no se puede renderizar cuando incluye la sección de códigos sincrónicos
- ❌ Error específico: `RenderViewport does not support returning intrinsic dimensions`
- ❌ El problema ocurre cuando `Wrap` está dentro de un `Column` dentro de un `AlertDialog`

### Causa Raíz

El error proviene de un conflicto de layout en Flutter:

1. El `AlertDialog` tiene restricciones de ancho fijas (280-420px)
2. Cuando el contenido incluye un `Column` con `mainAxisSize: MainAxisSize.min`
3. Y ese `Column` contiene un `Wrap` (que intenta calcular su ancho intrínseco)
4. Flutter no puede calcular las dimensiones sin instanciar todos los hijos
5. Esto causa el crash del RenderViewport

## 🔄 Comparación con Repeticiones (que SÍ funciona)

### Repeticiones (`repetition_session_screen.dart`)
- **Líneas 852-856:** Usa `SingleChildScrollView` → `Column` → contenido
- **Línea 995:** Usa `Wrap` con `spacing: 8, runSpacing: 8`
- **Línea 1009:** Contenedores con `width: 160`
- **Funciona:** ✅ El `SingleChildScrollView` permite que el `Wrap` calcule correctamente

### Campo Energético (`code_detail_screen.dart`)
- **Línea 170:** Usa `Column` directamente (sin `SingleChildScrollView`)
- **Línea 1058:** Usa `Wrap` con `spacing: 8, runSpacing: 8`
- **Línea 1072:** Contenedores con `width: 160`
- **Falla:** ❌ El `Column` sin scroll no permite que el `Wrap` calcule dimensiones intrínsecas

## 🎯 Intento de Soluciones

### Intento 1: Usar `SingleChildScrollView`
```dart
content: SingleChildScrollView(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // contenido
    ],
  ),
),
```
**Resultado:** ❌ Mismo error

### Intento 2: Eliminar `SingleChildScrollView`
```dart
content: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    // contenido
  ],
),
```
**Resultado:** ❌ Mismo error

### Intento 3: Cambiar `Wrap` por `Column`
```dart
Column(
  children: codigosSincronicos.map((codigo) {
    return Container(
      width: double.infinity, // Intentar ocupar todo el ancho
      // ...
    );
  }).toList(),
),
```
**Resultado:** ❌ Mismo error

## 🧩 Archivos Involucrados

### Archivo con Problema
- `lib/screens/codes/code_detail_screen.dart`
  - Línea 146: `_showCompletionDialog()`
  - Línea 170-216: Estructura del `AlertDialog`
  - Línea 1058-1108: Método `_buildSincronicosSection()`

### Archivo de Referencia (que funciona)
- `lib/screens/codes/repetition_session_screen.dart`
  - Línea 820: `_mostrarMensajeFinalizacion()`
  - Línea 852-956: Estructura del `AlertDialog`
  - Línea 962-1062: Método `_buildSincronicosSection()`

### Repositorio
- `lib/repositories/codigos_repository.dart`
  - Línea 89-157: Método `getSincronicosByCategoria()`
  - Línea 43-75: Método `_initSincronicosCache()`
  - Línea 77-87: Método `_saveSincronicosToLocalStorage()`

## 🎨 Estructura del Diálogo Problemático

```
AlertDialog
├── title: Row (icono + texto)
├── content: Column  ← PROBLEMA AQUÍ
│   ├── Text (mensaje de felicitación)
│   ├── SizedBox (espaciador)
│   ├── Container (información vibración)
│   ├── SizedBox (espaciador)
│   └── _buildSincronicosSection()  ← CAUSA EL ERROR
│       └── FutureBuilder
│           └── Container
│               └── Column
│                   ├── Row (título)
│                   ├── Text (descripción)
│                   ├── SizedBox
│                   └── Wrap  ← ESTE ES EL PROBLEMA
│                       └── GestureDetector[]
└── actions: ElevatedButton[]
```

## 💡 Posibles Soluciones

1. **Solución 1:** Usar `IntrinsicWidth` para envolver el `Wrap`
2. **Solución 2:** Convertir `Wrap` en `ListView` horizontal con altura fija
3. **Solución 3:** Pre-cargar los sincrónicos y usar un `StatefulBuilder`
4. **Solución 4:** Mover los códigos sincrónicos a un `Dialog` separado
5. **Solución 5:** Usar `SizedBox` con altura fija para limitar el contenido

## 📝 Logs Relevantes

```
✅ [CAMPO ENERGÉTICO] Temporizador completado! Mostrando diálogo...
🔍 [SINCRÓNICOS] Buscando códigos sincrónicos para categoría: Salud
🔄 [SINCRÓNICOS] Cargando datos desde Supabase para: Salud
📋 [SINCRÓNICOS] Categorías recomendadas: [Limpieza, Liberación, Protección, Energía, Conciencia]
✅ [SINCRÓNICOS] Encontrados 2 códigos sincrónicos
💾 Caché de sincrónicos guardado
══╡ EXCEPTION CAUGHT BY RENDERING LIBRARY
RenderViewport does not support returning intrinsic dimensions.
```

## 🔗 Referencias

- [Flutter: RenderViewport Error](https://api.flutter.dev/flutter/rendering/RenderViewport.html)
- [Flutter: Wrap Widget](https://api.flutter.dev/flutter/widgets/Wrap-class.html)
- [Flutter: AlertDialog](https://api.flutter.dev/flutter/material/AlertDialog-class.html)
