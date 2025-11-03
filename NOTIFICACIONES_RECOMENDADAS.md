# 🔔 Sistema de Notificaciones Recomendadas para ManiGrab

## 📊 Análisis de Funcionalidades Actuales

### Funcionalidades Principales Identificadas:
1. **Home Screen**: Portal energético con esfera dorada, código recomendado, nivel energético
2. **Biblioteca Cuántica**: Códigos Grabovoi organizados por categoría
3. **Pilotaje Cuántico Consciente**: Sesiones de 2 minutos con código y música
4. **Campo Energético** (CodeDetailScreen): Sesiones de 2 minutos con códigos específicos
5. **Sesión de Repetición**: Repetición de códigos con música
6. **Desafíos**: Desafíos de 7, 14 y 21 días
7. **Evolución**: Tracking de progreso y energía
8. **Perfil**: Gestión de usuario y configuraciones

### Métricas Clave que se Rastrean:
- Días consecutivos de práctica
- Total de pilotajes realizados
- Total de repeticiones
- Tiempo de meditación (minutos)
- Nivel energético (1-10)
- Progreso de desafíos
- Última fecha de pilotaje
- Códigos más usados
- Acciones del usuario

---

## 🔔 NOTIFICACIONES RECOMENDADAS

### 1️⃣ **NOTIFICACIONES DE CONSEJOS/RECORDATORIOS**

#### 🏠 Nivel de Interactividad Bajo

**1.1 Recordatorio de Código del Día**
- **Cuándo**: Cada día a las 9:00 AM
- **Criterio**: Si el usuario no ha visto el código del día
- **Mensaje**: "🌅 Hola [Nombre], tu Código Grabovoi de hoy espera por ti: [código]. ¡Recuerda que tu energía se eleva con cada pilotaje consciente!"
- **Acción**: Al tocar, abre Home Screen con el código destacado

**1.2 Recordatorio de Rutina Matutina**
- **Cuándo**: Lunes a Viernes a las 8:00 AM
- **Criterio**: Si el usuario ha completado ≥3 pilotajes la semana pasada
- **Mensaje**: "☀️ Buenos días [Nombre]. ¿Listo para comenzar el día con energía cuántica? Un piloto consciente de 2 minutos transformará tu mañana."
- **Acción**: Al tocar, abre Pilotaje Cuántico Consciente

**1.3 Recordatorio de Rutina Vespertina**
- **Cuándo**: Lunes a Viernes a las 7:00 PM
- **Criterio**: Si el usuario tiene racha ≥7 días
- **Mensaje**: "🌙 Excelente día [Nombre]. ¿Completas tu práctica cuántica de hoy? Tu racha de [X] días está en riesgo si no practicas hoy."
- **Acción**: Al tocar, abre Home Screen

**1.4 Consejo Motivacional Semanal**
- **Cuándo**: Domingos a las 10:00 AM
- **Criterio**: Todos los usuarios
- **Mensaje**: "💫 Recuerda: La constancia supera la perfección. Cada código que repites es una semilla de transformación que plantas en tu realidad."
- **Acción**: Al tocar, abre Home Screen

---

### 2️⃣ **NOTIFICACIONES DE RACHA/PROGRESO**

#### 🏆 Gestión de Continuidad

**2.1 Alerta de Racha en Riesgo (12 horas)**
- **Cuándo**: A las 6:00 PM si no se ha practicado ese día
- **Criterio**: Si tiene racha ≥3 días consecutivos y no ha realizado pilotaje hoy
- **Mensaje**: "⚠️ Atención [Nombre]: Tu racha de [X] días está en riesgo. ¡Hay tiempo aún! Realiza tu pilotaje de hoy para mantenerla viva."
- **Prioridad**: Alta
- **Acción**: Al tocar, abre Home Screen

**2.2 Racha Perdida**
- **Cuándo**: 24 horas después del último pilotaje (si se perdió la racha)
- **Criterio**: Si tenía racha ≥3 días y no practicó durante >24h
- **Mensaje**: "😔 Tu racha de [X] días se ha interrumpido, pero es solo un nuevo comienzo. El Piloto Consciente persevera. ¡Comienza de nuevo hoy!"
- **Acción**: Al tocar, abre Home Screen

**2.3 Celebración Hitos de Racha**
- **Cuándo**: Cuando alcanza hitos específicos (3, 7, 14, 21, 30 días)
- **Criterio**: Después de completar un pilotaje en esos días exactos
- **Mensaje**: 
  - 3 días: "🎉 ¡Felicidades! 3 días consecutivos. Tu energía comienza a estabilizarse."
  - 7 días: "🌟 ¡Increíble! 7 días consecutivos. Estás creando un hábito poderoso."
  - 14 días: "💎 ¡Extraordinario! 14 días consecutivos. Tu disciplina está transformando tu realidad."
  - 21 días: "👑 ¡Épico! 21 días consecutivos. El hábito está formado. Eres un Piloto Consciente."
  - 30 días: "🏆 ¡Legendario! 30 días consecutivos. Has alcanzado Maestría en Constancia."
- **Acción**: Al tocar, abre pantalla de logros/evolución

**2.4 Predicción de Racha Perfeccionista**
- **Cuándo**: Cada día a las 6:00 AM si no ha practicado
- **Criterio**: Si tiene racha ≥14 días y no ha practicado aún ese día
- **Mensaje**: "💫 [Nombre], llevas [X] días perfectos. Hoy es el día [X+1]. ¡Mantén tu racha dorada!"
- **Acción**: Al tocar, abre Home Screen

---

### 3️⃣ **NOTIFICACIONES DE NIVEL ENERGÉTICO**

#### ⚡ Sistema de Energía

**3.1 Nivel Energético Sube**
- **Cuándo**: Después de un pilotaje que causa subida de nivel
- **Criterio**: Si el nivel energético aumentó tras registrar un pilotaje
- **Mensaje**: "⚡ ¡Tu energía ha subido! Ahora estás en nivel [X]/10. ¡Sigue así!"
- **Acción**: Al tocar, abre pantalla de Evolución

**3.2 Alerta de Energía Baja**
- **Cuándo**: Si no ha practicado en 5 días y tenía nivel ≥5
- **Criterio**: Nivel ≥5 y última práctica >5 días
- **Mensaje**: "🔋 Tu nivel energético está bajando ([X]/10). Recarga tu energía con un pilotaje consciente hoy."
- **Acción**: Al tocar, abre Home Screen

**3.3 Nivel Máximo Alcanzado**
- **Cuándo**: Cuando alcanza nivel 10/10
- **Criterio**: Después de un pilotaje que le da nivel 10
- **Mensaje**: "👑 ¡MAESTRÍA! Has alcanzado el nivel máximo de energía (10/10). Eres un Piloto Consciente cuántico."
- **Acción**: Al tocar, abre pantalla de logros especiales

---

### 4️⃣ **NOTIFICACIONES DE DESAFÍOS**

#### 🎯 Desafíos Activos

**4.1 Recordatorio Diario de Desafío**
- **Cuándo**: A las 10:00 AM si hay desafío activo
- **Criterio**: Usuario con desafío activo que no completó acciones del día anterior
- **Mensaje**: "🎯 Tienes un desafío activo: [Nombre Desafío]. Día [X] de [Total]. ¡Completa tus acciones hoy!"
- **Acción**: Al tocar, abre pantalla de Desafíos

**4.2 Día de Desafío Completado**
- **Cuándo**: Después de completar todas las acciones de un día
- **Criterio**: Todas las acciones del día completadas
- **Mensaje**: "✅ ¡Día completado! Día [X]/[Total] del desafío [Nombre]. ¡Excelente trabajo!"
- **Acción**: Al tocar, abre pantalla de progreso del desafío

**4.3 Desafío en Riesgo de Falla**
- **Cuándo**: Si no completó un día consecutivo y el desafío requiere continuidad
- **Criterio**: Desafío activo con al menos 3 días y no completó ayer
- **Mensaje**: "⚠️ Tu desafío '[Nombre]' está en riesgo. ¡Completa el día [X] hoy!"
- **Prioridad**: Alta
- **Acción**: Al tocar, abre Desafíos

**4.4 Desafío Completado - Premio**
- **Cuándo**: Cuando completa un desafío entero
- **Criterio**: Último día del desafío completado
- **Mensaje**: "🏆 ¡DESAFÍO COMPLETADO! '[Nombre Desafío]'. Has desbloqueado: [Premios]. ¡Felicidades Piloto Consciente!"
- **Acción**: Al tocar, abre pantalla de felicitaciones con premios

**4.5 Nuevo Desafío Disponible**
- **Cuándo**: Cuando desbloquea un nuevo desafío o inicia semana
- **Criterio**: Nuevo desafío disponible basado en progreso
- **Mensaje**: "🎁 Nuevo desafío disponible: '[Nombre]'. [Descripción breve]. ¿Te atreves?"
- **Acción**: Al tocar, abre pantalla de Desafíos

---

### 5️⃣ **NOTIFICACIONES DE LOGROS/PREMIOS**

#### 🏅 Sistema de Gamificación

**5.1 Primer Pilotaje**
- **Cuándo**: Completar el primer pilotaje
- **Criterio**: Primera vez que completa un pilotaje
- **Mensaje**: "🎉 ¡Bienvenido al viaje cuántico! Has completado tu primer pilotaje consciente. El viaje de transformación comienza."
- **Acción**: Al tocar, abre Home Screen

**5.2 Primeros 10 Pilotajes**
- **Cuándo**: Al alcanzar 10 pilotajes totales
- **Criterio**: Total de pilotajes = 10
- **Mensaje**: "💪 ¡10 pilotajes completados! Estás construyendo un hábito poderoso."
- **Acción**: Al tocar, abre pantalla de Evolución

**5.3 Hitos de Cantidad (50, 100, 500, 1000)**
- **Cuándo**: Al alcanzar 50, 100, 500 o 1000 pilotajes totales
- **Criterio**: Total de pilotajes exactamente en esos números
- **Mensaje**: 
  - 50: "⭐ 50 pilotajes completados. Eres un Piloto Intermedio."
  - 100: "🌟 100 pilotajes completados. ¡Maestría Intermedia alcanzada!"
  - 500: "👑 500 pilotajes completados. Eres un Experto en Piloto Cuántico."
  - 1000: "🏆 1000 pilotajes completados. ¡LEYENDA VIVIENTE! Has dominado el arte."
- **Acción**: Al tocar, abre pantalla de logros especiales

**5.4 Código Favorito**
- **Cuándo**: Cuando usa un código 10 veces
- **Criterio**: Uso del mismo código = 10 veces
- **Mensaje**: "💎 [Código] es tu código favorito (usado 10 veces). El Universo reconoce tu afinidad con este número."
- **Acción**: Al tocar, abre detalles del código

**5.5 Diversidad de Códigos**
- **Cuándo**: Cuando usa 20 códigos diferentes
- **Criterio**: 20 códigos únicos usados
- **Mensaje**: "🌈 ¡Explorador! Has usado 20 códigos diferentes. Tu versatilidad cuántica es impresionante."
- **Acción**: Al tocar, abre Biblioteca

---

### 6️⃣ **NOTIFICACIONES DE CONTENIDO PERSONALIZADO**

#### 🎯 Basadas en IA/Análisis

**6.1 Código Personalizado Recomendado**
- **Cuándo**: 3 veces por semana (lunes, miércoles, viernes) a las 11:00 AM
- **Criterio**: Basado en historial de uso y patrones
- **Mensaje**: "✨ Basado en tu actividad, este código podría ser perfecto para ti hoy: [Código]. ¿Por qué no intentas una sesión?"
- **Acción**: Al tocar, abre detalle del código recomendado

**6.2 Resumen Semanal de Progreso**
- **Cuándo**: Domingos a las 8:00 PM
- **Criterio**: Todos los usuarios activos
- **Mensaje**: "📊 Tu semana cuántica: [X] pilotajes, [Y] códigos usados, nivel [Z]/10. ¡Sigue así!"
- **Acción**: Al tocar, abre pantalla de Evolución con resumen semanal

**6.3 Tendencias y Patrones**
- **Cuándo**: Mensualmente
- **Criterio**: Usuario con ≥20 pilotajes
- **Mensaje**: "📈 Análisis mensual: [Patrón observado, ej: 'Usas códigos de abundancia los viernes']. ¿Quieres ver más insights?"
- **Acción**: Al tocar, abre sección de insights

---

### 7️⃣ **NOTIFICACIONES ESPECIALES/TEMPORALES**

#### 🎊 Eventos y Ocasiones

**7.1 Aniversario de Registro**
- **Cuándo**: Exactamente 30, 90, 180, 365 días después del registro
- **Criterio**: Fecha exacta de aniversario
- **Mensaje**: "🎂 ¡Feliz [Aniversario]! [X] días como Piloto Consciente. Gracias por ser parte de la comunidad."
- **Acción**: Al tocar, abre pantalla de agradecimiento

**7.2 Cambio de Estación/Ciclos Lunares**
- **Cuándo**: Cambios de estación o luna nueva/llena
- **Criterio**: Eventos astronómicos
- **Mensaje**: "🌙 Luna Nueva/Primavera [etc]. Momento poderoso para nuevos inicios. Usa el código [Recomendado] para este ciclo."
- **Acción**: Al tocar, abre detalle del código estacional

**7.3 Código Especial del Mes**
- **Cuándo**: Primero de cada mes a las 9:00 AM
- **Criterio**: Todos los usuarios
- **Mensaje**: "📅 Nuevo mes, nueva energía. El código de [Mes] es: [Código]. ¡Comienza el mes con intención!"
- **Acción**: Al tocar, abre Home Screen

---

### 8️⃣ **NOTIFICACIONES SOCIAL/COMUNIDAD**

#### 👥 (Opcional - si implementas comunidad)

**8.1 Rankings Semanales**
- **Cuándo**: Lunes a las 10:00 AM
- **Criterio**: Si implementas rankings
- **Mensaje**: "🏅 Este fin de semana, [X] Pilotos Conscientes completaron desafíos. ¿Estás entre ellos?"
- **Acción**: Al tocar, abre ranking (si existe)

**8.2 Invitación a Compartir Logros**
- **Cuándo**: Después de logros importantes
- **Criterio**: Logros especiales (racha 21, nivel 10, etc.)
- **Mensaje**: "🎉 ¡Comparte tu logro con la comunidad! Has alcanzado [Logro]. ¡Inspira a otros!"
- **Acción**: Al tocar, abre diálogo de compartir

---

## ⚙️ CONFIGURACIÓN DE USUARIO

Permitir que el usuario configure:
1. **Horarios preferidos** (por ejemplo: 8:00-10:00 y 19:00-21:00)
2. **Frecuencia** (diario, días alternos, solo fines de semana)
3. **Tipos de notificaciones** (activar/desactivar por categoría)
4. **Silenciar días específicos** (por ejemplo: domingos)
5. **Idioma** (español/otros)
6. **Modo silencioso** (solo vibrar, no hacer sonido)

---

## 📱 IMPLEMENTACIÓN TÉCNICA SUGERIDA

### Paquetes Recomendados:
```yaml
dependencies:
  flutter_local_notifications: ^16.0.0  # Notificaciones locales
  timezone: ^0.9.0                      # Zonas horarias
  workmanager: ^0.5.2                   # Tareas en segundo plano
```

### Estructura Propuesta:
```
lib/
├── services/
│   ├── notification_service.dart       # Servicio principal de notificaciones
│   ├── notification_scheduler.dart     # Programación de notificaciones
│   └── notification_rules.dart         # Lógica de cuándo mostrar cada notificación
├── models/
│   └── notification_preferences.dart   # Preferencias del usuario
└── screens/
    └── settings/
        └── notifications_settings.dart # Configuración de notificaciones
```

### Variables que se necesitan rastrear:
- Última notificación enviada de cada tipo
- Racha actual del usuario
- Próxima notificación programada
- Preferencias del usuario
- Horario local del usuario
- Estado de desafíos activos

---

## 🎯 PRIORIZACIÓN RECOMENDADA

### FASE 1 (MVP - Crítico):
1. Recordatorio de Código del Día (1.1)
2. Alerta de Racha en Riesgo 12h (2.1)
3. Celebración Hitos de Racha 3,7,14,21 (2.3)
4. Desafío Día Completado (4.2)
5. Configuración básica de usuario

### FASE 2 (Importante):
1. Nivel Energético Sube (3.1)
2. Recordatorio Diario de Desafío (4.1)
3. Resumen Semanal (6.2)
4. Primer Pilotaje y primeras 10 (5.1, 5.2)
5. Hitos de Cantidad 50,100 (5.3)

### FASE 3 (Nice to Have):
1. Recordatorios Matutinos/Vespertinos (1.2, 1.3)
2. Código Personalizado (6.1)
3. Aniversarios (7.1)
4. Código del Mes (7.3)
5. Funciones sociales (8.x)

---

## 📝 NOTAS FINALES

- **Tonality**: Mantener el tono místico y motivacional de la app
- **Frecuencia**: No más de 3-4 notificaciones al día (excepto eventos especiales)
- **Personalización**: Usar el nombre del usuario siempre que sea posible
- **Testing**: Probar todas las notificaciones en diferentes estados del usuario
- **Analytics**: Rastrear qué notificaciones tienen mejor engagement
- **Fallback**: Si no hay nombre, usar "Piloto Consciente" o similar

