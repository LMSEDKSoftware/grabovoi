# 🔐 Configurar Reset Password en Supabase

Este documento explica **EXACTAMENTE** qué debes activar/configurar en Supabase para que el método `resetPasswordForEmail()` funcione correctamente.

---

## ✅ PASO 1: Configurar URLs de Redirección

Ve a: **Supabase Dashboard → Authentication → URL Configuration**

### 1.1 Site URL:
```
https://manigrab.app
```

### 1.2 Redirect URLs (agregar TODAS estas):

**Para desarrollo local:**
```
http://localhost
http://127.0.0.1
http://localhost/auth/callback
http://127.0.0.1/auth/callback
```

**Para producción:**
```
https://manigrab.app
https://manigrab.app/auth/callback
```

**Para móvil (deep links):**
```
com.manifestacion.grabovoi://login-callback
```

⚠️ **IMPORTANTE:** NO incluyas URLs con puertos específicos como `http://localhost:8080`

---

## ✅ PASO 2: Verificar Provider de Email

Ve a: **Supabase Dashboard → Authentication → Providers**

### 2.1 Habilitar Email Provider:
- ✅ **Enable Email provider**: Debe estar **ON** (verde)
- ✅ Esto permite autenticación por email/contraseña

---

## ✅ PASO 3: Configurar Confirmación de Email (OPCIONAL)

Ve a: **Supabase Dashboard → Authentication → Email**

### 3.1 Configuración Recomendada:

**Opción A: Sin confirmación de email (MÁS SIMPLE)**
- ✅ **Enable email confirmations**: **OFF**
- ✅ Esto permite que los usuarios cambien contraseña sin necesidad de confirmar email

**Opción B: Con confirmación de email (MÁS SEGURO)**
- ✅ **Enable email confirmations**: **ON**
- ⚠️ Requiere que el email esté confirmado antes de cambiar contraseña

**Recomendación:** Deja **OFF** para simplificar el flujo.

### 3.2 Otras configuraciones:
- ✅ **Enable signup**: **ON** (para permitir nuevos usuarios)
- ✅ **Minimum password length**: 6 (o el que prefieras)

---

## ✅ PASO 4: Configurar SMTP (RECOMENDADO)

Ve a: **Supabase Dashboard → Settings → Auth → SMTP Settings**

### 4.1 Habilitar SMTP Personalizado:
- ✅ **Enable custom SMTP**: **ON** (verde)

### 4.2 Configuración de SendGrid:
```
✅ Sender email address: hola@em6490.manigrab.app
✅ Sender name: ManiGrab
✅ Host: smtp.sendgrid.net
✅ Port number: 587
✅ Username: apikey
✅ Password: [Tu API Key de SendGrid que empieza con SG.]
```

### 4.3 Verificar en SendGrid:
1. Ve a **SendGrid Dashboard → Settings → Sender Authentication**
2. Verifica que `hola@em6490.manigrab.app` esté verificado ✅ (Ya está funcionando)
3. Verifica que tu API Key tenga permisos de "Mail Send"

⚠️ **NOTA:** Si no configuras SMTP, Supabase usará su servicio de email por defecto (limitado).

---

## ✅ PASO 5: Verificar Rate Limits

Ve a: **Supabase Dashboard → Settings → Auth → Rate Limits**

### 5.1 Verificar límites:
- ✅ **Email sent**: 100 por hora (por defecto)
- ⚠️ Si recibes "demasiados correos", aumenta este límite

---

## 📋 CHECKLIST COMPLETO

Marca cada punto cuando lo completes:

- [ ] ✅ **Site URL** configurada: `https://manigrab.app`
- [ ] ✅ **Redirect URLs** agregadas (todas las mencionadas arriba)
- [ ] ✅ **Email provider** habilitado en Providers
- [ ] ✅ **Enable email confirmations** configurado (OFF o ON según prefieras)
- [ ] ✅ **Enable signup** habilitado
- [ ] ✅ **SMTP personalizado** configurado con SendGrid (recomendado)
- [ ] ✅ Email remitente verificado en SendGrid

---

## 🧪 PROBAR

1. **En la app Flutter:**
   - Abre la pantalla de login
   - Presiona "Olvidé mi contraseña"
   - Ingresa un email válido
   - Deberías recibir un email con el link de recuperación

2. **Verifica en los logs:**
   - Ve a **Supabase Dashboard → Logs → Auth Logs**
   - Busca entradas relacionadas con `password reset` o `recovery`

---

## 🐛 Troubleshooting

### Error: "Invalid redirect URL"
- ✅ Verifica que todas las Redirect URLs estén agregadas
- ✅ Asegúrate de que la URL en el código coincida con las configuradas

### No llega el email
- ✅ Verifica que SMTP esté configurado correctamente
- ✅ Revisa los logs de SendGrid
- ✅ Verifica que el email remitente esté verificado

### Error: "Se han enviado demasiados correos"
- ✅ Aumenta el rate limit en Settings → Auth → Rate Limits
- ✅ Espera 1 hora si alcanzaste el límite

### El link no funciona
- ✅ Verifica que la ruta `/auth/callback` esté configurada en tu app
- ✅ Verifica que `AuthCallbackScreen` maneje correctamente el recovery

---

## 📝 CÓDIGO ACTUAL

El código ya está configurado para usar:
- **Web:** `${Uri.base.origin}/auth/callback`
- **Mobile:** `com.manifestacion.grabovoi://login-callback`

Estas URLs DEBEN estar en la lista de Redirect URLs de Supabase.

