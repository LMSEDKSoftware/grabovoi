# Reporte: requisitos para compilar APK (grabovoi_build)

**Proyecto:** manifestacion_numerica_grabovoi  
**Última actualización:** 2025-02-04 (alineado con compilación exitosa 2.3.23+23).

---

## 1. Versiones del proyecto

| Componente | Versión / Requisito |
|------------|---------------------|
| **App** | `2.3.23+23` (versionName + versionCode) |
| **Dart SDK** | `>=3.2.0 <4.0.0` (pubspec.yaml) |
| **Flutter** | Recomendado estable (ej. 3.24.x). En este equipo: 3.24.5 |
| **Android compileSdk** | 36 |
| **Android minSdk** | 21 |
| **Android targetSdk** | 36 |
| **Java** | 17 (sourceCompatibility / targetCompatibility) |
| **Kotlin (plugin)** | 2.2.0 (android/settings.gradle) |
| **Android Gradle Plugin** | 8.3.2 (settings.gradle) |
| **NDK** | 26.1.10909125 (android/app/build.gradle) |

---

## 2. Archivos del proyecto que no se deben borrar

- **Raíz:** `pubspec.yaml`, `pubspec.lock`, `.env`, `analysis_options.yaml`, `.metadata`
- **Código:** `lib/`, `android/`, `ios/`, `web/`, `assets/`, `database/`, `supabase/`, `test/`
- **Config:** `android/app/build.gradle`, `android/settings.gradle`, `android/build.gradle`, `ios/`, `.vscode/`, `.cursorrules`
- **Scripts:** `scripts/BUILD_APK.sh`, `scripts/BUILD_AAB.sh`
- **Firma release:** `android/key.properties` (y keystore referenciado) — necesario para APK release firmado

No eliminar nada dentro de la carpeta del proyecto salvo lo que indique explícitamente un script de limpieza documentado (por ejemplo `flutter clean` si se decide usarlo más adelante).

---

## 3. Requisitos previos en el equipo

1. **Flutter** instalado y en PATH (`flutter --version`).
2. **Android SDK** con compileSdk 36 y NDK 26.1.10909125 (o compatible).
3. **Archivo `.env`** en la raíz del proyecto con:
   - `OPENAI_API_KEY`
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `SB_SERVICE_ROLE_KEY`
4. **Firma release:** `android/key.properties` con `storeFile`, `storePassword`, `keyAlias`, `keyPassword` (y el keystore existente).

---

## 4. Instrucciones para compilar el APK

Desde la raíz del proyecto:

```bash
cd /Users/ifernandez/development/grabovoi_build
./scripts/BUILD_APK.sh
```

El script:

1. Incrementa automáticamente `version` en `pubspec.yaml` y `versionCode`/`versionName` en `android/app/build.gradle`.
2. Carga variables desde `.env`.
3. Ejecuta:  
   `flutter build apk --release --dart-define=...`

**Salida esperada:**  
`build/app/outputs/flutter-apk/app-release.apk`

Para compilar **sin** incrementar versión (por ejemplo para probar), se puede ejecutar manualmente:

```bash
source .env
flutter build apk --release \
  --dart-define=OPENAI_API_KEY="${OPENAI_API_KEY}" \
  --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}" \
  --dart-define=SB_SERVICE_ROLE_KEY="${SB_SERVICE_ROLE_KEY}"
```

---

## 5. Si falla la compilación

- **"No space left on device":** liberar espacio (ver sección de liberación más abajo) y volver a ejecutar `./scripts/BUILD_APK.sh`.
- **Errores de Kotlin / metadata** (ej. "binary version of its metadata is 2.2.0, expected version is 1.9.0"):
  - En `android/settings.gradle` debe estar: `id "org.jetbrains.kotlin.android" version "2.2.0" apply false`.
  - **Importante:** en `android/app/build.gradle`, el plugin de Kotlin debe declararse con versión explícita para que el módulo app use 2.2.0 y la compilación termine bien:
    ```gradle
    plugins {
        id "com.android.application"
        id "org.jetbrains.kotlin.android" version "2.2.0"
        id "dev.flutter.flutter-gradle-plugin"
    }
    ```
  - En `android/build.gradle` (ext): `kotlin_version = '2.2.0'`.
- **Falta `.env` o variables:** copiar desde `ENV_SAMPLE.txt` y completar valores.
- **Firma:** asegurar que `key.properties` y el keystore existan y las contraseñas sean correctas.

---

## 6. Liberación de espacio (sin afectar este proyecto)

Se puede liberar espacio **solo en cachés globales**, sin tocar archivos del proyecto:

| Qué se limpia | Ubicación | Efecto |
|---------------|-----------|--------|
| Caché de transforms de Gradle | `~/.gradle/caches/transforms-*` | Se regenera en la siguiente compilación. Libera varios GB. |
| Caché de build de Gradle | `~/.gradle/caches/build-cache-*` | Se regenera en la siguiente compilación. |
| Caché de journals de Gradle | `~/.gradle/caches/journal-*` | Metadata; se recrea si hace falta. |

**No se elimina:**

- Ningún archivo ni carpeta dentro de `grabovoi_build` (incluido `build/`, `lib/`, `android/`, etc.).
- No se ejecuta `flutter clean` (para no borrar el APK ya generado ni artefactos del proyecto).

Después de limpiar, la primera compilación puede tardar más porque Gradle volverá a generar los transforms.

---

### Ejecución realizada (liberación sin tocar el proyecto)

Se eliminó **solo** en `~/.gradle/caches/`:

- `transforms-4` (y cualquier `transforms-*`)

**Resultado:** espacio libre en disco pasó de ~176 MB a **~3.0 GB**. Caché Gradle de ~4.6 GB a ~1.4 GB. El proyecto `grabovoi_build` no fue modificado.

---

## 7. Resumen rápido

- **Compilar APK:** `./scripts/BUILD_APK.sh` (desde la raíz del proyecto, con `.env` y key.properties listos).
- **Versiones clave:** Flutter estable, Dart 3.2+, Android SDK 36, Kotlin 2.2.0 (plugin en `settings.gradle` y **versión explícita en `app/build.gradle`**), Java 17.
- **Liberar espacio sin tocar el proyecto:** borrar solo `~/.gradle/caches/transforms-*` y opcionalmente `build-cache-*` y `journal-*`.

**Configuración que hizo funcionar la última compilación (2.3.23+23):** igual a la descrita en este reporte; en particular, Kotlin 2.2.0 con versión explícita en `android/app/build.gradle` (bloque `plugins`) para evitar el fallo de metadata 2.2.0 vs 1.9.0.
