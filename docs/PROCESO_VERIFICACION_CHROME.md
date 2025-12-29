# ✅ Proceso de Verificación en Chrome

## 🌐 Estado Actual

- ✅ **Chrome está corriendo**
- ✅ **Servidor activo en:** `http://localhost:49181/`
- ✅ **Servidor respondiendo:** HTTP 200

---

## 📋 PASOS PARA VERIFICAR EL PROCESO COMPLETO

### 1. Abre la App en Chrome

Chrome debería estar abierto automáticamente en:
```
http://localhost:49181/
```

Si no está abierto, abre manualmente esa URL en Chrome.

---

### 2. Probar el Flujo de Recuperación de Contraseña

#### Paso 1: Ir a la Pantalla de Login
1. Navega a la pantalla de login de la app
2. Haz clic en **"¿Olvidaste tu contraseña?"** o el enlace de recuperación

#### Paso 2: Ingresar Email
1. Se mostrará un diálogo pidiendo tu email
2. Ingresa un email válido que exista en tu base de datos
3. Haz clic en **"Enviar"**

#### Paso 3: Verificar que Aparece el Diálogo de OTP
Después de enviar el email, **debería aparecer automáticamente** un diálogo que dice:
- Título: **"Verificar Código"**
- Texto: **"Paso 1: Ingresa el código de 6 dígitos que recibiste por email."**
- Campo de texto grande para ingresar el código OTP
- Botones: "Cancelar" y "Verificar"

#### Paso 4: Revisar el Correo
1. Abre tu cliente de correo (Gmail, Outlook, etc.)
2. Busca el email de recuperación de contraseña
3. Verifica que el correo tenga:
   - ✅ **Código OTP destacado** (ejemplo: `482913`)
   - ✅ **Instrucciones paso a paso**
   - ✅ **Link a reset-password.php**

#### Paso 5: Copiar y Pegar el OTP
1. Copia el código OTP del correo (ejemplo: `482913`)
2. Vuelve a Chrome (diálogo todavía debería estar abierto)
3. Pega el código en el campo de texto
4. Haz clic en **"Verificar"**

#### Paso 6: Verificar Mensaje "OTP Correcto"
Después de verificar, deberías ver:
- ✅ Un diálogo nuevo que dice:
  - Título: **"OTP Correcto"** (con icono verde)
  - Mensaje: "Tu código de verificación es válido..."
  - Botón: **"Continuar"**

#### Paso 7: Verificar Redirección
1. Haz clic en "Continuar"
2. Debería abrirse automáticamente una nueva pestaña con:
   - URL: `https://manigrab.app/reset-password.php?email=tu@email.com`
   - Página PHP para cambiar la contraseña

---

## ✅ Checklist de Verificación

- [ ] Chrome está abierto en `http://localhost:49181/`
- [ ] Puedo ver la pantalla de login
- [ ] Puedo hacer clic en "¿Olvidaste tu contraseña?"
- [ ] Aparece el diálogo para ingresar email
- [ ] Después de enviar, aparece automáticamente el diálogo de OTP
- [ ] Recibo el correo con el código OTP visible
- [ ] Puedo copiar y pegar el código OTP en el diálogo
- [ ] Al verificar, aparece el mensaje "OTP Correcto"
- [ ] Se abre automáticamente el link para cambiar contraseña

---

## 🔍 Qué Verificar Específicamente

### En el Correo:
1. ✅ El código OTP debe estar **grande y destacado** (fondo oscuro, letras doradas)
2. ✅ Las instrucciones deben estar **claramente numeradas** (1, 2, 3, 4)
3. ✅ Debe tener la **advertencia roja**: "Si los pasos no se hacen en ese orden, el resultado será una falla"

### En la App (Chrome):
1. ✅ El diálogo de OTP debe aparecer **automáticamente** después de enviar el correo
2. ✅ El campo de texto debe permitir **pegar el código** fácilmente
3. ✅ El botón debe decir **"Verificar"**
4. ✅ Después de verificar, debe aparecer el diálogo **"OTP Correcto"**
5. ✅ Debe abrirse automáticamente el **link para cambiar contraseña**

---

## 🐛 Si Algo No Funciona

### El diálogo no aparece después de enviar el correo:
- Verifica la consola del navegador (F12) para ver errores
- Verifica los logs de Flutter en: `/tmp/flutter_launch.log`

### El correo no tiene el código OTP:
- Verifica los logs de Supabase Edge Functions → send-otp
- Verifica que el template de SendGrid tenga `{{otp_code}}` configurado

### El mensaje "OTP Correcto" no aparece:
- Verifica que `verify-otp` esté funcionando correctamente
- Verifica la consola del navegador para errores

### El link no se abre:
- Verifica que la URL sea: `https://manigrab.app/reset-password.php?email=...`
- Verifica que el servidor PHP esté funcionando

---

## 📊 Estado del Servidor

- **URL Local:** http://localhost:49181/
- **Puerto:** 49181
- **Estado:** ✅ Activo (HTTP 200)
- **Chrome:** ✅ Abierto y navegando

---

## 💡 Comandos Útiles

Ver logs de Flutter:
```bash
tail -f /tmp/flutter_launch.log
```

Detener el servidor:
```bash
lsof -ti:49181 | xargs kill -9
```

Abrir Chrome manualmente:
```bash
open -a "Google Chrome" http://localhost:49181
```

