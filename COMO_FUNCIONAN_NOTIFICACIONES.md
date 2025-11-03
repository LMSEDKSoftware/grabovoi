# 📱 ¿CÓMO FUNCIONAN LAS NOTIFICACIONES?

## 🎯 TIPO DE NOTIFICACIONES IMPLEMENTADAS

Las notificaciones que implementé son **NOTIFICACIONES LOCALES DEL SISTEMA OPERATIVO**, NO son diálogos dentro de la app.

---

## 📲 DÓNDE SE MUESTRAN (PLATAFORMA ESPECÍFICA)

### ✅ ANDROID

**Cómo se ven**:
- Aparecen en la **barra de notificaciones superior** del teléfono
- Son **deslizables** (swipeable) desde arriba
- Se acumulan en el **centro de notificaciones**
- Pueden tener **sonido** y **vibración** según configuración
- Se muestran aunque la app esté cerrada

**Ejemplo visual**:
```
┌─────────────────────────────────┐
│ 📢 ManiGrab                     │
│ 🎉 ¡Bienvenido al viaje        │
│    cuántico!                    │
│                                 │
│ Has completado tu primer        │
│ pilotaje consciente.            │
└─────────────────────────────────┘
```

### ✅ iOS

**Cómo se ven**:
- Banner en la **parte superior** de la pantalla
- Pueden convertirse en **alertas** si la app está activa
- Van al **Centro de Notificaciones**
- Respetan el modo "No molestar"
- **No aparecen si la app está activa** (por defecto)

### ❌ WEB (CHROME)

**NO FUNCIONAN** - Implementé checks para evitar errores:
```dart
if (kIsWeb) {
  print('⚠️ Notificaciones locales no disponibles en web');
  return;
}
```

---

## 🔔 DOS TIPOS DE NOTIFICACIONES

### 1️⃣ INMEDIATAS (Event-Driven)
Se muestran **inmediatamente** cuando sucede algo:

**Ejemplo**:
```dart
// Usuario completa su primer pilotaje
await NotificationService().notifyFirstPilotage(userName);
// → NOTIFICACIÓN INMEDIATA en el teléfono
```

**Cuándo aparecen**:
- ✅ Después de completar un pilotaje
- ✅ Al alcanzar un milestone (3, 7, 21 días)
- ✅ Cuando sube el nivel energético
- ✅ Al completar un desafío
- ✅ Feedback "Gracias por mantener racha"

### 2️⃣ PROGRAMADAS (Scheduled)
Se programan para aparecer en **horarios específicos**:

**Ejemplo**:
```dart
// Programar para mañana a las 9:00 AM
await NotificationService().scheduleNotification(
  title: '🌅 Tu Código Grabovoi de Hoy',
  body: 'Tu código de hoy espera por ti...',
  scheduledDate: DateTime(...9:00 AM...),
);
// → NOTIFICACIÓN aparece mañana a las 9 AM
```

**Cuándo aparecen**:
- ✅ 9:00 AM - Código del día
- ✅ Hora matutina configurada (ej: 8:00 AM)
- ✅ Hora vespertina configurada (ej: 7:00 PM)
- ✅ 6:00 PM - Alerta de racha en riesgo

---

## 🔄 FLUJO COMPLETO

### Ejemplo: Primer Pilotaje

```
1. Usuario completa pilotaje
        ↓
2. BibliotecaSupabaseService.registrarPilotaje()
        ↓
3. NotificationScheduler.onPilotageCompleted()
        ↓
4. Detecta: Es el primer pilotaje? (totalPilotages == 1)
        ↓
5. NotificationService.notifyFirstPilotage()
        ↓
6. NotificationService.showNotification()
        ↓
7. FlutterLocalNotificationsPlugin.show()
        ↓
8. Sistema Operativo Android/iOS
        ↓
9. 📱 NOTIFICACIÓN APARECE EN EL TELÉFONO
```

---

## 🎨 CARACTERÍSTICAS VISUALES

### Android
- **Ícono**: 🔔 o el ícono de la app
- **Título**: Texto grande en negrita
- **Cuerpo**: Texto pequeño descriptivo
- **Big Text**: Todo el mensaje expandible
- **Prioridad Visual**:
  - HIGH: Aparece arriba, sonido fuerte
  - MEDIUM: Posición normal, sonido normal
  - LOW: Discreta, tal vez sin sonido

### iOS
- **Banner**: Deslizable desde arriba
- **Alert**: Popup si la app está activa (configurable)
- **Badge**: Número en el ícono de la app
- **Sound**: Personalizable

---

## ⚙️ DIFERENCIAS CON DIALOGS/ALERTS DE LA APP

| Característica | Notificaciones Sistema | Dialogs de App |
|----------------|------------------------|----------------|
| **Cuándo aparecen** | App cerrada o en background | Solo cuando app está activa |
| **Dónde** | Barra superior del teléfono | Dentro de la app |
| **Interacción** | Toque abre la app | Botones en el dialog |
| **Persistencia** | Permanecen en centro | Se cierran |
| **Sonido/Vibra** | ✅ Sí | ❌ No |
| **Configuración SO** | Respetada (DND, etc) | Ignorada |

---

## 🧪 CÓMO PROBAR

### En Android (APK)
1. Instala `manigrab-notificaciones.apk`
2. Completa un pilotaje
3. **Mira la barra superior** del teléfono
4. **Desliza hacia abajo** para ver el centro de notificaciones
5. Toca la notificación → abre la app

### En Web (Chrome)
**NO aparecerán** - Solo se verán en consola:
```
⚠️ Notificaciones locales no disponibles en web
```

---

## ⚠️ PERMISOS REQUERIDOS

### Android
El APK incluye en `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

Usuario debe **permitir notificaciones** la primera vez.

### iOS
Requiere permiso explícito del usuario vía `requestPermissions()`.

---

## 📊 EJEMPLOS PRÁCTICOS

### Ejemplo 1: Milestone de Racha
```
Usuario tiene racha de 2 días
↓
Completa pilotaje en día 3
↓
NotificationScheduler detecta: consecutiveDays == 3
↓
Android muestra:
┌────────────────────────────┐
│ 🎉 ¡Felicidades!          │
│ 3 días consecutivos.      │
│ Tu energía comienza a     │
│ estabilizarse.            │
└────────────────────────────┘
```

### Ejemplo 2: Recordatorio Matutino
```
Usuario configuró recordatorio a las 8:00 AM
↓
Programada para las 8:00 AM
↓
Usuario duerme con el teléfono
↓
A las 8:00 AM exactas:
┌────────────────────────────┐
│ ☀️ Buenos días, Piloto    │
│ Consciente                 │
│ ¿Listo para comenzar el   │
│ día con energía cuántica? │
└────────────────────────────┘
(Con vibración y sonido)
```

---

## 🔧 CONFIGURACIÓN DISPONIBLE

El usuario puede controlar:
- ✅ Activar/desactivar TODAS las notificaciones
- ✅ Sonido individual (on/off)
- ✅ Vibración individual (on/off)
- ✅ Horarios personalizados
- ✅ Días silenciosos específicos
- ✅ Categorías específicas (racha, logros, etc)

---

## 💡 IMPORTANTE

**LAS NOTIFICACIONES NO SON PARTE DE LA UI DE LA APP**

Son parte del sistema operativo. Esto significa:

✅ Funcionan con app cerrada  
✅ Respetan "No molestar"  
✅ Configurables desde Ajustes del teléfono  
✅ Se ven en barra superior  
✅ Son deslizables (swipeable)  
❌ NO son popups dentro de la app  
❌ NO bloquean la interacción  
❌ NO tienen botones de acción (a menos que implementes "Action Buttons")  

---

## 📝 RESUMEN

- **Dónde**: Barra superior del teléfono + Centro de notificaciones
- **Cuándo**: Según evento o horario programado
- **Cómo**: Sistema operativo nativo (Android/iOS)
- **Por qué**: Engagement, recordatorios, celebración de logros
- **Web**: NO soportadas (implementado correctamente)

**¡Es el sistema de notificaciones estándar que usan todas las apps móviles!** 📱🔔

