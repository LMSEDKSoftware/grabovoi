# 📧 Configuración de Templates de SendGrid

## ✅ Templates Configurados

### Template de Recuperación de Contraseña
- **Template ID:** `d-971362da419640f7be3c3cb7fae9881d`
- **Uso:** Envío de emails de recuperación de contraseña
- **Variables requeridas:**
  - `{{name}}` - Nombre del usuario
  - `{{app_name}}` - Nombre de la aplicación (ManiGrab)
  - `{{recovery_link}}` - Link completo de recuperación de Supabase

### Template de Bienvenida / Activación de Cuenta
- **Template ID:** `d-d13c788e070d4b55a9a70c118a53718b`
- **Uso:** Envío de emails de bienvenida y confirmación de cuenta

---

## 🔧 Configuración Automática

Los templates ya están configurados por defecto en el código:

### En Edge Function `send-otp`:
```typescript
const SENDGRID_TEMPLATE_RECOVERY = Deno.env.get('SENDGRID_TEMPLATE_RECOVERY') || 'd-971362da419640f7be3c3cb7fae9881d'
```

### En Servidor PHP:
```php
$sendgridTemplateRecovery = getenv('SENDGRID_TEMPLATE_RECOVERY') ?: 'd-971362da419640f7be3c3cb7fae9881d';
```

---

## 📋 Variables de Entorno (Opcional)

Si quieres sobrescribir los valores por defecto, puedes configurar en:

### Supabase Dashboard:
**Settings → Edge Functions → Secrets**
```
SENDGRID_TEMPLATE_RECOVERY=d-971362da419640f7be3c3cb7fae9881d
```

### Servidor (manigrab.app):
**Variables de entorno del servidor**
```bash
SENDGRID_TEMPLATE_RECOVERY=d-971362da419640f7be3c3cb7fae9881d
```

---

## ✅ Verificación

El sistema ahora:
1. ✅ Usa el template de SendGrid para recovery password
2. ✅ Envía emails a través del servidor propio (whitelist)
3. ✅ Pasa las variables correctas al template
4. ✅ Funciona automáticamente sin configuración adicional

