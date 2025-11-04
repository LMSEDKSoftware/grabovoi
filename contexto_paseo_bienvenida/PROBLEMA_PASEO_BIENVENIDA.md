# 🚨 PROBLEMA: Paseo de Bienvenida No Funciona

## 📋 DESCRIPCIÓN DEL PROBLEMA

El paseo de bienvenida (Welcome Tour) usando la librería `showcaseview` no se está iniciando automáticamente cuando debería. El tour debería mostrarse la primera vez que un usuario entra a la app, pero no aparece.

## 🎯 COMPORTAMIENTO ESPERADO

1. **Primera vez**: Cuando un usuario nuevo entra a la app, el tour debería iniciarse automáticamente después de 1.5 segundos
2. **Mostrar pasos**: Debería mostrar 5 pasos en orden:
   - Paso 1: Título "Portal Energético"
   - Paso 2: Nivel Energético
   - Paso 3: Código del Día
   - Paso 4: Próximo Paso
   - Paso 5: Estadísticas de Energía (solapa)
3. **Completar**: Al completar el tour, debería marcarse como completado y no mostrarse de nuevo
4. **Reiniciar**: Desde el perfil, el usuario puede reiniciar el tour con el botón "Ver Paseo de Bienvenida"

## ❌ COMPORTAMIENTO ACTUAL

- El tour **NO se inicia automáticamente** cuando debería
- El código intenta iniciarlo con `ShowCaseWidget.of(context).startShowCase([_one, _two, _three, _four, _five])`
- Pero no se muestra visualmente
- El botón de reinicio en el perfil no parece funcionar correctamente

## 📁 ARCHIVOS INVOLUCRADOS

### 1. Configuración Principal
- **`lib/main.dart`**: Configura `ShowCaseWidget` como builder global
  - Usa `enableAutoScroll: true`
  - Tiene callback `onFinish` que marca el tour como completado

### 2. Servicio de Estado
- **`lib/services/showcase_tour_service.dart`**: Maneja el estado persistente
  - Guarda en `SharedPreferences` si el tour está completado
  - Métodos: `isTourCompleted()`, `markTourAsCompleted()`, `resetTour()`

### 3. Pantalla Principal
- **`lib/screens/home/home_screen.dart`**: Pantalla que contiene los Showcase
  - Define 5 GlobalKeys: `_one`, `_two`, `_three`, `_four`, `_five`
  - En `initState()` llama a `_startTourIfNeeded()`
  - Intenta iniciar el tour con `ShowCaseWidget.of(context).startShowCase()`
  - Cada elemento tiene un widget `Showcase` con su respectivo `key`

### 4. Botón de Reinicio
- **`lib/screens/profile/profile_screen.dart`**: Botón para reiniciar el tour
  - Llama a `ShowcaseTourService.resetTour()`
  - Muestra un SnackBar pero no parece iniciar el tour

## 🔍 ESTRUCTURA ACTUAL DEL CÓDIGO

### En main.dart (líneas 111-122):
```dart
builder: (context, child) {
  return ShowCaseWidget(
    enableAutoScroll: true,
    onFinish: () async {
      await ShowcaseTourService.markTourAsCompleted();
    },
    builder: (context) => child ?? const SizedBox(),
  );
},
```

### En home_screen.dart (líneas 65-88):
```dart
Future<void> _startTourIfNeeded() async {
  final isCompleted = await ShowcaseTourService.isTourCompleted();
  if (!isCompleted) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          try {
            ShowCaseWidget.of(context).startShowCase([_one, _two, _three, _four, _five]);
            _listenForTourCompletion();
          } catch (e) {
            debugPrint('Error iniciando tour: $e');
          }
        }
      });
    });
  }
}
```

### Elementos Showcase (ejemplo):
```dart
Showcase(
  key: _one,
  title: '👋 ¡Bienvenido a MANIGRAB!',
  description: 'Esta es tu pantalla de Inicio...',
  child: Text('Portal Energético', ...),
),
```

## 🧩 POSIBLES CAUSAS

1. **Context incorrecto**: `ShowCaseWidget.of(context)` puede no encontrar el ShowCaseWidget si el context no está correcto
2. **Timing issue**: El delay de 1.5 segundos puede no ser suficiente para que el widget tree esté completamente construido
3. **GlobalKeys no listos**: Los GlobalKeys pueden no estar asignados cuando se intenta iniciar el tour
4. **Positioned wrapper**: El último Showcase (EnergyStatsTab) está envuelto en un `Positioned`, lo que podría afectar el cálculo de posiciones
5. **Error silencioso**: El try-catch puede estar ocultando un error que no se está logueando correctamente

## 🔧 INTENTOS REALIZADOS (POSIBLES)

1. ✅ Usar `addPostFrameCallback` para esperar que el widget tree esté listo
2. ✅ Agregar delay de 1.5 segundos
3. ✅ Usar try-catch para capturar errores
4. ❓ El botón de reinicio no parece funcionar correctamente

## 📝 NOTAS IMPORTANTES

- El código usa la librería `showcaseview: ^3.0.0`
- El tour se guarda en `SharedPreferences` con la key `showcase_tour_completed`
- Los GlobalKeys están definidos correctamente en `home_screen.dart`
- Los widgets Showcase están correctamente definidos con sus keys
- El `ShowCaseWidget` está configurado globalmente en `main.dart`

## 🎯 OBJETIVO

Identificar por qué `ShowCaseWidget.of(context).startShowCase()` no está iniciando el tour visualmente, especialmente considerando que:
- El código parece correcto sintácticamente
- No hay errores de compilación
- El contexto debería estar disponible
- Los GlobalKeys están asignados

## ⚠️ PROBLEMA ESPECÍFICO CON EL ÚLTIMO SHOWCASE

El último Showcase (key: `_five`) está envuelto en un `Positioned`:
```dart
Positioned(
  top: 0,
  right: 0,
  child: Showcase(
    key: _five,
    child: const EnergyStatsTab(),
  ),
),
```

Esto podría estar causando que showcaseview no pueda calcular correctamente la posición del elemento, lo que podría impedir que el tour funcione correctamente.

## 📦 ARCHIVOS INCLUIDOS EN ESTA CARPETA

Todos los archivos necesarios para entender y depurar el problema están en esta carpeta `contexto_paseo_bienvenida/`.

