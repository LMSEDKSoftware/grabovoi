# Historial de Versiones - Manifestación Numérica Grabovoi

## v1.0.0 - APK Funcional (15 Octubre 2025)

### ✅ Estado: COMPILADO Y FUNCIONANDO

**APK generado:** `grabovoi-release.apk` (24.7MB)

### 🔧 Configuración Técnica

- **Flutter:** 3.24.5 (stable)
- **Dart:** 3.5.4
- **Android SDK:** 34
- **JDK:** OpenJDK 17 (ARM64)
- **Gradle:** 8.7
- **Android Gradle Plugin:** 8.3.2
- **Kotlin:** 1.9.22

### 📱 Compatibilidad

- **minSdk:** 21 (Android 5.0 Lollipop)
- **targetSdk:** 34 (Android 14)
- **Plataformas:** Android, Web

### 🎯 Características Implementadas

#### Pantallas principales:
- ✅ Splash Screen con animaciones
- ✅ Onboarding interactivo
- ✅ Home místico con campo de estrellas animado
- ✅ Biblioteca de códigos Grabovoi (20+ códigos)
- ✅ Detalle de códigos con favoritos
- ✅ Tracker de repeticiones (sistema 108)
- ✅ Meditaciones guiadas
- ✅ Diario místico
- ✅ Pilotaje consciente (5 pantallas)
- ✅ Configuraciones personalizables
- ✅ Herramientas holísticas
- ✅ Ejercicios de respiración

#### Funcionalidades:
- ✅ Gestión de estado con Provider
- ✅ Navegación con GoRouter
- ✅ Persistencia local con Hive y SharedPreferences
- ✅ Tema oscuro místico personalizado
- ✅ Animaciones fluidas con Flutter Animate
- ✅ Fuentes personalizadas con Google Fonts (Space Mono)
- ✅ Audio con just_audio y audioplayers
- ✅ Notificaciones locales (flutter_local_notifications)

### 📦 Dependencias Principales

```yaml
- provider: ^6.1.1
- go_router: ^13.0.0
- hive: ^2.2.3
- shared_preferences: ^2.2.2
- google_fonts: ^6.1.0
- flutter_animate: ^4.5.0
- lottie: ^3.0.0
- audioplayers: ^5.2.1
- just_audio: ^0.9.36
- flutter_local_notifications: ^18.0.1
```

### ⚠️ Dependencias comentadas (temporalmente):
- `supabase_flutter` - No necesario para versión actual (usa mock data)
- `share_plus` - Reemplazado por funcionalidad de copiar al portapapeles

### 🛠️ Configuraciones Especiales

#### Android (android/app/build.gradle):
```gradle
android {
    compileSdk = 34
    minSdk = 21
    targetSdk = 34
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        coreLibraryDesugaringEnabled true
    }
    
    kotlinOptions {
        jvmTarget = '11'
    }
}

dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'
}
```

#### Gradle (android/gradle.properties):
```properties
org.gradle.java.home=/usr/local/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
```

### 📝 Notas Importantes

1. **Compilación:** Si Desktop da problemas de I/O (iCloud sync), usar `~/projects/grabovoi_build`
2. **JDK:** Requiere JDK 17 para AGP 8.3.2
3. **Core Library Desugaring:** Necesario para flutter_local_notifications en Android
4. **Mock Data:** App usa datos simulados, lista para integrar Supabase cuando sea necesario

### 🚀 Cómo compilar:

```bash
cd /Users/ifernandez/Desktop/grabovoi_build
/Users/ifernandez/development/flutter/bin/flutter build apk --release
```

### 🎨 Tema Visual

- **Colores principales:**
  - Primary: `#8B5CF6` (Púrpura místico)
  - Secondary: `#06B6D4` (Cian brillante)
  - Accent: `#F59E0B` (Dorado)
  - Background: `#0F0F23` (Azul muy oscuro)

- **Fuente:** Space Mono (monoespaciada)
- **Estilo:** Místico/Esotérico con animaciones suaves

---

## Próximas Versiones

### v1.1.0 - Planificado
- Nuevos cambios de fondo y forma
- Mejoras visuales
- Nuevas características


