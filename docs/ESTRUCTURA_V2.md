# 🚀 Guía para Nueva Versión 2.0

## ✅ QUÉ CONSERVAR (NO TOCAR - Ya está configurado para compilar)

### 📁 Carpetas de Configuración Completas:
```
✅ android/              # TODA la configuración Android
✅ ios/                  # TODA la configuración iOS
✅ web/                  # Configuración Web
✅ macos/                # Configuración macOS
✅ linux/                # Configuración Linux
✅ windows/              # Configuración Windows
```

### 📄 Archivos Raíz Importantes:
```
✅ pubspec.yaml          # Dependencias (puedes agregar más, pero no quites las esenciales)
✅ pubspec.lock          # Lock de dependencias
✅ analysis_options.yaml # Configuración del linter
✅ .gitignore           # Archivos ignorados
✅ .metadata            # Metadata de Flutter
```

### 🔧 Configuración Android (android/):
```
✅ android/app/build.gradle           # ¡CRÍTICO! Configuración de compilación
✅ android/build.gradle               # Configuración global
✅ android/gradle.properties          # JDK 17 configurado
✅ android/settings.gradle            # AGP 8.3.2, Kotlin 1.9.22
✅ android/app/src/main/AndroidManifest.xml
✅ android/app/src/main/kotlin/       # Código nativo Android
✅ android/app/src/main/res/          # Recursos Android (puedes cambiar iconos)
```

---

## 🎨 QUÉ PUEDES CAMBIAR LIBREMENTE

### 📱 TODO el Código Flutter (lib/):
```
🔄 lib/main.dart                    # Punto de entrada - CÁMBIALO
🔄 lib/config/theme.dart            # Colores, fuentes - REDISEÑA
🔄 lib/config/router.dart           # Rutas - CREA LAS TUYAS
🔄 lib/screens/                     # TODAS las pantallas - BORRA/CREA
🔄 lib/widgets/                     # Widgets - CREA LOS TUYOS
🔄 lib/models/                      # Modelos de datos - NUEVOS
🔄 lib/providers/                   # Estado - REDISEÑA
🔄 lib/services/                    # Servicios - NUEVOS
🔄 lib/data/                        # Datos mock - CAMBIA
```

### 🎭 Assets y Recursos:
```
🔄 assets/ (si la creas)            # Imágenes, fuentes, etc.
🔄 android/app/src/main/res/mipmap-*/*.png  # Iconos de la app
```

---

## 📦 Dependencias Esenciales (No Quitar)

### En `pubspec.yaml`, estas son CRÍTICAS para compilar:

```yaml
# ✅ MANTENER (necesarias para compilación Android)
dependencies:
  flutter:
    sdk: flutter
  
  # Gestión de estado (puedes cambiar provider por otro)
  provider: ^6.1.1  # O usa Riverpod, Bloc, GetX...
  
  # Navegación
  go_router: ^13.0.0  # O usa Navigator 2.0, auto_route...
  
  # Persistencia local
  shared_preferences: ^2.2.2
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  
  # Notificaciones (si las usas)
  flutter_local_notifications: ^18.0.1
  timezone: ^0.9.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

# ✅ NO TOCAR
environment:
  sdk: '>=3.0.0 <4.0.0'

flutter:
  uses-material-design: true
```

### Puedes AGREGAR libremente:
- Nuevas UI: animate_do, flutter_staggered_animations
- HTTP: dio, http
- State: riverpod, bloc, get
- Lo que necesites!

---

## 🏗️ Arquitectura Mínima Recomendada

### Opción 1: Estructura Simple
```
lib/
├── main.dart              # App principal
├── app.dart              # MaterialApp
├── screens/              # Pantallas
│   ├── home_screen.dart
│   ├── login_screen.dart
│   └── ...
└── widgets/              # Widgets reutilizables
    └── custom_button.dart
```

### Opción 2: Estructura Completa (tu elección)
```
lib/
├── main.dart
├── app.dart
├── core/                 # Configuración
│   ├── theme/
│   ├── routes/
│   └── constants/
├── features/             # Características por módulo
│   ├── auth/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── providers/
│   └── home/
│       ├── screens/
│       └── widgets/
└── shared/               # Compartido
    ├── widgets/
    └── utils/
```

---

## 🎯 Plan de Acción Recomendado

### Paso 1: Limpiar Código Viejo (Opcional)
```bash
# Eliminar todo el contenido de lib/ menos main.dart
# Puedes hacer esto manualmente o:
cd lib
rm -rf config/ data/ models/ providers/ screens/ services/ widgets/
```

### Paso 2: Crear Estructura Nueva
```bash
# Crear carpetas básicas
mkdir -p lib/screens lib/widgets lib/theme
```

### Paso 3: main.dart Minimalista
Crea un `main.dart` nuevo super simple para empezar:

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Nueva App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Versión 2.0'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¡Hola Mundo!',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Empezar'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Paso 4: Verificar que Compila
```bash
flutter clean
flutter pub get
flutter build apk --release
```

### Paso 5: Desarrollar Nueva App
¡Ahora construye tu nueva app desde aquí! 🚀

---

## ⚠️ REGLAS DE ORO

### ❌ NUNCA Modificar:
1. `android/app/build.gradle` - Configuración de compilación
2. `android/gradle.properties` - JDK configurado
3. `android/settings.gradle` - Plugins Android
4. `pubspec.yaml` → `environment:` section
5. Archivos `.gradle` y `gradle-wrapper`

### ✅ Modificar con Cuidado:
1. `pubspec.yaml` → `dependencies:` (solo agregar, no quitar las core)
2. `android/app/src/main/AndroidManifest.xml` (solo permisos)
3. Iconos de la app

### 🎨 Cambiar Todo lo que Quieras:
1. TODO en `lib/`
2. Colores, fuentes, temas
3. Pantallas, widgets, lógica
4. Assets, imágenes, recursos

---

## 🛡️ Backup y Seguridad

### Antes de Empezar:
```bash
# Ya tienes v1.0.0 guardada en Git
git tag -l  # Ver v1.0.0

# Si quieres hacer backup del código actual:
git add .
git commit -m "backup: Código v1 antes de v2"
```

### Durante Desarrollo:
```bash
# Commits frecuentes
git add .
git commit -m "wip: Nueva pantalla de inicio"
```

### Si Algo Sale Mal:
```bash
# Volver al último commit
git checkout .

# Volver a v1.0.0 completa
git checkout v1.0.0
```

---

## 📱 Información de Compilación (Ya Configurada)

### Android:
- **compileSdk:** 34
- **minSdk:** 21 (Android 5.0+)
- **targetSdk:** 34
- **JDK:** 17
- **AGP:** 8.3.2
- **Kotlin:** 1.9.22

### Compilar APK:
```bash
flutter build apk --release
```

### Compilar Web:
```bash
flutter build web
```

---

## 💡 Sugerencias Finales

### 1. Empieza Simple
No intentes recrear toda la app de una vez. Empieza con:
- 1 pantalla
- 1 tema básico
- Compila y prueba

### 2. Ve Agregando Gradualmente
- Pantalla por pantalla
- Característica por característica
- Commit después de cada cosa funcional

### 3. Mantén lo que Funciona
Si encuentras algo de v1 que te gusta:
- Cópialo desde el tag v1.0.0
- Adáptalo a tu nueva estructura

### 4. Usa la Guía
- `GUIA_GIT.md` para Git
- `VERSION.md` para referencia técnica
- Este archivo para qué tocar y qué no

---

## 🎯 Checklist Antes de Compilar

- [ ] ✅ No tocaste archivos de `android/` (excepto iconos/manifest)
- [ ] ✅ `pubspec.yaml` tiene las dependencias core
- [ ] ✅ `flutter pub get` funciona sin errores
- [ ] ✅ `flutter analyze` no tiene errores críticos
- [ ] ✅ Tienes commit guardado de tu código

---

## 🚀 ¡Estás Listo!

Toda la **configuración técnica difícil** (que nos tomó horas resolver) está **protegida y funcionando**.

Ahora puedes **crear libremente** tu nueva app sin preocuparte por:
- ❌ Problemas de JDK
- ❌ Configuración de Gradle
- ❌ Errores de compilación de Android
- ❌ Dependencias incompatibles

**¡TODO ESO YA ESTÁ RESUELTO!** 🎉

---

**Versión actual:** `v2-nueva-version` (branch)
**Versión base configurada:** `v1.0.0` (tag)
**¡A crear algo increíble!** 💪✨

