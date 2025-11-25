# Problema: Menú Inferior No Se Muestra

## Descripción del Problema

El menú de navegación inferior (`bottomNavigationBar`) en la aplicación Flutter no se muestra en la pantalla. El menú está definido en `MainNavigation` pero no aparece visualmente.

## Estructura de la Aplicación

### Flujo de Navegación

1. **MyApp** → `home: const AuthWrapper()`
2. **AuthWrapper** → Decide qué mostrar:
   - Si `_isAuthenticated && !_needsAssessment` → Muestra `MainNavigation()`
   - Si `_isAuthenticated && _needsTour` → Muestra `AppTourScreen()`
   - Si `_isAuthenticated && _needsAssessment` → Muestra `UserAssessmentScreen()`
   - Si no autenticado → Muestra `OnboardingScreen()` o `LoginScreen()`

3. **MainNavigation** → Contiene:
   - Un `Scaffold` con `body` y `bottomNavigationBar`
   - El `body` contiene un `GlowBackground` con un `IndexedStack` de pantallas
   - El `bottomNavigationBar` contiene el menú de navegación

### Estructura del Scaffold en MainNavigation

```dart
Scaffold(
  body: GlowBackground(
    child: IndexedStack(
      index: _currentIndex,
      children: _screens, // [HomeScreen(), QuantumPilotageScreen(), DesafiosScreen(), EvolucionScreen(), ProfileScreen()]
    ),
  ),
  bottomNavigationBar: MediaQuery(
    child: Container(
      decoration: BoxDecoration(...),
      child: SafeArea(
        child: Padding(
          child: Row(
            children: [
              _buildNavItem(icon: Icons.home_filled, label: 'Inicio', index: 0),
              _buildNavItem(icon: Icons.auto_awesome, label: 'Cuántico', index: 1),
              _buildNavItem(icon: Icons.emoji_events, label: 'Desafíos', index: 2),
              _buildNavItem(icon: Icons.show_chart, label: 'Evolución', index: 3),
              _buildNavItem(icon: Icons.person, label: 'Perfil', index: 4),
            ],
          ),
        ),
      ),
    ),
  ),
)
```

### Estructura de HomeScreen

`HomeScreen` tiene su propio `Scaffold`:

```dart
Scaffold(
  body: GlowBackground(
    child: Stack(
      children: [
        SafeArea(
          child: SingleChildScrollView(...),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: const EnergyStatsTab(),
        ),
      ],
    ),
  ),
)
```

## Problemas Identificados

1. **Scaffolds Anidados**: `HomeScreen` tiene su propio `Scaffold`, y está dentro del `body` del `Scaffold` de `MainNavigation`. Esto puede causar conflictos.

2. **IndexedStack con Scaffolds**: Las pantallas dentro del `IndexedStack` tienen sus propios `Scaffold`, lo que puede ocultar el `bottomNavigationBar` del `Scaffold` padre.

3. **GlowBackground**: Hay un `GlowBackground` tanto en `MainNavigation` como en `HomeScreen`, lo que puede estar causando problemas de renderizado.

## Cambios Realizados (sin éxito)

1. ✅ Comentado `StaticBibliotecaScreen` temporalmente
2. ✅ Comentado el ítem "Biblioteca" en el menú
3. ✅ Ajustados los índices del menú
4. ✅ Comentado `resetOnboarding()` para evitar que el tour se muestre siempre
5. ✅ Restaurado el `Scaffold` en `HomeScreen` (como estaba en el commit anterior)

## Preguntas para ChatGPT

1. ¿Por qué el `bottomNavigationBar` del `Scaffold` en `MainNavigation` no se muestra cuando las pantallas dentro del `IndexedStack` tienen sus propios `Scaffold`?

2. ¿Es correcto tener `Scaffold` anidados de esta manera? ¿Deberían las pantallas dentro del `IndexedStack` tener `Scaffold` o solo el `body`?

3. ¿El `GlowBackground` puede estar interfiriendo con el renderizado del `bottomNavigationBar`?

4. ¿Hay alguna propiedad del `Scaffold` que deba configurarse para que el `bottomNavigationBar` se muestre correctamente cuando hay `Scaffold` anidados?

5. ¿El `SafeArea` en el `bottomNavigationBar` puede estar causando problemas?

6. ¿El `PopScope` que envuelve el `Scaffold` puede estar afectando el renderizado?

## Archivos Incluidos

- `main.dart`: Contiene `MainNavigation` con el `Scaffold` y `bottomNavigationBar`
- `auth_wrapper.dart`: Maneja el flujo de autenticación y decide qué pantalla mostrar
- `home_screen.dart`: Pantalla de inicio que tiene su propio `Scaffold`

## Notas Adicionales

- La aplicación funciona en Flutter Web (Chrome)
- El menú debería aparecer en la parte inferior de la pantalla
- Las pantallas individuales funcionan correctamente, solo falta el menú inferior
- Se ha probado comentando `StaticBibliotecaScreen` pero el problema persiste
- Se ha probado comentando `resetOnboarding()` pero el problema persiste

