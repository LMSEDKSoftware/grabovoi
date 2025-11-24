# 📋 ANÁLISIS COMPLETO DE NOTIFICACIONES

## 🔔 RESUMEN GENERAL

La app tiene un sistema de notificaciones completo que incluye:
- **Notificaciones programadas** (diarias a horas específicas)
- **Notificaciones por eventos** (acciones del usuario)
- **Notificaciones por progreso** (logros y milestones)
- **Notificaciones de recordatorios** (rachas, desafíos)

---

## 📅 1. NOTIFICACIONES PROGRAMADAS (Diarias)

Estas notificaciones se programan automáticamente según las preferencias del usuario.

### 1.1. Recordatorio de Código del Día
- **Método**: `scheduleDailyNotifications()` → `scheduleNotification()`
- **Cuándo se programa**: Cada día a las **9:00 AM**
- **Condiciones**:
  - Preferencia `dailyCodeReminders` debe estar habilitada
  - Notificaciones generales deben estar habilitadas
  - No debe ser día silencioso
- **Título**: "🌅 Tu Código Grabovoi de Hoy"
- **Mensaje**: "Tu código de hoy espera por ti. ¡Recuerda que tu energía se eleva con cada pilotaje consciente!"
- **Tipo**: `NotificationType.dailyCodeReminder`
- **Prioridad**: Baja
- **Acción que la lanza**: Se programa automáticamente al inicializar la app o cuando se actualizan las preferencias de notificaciones

### 1.2. Recordatorio Matutino
- **Método**: `scheduleDailyNotifications()` → `scheduleNotification()`
- **Cuándo se programa**: Hora configurada por el usuario (`preferredMorningTime`), programada para **toda la semana**
- **Condiciones**:
  - Preferencia `morningReminders` debe estar habilitada
  - Notificaciones generales deben estar habilitadas
  - No debe ser día silencioso
- **Título**: "☀️ Buenos días, Piloto Consciente"
- **Mensaje**: "¿Listo para comenzar el día con energía cuántica? Un pilotaje consciente de 2 minutos transformará tu mañana."
- **Tipo**: `NotificationType.morningRoutineReminder`
- **Prioridad**: Baja
- **Acción que la lanza**: Se programa automáticamente al inicializar la app o cuando se actualizan las preferencias de notificaciones

### 1.3. Recordatorio Vespertino
- **Método**: `scheduleDailyNotifications()` → `scheduleNotification()`
- **Cuándo se programa**: Hora configurada por el usuario (`preferredEveningTime`), programada para **toda la semana**
- **Condiciones**:
  - Preferencia `eveningReminders` debe estar habilitada
  - Notificaciones generales deben estar habilitadas
  - No debe ser día silencioso
- **Título**: "🌙 Completa tu práctica cuántica"
- **Mensaje**: "Excelente día. ¿Completas tu práctica cuántica de hoy? Tu disciplina está transformando tu realidad."
- **Tipo**: `NotificationType.eveningRoutineReminder`
- **Prioridad**: Baja
- **Acción que la lanza**: Se programa automáticamente al inicializar la app o cuando se actualizan las preferencias de notificaciones

---

## ⚡ 2. NOTIFICACIONES POR ACCIONES DEL USUARIO

Estas notificaciones se lanzan inmediatamente después de que el usuario completa una acción.

### 2.1. Primer Pilotaje Completado
- **Método**: `NotificationScheduler().onPilotageCompleted()` → `notifyFirstPilotage()`
- **Cuándo se lanza**: Cuando el usuario completa su **primer pilotaje** (`totalPilotages == 1`)
- **Dónde se activa**: 
  - `biblioteca_supabase_service.dart` → `registrarPilotaje()` → `NotificationScheduler().onPilotageCompleted()`
- **Título**: "🎉 ¡Bienvenido al viaje cuántico!"
- **Mensaje**: "Has completado tu primer pilotaje consciente. El viaje de transformación comienza."
- **Tipo**: `NotificationType.firstPilotage`
- **Prioridad**: Media
- **Acción del usuario**: Completar una sesión de pilotaje (desde `pilotaje_screen.dart` o `quantum_pilotage_screen.dart`)

### 2.2. Disfruta tu Pilotaje
- **Método**: `NotificationScheduler().onRepetitionCompleted()` → `notifyEnjoyPilotage()`
- **Cuándo se lanza**: Después de completar **cualquier repetición** de código
- **Dónde se activa**:
  - `biblioteca_supabase_service.dart` → `registrarRepeticion()` → `NotificationScheduler().onRepetitionCompleted()`
- **Título**: "🎧 Disfruta tu pilotaje"
- **Mensaje**: "Respira, siente, transforma."
- **Tipo**: `NotificationType.enjoyYourPilotage`
- **Prioridad**: Media
- **Acción del usuario**: Completar una repetición de código (desde `repetition_session_screen.dart`)

### 2.3. Subida de Nivel Energético
- **Método**: `NotificationScheduler().onPilotageCompleted()` → `notifyEnergyLevelUp()`
- **Cuándo se lanza**: Cuando el nivel energético del usuario **aumenta** después de un pilotaje
- **Condiciones**:
  - `energyLevel > _lastKnownEnergyLevel`
  - Preferencia `energyLevelAlerts` debe estar habilitada
- **Título**: "⚡ ¡Tu energía ha subido!"
- **Mensaje**: "Ahora estás en nivel {newLevel}/10. ¡Sigue así!"
- **Tipo**: `NotificationType.energyLevelUp`
- **Prioridad**: Media
- **Acción del usuario**: Completar un pilotaje que incremente el nivel energético

### 2.4. Nivel Energético Máximo Alcanzado
- **Método**: `NotificationScheduler().onPilotageCompleted()` → `notifyEnergyMaxReached()`
- **Cuándo se lanza**: Cuando el usuario alcanza el **nivel 10/10** de energía
- **Condiciones**: `energyLevel >= 10`
- **Título**: "👑 ¡MAESTRÍA!"
- **Mensaje**: "Has alcanzado el nivel máximo de energía (10/10). Eres un Piloto Consciente cuántico."
- **Tipo**: `NotificationType.energyMaxReached`
- **Prioridad**: Media
- **Sonido**: Sí (prioridad alta)
- **Acción del usuario**: Alcanzar el nivel máximo de energía después de un pilotaje

---

## 🎯 3. NOTIFICACIONES DE LOGROS Y MILESTONES

Estas notificaciones se lanzan cuando el usuario alcanza hitos específicos en su progreso.

### 3.1. Milestones de Pilotajes Completados
- **Método**: `NotificationScheduler().onPilotageCompleted()` → `notifyPilotageMilestone()`
- **Cuándo se lanza**: Cuando el total de pilotajes alcanza: **10, 50, 100, 500, o 1000**
- **Títulos y mensajes**:
  - **10 pilotajes**: "💪 ¡10 pilotajes completados!" - "Estás construyendo un hábito poderoso."
  - **50 pilotajes**: "⭐ 50 pilotajes completados" - "Eres un Piloto Intermedio."
  - **100 pilotajes**: "🌟 100 pilotajes completados" - "¡Maestría Intermedia alcanzada!"
  - **500 pilotajes**: "👑 500 pilotajes completados" - "Eres un Experto en Piloto Cuántico."
  - **1000 pilotajes**: "🏆 1000 pilotajes completados" - "¡LEYENDA VIVIENTE! Has dominado el arte."
- **Tipos**: `milestone10Pilotages`, `milestone50Pilotages`, `milestone100Pilotages`, `milestone500Pilotages`, `milestone1000Pilotages`
- **Prioridad**: Media (excepto 1000 que tiene sonido)
- **Acción del usuario**: Completar un pilotaje que lleve el total a uno de estos números exactos

### 3.2. Milestones de Racha (Días Consecutivos)
- **Método**: `NotificationScheduler().onPilotageCompleted()` → `notifyStreakMilestone()`
- **Cuándo se lanza**: Cuando los días consecutivos alcanzan: **3, 7, 14, 21, o 30 días**
- **Títulos y mensajes**:
  - **3 días**: "🎉 ¡Felicidades!" - "3 días consecutivos. Tu energía comienza a estabilizarse."
  - **7 días**: "🌟 ¡Increíble!" - "7 días consecutivos. Estás creando un hábito poderoso."
  - **14 días**: "💎 ¡Extraordinario!" - "14 días consecutivos. Tu disciplina está transformando tu realidad."
  - **21 días**: "👑 ¡Épico!" - "21 días consecutivos. El hábito está formado. Eres un Piloto Consciente."
  - **30 días**: "🏆 ¡Legendario!" - "30 días consecutivos. Has alcanzado Maestría en Constancia."
- **Tipos**: `streakMilestone3`, `streakMilestone7`, `streakMilestone14`, `streakMilestone21`, `streakMilestone30`
- **Prioridad**: Media (excepto 21 y 30 que tienen sonido)
- **Condiciones**:
  - `consecutiveDays > _lastKnownStreakDays` (solo cuando aumenta)
  - Debe alcanzar exactamente uno de los números mencionados
- **Acción del usuario**: Completar un pilotaje que incremente los días consecutivos a uno de estos hitos

### 3.3. Gracias por Mantener la Racha
- **Método**: `NotificationScheduler().onPilotageCompleted()` → `notifyThanksForStreak()`
- **Cuándo se lanza**: Cuando el usuario mantiene una racha de **3+ días** y completa un pilotaje
- **Condiciones**:
  - `consecutiveDays >= 3`
  - `_lastKnownStreakDays != consecutiveDays` (solo una vez por día)
- **Título**: "👏 Gracias por mantener tu racha activa"
- **Mensaje**: "Tu disciplina cuántica está transformando tu realidad."
- **Tipo**: `NotificationType.thanksForMaintainingStreak`
- **Prioridad**: Media
- **Acción del usuario**: Completar un pilotaje manteniendo una racha activa de 3+ días

---

## ⚠️ 4. NOTIFICACIONES DE RACHA EN RIESGO/PERDIDA

Estas notificaciones se lanzan cuando el usuario corre riesgo de perder su racha.

### 4.1. Racha en Riesgo (12 horas)
- **Método**: `NotificationScheduler._checkStreakStatus()` → `notifyStreakAtRisk()`
- **Cuándo se lanza**: 
  - Verificación periódica cada **30 minutos** (`checkAndSendNotifications()`)
  - Cuando han pasado **más de 12 horas** desde el último pilotaje
  - Y la hora actual es **6:00 PM - 6:30 PM**
  - Y la racha es de **3+ días**
- **Condiciones**:
  - Preferencia `streakReminders` debe estar habilitada
  - `hoursSinceLastSession >= 12`
  - `now.hour == 18 && now.minute < 30`
  - `consecutiveDays >= 3`
- **Título**: "⚠️ Racha en Riesgo"
- **Mensaje**: "Atención {userName}: Tu racha de {streakDays} días está en riesgo. ¡Hay tiempo aún! Realiza tu pilotaje de hoy para mantenerla viva."
- **Tipo**: `NotificationType.streakAtRisk12h`
- **Prioridad**: Alta
- **Acción que la lanza**: Verificación automática periódica del scheduler

### 4.2. Racha Perdida
- **Método**: `NotificationScheduler._checkStreakStatus()` → `notifyStreakLost()`
- **Cuándo se lanza**:
  - Verificación periódica cada **30 minutos** (`checkAndSendNotifications()`)
  - Cuando han pasado **24 horas o más** desde el último pilotaje
  - Y la racha era de **3+ días**
- **Condiciones**:
  - Preferencia `streakReminders` debe estar habilitada
  - `hoursSinceLastSession >= 24`
  - `consecutiveDays >= 3`
- **Título**: "😔 Racha Interrumpida"
- **Mensaje**: "Tu racha de {streakDays} días se ha interrumpido, pero es solo un nuevo comienzo. El Piloto Consciente persevera. ¡Comienza de nuevo hoy!"
- **Tipo**: `NotificationType.streakLost`
- **Prioridad**: Alta
- **Acción que la lanza**: Verificación automática periódica del scheduler

---

## 🏆 5. NOTIFICACIONES DE DESAFÍOS

Estas notificaciones están relacionadas con los desafíos activos del usuario.

### 5.1. Acción de Desafío Completada
- **Método**: `ChallengeTrackingService._showActionNotification()` → `showActionCompletedNotification()`
- **Cuándo se lanza**: Cuando el usuario completa una **acción que cuenta para un desafío activo**
- **Dónde se activa**:
  - `challenge_tracking_service.dart` → `recordUserAction()` → `_showActionNotification()`
- **Título**: "¡Acción Completada! 🎉"
- **Mensaje**: "Has completado: {actionName} en {challengeName}"
- **Tipos de acciones**:
  - Sesión de pilotaje
  - Pilotaje compartido
  - Repetición de código
  - Uso de la aplicación
  - Código específico
- **Tipo**: `NotificationType.challengeDayCompleted`
- **Prioridad**: Media
- **Acción del usuario**: Cualquier acción que avance un desafío activo

### 5.2. Desafío Completado
- **Método**: `notifyChallengeCompleted()`
- **Cuándo se lanza**: Cuando el usuario **completa un desafío completo**
- **Título**: "🏆 ¡DESAFÍO COMPLETADO!"
- **Mensaje**: "{challengeName}. Has desbloqueado: {awards}. ¡Felicidades Piloto Consciente!"
- **Tipo**: `NotificationType.challengeCompleted`
- **Prioridad**: Media
- **Sonido**: Sí
- **Estado actual**: Método existe pero **no está siendo llamado** desde ningún lugar en el código actual

### 5.3. Día de Desafío Completado
- **Método**: `notifyChallengeDayCompleted()`
- **Cuándo se lanza**: Cuando el usuario completa **un día específico** de un desafío
- **Título**: "✅ ¡Día completado!"
- **Mensaje**: "Día {day}/{total} del desafío {challengeName}. ¡Excelente trabajo!"
- **Tipo**: `NotificationType.challengeDayCompleted`
- **Prioridad**: Media
- **Estado actual**: Método existe pero **no está siendo llamado** desde ningún lugar en el código actual

### 5.4. Recordatorio Diario de Desafío
- **Método**: `notifyChallengeDailyReminder()`
- **Cuándo se lanza**: Recordatorio diario cuando hay un desafío activo
- **Título**: "🎯 Tienes un desafío activo"
- **Mensaje**: "{challengeName}. Día {day} de {total}. ¡Completa tus acciones hoy!"
- **Tipo**: `NotificationType.challengeDailyReminder`
- **Prioridad**: Media
- **Estado actual**: Método existe pero **no está siendo llamado** desde ningún lugar en el código actual

### 5.5. Desafío en Riesgo
- **Método**: `notifyChallengeAtRisk()`
- **Cuándo se lanza**: Cuando un desafío está en riesgo de no completarse
- **Título**: "⚠️ Tu desafío está en riesgo"
- **Mensaje**: "{challengeName} está en riesgo. ¡Completa el día {day} hoy!"
- **Tipo**: `NotificationType.challengeAtRisk`
- **Prioridad**: Alta
- **Estado actual**: Método existe pero **no está siendo llamado** desde ningún lugar en el código actual

---

## 📊 6. NOTIFICACIONES DE RESUMEN Y PERSONALIZACIÓN

Estas notificaciones proporcionan información agregada o personalizada.

### 6.1. Código Personalizado Recomendado
- **Método**: `notifyPersonalizedCode()`
- **Cuándo se lanza**: Cuando el sistema recomienda un código personalizado basado en la actividad del usuario
- **Título**: "✨ Código Personalizado para Ti"
- **Mensaje**: "Basado en tu actividad, este código podría ser perfecto para ti hoy: {code}"
- **Tipo**: `NotificationType.personalizedCodeRecommendation`
- **Prioridad**: Baja
- **Estado actual**: Método existe pero **no está siendo llamado** desde ningún lugar en el código actual

### 6.2. Resumen Semanal
- **Método**: `notifyWeeklySummary()`
- **Cuándo se lanza**: Resumen semanal del progreso del usuario
- **Título**: "📊 Tu semana cuántica"
- **Mensaje**: "{pilotages} pilotajes, {codesUsed} códigos usados, nivel {energyLevel}/10. ¡Sigue así!"
- **Tipo**: `NotificationType.weeklyProgressSummary`
- **Prioridad**: Media
- **Estado actual**: Método existe pero **no está siendo llamado** desde ningún lugar en el código actual

---

## 🔄 FLUJO DE ACTIVACIÓN

### Al Inicializar la App (`main.dart`):
1. Se inicializa `NotificationScheduler().initialize()`
2. Se programan todas las notificaciones diarias según preferencias
3. Se inicia verificación periódica cada 30 minutos

### Al Completar un Pilotaje:
1. `biblioteca_supabase_service.dart` → `registrarPilotaje()`
2. → `NotificationScheduler().onPilotageCompleted()`
3. Se verifican múltiples condiciones y se envían notificaciones correspondientes:
   - Primer pilotaje
   - Subida de nivel energético
   - Nivel máximo alcanzado
   - Milestones de pilotajes (10, 50, 100, 500, 1000)
   - Milestones de racha (3, 7, 14, 21, 30)
   - Gracias por mantener racha

### Al Completar una Repetición:
1. `biblioteca_supabase_service.dart` → `registrarRepeticion()`
2. → `NotificationScheduler().onRepetitionCompleted()`
3. Se envía notificación "Disfruta tu pilotaje"

### Verificaciones Periódicas (cada 30 minutos):
1. `NotificationScheduler.checkAndSendNotifications()`
2. Verifica estado de racha (`_checkStreakStatus()`)
3. Puede enviar:
   - Racha en riesgo (si pasaron 12+ horas y es 6 PM)
   - Racha perdida (si pasaron 24+ horas)

### Al Registrar Acción de Desafío:
1. `challenge_tracking_service.dart` → `recordUserAction()`
2. → `_showActionNotification()`
3. Se envía notificación de acción completada

---

## ⚙️ CONTROLES Y PREFERENCIAS

Todas las notificaciones respetan las siguientes configuraciones del usuario:

- **Notificaciones generales**: Si están deshabilitadas, ninguna notificación se mostrará
- **Días silenciosos**: Los días configurados como silenciosos no recibirán notificaciones programadas
- **Horas silenciosas**: (Si implementado) Notificaciones no se mostrarán en horas específicas
- **Sonido**: Controlado por `soundEnabled` en preferencias
- **Vibración**: Controlada por `vibrationEnabled` en preferencias
- **Preferencias específicas**:
  - `dailyCodeReminders`: Recordatorio diario de código
  - `morningReminders`: Recordatorios matutinos
  - `eveningReminders`: Recordatorios vespertinos
  - `streakReminders`: Notificaciones de racha
  - `energyLevelAlerts`: Alertas de nivel energético
  - `challengeReminders`: Recordatorios de desafíos
  - `achievementCelebrations`: Celebraciones de logros

---

## 📝 NOTAS IMPORTANTES

1. **Anti-spam**: Las notificaciones de baja prioridad tienen un intervalo mínimo de 6 horas entre ellas
2. **Web**: Las notificaciones locales **no funcionan en web**, solo en Android/iOS
3. **Métodos no utilizados**: Varios métodos de notificaciones existen pero no están siendo llamados actualmente:
   - `notifyChallengeCompleted()`
   - `notifyChallengeDayCompleted()`
   - `notifyChallengeDailyReminder()`
   - `notifyChallengeAtRisk()`
   - `notifyPersonalizedCode()`
   - `notifyWeeklySummary()`
4. **Historial**: Todas las notificaciones enviadas se guardan en `NotificationHistory` para referencia futura

---

## 🎯 RECOMENDACIONES PARA OPTIMIZACIÓN

1. **Consolidar notificaciones múltiples**: Cuando un pilotaje dispara múltiples condiciones (ej: milestone + subida de nivel), considerar agrupar en una sola notificación
2. **Implementar notificaciones faltantes**: Los métodos de desafíos y resúmenes están listos pero no se usan
3. **Mejorar timing**: Ajustar las verificaciones periódicas según patrones de uso del usuario
4. **Personalización**: Implementar lógica para notificaciones personalizadas basadas en comportamiento
5. **Notificaciones diferidas**: Agrupar notificaciones menos urgentes y enviarlas en momentos óptimos

