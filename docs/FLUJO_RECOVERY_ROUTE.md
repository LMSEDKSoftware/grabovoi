# 🔄 Flujo de la Ruta `/recovery`

## ¿Qué sucede cuando Supabase redirige a `/recovery`?

### Paso a Paso del Flujo Completo:

---

## 1️⃣ **Usuario verifica OTP**

Cuando el usuario ingresa el código de 6 dígitos y presiona "Verificar":

```dart
// En LoginScreen._showResetPasswordDialog()
final recoveryLink = await _authService.verifyOTPAndGetRecoveryLink(
  email: email,
  token: otpCode,
);

// Se abre el recovery_link en el navegador/app
await launchUrl(Uri.parse(recoveryLink), mode: LaunchMode.externalApplication);
```

El `recoveryLink` tiene esta forma:
```
https://whtiazgcxdnemrrgjjqf.supabase.co/auth/v1/verify?token=xxxxx&type=recovery&redirect_to=https://manigrab.app/recovery
```

---

## 2️⃣ **Supabase procesa el token**

Cuando el usuario hace clic en el recovery_link:

1. El link va a Supabase: `https://[proyecto].supabase.co/auth/v1/verify?token=...`
2. Supabase valida el token
3. Supabase crea una sesión temporal de recuperación
4. Supabase redirige a tu `redirect_to`: `https://manigrab.app/recovery`

**Pero** cuando redirige, Supabase puede hacerlo de dos formas:

### Opción A: Con tokens en query params (preferido)
```
https://manigrab.app/recovery?access_token=xxx&refresh_token=yyy
```

### Opción B: Con hash en la URL (también posible)
```
https://manigrab.app/recovery#access_token=xxx&refresh_token=yyy
```

---

## 3️⃣ **Flutter captura la ruta `/recovery`**

En `lib/main.dart`, tenemos configurado:

```dart
onGenerateRoute: (settings) {
  // En web, capturar la ruta /recovery para cambio de contraseña
  if (kIsWeb && settings.name?.startsWith('/recovery') == true) {
    final uri = Uri.base;  // Esto obtiene la URL completa del navegador
    final accessToken = uri.queryParameters['access_token'];
    final refreshToken = uri.queryParameters['refresh_token'];
    
    return MaterialPageRoute(
      builder: (context) => RecoverySetPasswordScreen(
        accessToken: accessToken,
        refreshToken: refreshToken,
      ),
      settings: settings,
    );
  }
  return null;
},
```

**⚠️ IMPORTANTE:** `Uri.base` obtiene la URL completa del navegador, incluyendo todos los query parameters.

---

## 4️⃣ **RecoverySetPasswordScreen procesa los tokens**

Cuando la pantalla se carga:

```dart
@override
void initState() {
  super.initState();
  _setSessionFromTokens();  // Se ejecuta automáticamente
}

Future<void> _setSessionFromTokens() async {
  if (widget.accessToken == null || widget.refreshToken == null) {
    setState(() {
      _errorMessage = 'Tokens de recuperación no encontrados';
    });
    return;
  }

  try {
    // Establecer sesión de recuperación usando los tokens
    final response = await Supabase.instance.client.auth.setSession(
      widget.accessToken!,
      widget.refreshToken!,
    );

    if (response.session != null) {
      setState(() {
        _sessionSet = true;  // ✅ Sesión establecida, mostrar formulario
      });
    }
  } catch (e) {
    // ❌ Error estableciendo sesión
    setState(() {
      _errorMessage = 'Error estableciendo sesión: ${e.toString()}';
    });
  }
}
```

---

## 5️⃣ **Usuario ingresa nueva contraseña**

Una vez que `_sessionSet = true`, se muestra el formulario:

```dart
if (_sessionSet) ...[
  // Campos de contraseña
  TextFormField(...),  // Nueva contraseña
  TextFormField(...),  // Confirmar contraseña
  
  ElevatedButton(
    onPressed: _updatePassword,
    child: Text('Guardar Contraseña'),
  ),
]
```

---

## 6️⃣ **Actualización de contraseña**

Cuando el usuario envía el formulario:

```dart
Future<void> _updatePassword() async {
  // Validar formulario
  if (!_formKey.currentState!.validate()) return;
  
  // Actualizar contraseña usando updateUser() con sesión activa
  final response = await Supabase.instance.client.auth.updateUser(
    UserAttributes(password: _passwordController.text.trim()),
  );

  if (response.user != null) {
    // ✅ Contraseña actualizada exitosamente
    await Supabase.instance.client.auth.signOut();  // Cerrar sesión recovery
    Navigator.pushReplacement(..., LoginScreen());   // Ir a login
  }
}
```

**✅ Esto funciona** porque:
- Estamos usando `updateUser()` con una sesión activa
- La sesión fue creada por Supabase con el recovery token
- Es el flujo oficial de Supabase, no Admin API

---

## ⚠️ Posibles Problemas y Soluciones

### Problema 1: Tokens no llegan en query params

**Síntoma:** `accessToken` y `refreshToken` son `null`

**Solución:** Verificar que Supabase esté redirigiendo correctamente:
1. Verificar `APP_RECOVERY_URL` en variables de entorno de Supabase
2. Verificar Redirect URLs en Supabase Dashboard
3. Puede que los tokens vengan en el hash (`#`) en vez de query params

**Código mejorado para manejar ambos casos:**

```dart
// En main.dart, mejorar el parsing de tokens
if (kIsWeb && settings.name?.startsWith('/recovery') == true) {
  final uri = Uri.base;
  
  // Intentar obtener de query params primero
  String? accessToken = uri.queryParameters['access_token'];
  String? refreshToken = uri.queryParameters['refresh_token'];
  
  // Si no están en query params, intentar del hash
  if (accessToken == null && uri.hasFragment) {
    final fragment = uri.fragment;
    final hashParams = Uri.splitQueryString(fragment);
    accessToken = hashParams['access_token'];
    refreshToken = hashParams['refresh_token'];
  }
  
  return MaterialPageRoute(
    builder: (context) => RecoverySetPasswordScreen(
      accessToken: accessToken,
      refreshToken: refreshToken,
    ),
  );
}
```

### Problema 2: Ruta `/recovery` no se captura

**Síntoma:** La app no navega a `RecoverySetPasswordScreen`

**Solución:** Verificar:
1. Que `onGenerateRoute` esté configurado correctamente
2. Que la URL en el navegador sea exactamente `/recovery` (o `/recovery?params`)
3. Que `kIsWeb` sea `true`

### Problema 3: `setSession` falla

**Síntoma:** `_errorMessage` muestra "Error estableciendo sesión"

**Posibles causas:**
- Tokens inválidos o expirados
- Formato incorrecto de `setSession()`

**Verificar formato de setSession:**
```dart
// En Supabase Flutter, puede requerir:
await Supabase.instance.client.auth.setSession(
  accessToken,
  refreshToken,
);

// O en versiones más recientes:
await Supabase.instance.client.auth.setSession(
  Session(
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresIn: 3600,
    tokenType: 'bearer',
    user: User(...),
  ),
);
```

---

## ✅ Checklist de Configuración

- [ ] **APP_RECOVERY_URL** configurada en Supabase Edge Functions
  - Valor: `https://manigrab.app/recovery` (o tu dominio)
- [ ] **Redirect URLs** en Supabase Dashboard incluyen:
  - `https://manigrab.app/recovery`
  - `https://manigrab.app/auth/callback` (por si acaso)
- [ ] **Ruta `/recovery`** configurada en `main.dart`
- [ ] **RecoverySetPasswordScreen** creada y funcionando
- [ ] **Probar flujo completo:**
  1. Solicitar OTP
  2. Verificar código
  3. Hacer clic en recovery link
  4. Verificar que redirige a `/recovery` con tokens
  5. Verificar que se establece sesión
  6. Ingresar nueva contraseña
  7. Verificar que funciona el login

---

## 📝 Notas Adicionales

### ¿Por qué funciona este flujo?

1. **Supabase genera el recovery link** usando `admin.generateLink()`
2. **Supabase crea la sesión** cuando valida el token
3. **Redirige con tokens** en la URL
4. **Nosotros establecemos la sesión** con esos tokens
5. **Actualizamos la contraseña** usando `updateUser()` con sesión activa
6. **Funciona** porque es el flujo oficial de Supabase, no Admin API

### Alternativa si los tokens no llegan directamente

Si Supabase no redirige con tokens directamente, puede que necesitemos usar `exchangeCodeForSession`:

```dart
// Si recibimos un código en vez de tokens
final code = uri.queryParameters['code'];
if (code != null) {
  final response = await Supabase.instance.client.auth.exchangeCodeForSession(code);
  if (response.session != null) {
    // Usar la sesión de response.session
  }
}
```

Pero según la documentación de Supabase, cuando usas `generateLink` con `redirectTo`, debería redirigir con los tokens directamente en la URL.

