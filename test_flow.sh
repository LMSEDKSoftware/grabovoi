#!/bin/bash

# Script de prueba para verificar el flujo de la aplicación
# Este script simula el proceso de registro y login para verificar el orden de las pantallas

echo "🧪 Script de Prueba del Flujo de la Aplicación"
echo "=============================================="
echo ""
echo "Este script verificará el flujo completo:"
echo "1. Crear cuenta → Login"
echo "2. Login → Pantalla de 7 días premium"
echo "3. Pantalla de 7 días premium → MainNavigation"
echo "4. Tour → se muestra como overlay"
echo "5. Encuesta → después del tour"
echo "6. WelcomeModal → después de la encuesta"
echo "7. MuralModal → después del WelcomeModal"
echo "8. Interfaz de app"
echo ""
echo "⚠️  IMPORTANTE: Este script solo verifica la lógica del código."
echo "   Para pruebas reales, debes:"
echo "   1. Crear un nuevo usuario en la app"
echo "   2. Hacer login"
echo "   3. Verificar que las pantallas aparezcan en el orden correcto"
echo ""
echo "📋 Verificando archivos clave..."
echo ""

# Verificar que los archivos existan
FILES=(
  "lib/screens/auth/register_screen.dart"
  "lib/screens/auth/login_screen.dart"
  "lib/widgets/subscription_welcome_modal.dart"
  "lib/main.dart"
  "lib/widgets/auth_wrapper.dart"
  "lib/screens/onboarding/user_assessment_screen.dart"
  "lib/widgets/welcome_modal.dart"
  "lib/widgets/mural_modal.dart"
  "lib/screens/home/home_screen.dart"
)

for file in "${FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "✅ $file existe"
  else
    echo "❌ $file NO existe"
  fi
done

echo ""
echo "🔍 Verificando flujo en el código..."
echo ""

# Verificar que RegisterScreen navegue a LoginScreen
if grep -q "LoginScreen" lib/screens/auth/register_screen.dart; then
  echo "✅ RegisterScreen → LoginScreen: OK"
else
  echo "❌ RegisterScreen → LoginScreen: FALLO"
fi

# Verificar que LoginScreen muestre SubscriptionWelcomeModal
if grep -q "SubscriptionWelcomeModal" lib/screens/auth/login_screen.dart; then
  echo "✅ LoginScreen muestra SubscriptionWelcomeModal: OK"
else
  echo "❌ LoginScreen muestra SubscriptionWelcomeModal: FALLO"
fi

# Verificar que SubscriptionWelcomeModal navegue a AuthWrapper
if grep -q "AuthWrapper\|MainNavigation" lib/widgets/subscription_welcome_modal.dart; then
  echo "✅ SubscriptionWelcomeModal navega correctamente: OK"
else
  echo "⚠️  SubscriptionWelcomeModal: Revisar navegación"
fi

# Verificar que AuthWrapper maneje el tour
if grep -q "_needsTour\|showTour" lib/widgets/auth_wrapper.dart; then
  echo "✅ AuthWrapper maneja tour: OK"
else
  echo "❌ AuthWrapper maneja tour: FALLO"
fi

# Verificar que AuthWrapper maneje la evaluación
if grep -q "_needsAssessment\|UserAssessmentScreen" lib/widgets/auth_wrapper.dart; then
  echo "✅ AuthWrapper maneja evaluación: OK"
else
  echo "❌ AuthWrapper maneja evaluación: FALLO"
fi

# Verificar que MainNavigation tenga tour overlay
if grep -q "_TourOverlay\|showTour" lib/main.dart; then
  echo "✅ MainNavigation tiene tour overlay: OK"
else
  echo "❌ MainNavigation tiene tour overlay: FALLO"
fi

# Verificar que HomeScreen tenga WelcomeModal
if grep -q "WelcomeModal\|_checkWelcomeModal" lib/screens/home/home_screen.dart; then
  echo "✅ HomeScreen tiene WelcomeModal: OK"
else
  echo "❌ HomeScreen tiene WelcomeModal: FALLO"
fi

# Verificar que HomeScreen tenga MuralModal
if grep -q "MuralModal\|_checkMuralMessages" lib/screens/home/home_screen.dart; then
  echo "✅ HomeScreen tiene MuralModal: OK"
else
  echo "❌ HomeScreen tiene MuralModal: FALLO"
fi

echo ""
echo "📝 Resumen del flujo esperado:"
echo "1. RegisterScreen → LoginScreen"
echo "2. LoginScreen → SubscriptionWelcomeModal → AuthWrapper"
echo "3. AuthWrapper → MainNavigation (con tour si _needsTour)"
echo "4. Tour termina → AuthWrapper verifica evaluación"
echo "5. Si necesita evaluación → UserAssessmentScreen"
echo "6. UserAssessmentScreen termina → MainNavigation"
echo "7. MainNavigation → HomeScreen → WelcomeModal"
echo "8. WelcomeModal → MuralModal"
echo ""
echo "✅ Verificación completa. Revisa los resultados arriba."

