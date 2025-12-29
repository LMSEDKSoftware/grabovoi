# 🔐 Configurar Redirect URLs en Supabase

Este documento explica cómo configurar las URLs de redirección en Supabase para que funcionen correctamente con Flutter Web, independientemente del puerto dinámico que use Flutter.

## 🟣 Problema

Flutter Web local usa puertos aleatorios como:
- `http://localhost:51921`
- `http://localhost:49873`
- `http://localhost:61234`

No puedes usar un puerto fijo en `emailRedirectTo` porque Flutter asigna puertos dinámicamente.

## 🟢 Solución

Configurar URLs sin puerto específico en Supabase y usar URLs universales en el código.

---

## ✅ Paso 1: Configurar URLs en Supabase Dashboard

Ve a: **Supabase Dashboard → Authentication → URL Configuration**

### Site URL:
```
https://manigrab.app
```

### Redirect URLs (agregar TODAS estas):

#### Para desarrollo local (cualquier puerto):
```
http://localhost
http://127.0.0.1
http://localhost/auth/callback
http://127.0.0.1/auth/callback
```

#### Para producción:
```
https://manigrab.app
https://manigrab.app/auth/callback
```

#### Para móvil (deep links):
```
com.manifestacion.grabovoi://login-callback
```

---

## ⚠️ IMPORTANTE

**NO incluyas URLs con puertos específicos** como:
- ❌ `http://localhost:51921/auth/callback`
- ❌ `http://localhost:8080/auth/callback`
- ❌ `http://localhost:3000/auth/callback`

Esto romperá la autenticación cuando Flutter cambie de puerto.

---

## ✅ Paso 2: Verificar que el código esté actualizado

El código ya está configurado para usar URLs sin puerto específico:

### En `lib/services/auth_service_simple.dart`:

**Para registro (signUp):**
```dart
if (kIsWeb) {
  emailRedirectTo = 'http://localhost/auth/callback';
} else {
  emailRedirectTo = 'com.manifestacion.grabovoi://login-callback';
}
```

**Para OAuth (Google Sign In):**
```dart
if (kIsWeb) {
  redirectTo = 'http://localhost/auth/callback';
} else {
  redirectTo = 'com.manifestacion.grabovoi://login-callback';
}
```

### En `lib/main.dart`:

Se agregó el manejo de la ruta `/auth/callback`:
```dart
onGenerateRoute: (settings) {
  if (kIsWeb && settings.name == '/auth/callback') {
    return MaterialPageRoute(
      builder: (context) => const AuthCallbackScreen(),
      settings: settings,
    );
  }
  return null;
},
```

---

## ✅ Paso 3: Probar

1. **En desarrollo local:**
   - Inicia la app con `flutter run -d chrome`
   - Flutter asignará un puerto aleatorio (ej: `localhost:51921`)
   - Intenta registrarte o iniciar sesión con Google
   - Deberías ser redirigido a `http://localhost:51921/auth/callback` (funciona porque `http://localhost` está en la lista de URLs permitidas)

2. **En producción:**
   - El código debería detectar que no es localhost y usar `https://manigrab.app/auth/callback`
   - (Nota: Actualmente el código usa `http://localhost/auth/callback` para web. Si necesitas producción, ajusta la lógica para detectar el entorno)

---

## 🔧 Nota sobre Producción

Actualmente el código usa `http://localhost/auth/callback` para todas las instancias web. Si necesitas que funcione en producción con `https://manigrab.app/auth/callback`, puedes:

1. **Opción A:** Agregar detección de entorno:
```dart
if (kIsWeb) {
  // Detectar si estamos en producción
  final isProduction = !html.window.location.hostname.contains('localhost');
  emailRedirectTo = isProduction 
    ? 'https://manigrab.app/auth/callback'
    : 'http://localhost/auth/callback';
}
```

2. **Opción B:** Usar una variable de entorno o constante de configuración.

---

## 📋 Checklist

- [ ] Agregar todas las URLs en Supabase Dashboard → Authentication → URL Configuration
- [ ] Verificar que el código use `http://localhost/auth/callback` (sin puerto)
- [ ] Probar registro con email en desarrollo local
- [ ] Probar login con Google en desarrollo local
- [ ] Verificar que la ruta `/auth/callback` funciona correctamente
- [ ] (Opcional) Configurar detección de producción si es necesario

---

## 🐛 Troubleshooting

### Error: "Invalid redirect URL"
- Verifica que hayas agregado `http://localhost` (sin puerto) en Supabase Dashboard
- Verifica que no hayas agregado URLs con puertos específicos

### El callback no funciona
- Verifica que la ruta `/auth/callback` esté configurada en `main.dart`
- Revisa la consola del navegador para ver los parámetros de la URL
- Verifica que `AuthCallbackScreen` esté procesando correctamente el token

### Funciona en desarrollo pero no en producción
- Asegúrate de haber agregado `https://manigrab.app/auth/callback` en Supabase
- Verifica que el código detecte correctamente el entorno de producción

