# Auditoría de puntos a revisar - ManiGraB

**Fecha de auditoría:** 2025  
**Objetivo:** Identificar posibles fuentes de errores sin modificar código. Revisar detalladamente cada punto antes de aplicar cambios.

---

## 1. SEGURIDAD

### 1.1 API Keys y secretos hardcodeados
- **Archivos afectados:**
  - `lib/services/api_service.dart` - apiKey Supabase anon hardcodeada
  - `lib/services/robust_api_service.dart` - _apiKey hardcodeada
  - `lib/services/simple_api_service.dart` - apiKey hardcodeada
  - `lib/services/custom_domain_service.dart` - apiKey hardcodeada
  - `lib/services/proxy_api_service.dart` - apiKey hardcodeada
  - `lib/scripts/export_codes_from_supabase.dart` - apiKey en script
  - `lib/services/net_diag.dart` - Bearer token hardcodeado en línea 85
- **Riesgo:** Exposición de credenciales en repositorio, rotación imposible sin redeploy.
- **Revisar:** Migrar todas las APIs a `Env` o variables de entorno. Nunca commitear keys en código.

### 1.2 SSL Bypass en producción
- **Archivos afectados:**
  - `lib/services/api_service.dart` (líneas 127-131) - En el primer intento usa `SecureHttp.createUnsafeClient()` que acepta **cualquier** certificado SSL.
  - `lib/services/simple_api_service.dart` (líneas 66-71) - `badCertificateCallback` retorna `true` siempre.
- **Riesgo:** Man-in-the-middle, interceptación de tráfico en redes inseguras.
- **Revisar:** Eliminar SSL bypass en producción. Si era solo para diagnóstico, condicionar a modo debug o eliminarlo.

---

## 2. AUTENTICACIÓN Y ESTADO

### 2.1 Listeners de Supabase sin cancelar
- **Archivos afectados:**
  - `lib/main.dart` (línea 64) - `Supabase.instance.client.auth.onAuthStateChange.listen(...)` no se guarda ni cancela.
  - `lib/widgets/auth_wrapper.dart` (línea 39) - Mismo listener en `initState`, sin `StreamSubscription` ni `cancel()` en `dispose`.
- **Riesgo:** Posible fuga de memoria; listeners activos tras desmontar widgets; llamadas a `_checkAuthStatus` con widget desmontado.
- **Revisar:** Guardar `StreamSubscription` y llamar `.cancel()` en `dispose`.

### 2.2 setState / Navigator sin verificar `mounted`
- **Archivos afectados:**
  - `lib/widgets/subscription_welcome_modal.dart` (líneas 62-66): `_loadRemainingDays` llama `setState` sin comprobar `mounted` antes del `await`.
  - `lib/widgets/subscription_welcome_modal.dart` (líneas 75-82): `Future.delayed` usa `Navigator.of(context).push` sin verificar `mounted` tras el delay; el contexto puede estar desmontado.
- **Riesgo:** `setState() called after dispose()` y fallos de navegación.
- **Revisar:** Añadir `if (!mounted) return` tras cada `await` antes de `setState`/Navigator/ScaffoldMessenger.

---

## 3. BASE DE DATOS (SUPABASE)

### 3.1 Uso de `.single()` sin try-catch
- **Archivos afectados (entre otros):**
  - `lib/screens/codes/code_detail_screen.dart` (líneas 1016-1018, 1918-1920) - `_obtenerCategoriaPorCodigo`
  - `lib/screens/codes/repetition_session_screen.dart` (líneas 2360-2362)
  - `lib/screens/pilotaje/quantum_pilotage_screen.dart` (líneas 5904-5906)
  - `lib/services/supabase_service.dart` - múltiples `.single()`
  - `lib/services/auth_service_simple.dart` (líneas 52-54, 104-106)
  - `lib/services/resources_service.dart` (líneas 37-39)
  - `lib/services/diario_service.dart` (líneas 62-64, 391-393)
- **Riesgo:** `PgException` o similar si la consulta no devuelve exactamente una fila (0 o 2+).
- **Revisar:** Envolver en try-catch o usar `.maybeSingle()` con manejo de `null`.

### 3.2 Tablas / columnas que pueden no existir
- **StoreConfigService** usa:
  - `paquetes_cristales`
  - `elementos_tienda`
  - Columna `activo` en `codigos_premium` y `meditaciones_especiales`
- **Riesgo:** Si `database/migration_store_config_db.sql` no se ejecutó, fallan las consultas.
- **Revisar:** Confirmar que la migración se aplicó en todos los entornos. Valorar fallbacks o detección de schema antes de usar estas tablas.

---

## 4. VARIABLES DE ENTORNO Y CONFIGURACIÓN

### 4.1 Web sin .env
- **Archivos:** `lib/config/env.dart`, `lib/main.dart`
- **Riesgo:** En web, `dotenv` no carga `.env`; se depende de `--dart-define` vía `launch_chrome.sh`. Si se lanza sin ese script, Supabase/OpenAI pueden quedar sin configurar.
- **Revisar:** Documentar y validar en startup que `SUPABASE_URL` y `SUPABASE_ANON_KEY` estén definidos; fallar con mensaje claro si faltan.

### 4.2 OpenAI API Key vacía
- **Archivos:** `lib/screens/biblioteca/static_biblioteca_screen.dart`, `lib/screens/pilotaje/quantum_pilotage_screen.dart` - `Env.openAiKey`
- **Riesgo:** Si está vacía, las llamadas a OpenAI pueden devolver 401 o errores poco informativos.
- **Revisar:** Verificar que la key esté configurada antes de llamar a la API; deshabilitar o mostrar mensaje amigable si no está.

---

## 5. ASINCRONÍA Y RACE CONDITIONS

### 5.1 AuthWrapper y `_checkAuthStatus` concurrente
- **Archivo:** `lib/widgets/auth_wrapper.dart`
- **Riesgo:** `onAuthStateChange` puede disparar `_checkAuthStatus` varias veces seguidas; `didChangeDependencies` también lo llama. Riesgo de condiciones de carrera y múltiples `setState`.
- **Revisar:** Añadir debounce, flag de “en progreso” o cancelación del `Future` anterior.

### 5.2 Navegación tras `Future.delayed`
- **Archivo:** `lib/widgets/subscription_welcome_modal.dart` (líneas 75-82)
- **Riesgo:** Tras 300 ms el widget puede estar desmontado; usar `context` o `Navigator` puede fallar.
- **Revisar:** Comprobar `mounted` antes de navegar; o usar un `Completer`/callback controlado.

---

## 6. DEPENDENCIAS EXTERNAS

### 6.1 Cliente HTTP sin cerrar
- **Archivos:** `lib/services/api_service.dart`, `lib/services/simple_api_service.dart`
- **Riesgo:** Se crean `http.Client` (o `IOClient`) en cada petición; no se llama `.close()`. Posible fuga de recursos en uso intensivo.
- **Revisar:** Reutilizar un cliente (singleton) o asegurar `.close()` cuando corresponda.

### 6.2 Timeouts y reintentos
- **Archivos:** Varios servicios de API
- **Riesgo:** Timeouts fijos pueden ser cortos en redes lentas; reintentos sin backoff exponencial pueden saturar el servidor.
- **Revisar:** Ajustar timeouts y estrategia de reintentos según uso real.

---

## 7. UI / FLUTTER

### 7.1 `print()` en producción
- **Archivos:** Casi todos los servicios y varias pantallas
- **Riesgo:** Ruido en logs, posible fuga de información sensible, impacto en rendimiento.
- **Revisar:** Sustituir por `debugPrint`, `log` de `dart:developer` o un logger condicionado a modo debug.

### 7.2 `ScaffoldMessenger.of(context)` tras operaciones async
- **Archivos:** Múltiples pantallas tras `await`
- **Riesgo:** Si el widget se desmonta durante el `await`, `context` puede ser inválido.
- **Revisar:** Capturar `ScaffoldMessenger.of(context)` antes del `await` o verificar `mounted` y usar `ScaffoldMessenger.maybeOf(context)`.

### 7.3 Divisiones y posibles divisiones por cero
- **Archivo:** `lib/screens/rewards/premium_wallpaper_screen.dart` (líneas 158-160) - `expectedTotalBytes ?? 1` evita dividir por 0.
- **Revisar:** Buscar otros cálculos con división (`/`, `~/`) donde el divisor pueda ser 0.

---

## 8. LÓGICA DE NEGOCIO

### 8.1 Valores por defecto de StoreConfigService
- **Archivo:** `lib/services/store_config_service.dart`
- **Riesgo:** Si `paquetes_cristales` o `elementos_tienda` fallan, se devuelven listas vacías; la tienda usa fallbacks hardcodeados. Comportamiento correcto pero frágil ante cambios de schema.
- **Revisar:** Mantener fallbacks coherentes; añadir logs cuando se usen valores por defecto.

### 8.2 Caché de StoreConfigService
- **Archivo:** `lib/services/store_config_service.dart` - caché de 5 minutos
- **Riesgo:** Cambios en Supabase (precios, activar/desactivar) tardan hasta 5 min en reflejarse.
- **Revisar:** Documentar este retardo; valorar invalidación manual o tiempo de caché configurable.

---

## 9. PLATAFORMA ESPECÍFICA

### 9.1 iOS - Permisos y configuración
- **Archivo:** `ios/Runner/Info.plist`
- **Revisar:** Confirmar que `CFBundleURLTypes` para OAuth está bien configurado (ya añadido). Revisar descripciones de uso de cámara, micrófono, fotos, Face ID.

### 9.2 Android - network_security_config
- **Archivo:** `android/app/src/main/res/xml/network_security_config.xml`
- **Revisar:** No debe permitir cleartext ni confiar en certificados no válidos en release.

---

## 10. SCRIPTS Y HERRAMIENTAS

### 10.1 Scripts con credenciales
- **Archivo:** `lib/scripts/export_codes_from_supabase.dart`
- **Riesgo:** API key en código fuente.
- **Revisar:** Leer la key desde variable de entorno o archivo no versionado.

### 10.2 Supabase Edge Functions
- **Carpeta:** `supabase/functions/`
- **Revisar:** Variables de entorno (p. ej. `SENDGRID_API_KEY`), manejo de errores y CORS.

---

## Resumen de prioridad

| Prioridad | Categoría            | Cantidad aprox. |
|----------|----------------------|-----------------|
| Crítica  | API keys, SSL bypass | 7+ archivos     |
| Alta     | Listeners sin cancelar, setState/Navigator sin mounted | 4+ archivos |
| Alta     | `.single()` sin manejo de error | 15+ ubicaciones |
| Media    | Variables de entorno, tablas no migradas | 5+ puntos |
| Media    | Prints, cliente HTTP | Varios         |
| Baja     | Caché, timeouts, documentación | Varios   |

---

*Este documento es solo una guía de revisión. No se ha modificado código. Cada punto debe validarse en el entorno real antes de aplicar cambios.*
