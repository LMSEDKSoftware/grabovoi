# Comparación Detallada: Repeticiones vs Campo Energético

## Método: _registrarRepeticionYMostrarRecompensas()

### REPETICIONES (FUNCIONA) - Líneas 1395-1424
```dart
Future<void> _registrarRepeticionYMostrarRecompensas() async {
  try {
    // Registrar repetición
    await BibliotecaSupabaseService.registrarRepeticion(
      codeId: widget.codigo,
      codeName: widget.nombre ?? widget.codigo,
      durationMinutes: 2,
    );
    
    // Obtener recompensas
    final rewardsService = RewardsService();
    final recompensasInfo = await rewardsService.recompensarPorRepeticion();
    
    // Mostrar modal con recompensas
    if (mounted) {
      _mostrarMensajeFinalizacion(
        cristalesGanados: recompensasInfo['cristalesGanados'] as int,
        luzCuanticaAnterior: recompensasInfo['luzCuanticaAnterior'] as double,
        luzCuanticaActual: recompensasInfo['luzCuanticaActual'] as double,
      );
    }
  } catch (e) {
    print('⚠️ Error registrando repetición y obteniendo recompensas: $e');
    // Mostrar modal sin recompensas si hay error
    if (mounted) {
      _mostrarMensajeFinalizacion();
    }
  }
}
```

### CAMPO ENERGÉTICO (NO FUNCIONA) - Líneas 199-235
```dart
Future<void> _registrarRepeticionYMostrarRecompensas() async {
  try {
    // Registrar repetición
    await BibliotecaSupabaseService.registrarRepeticion(
      codeId: widget.codigo,
      codeName: widget.codigo,
      durationMinutes: 2,
    );
    
    // Obtener recompensas
    final rewardsService = RewardsService();
    final recompensasInfo = await rewardsService.recompensarPorRepeticion();
    
    // Debug: Verificar valores obtenidos
    print('🔍 [CAMPO ENERGÉTICO] Recompensas obtenidas:');
    print('   cristalesGanados: ${recompensasInfo['cristalesGanados']}');
    print('   luzCuanticaAnterior: ${recompensasInfo['luzCuanticaAnterior']}');
    print('   luzCuanticaActual: ${recompensasInfo['luzCuanticaActual']}');
    
    // Mostrar modal con recompensas
    if (mounted) {
      _mostrarMensajeFinalizacion(
        cristalesGanados: recompensasInfo['cristalesGanados'] as int,
        luzCuanticaAnterior: recompensasInfo['luzCuanticaAnterior'] as double,
        luzCuanticaActual: recompensasInfo['luzCuanticaActual'] as double,
      );
    }
  } catch (e, stackTrace) {
    print('⚠️ Error registrando repetición y obteniendo recompensas: $e');
    print('⚠️ Stack trace: $stackTrace');
    // Mostrar modal sin recompensas si hay error
    if (mounted) {
      _mostrarMensajeFinalizacion();
    }
  }
}
```

**DIFERENCIAS:**
- ✅ Campo energético tiene logs de debug adicionales
- ✅ Campo energético captura `stackTrace` en el catch (mejor para debugging)
- ✅ El resto del código es IDÉNTICO

## Método: _mostrarMensajeFinalizacion()

### REPETICIONES (FUNCIONA) - Líneas 1426-1448
```dart
void _mostrarMensajeFinalizacion({
  int? cristalesGanados,
  double? luzCuanticaAnterior,
  double? luzCuanticaActual,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.9),
    builder: (context) => SequenciaActivadaModal(
      onContinue: () {
        Navigator.of(context).pop();
      },
      buildSincronicosSection: ({void Function(String)? onCodeCopied}) => _buildSincronicosSection(onCodeCopied: onCodeCopied),
      mensajeCompletado: '¡Excelente trabajo! Has completado tu sesión de repeticiones.',
      cristalesGanados: cristalesGanados,
      luzCuanticaAnterior: luzCuanticaAnterior,
      luzCuanticaActual: luzCuanticaActual,
      tipoAccion: 'repeticion',
    ),
  );
}
```

### CAMPO ENERGÉTICO (NO FUNCIONA) - Líneas 237-266
```dart
void _mostrarMensajeFinalizacion({
  int? cristalesGanados,
  double? luzCuanticaAnterior,
  double? luzCuanticaActual,
}) {
  // Debug: Verificar valores que se pasan al modal
  print('🔍 [CAMPO ENERGÉTICO] Valores pasados al modal:');
  print('   cristalesGanados: $cristalesGanados');
  print('   luzCuanticaAnterior: $luzCuanticaAnterior');
  print('   luzCuanticaActual: $luzCuanticaActual');
  print('   tipoAccion: campo_energetico');
  
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.9),
    builder: (context) => SequenciaActivadaModal(
      onContinue: () {
        Navigator.of(context).pop();
      },
      buildSincronicosSection: ({void Function(String)? onCodeCopied}) => _buildSincronicosSection(onCodeCopied: onCodeCopied),
      mensajeCompletado: '¡Excelente trabajo! Has completado tu sesión de campo energético.',
      cristalesGanados: cristalesGanados,
      luzCuanticaAnterior: luzCuanticaAnterior,
      luzCuanticaActual: luzCuanticaActual,
      tipoAccion: 'campo_energetico',
    ),
  );
}
```

**DIFERENCIAS:**
- ✅ Campo energético tiene logs de debug adicionales
- ✅ Mensaje diferente: "campo energético" vs "repeticiones"
- ✅ `tipoAccion` diferente: 'campo_energetico' vs 'repeticion'
- ✅ El resto del código es IDÉNTICO

## CONCLUSIÓN

**El código es prácticamente IDÉNTICO entre ambas secciones.**

Las únicas diferencias son:
1. Logs de debug en campo energético (no afectan funcionalidad)
2. Mensaje personalizado para cada sección
3. `tipoAccion` diferente (no afecta la funcionalidad de mostrar cristales)

## PROBLEMA REAL

Según los logs de la consola, el problema es:
- **Error RLS en Supabase**: `PostgrestException (message: new row violates row-level security policy for table "user_rewards", code: 42501)`
- **Error 401 Unauthorized** al hacer POST a Supabase

Esto significa que:
1. El código está correcto
2. El problema está en las políticas de Supabase (RLS)
3. O en la autenticación del usuario cuando se ejecuta desde campo energético

## SOLUCIÓN

El código ya está correcto. El problema está en Supabase, no en el código Dart.

**Verificar:**
1. Que las políticas RLS en Supabase permitan INSERT/UPDATE para el usuario autenticado
2. Que el token de autenticación sea válido cuando se ejecuta desde campo energético
3. Que el `user_id` se esté pasando correctamente en todas las operaciones

