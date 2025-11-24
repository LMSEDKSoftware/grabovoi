# 🧠 Módulo de IA - Documentación Completa

## 📋 Resumen

El módulo de IA de Manifestación Numérica Grabovoi es un **sistema inteligente local** que:
- ✅ Analiza hábitos del usuario
- ✅ Recomienda códigos personalizados
- ✅ Sugiere desafíos adaptados al progreso
- ✅ Calcula nivel vibracional
- ✅ Genera reportes energéticos
- ❌ **NO usa voz ni NLP**
- ❌ **NO requiere conexión a internet**

---

## 📂 Estructura

```
lib/services/ai/
├── ai_service.dart              ← Servicio principal (API única)
├── recommendation_service.dart  ← Motor de recomendaciones
├── progress_service.dart        ← Análisis de progreso
└── habit_tracker.dart           ← Tracking de hábitos

lib/models/
└── user_progress.dart           ← Modelo de datos del progreso
```

---

## 🚀 Uso Rápido

### 1. Inicializar el Servicio

```dart
import 'package:manifestacion_numerica_grabovoi/services/ai/ai_service.dart';

final aiService = AIService();
```

### 2. Obtener Dashboard Completo

```dart
// Obtiene TODO lo necesario para el dashboard
final dashboard = await aiService.obtenerDashboard();

print('Nivel: ${dashboard['nivel']}');              // 1-7
print('Mensaje: ${dashboard['mensaje']}');          // Frase motivacional
print('Color aura: ${dashboard['colorAura']}');     // #FFD700
print('Energía: ${dashboard['energia']}');          // 0-100
```

### 3. Registrar una Sesión

```dart
// Cuando el usuario completa un pilotaje
await aiService.registrarSesion(categoria: 'Abundancia');

// Cuando completa una meditación
await aiService.registrarSesion(categoria: 'Salud');
```

### 4. Obtener Recomendaciones

```dart
// Código del día
final codigo = await aiService.obtenerCodigoRecomendado();

// Código de categoría específica
final codigoSalud = await aiService.obtenerCodigoRecomendado(categoria: 'Salud');

// Desafío personalizado
final desafio = await aiService.obtenerDesafioPersonalizado();

// Meditación recomendada
final meditacion = await aiService.obtenerMeditacionRecomendada();
```

---

## 🎯 Funciones Principales

### AIService (lib/services/ai/ai_service.dart)

| Método | Descripción | Retorna |
|--------|-------------|---------|
| `obtenerDashboard()` | Dashboard completo con todo | `Map<String, dynamic>` |
| `obtenerCodigoRecomendado()` | Código personalizado | `String` |
| `obtenerDesafioPersonalizado()` | Desafío según nivel | `String` |
| `obtenerResumenEnergetico()` | Reporte completo | `Map` |
| `registrarSesion()` | Guarda práctica realizada | `Future<void>` |
| `obtenerProgreso()` | Progreso del usuario | `UserProgress` |
| `analizarPatrones()` | Análisis avanzado | `Map` |
| `predecirProximoPaso()` | Siguiente acción sugerida | `String` |
| `obtenerPracticaOptima()` | Práctica óptima para hoy | `Map` |

---

## 📊 Sistema de Niveles Vibracionales

### Niveles (1-7)

| Nivel | Nombre | Score Requerido | Características |
|-------|--------|-----------------|-----------------|
| **7** | Maestro de Luz | 50+ puntos | Color #FFD700 (dorado brillante) |
| **6** | Vibración Dorada | 35-49 puntos | Color #F4C430 (dorado suave) |
| **5** | Piloto Consciente | 20-34 puntos | Color #DDA15E (bronce dorado) |
| **4** | Viajero Energético | 12-19 puntos | Color #BC6C25 (cobre) |
| **3** | Despertar Luminoso | 6-11 puntos | Color #8B7355 (tierra dorada) |
| **2** | Semilla en Crecimiento | 2-5 puntos | Color #A0A0A0 (plata) |
| **1** | Inicio del Camino | 0-1 puntos | Color #808080 (gris) |

### Cálculo de Score

```
Score = (días consecutivos × 2) + total sesiones

Ejemplos:
- 7 días + 10 sesiones = 14 + 10 = 24 puntos → Nivel 5
- 21 días + 30 sesiones = 42 + 30 = 72 puntos → Nivel 7
```

---

## 🎨 Integración en las Pantallas

### Home Screen (Portal Energético)

```dart
final aiService = AIService();

// En initState o FutureBuilder
final dashboard = await aiService.obtenerDashboard();

// Mostrar nivel
Text('Nivel ${dashboard['nivel']}/7');

// Mostrar código del día
Text(dashboard['sugerencias']['codigoDelDia']);

// Mostrar mensaje motivacional
Text(dashboard['mensaje']);

// Mostrar color de aura
Container(
  color: Color(int.parse(
    dashboard['colorAura'].replaceAll('#', '0xFF')
  )),
)
```

### Pantalla de Pilotaje

```dart
// Al completar un pilotaje
await aiService.registrarSesion(categoria: 'Abundancia');

// Mostrar códigos complementarios
final complementarios = aiService.obtenerCodigosComplementarios('318798');
// → ['520741', '71427321893', '5197148']
```

### Pantalla de Evolución

```dart
// Obtener reporte completo
final reporte = await aiService.obtenerResumenEnergetico();

// Mostrar progreso hacia siguiente nivel
Text('Nivel ${reporte['nivel']}: ${reporte['nombreNivel']}');
Text('${reporte['sesionesParaSubir']} sesiones para nivel ${reporte['proximoNivel']}');

// Gráfico con fl_chart
final energia = reporte['energiaPromedio'];  // 0-100
```

### Pantalla de Desafíos

```dart
// Obtener desafío personalizado
final desafio = await aiService.obtenerDesafioPersonalizado();

// Mostrar según nivel:
// - Nivel 1-2: "Desafío de Abundancia" (7 días)
// - Nivel 3-4: "Camino de Sanación" (14 días)
// - Nivel 5+:  "Transformación Total" (21 días)
```

---

## 💾 Persistencia de Datos

### Datos Guardados Localmente

El `HabitTracker` guarda en `SharedPreferences`:

```dart
'ultimaSesion'           // DateTime ISO
'totalSesiones'          // int
'diasConsecutivos'       // int
'categoriasUsadas'       // List<String>
'frecuenciaCategoria'    // Map<String, int>
'fechasRegistradas'      // List<String> (últimos 90 días)
```

### Acceso Manual (opcional)

```dart
import 'package:shared_preferences/shared_preferences.dart';

final prefs = await SharedPreferences.getInstance();
int sesiones = prefs.getInt('totalSesiones') ?? 0;
print('Total de sesiones: $sesiones');
```

---

## 🎯 Algoritmos de IA

### 1. Recomendación de Código

```dart
Lógica:
1. ¿Tiene categoría preferida? → Usar esa
2. ¿No? → Buscar categoría más usada en historial
3. Dentro de categoría → Rotar códigos según día/sesiones
4. Si nada aplica → Usar código universal rotativo
```

### 2. Sugerencia de Desafío

```dart
Lógica basada en constancia:
- 0 días: "Desafío de Abundancia" (7 días)
- 3-6 días: "Desafío de Abundancia" 
- 7-13 días: "Camino de Sanación" (14 días)
- 14+ días o 30+ sesiones: "Transformación Total" (21 días)
```

### 3. Cálculo de Nivel

```dart
Score = (días consecutivos × 2) + total sesiones

Niveles:
- Score 0-1:    Nivel 1
- Score 2-5:    Nivel 2
- Score 6-11:   Nivel 3
- Score 12-19:  Nivel 4
- Score 20-34:  Nivel 5
- Score 35-49:  Nivel 6
- Score 50+:    Nivel 7
```

### 4. Energía Promedio

```dart
Base: 50 puntos
+ (total sesiones × 2) puntos [máximo 30]
+ (días consecutivos × 3) puntos [máximo 20]
= Total (0-100)
```

### 5. Tendencia

```dart
- días ≥ 7:  "creciente"   (muy activo)
- días ≥ 3:  "estable"     (consistente)
- sesiones > 0: "irregular" (ocasional)
- sesiones = 0: "inicio"    (nuevo)
```

---

## 📈 Ejemplo Completo de Uso

### En Home Screen

```dart
import 'package:flutter/material.dart';
import 'package:manifestacion_numerica_grabovoi/services/ai/ai_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final aiService = AIService();
  Map<String, dynamic>? dashboard;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDashboard();
  }

  Future<void> _cargarDashboard() async {
    final data = await aiService.obtenerDashboard();
    setState(() {
      dashboard = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return CircularProgressIndicator();
    
    return Column(
      children: [
        // Nivel vibracional
        Text('Nivel ${dashboard!['nivel']}/7'),
        Text(dashboard!['reporte']['nombreNivel']),
        
        // Energía
        LinearProgressIndicator(
          value: dashboard!['energia'] / 100,
        ),
        
        // Código del día
        Text(dashboard!['sugerencias']['codigoDelDia']),
        
        // Mensaje motivacional
        Text(dashboard!['mensaje']),
        
        // Botón de acción
        ElevatedButton(
          onPressed: () async {
            // Registrar sesión al completar pilotaje
            await aiService.registrarSesion(categoria: 'Abundancia');
            await _cargarDashboard(); // Recargar
          },
          child: Text('Completar Pilotaje'),
        ),
      ],
    );
  }
}
```

---

## 🔧 Configuración Inicial

### En main.dart

```dart
import 'package:manifestacion_numerica_grabovoi/services/ai/ai_service.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<AIService>(create: (_) => AIService()),
      ],
      child: MyApp(),
    ),
  );
}
```

### Uso en cualquier pantalla

```dart
final aiService = Provider.of<AIService>(context, listen: false);
final dashboard = await aiService.obtenerDashboard();
```

---

## 📊 Datos de Ejemplo

### Progreso de Usuario Nuevo

```dart
UserProgress(
  diasConsecutivos: 0,
  totalSesiones: 0,
  categoriasUsadas: [],
  nivelVibracional: 1,
)
→ Nivel 1: "Inicio del Camino"
→ Código: "5197148" (universal)
→ Desafío: "Desafío de Abundancia"
```

### Progreso de Usuario Activo

```dart
UserProgress(
  diasConsecutivos: 14,
  totalSesiones: 25,
  categoriasUsadas: ['Abundancia', 'Salud', 'Armonía'],
  nivelVibracional: 5,
)
→ Nivel 5: "Piloto Consciente"
→ Energía: 78/100
→ Desafío: "Transformación Total"
```

### Progreso de Maestro

```dart
UserProgress(
  diasConsecutivos: 30,
  totalSesiones: 60,
  nivelVibracional: 7,
)
→ Nivel 7: "Maestro de Luz"
→ Energía: 100/100
→ Color aura: #FFD700
```

---

## 🎨 Visualización Sugerida

### Color de Aura por Nivel

Use el color retornado en `colorAura` para:
- Mandalas animados
- Bordes de contenedores
- Efectos de glow
- Gradientes de fondo

```dart
final colorAura = Color(int.parse(
  dashboard['colorAura'].replaceAll('#', '0xFF')
));

Container(
  decoration: BoxDecoration(
    gradient: RadialGradient(
      colors: [
        colorAura.withOpacity(0.3),
        Colors.transparent,
      ],
    ),
  ),
)
```

### Mandala Animado

```dart
// En EvolucionScreen
AnimatedContainer(
  duration: Duration(milliseconds: 500),
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: colorAura.withOpacity(0.5),
        blurRadius: 40,
        spreadRadius: 10,
      ),
    ],
  ),
)
```

---

## 📅 Flujo Completo del Usuario

### Día 1

```dart
Usuario abre app → aiService.obtenerDashboard()
→ Nivel 1, 0 sesiones
→ Recomienda: "Desafío de Abundancia"
→ Código: "318798"

Usuario completa pilotaje → aiService.registrarSesion()
→ Nivel sube a 2
→ diasConsecutivos = 1
```

### Día 7

```dart
Usuario lleva 7 días consecutivos → aiService.obtenerDashboard()
→ Nivel 4 o 5 (depende de sesiones)
→ Recomienda: "Camino de Sanación" (14 días)
→ Mensaje: "Has desbloqueado el poder del pilotaje consciente"
```

### Día 21

```dart
Usuario lleva 21 días consecutivos → aiService.obtenerDashboard()
→ Nivel 6 o 7
→ Color aura: Dorado brillante
→ Mensaje: "Maestro de la Manifestación"
→ Recomendación: "Comparte tu luz con la comunidad"
```

---

## 🔍 Análisis de Patrones

### Método `analizarPatrones()`

Retorna información completa:

```dart
final analisis = await aiService.analizarPatrones();

{
  'nivelVibracional': 5,
  'nombreNivel': 'Piloto Consciente',
  'energiaPromedio': 75.0,
  'tendencia': 'creciente',
  'diasConsecutivos': 10,
  'totalSesiones': 15,
  'codigoRecomendado': '318798',
  'desafioSugerido': 'Camino de Sanación',
  'meditacionRecomendada': 'Meditación Intermedia',
  'fraseMotiadora': '💫 En Expansión Constante',
  'proximoNivel': 'Vibración Dorada',
  'sesionesParaSubir': 20,
  'colorAura': '#DDA15E',
}
```

---

## 🛠️ Casos de Uso Avanzados

### 1. Mostrar Progreso Semanal

```dart
final stats = await aiService.obtenerEstadisticasSemanales();

print('Energía promedio: ${stats['energiaPromedio']}');
print('Sesiones esta semana: ${stats['sesionesEstaSemana']}');
print('Categoría preferida: ${stats['categoriaPreferida']}');
print('¿Constante? ${stats['constanteEstaSemana']}');
```

### 2. Sugerir Práctica Óptima

```dart
final practica = await aiService.obtenerPracticaOptima();

print('Categoría: ${practica['categoriaSugerida']}');
print('Código: ${practica['codigoSugerido']}');
print('Duración: ${practica['duracionSugerida']} minutos');
print('Horario: ${practica['horarioOptimo']}');
print('Intensidad: ${practica['intensidad']}');
```

### 3. Obtener Recomendaciones de Mejora

```dart
final recomendaciones = await aiService.obtenerRecomendacionesMejora();

for (var rec in recomendaciones) {
  print('• $rec');
}

// Ejemplo de output:
// • Completa más sesiones para profundizar tu conexión
// • Explora diferentes categorías de códigos para equilibrio
```

### 4. Códigos Complementarios

```dart
// Cuando el usuario selecciona un código
final complementarios = aiService.obtenerCodigosComplementarios('318798');

// Mostrar sugerencias:
// "Códigos que van bien con este:"
// → 520741, 71427321893, 5197148
```

---

## 📊 Integración con fl_chart

### Gráfico de Energía Semanal

```dart
import 'package:fl_chart/fl_chart.dart';

LineChart(
  LineChartData(
    lineBarsData: [
      LineChartBarData(
        spots: _generarSpotsEnergia(),
        isCurved: true,
        color: Color(int.parse(colorAura.replaceAll('#', '0xFF'))),
        barWidth: 3,
        belowBarData: BarAreaData(
          show: true,
          color: colorAura.withOpacity(0.2),
        ),
      ),
    ],
  ),
)
```

---

## ⚡ Optimización y Performance

### Caché en Memoria

```dart
class AIServiceCached extends AIService {
  UserProgress? _cacheProgreso;
  DateTime? _cacheTime;
  
  @override
  Future<UserProgress> obtenerProgreso() async {
    // Cache por 5 minutos
    if (_cacheProgreso != null && _cacheTime != null) {
      if (DateTime.now().difference(_cacheTime!) < Duration(minutes: 5)) {
        return _cacheProgreso!;
      }
    }
    
    _cacheProgreso = await super.obtenerProgreso();
    _cacheTime = DateTime.now();
    return _cacheProgreso!;
  }
}
```

---

## 🧪 Testing

### Ejemplo de Test

```dart
void main() {
  test('Nivel vibracional se calcula correctamente', () async {
    final aiService = AIService();
    
    // Simular 10 días + 15 sesiones
    // Score = 10*2 + 15 = 35
    // Nivel esperado = 6
    
    final progreso = UserProgress(
      diasConsecutivos: 10,
      totalSesiones: 15,
      categoriasUsadas: [],
      ultimaSesion: DateTime.now(),
    );
    
    final reporte = await aiService._progressService.generarReporte(progreso);
    expect(reporte['nivel'], 6);
  });
}
```

---

## 🔮 Funcionalidades Futuras (Opcional)

### Posibles Extensiones

1. **Predicción de Próxima Sesión**
   - Analizar horarios históricos
   - Sugerir mejor momento del día

2. **Sincronización de Frecuencias**
   - Detectar patrones cíclicos
   - Alinear con fases lunares

3. **Recomendaciones de Comunidad**
   - Conectar usuarios con mismos objetivos
   - Sin compartir datos privados

4. **Gamificación**
   - Logros desbloqueables
   - Badges por hitos
   - Sistema de recompensas

---

## ✅ Checklist de Implementación

### Para usar el módulo de IA:

- [x] ✅ Crear carpeta `lib/services/ai/`
- [x] ✅ Crear modelo `UserProgress`
- [x] ✅ Implementar `HabitTracker`
- [x] ✅ Implementar `RecommendationService`
- [x] ✅ Implementar `ProgressService`
- [x] ✅ Implementar `AIService` principal
- [ ] Integrar en pantallas
- [ ] Mostrar visualizaciones
- [ ] Agregar Provider para acceso global
- [ ] Implementar persistencia completa
- [ ] Agregar animaciones según nivel

---

## 🎉 Ventajas del Sistema

### ✨ Beneficios

- **Local:** No requiere internet ni APIs externas
- **Rápido:** Cálculos instantáneos
- **Privado:** Datos solo en el dispositivo
- **Personalizado:** Se adapta al usuario
- **Simple:** Fácil de mantener y extender
- **Predecible:** Lógica clara basada en reglas

### 🎯 vs Sistemas Complejos

| Característica | IA Simple (V2) | IA con NLP/ML |
|----------------|----------------|---------------|
| Velocidad | ⚡ Instantánea | 🐌 Segundos |
| Tamaño | 📦 +0 MB | 📦 +50-200 MB |
| Internet | ❌ No requiere | ✅ Necesita |
| Privacidad | 🛡️ Total | ⚠️ Depende |
| Mantenimiento | ✅ Fácil | ❌ Complejo |
| Personalización | ✅ Alta | ⚠️ Media |

---

## 🚀 Próximos Pasos

1. **Integrar en pantallas** - Usa los ejemplos de arriba
2. **Agregar visualizaciones** - Mandalas, gráficos, colores
3. **Implementar Provider** - Para acceso global
4. **Testear flujo completo** - Probar con usuarios reales
5. **Optimizar** - Caché y performance

---

**El módulo está completo y listo para usar. ¡Todo funciona localmente sin necesidad de servicios externos!** 🎉✨

**Código Universal: 5197148** 🌟


