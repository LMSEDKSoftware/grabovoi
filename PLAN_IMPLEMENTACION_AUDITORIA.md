# Plan de implementación – Auditoría ManiGraB

**Regla principal:** No modificar funcionalidades de la app. Si un cambio puede alterar el comportamiento visible o la lógica de negocio, **consultar primero**. Tras recibir la orden, hacer **respaldo de los archivos a modificar** y luego aplicar el cambio.

---

## Reglas de implementación

1. **No cambiar funcionalidad**  
   Los cambios deben ser solo de calidad/seguridad/estabilidad (quitar keys, añadir `mounted`, try-catch, etc.). Si algo implica cambiar flujos o UX, **consultar antes**.

2. **Respaldo antes de tocar**  
   Antes de modificar cualquier archivo listado en una fase:
   - Copiar el archivo a `backups/implementacion_auditoria/<fase>/` (o ejecutar el script de respaldo indicado).
   - Sólo después aplicar los cambios.

3. **Avance**  
   Actualizar `IMPLEMENTACION_AVANCE.md` al iniciar y al terminar cada ítem (Pendiente → En curso → Hecho / Bloqueado).

4. **Orden**  
   Respetar el orden por fases. No pasar a una fase siguiente si la anterior tiene ítems Hecho/Bloqueado pendientes de revisar.

---

## Fase 1 – CRÍTICA (Seguridad)

**Objetivo:** Eliminar API keys hardcodeadas y SSL bypass sin cambiar comportamiento funcional.

### Paso 1.1 – API keys a Env/variables
- **Archivos:**  
  `lib/services/api_service.dart`, `lib/services/robust_api_service.dart`, `lib/services/simple_api_service.dart`, `lib/services/custom_domain_service.dart`, `lib/services/proxy_api_service.dart`, `lib/services/net_diag.dart`, `lib/scripts/export_codes_from_supabase.dart`
- **Acción:** Sustituir la constante/key hardcodeada por lectura desde `Env` (o variable de entorno en scripts). Misma key, mismo uso; solo cambia el origen.
- **Respaldo:** Copiar los 7 archivos a `backups/implementacion_auditoria/fase1/` antes de editar.

### Paso 1.2 – Eliminar SSL bypass en producción
- **Archivos:**  
  `lib/services/api_service.dart`, `lib/services/simple_api_service.dart`
- **Acción:**  
  - En `api_service.dart`: no usar `createUnsafeClient()` en el primer intento; usar siempre cliente seguro, o condicionar a `kDebugMode` si se mantiene bypass solo en desarrollo.  
  - En `simple_api_service.dart`: quitar `badCertificateCallback` que retorna `true` (o condicionar a debug).  
  Sin cambiar URLs ni lógica de negocio.
- **Respaldo:** Incluido en Paso 1.1 si ya se respaldó; si no, respaldar estos 2 archivos.

---

## Fase 2 – ALTA (Autenticación y estado)

**Objetivo:** Evitar fugas de memoria y uso de contexto desmontado.

### Paso 2.1 – Cancelar listeners de auth
- **Archivos:**  
  `lib/main.dart`, `lib/widgets/auth_wrapper.dart`
- **Acción:** Guardar `StreamSubscription` de `onAuthStateChange.listen` y llamar `.cancel()` en el `dispose` correspondiente (en `AuthWrapper`) o al cerrar la app si aplica en `main`. No cambiar la lógica de redirección ni de sesión.
- **Respaldo:** Copiar ambos archivos a `backups/implementacion_auditoria/fase2/` antes de editar.

### Paso 2.2 – setState y Navigator con `mounted`
- **Archivos:**  
  `lib/widgets/subscription_welcome_modal.dart`
- **Acción:** En `_loadRemainingDays`, tras el `await`, comprobar `if (!mounted) return` antes de `setState`. En el callback de `Future.delayed`, comprobar `mounted` antes de `Navigator.of(context).push`. No cambiar flujos ni textos.
- **Respaldo:** Copiar a `backups/implementacion_auditoria/fase2/` antes de editar.

---

## Fase 3 – ALTA (Base de datos)

**Objetivo:** Evitar excepciones no controladas por `.single()` y dependencia de schema no migrado.

### Paso 3.1 – Proteger consultas `.single()`
- **Archivos (prioridad):**  
  `lib/screens/codes/code_detail_screen.dart`, `lib/screens/codes/repetition_session_screen.dart`, `lib/screens/pilotaje/quantum_pilotage_screen.dart`  
  (función tipo `_obtenerCategoriaPorCodigo` / uso de `.single()` para categoría).
- **Resto:**  
  `lib/services/supabase_service.dart`, `lib/services/auth_service_simple.dart`, `lib/services/resources_service.dart`, `lib/services/diario_service.dart`, y otros que usen `.single()` según auditoría.
- **Acción:** En cada uso de `.single()` que pueda devolver 0 o 2+ filas, envolver en try-catch y usar valor por defecto o `maybeSingle()` con manejo de `null`. No cambiar reglas de negocio (solo evitar crash).
- **Respaldo:** Copiar cada archivo a `backups/implementacion_auditoria/fase3/` antes de editar.

### Paso 3.2 – Migración y fallbacks StoreConfig
- **Acción (documentación/validación):** Confirmar que `database/migration_store_config_db.sql` está aplicada en todos los entornos. Opcional: en `StoreConfigService`, si la tabla no existe o falla la query, mantener fallbacks actuales y registrar log. No cambiar precios ni lógica de tienda.
- **Respaldo:** Si se toca `lib/services/store_config_service.dart`, copiarlo a `backups/implementacion_auditoria/fase3/`.

---

## Fase 4 – MEDIA (Configuración y entorno)

**Objetivo:** Validar configuración y evitar errores silenciosos por keys vacías.

### Paso 4.1 – Validación Supabase/OpenAI al inicio
- **Archivos:**  
  `lib/main.dart` y/o `lib/config/env.dart`
- **Acción:** Tras inicializar Supabase, si `SUPABASE_URL` o `SUPABASE_ANON_KEY` están vacíos (web o móvil), log claro o mensaje de “configuración incompleta”. Opcional: en pantallas que usan OpenAI, comprobar `Env.openAiKey.isNotEmpty` antes de llamar y mostrar mensaje amigable si está vacía. No cambiar flujos de login ni de IA.
- **Respaldo:** Copiar archivos tocados a `backups/implementacion_auditoria/fase4/`.

### Paso 4.2 – Documentar lanzamiento web
- **Acción:** En README o en `GUIA_COMPILACION_LIMPIA.md` / documentación, indicar que en web se debe usar `./scripts/launch_chrome.sh` (o equivalente con `--dart-define`) para inyectar variables. Sin cambios de código funcional.

---

## Fase 5 – MEDIA (Asincronía y recursos)

**Objetivo:** Reducir condiciones de carrera y fugas de recursos.

### Paso 5.1 – AuthWrapper: evitar _checkAuthStatus concurrente
- **Archivo:**  
  `lib/widgets/auth_wrapper.dart`
- **Acción:** Añadir flag “en progreso” o cancelación del `Future` anterior para no lanzar varios `_checkAuthStatus` a la vez. Misma lógica de redirección.
- **Respaldo:** Incluido en Fase 2; si ya se modificó, respaldar de nuevo antes de este paso.

### Paso 5.2 – Cliente HTTP reutilizable o cierre
- **Archivos:**  
  `lib/services/api_service.dart`, `lib/services/simple_api_service.dart`
- **Acción:** Usar un cliente HTTP compartido (singleton) o asegurar `.close()` cuando corresponda. No cambiar URLs ni reintentos de contenido.
- **Respaldo:** Usar respaldos de Fase 1 o copiar de nuevo a `backups/implementacion_auditoria/fase5/`.

---

## Fase 6 – BAJA (Calidad y mantenimiento)

**Objetivo:** Mejorar logs y documentación sin tocar funcionalidad.

### Paso 6.1 – Sustituir `print()` por `debugPrint` / logger
- **Archivos:** Múltiples (servicios y pantallas).
- **Acción:** Reemplazar `print(...)` por `debugPrint(...)` (o logger condicionado a debug) en los archivos listados en la auditoría. Sin cambiar mensajes de usuario ni flujos.
- **Respaldo:** Por lotes; copiar cada archivo antes de modificar a `backups/implementacion_auditoria/fase6/`.

### Paso 6.2 – Timeouts y reintentos (opcional)
- **Acción:** Revisar timeouts y estrategia de reintentos; ajustar solo si hay consenso. Documentar en este plan o en IMPLEMENTACION_AVANCE si se pospone.

---

## Respaldo de archivos

- **Carpeta base:** `backups/implementacion_auditoria/`
- **Por fase:** `backups/implementacion_auditoria/fase1/`, `fase2/`, … con copia de cada archivo **antes** de la primera modificación en esa fase.
- **Nomenclatura:** Mantener el mismo nombre de archivo (ej. `api_service.dart`) dentro de la carpeta de la fase; opcional: añadir sufijo con fecha si se hacen varios respaldos (ej. `api_service_20250213.dart`).
- **Script opcional:** Ver `backups/implementacion_auditoria/README.md` para comandos o script de respaldo por fase.

---

## Orden de ejecución recomendado

1. Crear respaldos de Fase 1 → Ejecutar Paso 1.1 → Paso 1.2 → Actualizar IMPLEMENTACION_AVANCE.
2. Respaldo Fase 2 → Paso 2.1 → Paso 2.2 → Actualizar avance.
3. Respaldo Fase 3 → Paso 3.1 → Paso 3.2 → Actualizar avance.
4. Seguir Fases 4, 5 y 6 de la misma forma.

Si en cualquier paso se requiere **cambiar funcionalidad**, detener, documentar en IMPLEMENTACION_AVANCE como “Bloqueado – pendiente consulta” y consultar antes de seguir.
