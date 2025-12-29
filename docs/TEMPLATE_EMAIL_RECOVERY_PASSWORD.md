# 📧 Template HTML para Email de Recuperación de Contraseña

Este es el template HTML optimizado para SendGrid que incluye el link oficial de recuperación de Supabase.

---

## 🎨 Template HTML

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8" />
  <title>Recuperación de Contraseña</title>
  <style>
    body {
      margin: 0;
      padding: 0;
      background-color: #f5f7fa;
      font-family: Arial, Helvetica, sans-serif;
      color: #333;
    }
    .container {
      max-width: 420px;
      margin: 40px auto;
      background: #ffffff;
      padding: 32px;
      border-radius: 12px;
      box-shadow: 0 4px 16px rgba(0,0,0,0.08);
    }
    h1 {
      font-size: 22px;
      margin-bottom: 12px;
      color: #111;
      text-align: center;
    }
    p {
      font-size: 16px;
      line-height: 1.6;
      margin: 0 0 16px;
      text-align: center;
    }
    .button-container {
      text-align: center;
      margin: 30px 0;
    }
    .button {
      display: inline-block;
      padding: 14px 32px;
      background: linear-gradient(135deg, #FFD700 0%, #FFA500 100%);
      color: #1C2541;
      text-decoration: none;
      border-radius: 8px;
      font-weight: bold;
      font-size: 16px;
      box-shadow: 0 4px 12px rgba(255, 215, 0, 0.3);
      transition: transform 0.2s;
    }
    .button:hover {
      transform: translateY(-2px);
    }
    .link-container {
      margin: 20px 0;
      padding: 16px;
      background: #f9f9f9;
      border-radius: 8px;
      border: 1px solid #e0e0e0;
    }
    .link-text {
      font-size: 12px;
      color: #666;
      margin-bottom: 8px;
      text-align: center;
    }
    .link-url {
      font-size: 11px;
      color: #0066cc;
      word-break: break-all;
      text-align: center;
      text-decoration: none;
    }
    .expiry {
      font-size: 14px;
      color: #666;
      text-align: center;
      margin-top: 20px;
      font-style: italic;
    }
    .footer {
      text-align: center;
      margin-top: 30px;
      font-size: 13px;
      color: #888;
    }
    .warning {
      font-size: 13px;
      color: #888;
      text-align: center;
      margin-top: 16px;
      padding-top: 16px;
      border-top: 1px solid #e0e0e0;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>Recuperación de Contraseña</h1>

    <p>Hola {{name}},</p>
    
    <p>Hemos recibido una solicitud para restablecer tu contraseña. Haz clic en el siguiente botón para crear una nueva contraseña:</p>

    <div class="button-container">
      <a href="{{recovery_link}}" class="button">Restablecer Contraseña</a>
    </div>

    <div class="link-container">
      <div class="link-text">O copia y pega este enlace en tu navegador:</div>
      <a href="{{recovery_link}}" class="link-url">{{recovery_link}}</a>
    </div>

    <p class="expiry">Este link expirará en 1 hora.</p>

    <div class="warning">
      Si no solicitaste este cambio de contraseña, puedes ignorar este mensaje de forma segura.
    </div>

    <div class="footer">
      © {{app_name}} — Seguridad y confianza primero.
    </div>
  </div>
</body>
</html>
```

---

## 📝 Versión Texto Plano

```
Recuperación de Contraseña - {{app_name}}

Hola {{name}},

Hemos recibido una solicitud para restablecer tu contraseña.

Haz clic en el siguiente enlace para crear una nueva contraseña:

{{recovery_link}}

Este link expirará en 1 hora.

Si no solicitaste este cambio de contraseña, puedes ignorar este mensaje de forma segura.

© {{app_name}} — Seguridad y confianza primero.
```

---

## 🔧 Variables Requeridas

El template requiere estas variables de SendGrid:

- `{{name}}` - Nombre del usuario
- `{{app_name}}` - Nombre de la aplicación (ej: "ManiGrab")
- `{{recovery_link}}` - **Link completo de recuperación de Supabase** (ej: `https://whtiazgcxdnemrrgjjqf.supabase.co/auth/v1/verify?token=...&type=recovery&redirect_to=...`)

---

## 📋 Cómo Usar en la Edge Function

Cuando llames a SendGrid desde tu Edge Function, asegúrate de pasar estas variables en el objeto `personalizations`:

```typescript
personalizations: [{
  to: [{ email: userEmail }],
  dynamic_template_data: {
    name: userName,
    app_name: 'ManiGrab',
    recovery_link: recoveryLink  // Link completo generado por Supabase
  }
}]
```

O si usas el template directo en el HTML:

```typescript
let emailHtml = templateHtml
  .replace(/\{\{name\}\}/g, userName)
  .replace(/\{\{app_name\}\}/g, 'ManiGrab')
  .replace(/\{\{recovery_link\}\}/g, recoveryLink)
```

---

## ✅ Características del Template

- ✅ Diseño responsive y moderno
- ✅ Botón destacado para restablecer contraseña
- ✅ Link alternativo por si el botón no funciona
- ✅ Indicador de expiración del link
- ✅ Mensaje de seguridad
- ✅ Compatible con todos los clientes de email
- ✅ Usa los colores de la marca (dorado #FFD700)

