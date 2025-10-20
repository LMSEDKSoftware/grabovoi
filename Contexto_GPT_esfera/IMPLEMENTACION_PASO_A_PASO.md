# 🛠️ Implementación Paso a Paso

## 📋 **PASO 1: Agregar Variables de Estado**

Agregar al inicio de la clase `_RepetitionSessionScreenState`:

```dart
// Variables para selector de colores
String _colorSeleccionado = 'dorado';
Map<String, Color> _coloresDisponibles = {
  'dorado': Color(0xFFFFD700),
  'plateado': Color(0xFFC0C0C0),
  'azul_celestial': Color(0xFF87CEEB),
  'categoria': _colorVibracional,
};

// Variables para animación de barra
bool _isColorBarExpanded = true;
AnimationController? _colorBarController;
Animation<double>? _colorBarAnimation;
```

## 📋 **PASO 2: Inicializar Animaciones**

En el método `initState()`, agregar:

```dart
@override
void initState() {
  super.initState();
  
  // ... código existente ...
  
  // Inicializar animaciones de selector de colores
  _colorBarController = AnimationController(
    duration: Duration(milliseconds: 300),
    vsync: this,
  );
  
  _colorBarAnimation = Tween<Offset>(
    begin: Offset.zero,
    end: Offset(1.0, 0.0),
  ).animate(CurvedAnimation(
    parent: _colorBarController!,
    curve: Curves.easeInOut,
  ));
}
```

## 📋 **PASO 3: Disposar Controladores**

En el método `dispose()`, agregar:

```dart
@override
void dispose() {
  // ... código existente ...
  
  _colorBarController?.dispose();
  super.dispose();
}
```

## 📋 **PASO 4: Implementar Métodos de Color**

Agregar estos métodos a la clase:

```dart
// Método para obtener color seleccionado
Color _getColorSeleccionado() {
  if (_colorSeleccionado == 'categoria') {
    return _colorVibracional;
  }
  return _coloresDisponibles[_colorSeleccionado] ?? Color(0xFFFFD700);
}

// Método para seleccionar color
void _selectColor(String color) {
  setState(() {
    _colorSeleccionado = color;
  });
  _hideColorBarAfterDelay();
}

// Método para ocultar barra después de 3 segundos
void _hideColorBarAfterDelay() {
  Future.delayed(Duration(seconds: 3), () {
    if (mounted) {
      setState(() {
        _isColorBarExpanded = false;
      });
      _colorBarController?.forward();
    }
  });
}

// Método para toggle de barra
void _toggleColorBar() {
  setState(() {
    _isColorBarExpanded = !_isColorBarExpanded;
  });
  
  if (_isColorBarExpanded) {
    _colorBarController?.reverse();
  } else {
    _colorBarController?.forward();
  }
}
```

## 📋 **PASO 5: Implementar Widget Selector de Colores**

Agregar este método:

```dart
Widget _buildColorSelector() {
  return Positioned(
    bottom: -40,
    child: SlideTransition(
      position: _colorBarAnimation!,
      child: GestureDetector(
        onTap: _toggleColorBar,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: _coloresDisponibles.entries.map((entry) {
              final isSelected = _colorSeleccionado == entry.key;
              return GestureDetector(
                onTap: () => _selectColor(entry.key),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: entry.value,
                    shape: BoxShape.circle,
                    border: isSelected 
                      ? Border.all(color: Colors.white, width: 2)
                      : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    ),
  );
}
```

## 📋 **PASO 6: Modificar la Visualización de la Esfera**

**REEMPLAZAR** el código problemático:

```dart
// ❌ CÓDIGO A ELIMINAR
GoldenSphere(
  size: 200,
  color: _getColorSeleccionado(),
  code: widget.codigo, // ← ESTO CAUSA ERROR
)
```

**POR** esta estructura:

```dart
// ✅ CÓDIGO CORRECTO
Stack(
  alignment: Alignment.center,
  children: [
    // Esfera dorada (SOLO visual)
    GoldenSphere(
      size: 260,
      color: _getColorSeleccionado(),
      glowIntensity: 0.8,
    ),
    
    // Código iluminado superpuesto
    IlluminatedCodeText(
      code: CodeFormatter.formatCodeForDisplay(widget.codigo),
      fontSize: CodeFormatter.calculateFontSize(widget.codigo),
      color: _getColorSeleccionado(),
    ),
    
    // Selector de colores animado
    _buildColorSelector(),
  ],
)
```

## 📋 **PASO 7: Llamar Animación al Iniciar**

En el método que inicia la repetición, agregar:

```dart
void _startRepetition() {
  // ... código existente ...
  
  // Iniciar animación de ocultar barra
  _hideColorBarAfterDelay();
}
```

## 📋 **PASO 8: Agregar Imports Necesarios**

Asegurar que estos imports estén presentes:

```dart
import 'package:flutter/material.dart';
import 'package:manifestacion_numerica_grabovoi/widgets/golden_sphere.dart';
import 'package:manifestacion_numerica_grabovoi/widgets/illuminated_code_text.dart';
import 'package:manifestacion_numerica_grabovoi/utils/code_formatter.dart';
// ... otros imports existentes ...
```

## 📋 **PASO 9: Verificar Compilación**

Ejecutar:
```bash
flutter run -d chrome --debug
```

## 📋 **PASO 10: Verificar Funcionalidad**

Probar:
- [ ] La esfera se muestra correctamente
- [ ] El código aparece iluminado sobre la esfera
- [ ] El selector de colores funciona
- [ ] La barra se desliza a la derecha después de 3 segundos
- [ ] Al tocar la barra oculta, regresa al centro
- [ ] Los colores cambian correctamente
- [ ] No hay errores de compilación

## 🎯 **RESULTADO ESPERADO**

La pantalla de "Sesión de Repetición" debería verse y funcionar **EXACTAMENTE** igual que la de "Pilotaje Cuántico":

- ✅ Esfera dorada animada
- ✅ Código iluminado superpuesto
- ✅ Selector de colores con 4 opciones
- ✅ Animación de deslizamiento de barra
- ✅ Integración visual sin contenedor oscuro
- ✅ Funcionalidad idéntica a Cuántico

## ⚠️ **NOTAS IMPORTANTES**

1. **NO** pasar `code` a `GoldenSphere` - no acepta ese parámetro
2. **SÍ** usar `Stack` para superponer elementos
3. **SÍ** usar `IlluminatedCodeText` para mostrar el código
4. **SÍ** usar `CodeFormatter` para formatear el código
5. **SÍ** implementar todas las animaciones y funcionalidades de color
