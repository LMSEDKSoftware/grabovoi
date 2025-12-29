# 🔍 DEBUG: Construcción del Email de Recuperación de Contraseña

Este documento muestra **EXACTAMENTE** cómo se construye el correo en cada paso del proceso para identificar por qué los links no aparecen.

---

## 📍 Flujo Completo

1. **Edge Function `send-otp`** genera el recovery link
2. **Edge Function `send-otp`** construye el payload con `template_data`
3. **Edge Function `send-otp`** envía el payload al servidor PHP
4. **Servidor PHP** recibe y procesa el payload
5. **Servidor PHP** construye el JSON para SendGrid
6. **Servidor PHP** envía el JSON a SendGrid API
7. **SendGrid** reemplaza las variables del template con los datos

---

## PASO 1: Edge Function `send-otp` - Generación del Recovery Link

**Archivo:** `supabase/functions/send-otp/index.ts`

```typescript
// Líneas 157-163: Generar recovery link oficial de Supabase
const { data: linkData, error: linkError } = await supabase.auth.admin.generateLink({
  type: 'recovery',
  email: requestEmail,
  options: {
    redirectTo: redirectTo,
  },
})

const recoveryLink = linkData.properties.action_link
// Ejemplo: https://whtiazgcxdnemrrgjjqf.supabase.co/auth/v1/verify?token=XXX&type=recovery&redirect_to=YYY
```

**Líneas 197-225: Extraer token y construir URL personalizada**

```typescript
// Extraer el token del link
const tokenMatch = recoveryLink.match(/token=([^&]+)/)
const recoveryToken = tokenMatch ? tokenMatch[1] : null

// Construir nuestra propia URL
const customRecoveryUrl = `${redirectTo}?token=${encodeURIComponent(recoveryToken)}&type=recovery`
// Ejemplo: https://manigrab.app/auth/callback?token=XXX&type=recovery

// Validar y usar customRecoveryUrl o fallback a recoveryLink
const finalRecoveryUrl = (customRecoveryUrl && customRecoveryUrl.trim() !== '' && customRecoveryUrl.includes('token=')) 
  ? customRecoveryUrl 
  : recoveryLink
```

**⚠️ CRÍTICO:** La variable `finalRecoveryUrl` debe contener el link completo. Si está vacía aquí, el problema está en la generación del link.

---

## PASO 2: Edge Function `send-otp` - Construcción del Payload para el Servidor PHP

**Archivo:** `supabase/functions/send-otp/index.ts`

**Líneas 380-424: Construir payload con template_data**

```typescript
if (SENDGRID_TEMPLATE_RECOVERY) {
  // Obtener nombre del usuario
  const userName = foundUser.user_metadata?.full_name || foundUser.user_metadata?.name || foundUser.email?.split('@')[0] || 'Usuario'
  
  // ⚠️ VALIDACIÓN CRÍTICA
  if (!finalRecoveryUrl || finalRecoveryUrl.trim() === '' || typeof finalRecoveryUrl !== 'string') {
    console.error('❌ ERROR CRÍTICO: finalRecoveryUrl está vacío o inválido antes de construir template_data')
    throw new Error('finalRecoveryUrl no puede estar vacío')
  }
  
  const templateDataRecoveryLink = finalRecoveryUrl.trim()
  
  serverPayload.template_id = SENDGRID_TEMPLATE_RECOVERY
  serverPayload.template_data = {
    name: userName || 'Usuario',
    app_name: 'ManiGrab',
    recovery_link: templateDataRecoveryLink // ⚠️ ESTA ES LA VARIABLE CRÍTICA
  }
  
  // ⚠️ VALIDACIÓN POST-CONSTRUCCIÓN
  if (!serverPayload.template_data.recovery_link || serverPayload.template_data.recovery_link.trim() === '') {
    console.error('❌ ERROR CRÍTICO: recovery_link está vacío después de construir template_data')
    throw new Error('recovery_link no puede estar vacío en template_data')
  }
  
  console.log('📦 PAYLOAD COMPLETO A ENVIAR AL SERVIDOR:')
  console.log(JSON.stringify(serverPayload, null, 2))
}
```

### 📋 EJEMPLO DEL PAYLOAD QUE SE ENVÍA AL SERVIDOR PHP:

```json
{
  "to": "usuario@ejemplo.com",
  "template_id": "d-971362da419640f7be3c3cb7fae9881d",
  "template_data": {
    "name": "Usuario de Prueba",
    "app_name": "ManiGrab",
    "recovery_link": "https://manigrab.app/auth/callback?token=abc123XYZ&type=recovery"
  },
  "subject": "Recuperación de Contraseña - ManiGrab"
}
```

**⚠️ VALIDACIONES EN ESTE PUNTO:**
- ✅ `template_id` debe estar presente
- ✅ `template_data.recovery_link` debe estar presente y NO vacío
- ✅ `template_data.name` debe estar presente
- ✅ `template_data.app_name` debe estar presente

---

## PASO 3: Servidor PHP - Procesamiento del Payload

**Archivo:** `server/email_endpoint.php`

**Líneas 158-212: Procesar template_data y construir JSON para SendGrid**

```php
if ($useTemplate && $templateId) {
    // USAR TEMPLATE DE SENDGRID
    $templateData = $data['template_data'] ?? [];
    
    // ⚠️ VALIDACIÓN: Asegurar que recovery_link existe y no está vacío
    if (empty($templateData['recovery_link'])) {
        error_log("❌ ERROR CRÍTICO: recovery_link está vacío en templateData antes de enviar a SendGrid");
        error_log("   templateData completo: " . json_encode($templateData, JSON_PRETTY_PRINT));
    } else {
        error_log("✅ recovery_link válido antes de construir emailData");
        error_log("   recovery_link: " . $templateData['recovery_link']);
    }
    
    $emailData = [
        'personalizations' => [
            [
                'to' => [
                    ['email' => $data['to']]
                ],
                'dynamic_template_data' => $templateData, // ⚠️ AQUÍ SE PASAN LOS DATOS
                'subject' => $subject
            ]
        ],
        'from' => [
            'email' => $fromEmail,
            'name' => $fromName
        ],
        'subject' => $subject,
        'template_id' => $templateId
    ];
    
    // Log final antes de enviar
    error_log("SENDGRID DEBUG: JSON completo a enviar: " . json_encode($emailData, JSON_PRETTY_PRINT));
}
```

### 📋 EJEMPLO DEL JSON QUE SE ENVÍA A SENDGRID:

```json
{
  "personalizations": [
    {
      "to": [
        {
          "email": "usuario@ejemplo.com"
        }
      ],
      "dynamic_template_data": {
        "name": "Usuario de Prueba",
        "app_name": "ManiGrab",
        "recovery_link": "https://manigrab.app/auth/callback?token=abc123XYZ&type=recovery"
      },
      "subject": "Recuperación de Contraseña - ManiGrab"
    }
  ],
  "from": {
    "email": "hola@em6490.manigrab.app",
    "name": "ManiGrab"
  },
  "subject": "Recuperación de Contraseña - ManiGrab",
  "template_id": "d-971362da419640f7be3c3cb7fae9881d"
}
```

**⚠️ VALIDACIONES EN ESTE PUNTO:**
- ✅ `personalizations[0].dynamic_template_data.recovery_link` debe estar presente
- ✅ `template_id` debe coincidir con el template configurado en SendGrid
- ✅ `from.email` debe estar configurado

---

## PASO 4: SendGrid - Reemplazo de Variables en el Template

**Template ID:** `d-971362da419640f7be3c3cb7fae9881d`

### 📋 Variables que el Template DEBE tener configuradas:

El template en SendGrid debe tener estas variables en su HTML:

```html
<p>Hola {{name}},</p>
<p>Hemos recibido una solicitud para restablecer tu contraseña.</p>

<div class="button-container">
  <a href="{{recovery_link}}" class="button">Restablecer Contraseña</a>
</div>

<div class="link-container">
  <div class="link-text">O copia y pega este enlace en tu navegador:</div>
  <a href="{{recovery_link}}" class="link-url">{{recovery_link}}</a>
</div>

<p>© {{app_name}}</p>
```

### ⚠️ PROBLEMAS COMUNES EN EL TEMPLATE DE SENDGRID:

1. **El template NO tiene la variable `{{recovery_link}}` configurada**
   - Solución: Agregar `{{recovery_link}}` en el HTML del template

2. **La variable está mal escrita (ej: `{{recovery_link }}` con espacio)**
   - Solución: Asegurar que no haya espacios dentro de las llaves

3. **El template está usando una versión antigua sin la variable**
   - Solución: Actualizar el template con la versión correcta

4. **La variable está en el HTML pero no está activada en SendGrid**
   - Solución: Verificar que las variables dinámicas estén habilitadas

---

## 🔍 CÓMO VERIFICAR DÓNDE ESTÁ EL PROBLEMA

### 1. Verificar logs de la Edge Function `send-otp`

Busca en los logs de Supabase (Edge Functions → send-otp → Logs):

```
📦 PAYLOAD COMPLETO A ENVIAR AL SERVIDOR:
{
  "to": "...",
  "template_data": {
    "recovery_link": "..." // ⚠️ ¿Está presente y tiene valor?
  }
}
```

**Si `recovery_link` está vacío aquí → Problema en la generación del link**

### 2. Verificar logs del Servidor PHP

Busca en los logs del servidor (`/var/log/php/error.log` o similar):

```
SENDGRID DEBUG: recovery_link en template_data: https://...
SENDGRID DEBUG: JSON completo a enviar: {...}
```

**Si `recovery_link` está vacío aquí → Problema en la transmisión del payload**

### 3. Verificar el Template en SendGrid

1. Ve a: https://app.sendgrid.com/email_templates
2. Busca el template con ID: `d-971362da419640f7be3c3cb7fae9881d`
3. Abre el editor del template
4. Busca en el HTML: `{{recovery_link}}`
5. Verifica que esté en:
   - El atributo `href` del botón: `<a href="{{recovery_link}}">`
   - El texto del link alternativo: `{{recovery_link}}`

**Si NO encuentras `{{recovery_link}}` en el template → AHÍ ESTÁ EL PROBLEMA**

---

## ✅ CHECKLIST DE VERIFICACIÓN

- [ ] Edge Function genera `finalRecoveryUrl` correctamente (logs muestran el link)
- [ ] Edge Function construye `template_data.recovery_link` con valor no vacío
- [ ] Servidor PHP recibe `template_data.recovery_link` con valor no vacío
- [ ] Servidor PHP envía `dynamic_template_data.recovery_link` a SendGrid
- [ ] Template en SendGrid tiene `{{recovery_link}}` configurado en el HTML
- [ ] Template en SendGrid tiene variables dinámicas habilitadas

---

## 🔧 SOLUCIÓN RÁPIDA SI EL TEMPLATE NO TIENE LA VARIABLE

Si el template de SendGrid no tiene `{{recovery_link}}`, debes:

1. Ir a SendGrid → Email Templates
2. Buscar el template ID: `d-971362da419640f7be3c3cb7fae9881d`
3. Editar el template
4. Buscar donde dice algo como "Restablecer Contraseña"
5. Reemplazar cualquier URL hardcodeada por: `{{recovery_link}}`
6. Guardar el template

### Ejemplo de corrección:

**❌ ANTES (incorrecto):**
```html
<a href="https://manigrab.app/reset-password" class="button">Restablecer Contraseña</a>
```

**✅ DESPUÉS (correcto):**
```html
<a href="{{recovery_link}}" class="button">Restablecer Contraseña</a>
```

Y también agregar el link alternativo:
```html
<p>O copia y pega este enlace: {{recovery_link}}</p>
```

---

## 📝 PRÓXIMOS PASOS

1. **Ejecutar un test de recuperación de contraseña**
2. **Revisar los logs en cada paso:**
   - Logs de Supabase Edge Functions
   - Logs del servidor PHP
   - Actividad de envío en SendGrid
3. **Verificar que el correo recibido tenga los links**
4. **Si no tiene links, revisar el template en SendGrid**

---

## 🚨 SI EL PROBLEMA PERSISTE

Si después de verificar todo lo anterior el correo sigue sin links, entonces:

1. El template de SendGrid puede estar usando variables diferentes (ej: `{{action_url}}` en lugar de `{{recovery_link}}`)
2. El template puede tener errores de sintaxis que impiden el reemplazo
3. SendGrid puede estar rechazando las variables por algún motivo

**Solución temporal:** Usar HTML directo en lugar del template (modificar el código para enviar HTML completo en lugar de usar template_id).

