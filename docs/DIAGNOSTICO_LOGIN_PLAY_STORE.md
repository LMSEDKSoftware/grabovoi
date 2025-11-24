# 🔍 Diagnóstico: Problema de Login en Play Store

## 🚨 Problema Reportado
La app en Play Store no permite loguearse.

## 🔍 Posibles Causas

### 1. **Variables de Entorno No Incluidas en el Build** ⚠️ (MÁS PROBABLE)

**Síntoma:** La app no puede conectarse a Supabase, por lo tanto el login falla.

**Causa:** Si el AAB/APK se compiló sin `--dart-define`, las variables de entorno no estarán disponibles en tiempo de ejecución.

**Variables requeridas:**
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SB_SERVICE_ROLE_KEY`
- `OPENAI_API_KEY`

**Solución:**
1. Verificar cómo se compiló el AAB que se subió a Play Store
2. Asegurarse de usar `BUILD_AAB.sh` que incluye las variables
3. Recompilar el AAB con las variables correctas

### 2. **Configuración de Supabase Incorrecta**

**Síntoma:** Errores de conexión o autenticación fallida.

**Verificar:**
- URL de Supabase correcta en producción
- Anon Key válida
- Service Role Key válida
- Políticas RLS (Row Level Security) configuradas correctamente

**Solución:**
1. Verificar en Supabase Dashboard que las credenciales sean correctas
2. Revisar las políticas RLS en la tabla `users` y `auth.users`
3. Verificar que el email confirmation no esté bloqueando el login

### 3. **Problema con OAuth de Google**

**Síntoma:** Login con Google no funciona.

**Verificar:**
- OAuth configurado en Supabase Dashboard
- Redirect URL correcta en Google Cloud Console
- Client ID y Secret correctos

**Solución:**
1. Revisar configuración OAuth en Supabase
2. Verificar redirect URLs en Google Cloud Console
3. Asegurarse de que el SHA-1 del keystore esté registrado

### 4. **Problema con Email Confirmation**

**Síntoma:** Login falla con mensaje "Email not confirmed".

**Causa:** Supabase requiere confirmación de email por defecto.

**Solución:**
1. Deshabilitar email confirmation en Supabase Dashboard (Settings > Auth > Email Auth)
2. O enviar emails de confirmación automáticamente

### 5. **Problema con Políticas RLS (Row Level Security)**

**Síntoma:** Login exitoso pero no puede acceder a datos del usuario.

**Causa:** Las políticas RLS están bloqueando el acceso.

**Solución:**
1. Verificar políticas RLS en Supabase
2. Asegurarse de que usuarios autenticados puedan leer/escribir sus propios datos

## 🔧 Soluciones Paso a Paso

### Solución 1: Recompilar AAB con Variables de Entorno

```bash
# 1. Asegurarse de tener el archivo .env con todas las variables
cat .env

# 2. Compilar AAB con variables incluidas
./BUILD_AAB.sh

# 3. Verificar que el AAB se compiló correctamente
ls -lh build/app/outputs/bundle/release/app-release.aab

# 4. Subir el nuevo AAB a Play Store
```

### Solución 2: Verificar Configuración de Supabase

1. **Ir a Supabase Dashboard:**
   - Settings > API
   - Verificar URL y Keys

2. **Verificar Auth Settings:**
   - Settings > Auth > Email Auth
   - Deshabilitar "Enable email confirmations" si es necesario

3. **Verificar RLS Policies:**
   - Table Editor > users
   - Verificar que existan políticas para usuarios autenticados

### Solución 3: Verificar Logs de la App

Para diagnosticar el problema, necesitas ver los logs de la app en producción:

1. **Habilitar logging en producción:**
   - Agregar `print()` statements en `auth_service_simple.dart`
   - O usar un servicio de logging como Sentry

2. **Revisar logs en Play Console:**
   - Play Console > App > Quality > Crashes & ANRs
   - Buscar errores relacionados con autenticación

3. **Usar Firebase Crashlytics o Sentry:**
   - Integrar para capturar errores en producción

## 📋 Checklist de Verificación

Antes de subir una nueva versión a Play Store:

- [ ] Variables de entorno incluidas en el build (`--dart-define`)
- [ ] AAB compilado con `BUILD_AAB.sh`
- [ ] Credenciales de Supabase verificadas
- [ ] OAuth de Google configurado (si se usa)
- [ ] Políticas RLS verificadas
- [ ] Email confirmation configurado correctamente
- [ ] Logging habilitado para diagnóstico

## 🧪 Pruebas Locales

Para probar localmente antes de subir a Play Store:

```bash
# 1. Compilar APK release con variables
./BUILD_APK.sh

# 2. Instalar en dispositivo físico
adb install build/app/outputs/flutter-apk/app-release.apk

# 3. Probar login
# - Intentar login con email/password
# - Intentar login con Google
# - Verificar logs con: adb logcat | grep -i "auth\|supabase"
```

## 🔐 Verificación de Variables en el APK/AAB

Para verificar que las variables están incluidas:

```bash
# Extraer el APK/AAB y buscar las variables
unzip -p app-release.apk lib/arm64-v8a/libapp.so | strings | grep -i "supabase\|openai"
```

O mejor, agregar logging temporal:

```dart
// En lib/config/env.dart
print('🔍 SUPABASE_URL: ${Env.supabaseUrl}');
print('🔍 SUPABASE_ANON_KEY: ${Env.supabaseAnonKey.substring(0, 20)}...');
```

Si las variables están vacías, el problema es que no se incluyeron en el build.

## 🚀 Próximos Pasos Recomendados

1. **Inmediato:**
   - Verificar cómo se compiló el AAB actual en Play Store
   - Recompilar con `BUILD_AAB.sh` si es necesario
   - Subir nueva versión a Play Store

2. **Corto Plazo:**
   - Integrar Firebase Crashlytics o Sentry para logging
   - Agregar manejo de errores más descriptivo
   - Crear pantalla de diagnóstico para usuarios

3. **Largo Plazo:**
   - Mover variables sensibles a un backend
   - Usar Supabase Edge Functions para operaciones sensibles
   - Implementar sistema de feature flags

## 📞 Contacto para Soporte

Si el problema persiste después de verificar todo lo anterior:

1. Revisar logs de Supabase Dashboard (Logs > Auth)
2. Revisar logs de Google Cloud Console (si se usa OAuth)
3. Contactar soporte de Supabase si es necesario

---

**Última actualización:** Noviembre 2025  
**Versión del documento:** 1.0

