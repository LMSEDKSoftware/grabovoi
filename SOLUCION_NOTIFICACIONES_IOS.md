# Soluciones para Notificaciones iOS

## Problema
Las notificaciones no aparecen en el centro de notificaciones ni como badge en iOS.

## Opciones de Solución

### Opción 1: Verificar Permisos Manualmente (RECOMENDADO PRIMERO)

1. **Abrir Configuración de iOS**
   - Ve a: Configuración > MANIGRAB > Notificaciones
   - Asegúrate de que "Permitir notificaciones" esté **ACTIVADO**
   - Verifica que estén habilitados:
     - ✅ Pantalla bloqueada
     - ✅ Centro de notificaciones
     - ✅ Tiras (Banners)
     - ✅ Sonidos
     - ✅ Contador (Badge)

2. **Si no aparece en Configuración:**
   - Desinstala completamente la app
   - Reinstala desde cero
   - Al iniciar, debería solicitar permisos automáticamente

### Opción 2: Usar Script de Diagnóstico

He creado un script de diagnóstico que puedes ejecutar desde la app:

```dart
// En cualquier pantalla, agregar un botón temporal:
import 'scripts/test_ios_notifications.dart';

ElevatedButton(
  onPressed: () => testIOSNotifications(context),
  child: Text('Probar Notificaciones iOS'),
)
```

Este script:
- Verifica permisos
- Intenta solicitar permisos
- Envía una notificación de prueba
- Muestra logs detallados en la consola

### Opción 3: Verificar Logs en Xcode

1. Abre Xcode
2. Conecta tu dispositivo iOS
3. Ejecuta la app desde Xcode
4. Busca en la consola estos mensajes:
   - `✅ [iOS] Permisos de notificaciones otorgados`
   - `✅ [iOS] Notificación mostrada exitosamente`
   - Si ves `⚠️` o `❌`, ese es el problema

### Opción 4: Verificar Configuración del Proyecto

1. **Abrir en Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Verificar Capabilities:**
   - Selecciona el target "Runner"
   - Ve a "Signing & Capabilities"
   - Verifica que "Push Notifications" esté habilitado (aunque usemos notificaciones locales)

3. **Verificar Deployment Target:**
   - En "Build Settings"
   - "iOS Deployment Target" debe ser 12.0 o superior

### Opción 5: Resetear Permisos del Dispositivo

1. Ve a: Configuración > General > Transferir o Restablecer iPhone
2. Selecciona "Restablecer"
3. Elige "Restablecer ubicación y privacidad"
4. Esto resetea TODOS los permisos de TODAS las apps
5. Reinstala la app y acepta los permisos

### Opción 6: Verificar que la App Esté en Primer Plano

**IMPORTANTE:** En iOS, si la app está en primer plano, las notificaciones pueden no mostrarse automáticamente. 

**Solución:** Minimiza la app (presiona el botón home) y luego envía una notificación de prueba.

### Cambios Aplicados en el Código

1. ✅ Solicitud automática de permisos al inicializar
2. ✅ Verificación de permisos antes de mostrar notificaciones
3. ✅ Configuración correcta de `DarwinNotificationDetails`:
   - `presentAlert: true` - Para centro de notificaciones
   - `presentBadge: true` - Para badge en icono
   - `interruptionLevel: active` - Para que aparezcan en centro
4. ✅ Logging detallado para diagnóstico
5. ✅ Script de prueba creado

### Próximos Pasos Recomendados

1. **Primero:** Verifica manualmente en Configuración > MANIGRAB > Notificaciones
2. **Segundo:** Ejecuta el script de diagnóstico (`testIOSNotifications`)
3. **Tercero:** Revisa los logs en Xcode para ver qué está fallando
4. **Cuarto:** Si nada funciona, prueba resetear permisos del dispositivo

### Archivos Creados/Modificados

- `lib/services/notification_service.dart` - Mejorado con más logging
- `lib/utils/ios_notification_debug.dart` - Utilidad de diagnóstico
- `lib/scripts/test_ios_notifications.dart` - Script de prueba
- `lib/main.dart` - Solicitud automática de permisos

### Backup

Todos los archivos originales están en:
`backups/ios_fixes_20260112_201355/`
