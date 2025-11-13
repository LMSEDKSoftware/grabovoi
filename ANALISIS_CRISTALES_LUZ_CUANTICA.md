# Análisis: Sistema de Cristales de Energía y Luz Cuántica

## 📋 Cómo DEBERÍA funcionar según el código

### 🔹 **Cristales de Energía**
- **Valor inicial**: 0 cristales para usuarios nuevos
- **Ganancia por sesión**: +10 cristales por cada pilotaje/repetición completada
- **Constante**: `cristalesPorDia = 10` (en `RewardsService`)
- **Uso**: Se pueden gastar para comprar códigos premium (100 cristales por código)

### 🔹 **Luz Cuántica**
- **Valor inicial**: 0.0 para usuarios nuevos
- **Ganancia por sesión**: +5.0 luz cuántica por cada pilotaje/repetición completada
- **Máximo**: 100.0 (100%)
- **Constante**: `luzCuanticaPorPilotaje = 5.0` (en `RewardsService`)
- **Uso**: Cuando llega a 100%, el usuario puede acceder a meditaciones especiales

### 🔹 **Almacenamiento**
- Los valores se guardan en la tabla `user_rewards` en Supabase
- Campos:
  - `cristales_energia` (INTEGER, default: 0)
  - `luz_cuantica` (DOUBLE PRECISION, default: 0.0)
  - `ultima_actualizacion` (TIMESTAMP)

## ❌ Problemas encontrados

### 1. **FALTA: Recompensar por completar pilotajes**
   - **Ubicación**: `lib/screens/pilotaje/quantum_pilotage_screen.dart`
   - **Problema**: Cuando se completa un pilotaje (`_completarPilotajeAutomatico()`), NO se llama a `recompensarPorPilotaje()`
   - **Impacto**: Los usuarios NO obtienen cristales ni luz cuántica cuando completan pilotajes
   - **Solución**: Agregar la llamada a `recompensarPorPilotaje()` cuando se completa un pilotaje

### 2. **VERIFICAR: Lectura desde Supabase**
   - **Ubicación**: `lib/services/rewards_service.dart` → `getUserRewards()`
   - **Posible problema**: Si hay un error al leer desde Supabase, se usa fallback a SharedPreferences
   - **Impacto**: Los valores podrían no estar sincronizados correctamente
   - **Solución**: Verificar que los valores se estén leyendo correctamente desde Supabase

### 3. **VERIFICAR: Inicialización de usuarios nuevos**
   - **Ubicación**: `lib/services/rewards_service.dart` → `getUserRewards()`
   - **Problema**: Si un usuario no tiene registro en `user_rewards`, se retorna un objeto con valores en 0, pero NO se guarda en Supabase
   - **Impacto**: Cada vez que se consulta, se retorna valores en 0 en lugar de crear el registro
   - **Solución**: Cuando no existe el registro, crearlo en Supabase con valores iniciales

### 4. **VERIFICAR: Actualización del widget**
   - **Ubicación**: `lib/widgets/energy_stats_tab.dart`
   - **Problema**: El widget solo carga los valores al iniciar (`_loadRewards()` en `initState()`)
   - **Impacto**: Si los valores cambian, el widget no se actualiza automáticamente
   - **Solución**: Agregar un método para recargar los valores cuando sea necesario

## ✅ Qué SÍ funciona correctamente

1. **Repeticiones**: Cuando se completa una repetición, se llama a `recompensarPorPilotaje()` correctamente
   - **Ubicación**: `lib/services/biblioteca_supabase_service.dart` → `recordRepetitionSession()`

2. **Guardado en Supabase**: El método `saveUserRewards()` guarda correctamente en Supabase usando `upsert`

3. **Cálculo de valores**: El método `recompensarPorPilotaje()` calcula correctamente los nuevos valores

## 🔧 Soluciones propuestas

### Solución 1: Agregar recompensas al completar pilotajes
```dart
// En lib/screens/pilotaje/quantum_pilotage_screen.dart
void _completarPilotajeAutomatico() {
  // ... código existente ...
  
  // Agregar recompensas por completar pilotaje
  _otorgarRecompensasPorPilotaje();
  
  // Mostrar mensaje de finalización
  _mostrarMensajeFinalizacion();
}

Future<void> _otorgarRecompensasPorPilotaje() async {
  try {
    final rewardsService = RewardsService();
    await rewardsService.recompensarPorPilotaje();
    await rewardsService.addToHistory(
      'cristales',
      'Cristales de energía ganados por completar pilotaje',
      cantidad: RewardsService.cristalesPorDia,
    );
    await rewardsService.addToHistory(
      'luz_cuantica',
      'Luz cuántica ganada por completar pilotaje',
      cantidad: RewardsService.luzCuanticaPorPilotaje.toInt(),
    );
  } catch (e) {
    print('⚠️ Error otorgando recompensas: $e');
  }
}
```

### Solución 2: Crear registro inicial en Supabase
```dart
// En lib/services/rewards_service.dart
Future<UserRewards> getUserRewards() async {
  // ... código existente ...
  
  // Si no existe en Supabase, crear uno nuevo Y GUARDARLO
  final newRewards = UserRewards(
    userId: userId,
    cristalesEnergia: 0,
    restauradoresArmonia: 0,
    luzCuantica: 0.0,
    mantrasDesbloqueados: [],
    codigosPremiumDesbloqueados: [],
    ultimaActualizacion: DateTime.now(),
    logros: {},
  );
  
  // Guardar el nuevo registro en Supabase
  await saveUserRewards(newRewards);
  return newRewards;
}
```

### Solución 3: Actualizar widget cuando cambien los valores
```dart
// En lib/widgets/energy_stats_tab.dart
void _reloadRewards() async {
  await _loadRewards();
}

// Llamar a _reloadRewards() cuando sea necesario (ej: después de completar una sesión)
```

## 🎯 Resumen

### Cómo deberían funcionar los cristales y luz cuántica:
1. **Usuarios nuevos**: Empiezan con 0 cristales y 0% luz cuántica
2. **Por cada pilotaje completado**: +10 cristales, +5% luz cuántica
3. **Por cada repetición completada**: +10 cristales, +5% luz cuántica
4. **Máximo de luz cuántica**: 100% (cuando llega, puede usar meditaciones especiales)
5. **Los valores se acumulan**: No se resetean, se van sumando

### Problemas principales:
1. ❌ **FALTA**: Recompensar por completar pilotajes
2. ⚠️ **VERIFICAR**: Inicialización de usuarios nuevos (no se guarda el registro inicial)
3. ⚠️ **VERIFICAR**: Actualización del widget cuando cambian los valores

### Si los usuarios ven siempre 10 cristales y 5% luz cuántica:
- **Posible causa 1**: Ya completaron una sesión y tienen esos valores guardados
- **Posible causa 2**: Hay un problema al leer desde Supabase (fallback a SharedPreferences)
- **Posible causa 3**: Los valores no se están actualizando correctamente después de completar sesiones
- **Posible causa 4**: El widget no se está actualizando cuando cambian los valores

## 📝 Próximos pasos

1. ✅ Agregar recompensas al completar pilotajes
2. ✅ Crear registro inicial en Supabase cuando no existe
3. ✅ Verificar que los valores se estén leyendo correctamente desde Supabase
4. ✅ Agregar método para actualizar el widget cuando cambien los valores
5. ✅ Verificar que no haya valores hardcodeados en ningún lugar

