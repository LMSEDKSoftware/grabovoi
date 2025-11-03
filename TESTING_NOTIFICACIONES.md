# 🧪 ESCENARIOS DE PRUEBA - SISTEMA DE NOTIFICACIONES

## 📋 INSTRUCCIONES GENERALES

1. Instala el APK: `~/Desktop/manigrab-notificaciones.apk`
2. Inicia sesión con tu usuario
3. Ve a **Perfil → Notificaciones** y verifica configuración inicial
4. Sigue los escenarios en orden

---

## 🎯 ESCENARIOS DE PRUEBA

### ✅ ESCENARIO 1: Primer Uso - Bienvenida
**Objetivo**: Verificar notificación de primer pilotaje

**Pasos**:
1. Usa un usuario NUEVO o sin pilotajes previos
2. Ve a **Inicio**
3. Toca "Tocar para pilotar" → Completa 1 pilotaje de 2 minutos
4. Debe aparecer: "🎉 ¡Bienvenido al viaje cuántico!"

**✅ Resultado Esperado**: 
- Notificación inmediata
- Mensaje: "Has completado tu primer pilotaje consciente"

---

### ✅ ESCENARIO 2: Construcción de Racha (Días 1-3)
**Objetivo**: Verificar milestones de racha 3 días

**Pasos**:
1. Día 1: Completa 1 pilotaje → Nada especial
2. Día 2: Completa 1 pilotaje (debe mostrar contador "2 días")
3. Día 3: Completa 1 pilotaje
4. Debe aparecer: "🎉 ¡Felicidades! 3 días consecutivos"

**✅ Resultado Esperado**: 
- Al completar día 3, notificación de milestone
- Mensaje: "Tu energía comienza a estabilizarse"

**⚠️ Importante**: Debe ser el 3er día CONSECUTIVO

---

### ✅ ESCENARIO 3: Hitos de Cantidad (10 Pilotajes)
**Objetivo**: Verificar milestone de 10 pilotajes

**Pasos**:
1. Completa pilotajes hasta tener **9 totales** registrados
2. Completa el **10mo pilotaje**
3. Debe aparecer: "💪 ¡10 pilotajes completados!"

**✅ Resultado Esperado**: 
- Notificación inmediata después del 10mo pilotaje
- Mensaje: "Estás construyendo un hábito poderoso"

**⚠️ Importante**: Debe ser exactamente el 10mo

---

### ✅ ESCENARIO 4: Racha en Riesgo (12 horas)
**Objetivo**: Verificar alerta de racha en peligro

**Pasos**:
1. Construye racha de al menos 3 días
2. NO practiques en un día
3. Espera hasta las 6:00 PM del mismo día
4. Debe aparecer: "⚠️ Racha en Riesgo"

**✅ Resultado Esperado**: 
- Notificación a las 6:00 PM
- Mensaje: "Tu racha de X días está en riesgo"
- Prioridad: ALTA

**⚠️ Complicado**: Requiere esperar hasta las 6 PM

---

### ✅ ESCENARIO 5: Configuración de Preferencias
**Objetivo**: Verificar UI de configuraciones

**Pasos**:
1. Ve a **Perfil → Notificaciones**
2. Debe aparecer pantalla con toggle principal
3. Desactiva "Código del Día"
4. Desactiva "Rachas en Riesgo"
5. Activa "Modo Vibración"
6. Toca "Guardar Cambios"

**✅ Resultado Esperado**: 
- Todas las categorías visibles
- Toggles funcionando
- Mensaje: "Configuración guardada"
- Cambios persistidos

---

### ✅ ESCENARIO 6: Desactivar Todas las Notificaciones
**Objetivo**: Verificar toggle principal

**Pasos**:
1. Ve a **Perfil → Notificaciones**
2. Desactiva el toggle principal "Notificaciones"
3. Debe ocultarse todo el contenido
4. Completa un pilotaje
5. NO debe aparecer ninguna notificación

**✅ Resultado Esperado**: 
- Toggle principal funciona
- Contenido se oculta
- No se envían notificaciones

---

### ✅ ESCENARIO 7: Recordatorio de Código del Día
**Objetivo**: Verificar notificación programada (9:00 AM)

**Pasos**:
1. Ve a **Notificaciones**
2. Activa "Código del Día" si no está activa
3. Cierra la app completamente
4. Espera hasta las 9:00 AM
5. Debe aparecer: "🌅 Tu Código Grabovoi de Hoy"

**✅ Resultado Esperado**: 
- Notificación a las 9:00 AM
- Mensaje: "Tu código de hoy espera por ti"
- Prioridad: BAJA

**⚠️ Complicado**: Requiere esperar hasta las 9 AM

---

### ✅ ESCENARIO 8: Feedback Inmediato - Gracias
**Objetivo**: Verificar feedback después de completar pilotaje

**Pasos**:
1. Construye racha de al menos 3 días
2. Completa UN pilotaje de 2 minutos
3. Debe aparecer: "👏 Gracias por mantener tu racha activa"

**✅ Resultado Esperado**: 
- Notificación inmediata
- Mensaje de gratitud
- Solo UNA vez por día

**⚠️ Importante**: Debe tener racha ≥3 días

---

### ✅ ESCENARIO 9: Feedback - Disfruta Pilotaje
**Objetivo**: Verificar feedback después de repetición

**Pasos**:
1. Ve a cualquier código en Biblioteca
2. Toca "Iniciar sesión de repetición"
3. Completa la sesión completa
4. Debe aparecer: "🎧 Disfruta tu pilotaje"

**✅ Resultado Esperado**: 
- Notificación inmediata
- Mensaje: "Respira, siente, transforma"
- Prioridad: BAJA

---

### ✅ ESCENARIO 10: Nivel Energético Sube
**Objetivo**: Verificar notificación de subida de nivel

**Pasos**:
1. Verifica tu nivel actual en Inicio (ej: 5/10)
2. Completa pilotajes hasta que subas de nivel
3. Debe aparecer: "⚡ ¡Tu energía ha subido!"

**✅ Resultado Esperado**: 
- Notificación cuando subes nivel
- Mensaje: "Ahora estás en nivel X/10"
- Comparación con nivel anterior

**⚠️ Cálculo de nivel**:
- Días consecutivos: 3, 7, 14, 21
- Total pilotajes: 5, 20, 50, 100

---

### ✅ ESCENARIO 11: Primera Racha de 7 Días
**Objetivo**: Verificar milestone épico

**Pasos**:
1. Practica 6 días consecutivos
2. En el día 7, completa el pilotaje
3. Debe aparecer: "🌟 ¡Increíble! 7 días consecutivos"

**✅ Resultado Esperado**: 
- Notificación especial
- Mensaje: "Estás creando un hábito poderoso"
- Prioridad: MEDIA

---

### ✅ ESCENARIO 12: Llegar a Nivel Máximo (10/10)
**Objetivo**: Verificar notificación de maestría

**Pasos**:
1. Sube progresivamente hasta nivel 9/10
2. Completa pilotajes para llegar a nivel 10/10
3. Debe aparecer: "👑 ¡MAESTRÍA!"

**✅ Resultado Esperado**: 
- Notificación especial
- Mensaje: "Has alcanzado el nivel máximo"
- Sonido activado
- Prioridad: MEDIA

---

### ✅ ESCENARIO 13: Configurar Horarios Personalizados
**Objetivo**: Verificar horarios personalizados

**Pasos**:
1. Ve a **Perfil → Notificaciones**
2. Busca "Rutina Matutina" (por defecto 8:00)
3. Configura hora personalizada (ej: 7:30)
4. Verifica que se guarda

**✅ Resultado Esperado**: 
- Horarios se guardan correctamente
- Se programan notificaciones para esa hora
- Funciona para matutino y vespertino

---

### ✅ ESCENARIO 14: Milestone de 21 Días (Épico)
**Objetivo**: Verificar celebración de 21 días

**Pasos**:
1. Practica 20 días consecutivos
2. En el día 21, completa el pilotaje
3. Debe aparecer: "👑 ¡Épico! 21 días consecutivos"

**✅ Resultado Esperado**: 
- Notificación muy especial
- Mensaje: "El hábito está formado"
- Prioridad: MEDIA
- Sonido especial

**⚠️ Más épico**: También funciona para 14 y 30 días

---

### ✅ ESCENARIO 15: Anti-Spam (Baja Prioridad)
**Objetivo**: Verificar que no hay spam de notificaciones

**Pasos**:
1. Activa TODAS las notificaciones de baja prioridad
2. Completa varios pilotajes rápidamente
3. NO debería aparecer notificación de baja prioridad hasta 6 horas después

**✅ Resultado Esperado**: 
- Solo 1 notificación cada 6 horas (baja prioridad)
- Logs en consola: "⏭️ Notificación omitida por intervalo mínimo"
- Milestones y feedback funcionan normal

---

### ✅ ESCENARIO 16: Modo Silencioso (Sin Sonido)
**Objetivo**: Verificar que se respeta configuración de sonido

**Pasos**:
1. Ve a **Notificaciones**
2. Desactiva "Reproducir Sonido"
3. Completa un milestone importante (10, 21 días)
4. Debe aparecer notificación SIN sonido

**✅ Resultado Esperado**: 
- Notificación aparece
- Vibración funciona si está activada
- No suena

---

### ✅ ESCENARIO 17: Sin Vibración
**Objetivo**: Verificar configuración de vibración

**Pasos**:
1. Ve a **Notificaciones**
2. Desactiva "Vibración"
3. Completa un pilotaje
4. Debe aparecer notificación SIN vibración

**✅ Resultado Esperado**: 
- Notificación aparece
- Sonido funciona si está activado
- No vibra

---

### ✅ ESCENARIO 18: Milestone de 50 Pilotajes
**Objetivo**: Verificar celebración intermedia

**Pasos**:
1. Completa 49 pilotajes
2. Completa el 50mo pilotaje
3. Debe aparecer: "⭐ 50 pilotajes completados"

**✅ Resultado Esperado**: 
- Notificación especial
- Mensaje: "Eres un Piloto Intermedio"
- Solo una vez en el 50

---

### ✅ ESCENARIO 19: Milestone Legendario (1000 Pilotajes)
**Objetivo**: Verificar máximo hito

**Pasos**:
1. Completa 999 pilotajes (o mock)
2. Completa el 1000° pilotaje
3. Debe aparecer: "🏆 1000 pilotajes completados"

**✅ Resultado Esperado**: 
- Notificación ÉPICA
- Mensaje: "¡LEYENDA VIVIENTE!"
- Sonido especial
- Prioridad: MEDIA

**⚠️ Mock**: Para testing, puedes modificar el contador en BD

---

### ✅ ESCENARIO 20: Verificación Periódica (Racha Perdida)
**Objetivo**: Verificar detección automática de racha perdida

**Pasos**:
1. Construye racha de 5+ días
2. NO practiques durante 24+ horas
3. Abre la app
4. Espera hasta 30 minutos o fuerza verificación
5. Debe aparecer: "😔 Racha Interrumpida"

**✅ Resultado Esperado**: 
- Verificación cada 30 minutos
- Notificación cuando detecta racha perdida
- Mensaje motivacional

**⚠️ Complicado**: Requiere esperar o ajustar timer

---

## 🔍 CHECKLIST DE VERIFICACIÓN

### Funcionalidad Básica
- [ ] Notificaciones se inicializan al abrir app
- [ ] UI de configuración carga correctamente
- [ ] Preferencias se guardan y cargan
- [ ] Toggle principal funciona
- [ ] Sin crashes al abrir pantalla de notificaciones

### Notificaciones Inmediatas
- [ ] Primer pilotaje
- [ ] Feedback "Gracias por racha"
- [ ] Feedback "Disfruta pilotaje"
- [ ] Milestones de racha (3, 7, 14, 21, 30)
- [ ] Milestones de cantidad (10, 50, 100, 500, 1000)
- [ ] Nivel energético sube
- [ ] Nivel máximo alcanzado

### Notificaciones Programadas
- [ ] Código del día (9:00 AM)
- [ ] Rutina matutina (horario configurado)
- [ ] Rutina vespertina (horario configurado)

### Configuración
- [ ] Todos los toggles funcionan
- [ ] Horarios se guardan
- [ ] Días silenciosos se respetan
- [ ] Sonido se activa/desactiva
- [ ] Vibración se activa/desactiva

### Anti-Spam
- [ ] No hay notificaciones duplicadas
- [ ] Intervalo de 6 horas se respeta
- [ ] Milestones no se duplican

---

## 🐛 POSIBLES PROBLEMAS Y SOLUCIONES

### Problema: Notificaciones no aparecen
**Causas**:
- Permisos no otorgados en Android
- Notificaciones deshabilitadas globalmente
- Toggle principal desactivado

**Solución**:
1. Ve a Configuración del dispositivo → Apps → ManiGrab → Notificaciones → Permitir
2. Verifica que estén activadas en la app

### Problema: Notificaciones programadas no funcionan
**Causas**:
- App no está en segundo plano
- Android mató el proceso
- Horarios mal configurados

**Solución**:
1. Verifica horarios en SharedPreferences
2. Asegura que app tiene permisos de segundo plano

### Problema: Milestones duplicados
**Causas**:
- Tracking de valores conocido falla
- Múltiples llamadas simultáneas

**Solución**:
1. Revisa logs: valores conocidos se actualizan
2. Verifica que solo se llama una vez al completar

### Problema: Anti-spam muy agresivo
**Causas**:
- Intervalo de 6h es muy largo
- Clasificación de prioridad incorrecta

**Solución**:
1. Reduce intervalo en código si necesario
2. Verifica que milestones sean MEDIA priority

---

## 📊 LOGS PARA VERIFICAR

En `adb logcat` o consola de Flutter, busca:

```
✅ NotificationService inicializado
✅ NotificationScheduler inicializado
📤 Notificación enviada: [título]
📅 Notificación programada: [título]
⏭️ Notificación omitida por intervalo mínimo
```

---

## 🎯 CRITERIOS DE ÉXITO

### Must Have
- ✅ Primer pilotaje notifica
- ✅ Milestones de racha funcionan
- ✅ Configuración se guarda
- ✅ Toggle principal funciona

### Should Have
- ✅ Anti-spam funciona
- ✅ Feedback inmediato aparece
- ✅ Nivel energético notifica

### Nice to Have
- ✅ Horarios personalizados
- ✅ Días silenciosos
- ✅ Verificación periódica

---

## 📱 DISPOSITIVO DE TESTING RECOMENDADO

- **Android 10+** (mejor soporte de notificaciones)
- **Permisos otorgados** para notificaciones
- **Batería optimizada** desactivada para app
- **Permisos de segundo plano** activados

---

## ⏱️ TIEMPO ESTIMADO DE PRUEBA

- **Escenarios básicos** (1-5): 30 minutos
- **Escenarios intermedios** (6-10): 1 hora
- **Escenarios avanzados** (11-15): 2 horas
- **Escenarios épicos** (16-20): Requiere múltiples días
- **Total completo**: 3-4 horas + tiempo de espera

---

## 🎉 ÉXITO CRITERIA

**Sistema funciona correctamente si**:
1. ✅ Mínimo 15/20 escenarios pasan
2. ✅ No hay crashes
3. ✅ Configuración persiste entre sesiones
4. ✅ Anti-spam funciona correctamente
5. ✅ Usuario puede configurar todo

**¡LISTO PARA PROBAR!** 🚀

