# 🔐 Guía: Configurar Google OAuth en Supabase

## ❌ Error Actual
```
400 Bad Request
"Unsupported provider: provider is not enabled"
```

Este error significa que **Google OAuth no está habilitado** en tu proyecto de Supabase.

---

## ✅ Solución: Habilitar Google en Supabase Dashboard

### Paso 1: Configurar OAuth Consent Screen (para mostrar "manigrab.app")

**IMPORTANTE**: Esto configura qué dominio/nombre aparece en la pantalla de autorización de Google.

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Selecciona tu proyecto
3. Ve a **APIs & Services > OAuth consent screen**
4. Configura:
   - **User Type**: External (o Internal si es solo para tu organización)
   - **App name**: ManiGrab (o el nombre que quieras mostrar)
   - **User support email**: Tu email de soporte
   - **Developer contact information**: Tu email
5. En la sección **App domain**:
   - **Application home page**: `https://manigrab.app`
   - **Application privacy policy link**: `https://manigrab.app/privacy` (opcional)
   - **Application terms of service link**: `https://manigrab.app/terms` (opcional)
6. En **Authorized domains**, agrega:
   - `manigrab.app`
   - `supabase.co` (necesario para que funcione con Supabase)
7. Guarda y continúa (puedes saltar los scopes por ahora si no los necesitas)
8. Completa la configuración

### Paso 2: Obtener Credenciales de Google Cloud Console

1. En Google Cloud Console, ve a **APIs & Services > Credentials**
2. Haz clic en **Create Credentials > OAuth client ID**
3. Si te pide seleccionar el tipo de aplicación, elige **Web application**
4. Configura:
   - **Name**: ManiGrab OAuth
   - **Authorized redirect URIs**: 
     ```
     https://whtiazgcxdnemrrgjjqf.supabase.co/auth/v1/callback
     ```
5. Copia el **Client ID** y **Client Secret**

### Paso 3: Habilitar Google en Supabase

1. Ve a tu [Supabase Dashboard](https://supabase.com/dashboard)
2. Selecciona tu proyecto
3. Ve a **Authentication > Providers**
4. Busca **Google** y haz clic en el toggle para habilitarlo
5. Ingresa:
   - **Client ID**: (el que copiaste de Google Cloud)
   - **Client Secret**: (el que copiaste de Google Cloud)
6. Guarda los cambios

### Paso 4: Configurar Redirect URLs

En Supabase Dashboard > Authentication > URL Configuration:

**Site URL:**
```
https://whtiazgcxdnemrrgjjqf.supabase.co
```

**Redirect URLs** (agregar todas estas):
```
com.manifestacion.grabovoi://login-callback
http://localhost:*
https://whtiazgcxdnemrrgjjqf.supabase.co/auth/v1/callback
```

---

## 🔧 Alternativa: Usar Google Sign In nativo (más complejo)

Si prefieres no configurar OAuth en Supabase, puedes usar el paquete `google_sign_in` directamente, pero requiere más configuración.

---

## 📋 Verificación

Después de configurar:
1. Recarga la app
2. Haz clic en "Continuar con Google"
3. Deberías ver la pantalla de autorización de Google mostrando **"manigrab.app"** en lugar del dominio de Supabase
4. Después de seleccionar tu cuenta, deberías regresar a la app autenticado

**Nota**: Si aún ves el dominio de Supabase, verifica que:
- Hayas completado la configuración del OAuth consent screen
- Hayas agregado `manigrab.app` en los Authorized domains
- Hayas guardado todos los cambios en Google Cloud Console

---

## ⚠️ Nota Importante

El código ya está listo. Solo falta la configuración en Supabase Dashboard.

