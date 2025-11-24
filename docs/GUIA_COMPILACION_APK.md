# 📦 Guía de Compilación de APK con Variables de Entorno

## ⚠️ IMPORTANTE

**NUNCA compiles el APK directamente con `flutter build apk` sin incluir las variables de entorno.**

Si compilas sin las variables de entorno, la aplicación NO funcionará correctamente porque:
- ❌ No podrá conectarse a Supabase
- ❌ No podrá usar la API de OpenAI
- ❌ Las funciones principales fallarán

## ✅ Forma Correcta de Compilar

### Para APK DEBUG (desarrollo/testing)

```bash
./BUILD_APK_DEBUG.sh
```

Este script:
- ✅ Carga las variables desde `.env`
- ✅ Verifica que todas las variables existan
- ✅ Compila con `--dart-define` para incluir las variables
- ✅ Genera: `build/app/outputs/flutter-apk/app-debug.apk`

### Para APK RELEASE (producción)

```bash
./BUILD_APK.sh
```

Este script:
- ✅ Carga las variables desde `.env`
- ✅ Verifica que todas las variables existan
- ✅ Compila en modo release con `--dart-define`
- ✅ Genera: `build/app/outputs/flutter-apk/app-release.apk`

## 📋 Variables de Entorno Requeridas

El archivo `.env` debe contener:

```env
OPENAI_API_KEY=sk-xxxx...
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SB_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
ENV=dev
```

## 🔍 Cómo Funciona

### 1. Carga de Variables

El código en `lib/config/env.dart` intenta leer las variables en este orden:

1. **Desde `--dart-define`** (usado en compilación):
   ```dart
   String.fromEnvironment('OPENAI_API_KEY')
   ```

2. **Desde archivo `.env`** (solo en desarrollo local):
   ```dart
   dotenv.maybeGet('OPENAI_API_KEY')
   ```

### 2. Compilación con Variables

Cuando usas `--dart-define`, Flutter compila las variables directamente en el código:

```bash
flutter build apk --debug \
    --dart-define=OPENAI_API_KEY="valor" \
    --dart-define=SUPABASE_URL="url" \
    ...
```

Estas variables quedan **compiladas en el APK** y están disponibles en tiempo de ejecución.

## 🚨 Errores Comunes

### Error: "No se encontró el archivo .env"
**Solución:** Asegúrate de que el archivo `.env` existe en la raíz del proyecto.

### Error: "Faltan variables de entorno"
**Solución:** Verifica que todas las variables requeridas estén en `.env`.

### Error: La app no se conecta a Supabase
**Causa:** Compilaste sin `--dart-define`
**Solución:** Usa `./BUILD_APK_DEBUG.sh` o `./BUILD_APK.sh`

## 📝 Comandos Manuales (si prefieres no usar los scripts)

### APK DEBUG:
```bash
source .env
flutter build apk --debug \
    --dart-define=OPENAI_API_KEY="${OPENAI_API_KEY}" \
    --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
    --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}" \
    --dart-define=SB_SERVICE_ROLE_KEY="${SB_SERVICE_ROLE_KEY}"
```

### APK RELEASE:
```bash
source .env
flutter build apk --release \
    --dart-define=OPENAI_API_KEY="${OPENAI_API_KEY}" \
    --dart-define=SUPABASE_URL="${SUPABASE_URL}" \
    --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}" \
    --dart-define=SB_SERVICE_ROLE_KEY="${SB_SERVICE_ROLE_KEY}"
```

## ✅ Verificación

Después de compilar, puedes verificar que las variables están incluidas ejecutando la app y revisando los logs. Deberías ver que Supabase se conecta correctamente.

## 📍 Ubicación de APKs Compilados

- **DEBUG:** `build/app/outputs/flutter-apk/app-debug.apk`
- **RELEASE:** `build/app/outputs/flutter-apk/app-release.apk`

## 🔐 Seguridad

⚠️ **IMPORTANTE:** Las variables de entorno compiladas con `--dart-define` quedan **visibles en el APK**. 

Para producción, considera:
- Usar variables de entorno del servidor cuando sea posible
- No incluir claves sensibles directamente en el código
- Usar Supabase Edge Functions para operaciones sensibles

