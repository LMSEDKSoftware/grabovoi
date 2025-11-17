# 📋 Requisitos de Instalación - Proyecto Flutter Grabovoi

## 🖥️ Sistema Operativo

### macOS (recomendado para desarrollo)
- macOS 11.0 (Big Sur) o superior
- Terminal con Bash o Zsh

### Windows (alternativa)
- Windows 10 o superior
- PowerShell o Git Bash

### Linux (alternativa)
- Ubuntu 18.04 o superior
- O distribución compatible

---

## 🔧 Herramientas Base Requeridas

### 1. Flutter SDK
**Versión requerida:** Flutter 3.24.5 o superior (stable)
**Dart SDK:** 3.5.0 o superior

```bash
# Verificar versión instalada
flutter --version

# Si no está instalado, descargar desde:
# https://docs.flutter.dev/get-started/install

# Agregar Flutter al PATH
export PATH="$PATH:/ruta/a/flutter/bin"
```

### 2. Chrome Browser (CRÍTICO para web)
**Requisito obligatorio:** Google Chrome instalado y actualizado

```bash
# macOS - Verificar instalación
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version

# Si no está instalado, descargar desde:
# https://www.google.com/chrome/
```

### 3. Java Development Kit (JDK)
**Versión requerida:** JDK 17 (OpenJDK o Oracle JDK)

```bash
# macOS - Instalar con Homebrew
brew install openjdk@17

# Configurar JAVA_HOME
export JAVA_HOME=$(/usr/libexec/java_home -v 17)

# Verificar instalación
java -version
# Debe mostrar: openjdk version "17.x.x"
```

### 4. Android Studio (opcional pero recomendado)
**Versión:** Android Studio Hedgehog o superior

- Descargar desde: https://developer.android.com/studio
- Instalar Android SDK Tools
- Configurar Android SDK Platform 35
- Configurar Android SDK Build-Tools

```bash
# Verificar Android SDK
echo $ANDROID_HOME
# Debe apuntar a: ~/Library/Android/sdk (macOS) o %LOCALAPPDATA%\Android\Sdk (Windows)
```

### 5. Gradle
**Versión:** Gradle 8.7 o superior (se instala automáticamente con Flutter)

```bash
# Verificar versión
cd android && ./gradlew --version
```

---

## 📦 Dependencias del Proyecto

### Dependencias Flutter (se instalan automáticamente con `flutter pub get`)

```yaml
# UI y Diseño
- cupertino_icons: ^1.0.8
- google_fonts: ^6.2.1
- flutter_animate: ^4.5.0
- shimmer: ^3.0.0
- lottie: ^3.1.2
- flutter_svg: ^2.0.9
- flutter_staggered_animations: ^1.1.1
- animations: ^2.0.10

# Estado y Navegación
- provider: ^6.1.1

# Base de datos
- supabase_flutter: ^2.4.3
- shared_preferences: ^2.3.1
- path_provider: ^2.1.3
- flutter_secure_storage: ^9.0.0

# Gráficos
- fl_chart: ^0.67.0

# Audio
- audioplayers: ^6.0.0
- just_audio: ^0.9.36

# Utilidades
- intl: ^0.19.0
- http: ^1.1.0
- pretty_http_logger: ^1.0.5
- json_annotation: ^4.9.0
- share_plus: ^10.0.2
- screenshot: ^3.0.0
- url_launcher: ^6.3.0
- flutter_local_notifications: ^17.2.3
- flutter_dotenv: ^5.2.1
- timezone: ^0.9.0
- workmanager: ^0.5.2
- image_picker: ^1.0.7
- permission_handler: ^11.2.0
- cached_network_image: ^3.3.1
- showcaseview: ^3.0.0

# Suscripciones
- in_app_purchase: ^3.1.11
- local_auth: ^2.2.0
```

---

## 🚀 Pasos de Instalación

### Paso 1: Clonar el Proyecto
```bash
git clone <url-del-repositorio>
cd grabovoi_build
```

### Paso 2: Verificar Flutter
```bash
flutter doctor
```

**Salida esperada:**
```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.24.5)
[✓] Android toolchain - develop for Android devices
[✓] Chrome - develop for the web
[✓] Android Studio
[✓] VS Code (opcional)
[✓] Connected device (1 available)
[✓] Network resources
```

### Paso 3: Instalar Dependencias
```bash
flutter pub get
```

### Paso 4: Configurar Variables de Entorno

Crear archivo `.env` en la raíz del proyecto:

```env
OPENAI_API_KEY=sk-proj-xxxxxxxxxxxx
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SB_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
ENV=dev
```

**⚠️ IMPORTANTE:** Este archivo NO debe subirse a Git (debe estar en `.gitignore`)

### Paso 5: Configurar Android SDK

#### En macOS/Linux:
```bash
# Agregar a ~/.zshrc o ~/.bashrc
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
```

#### En Windows:
```powershell
# Variables de entorno del sistema
ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk
PATH=%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\tools;%PATH%
```

### Paso 6: Verificar Dispositivos Disponibles

```bash
# Ver dispositivos conectados
flutter devices

# Debe mostrar al menos:
# Chrome (chrome) • chrome • web-javascript • Google Chrome
```

---

## 🌐 Lanzar en Chrome (Web)

### Opción 1: Usar el Script Automático
```bash
# Dar permisos de ejecución
chmod +x launch_chrome.sh

# Ejecutar
./launch_chrome.sh
```

Este script:
- ✅ Carga variables de entorno desde `.env`
- ✅ Verifica que Chrome esté instalado
- ✅ Compila y lanza Flutter en Chrome
- ✅ Abre automáticamente Chrome con la app

### Opción 2: Manual
```bash
# Cargar variables de entorno
source .env

# Lanzar Flutter en Chrome
flutter run -d chrome \
  --dart-define=OPENAI_API_KEY="${OPENAI_API_KEY}" \
  --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}" \
  --dart-define=SB_SERVICE_ROLE_KEY="${SB_SERVICE_ROLE_KEY}"
```

---

## 📱 Compilar APK (Android)

### Usar el Script Automático
```bash
# Dar permisos de ejecución
chmod +x BUILD_APK.sh

# Compilar APK Release
./BUILD_APK.sh
```

Este script:
- ✅ Carga variables de entorno desde `.env`
- ✅ Verifica que todas las variables existan
- ✅ Compila en modo release con `--dart-define`
- ✅ Genera: `build/app/outputs/flutter-apk/app-release.apk`

---

## ⚠️ Problemas Comunes y Soluciones

### 1. Chrome no se abre / Error "Chrome executable not found"

**Solución:**
```bash
# Verificar que Chrome esté instalado
which google-chrome  # Linux
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version  # macOS

# Si no está instalado, instalar Chrome
# macOS: https://www.google.com/chrome/
# Linux: sudo apt-get install google-chrome-stable
```

### 2. Error "Flutter doctor" muestra problemas con Chrome

**Solución:**
```bash
# Instalar Chrome Web
flutter config --enable-web
flutter doctor
```

### 3. Error "SDK location not found" (Android)

**Solución:**
```bash
# Configurar ANDROID_HOME
export ANDROID_HOME=$HOME/Library/Android/sdk  # macOS/Linux
export ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk  # Windows

# O crear archivo local.properties en android/
echo "sdk.dir=$ANDROID_HOME" > android/local.properties
```

### 4. Error "Java version" incorrecta

**Solución:**
```bash
# Verificar versión Java
java -version
# Debe ser Java 17

# Configurar JAVA_HOME
export JAVA_HOME=$(/usr/libexec/java_home -v 17)  # macOS
# O instalar OpenJDK 17
brew install openjdk@17  # macOS
```

### 5. Error "Variables de entorno no encontradas"

**Solución:**
```bash
# Verificar que existe .env en la raíz del proyecto
ls -la .env

# Verificar contenido (sin mostrar valores sensibles)
cat .env | grep -v "KEY" | grep -v "TOKEN"
```

### 6. Error "Web renderer" o visual no se muestra

**Solución:**
```bash
# Usar renderer HTML (más compatible)
flutter run -d chrome --web-renderer html

# O canvas-kit (mejor rendimiento pero puede tener problemas)
flutter run -d chrome --web-renderer canvaskit
```

---

## 🔍 Verificación Completa

### Checklist de Instalación

- [ ] Flutter instalado (`flutter --version` muestra 3.24.5+)
- [ ] Dart instalado (viene con Flutter)
- [ ] Chrome instalado y accesible
- [ ] JDK 17 instalado (`java -version` muestra 17)
- [ ] Android SDK configurado (si compila para Android)
- [ ] Variables de entorno configuradas (archivo `.env` existe)
- [ ] Dependencias instaladas (`flutter pub get` exitoso)
- [ ] Dispositivo Chrome disponible (`flutter devices` muestra Chrome)

### Comando de Verificación Rápida
```bash
# Ejecutar todos los checks
flutter doctor && \
flutter devices && \
flutter pub get && \
[ -f .env ] && echo "✅ .env existe" || echo "❌ .env NO existe"
```

---

## 📚 Recursos Adicionales

### Documentación Oficial
- Flutter: https://docs.flutter.dev/
- Dart: https://dart.dev/
- Chrome Web: https://docs.flutter.dev/get-started/web

### Scripts del Proyecto
- `launch_chrome.sh` - Lanzar app en Chrome
- `BUILD_APK.sh` - Compilar APK release
- `BUILD_APK_DEBUG.sh` - Compilar APK debug
- `RUN_ANDROID.sh` - Ejecutar en Android

---

## 💡 Tips Importantes

1. **Siempre usar los scripts** (`launch_chrome.sh`, `BUILD_APK.sh`) en lugar de comandos directos para asegurar que las variables de entorno estén incluidas.

2. **No subir `.env` a Git** - Este archivo contiene credenciales sensibles.

3. **Verificar que Chrome esté instalado** antes de intentar lanzar la app en web.

4. **Usar Flutter stable channel** - Este proyecto requiere Flutter estable, no beta ni master.

5. **Mantener herramientas actualizadas** - Actualizar Flutter regularmente con `flutter upgrade`.

---

## 🆘 Si Nada Funciona

1. **Limpiar todo y reinstalar:**
```bash
flutter clean
rm -rf .dart_tool
rm -rf build
flutter pub get
```

2. **Verificar permisos de scripts:**
```bash
chmod +x launch_chrome.sh BUILD_APK.sh BUILD_APK_DEBUG.sh
```

3. **Reinstalar dependencias:**
```bash
flutter pub cache repair
flutter pub get
```

4. **Verificar configuración de web:**
```bash
flutter config --enable-web
flutter doctor -v
```

