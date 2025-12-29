# 🔍 Diagnóstico: Template SendGrid Sin Links

## ✅ Template HTML Está Correcto

El template que me mostraste tiene todas las variables correctamente configuradas:
- ✅ `{{name}}`
- ✅ `{{app_name}}`
- ✅ `{{recovery_link}}` (en dos lugares)

## 🔍 Posibles Problemas a Verificar

### 1. El Template en SendGrid NO coincide con el ID

**Verificar:**
1. Ve a SendGrid → Email Templates
2. Busca el template con ID: `d-971362da419640f7be3c3cb7fae9881d`
3. **Verifica que el HTML que veas en SendGrid sea EXACTAMENTE el mismo que me mostraste**

**Problema común:** Puede haber múltiples versiones del template y estar usando una versión antigua.

### 2. El Template NO está activo o NO está publicado

**Verificar:**
1. En SendGrid, abre el template `d-971362da419640f7be3c3cb7fae9881d`
2. Verifica que esté en estado "Active" o "Published"
3. Si hay una versión "Draft", puede que esté usando esa en lugar de la publicada

### 3. Las Variables Dinámicas NO están habilitadas en SendGrid

SendGrid requiere que las variables dinámicas estén explícitamente habilitadas.

**Verificar:**
1. En el editor del template, busca la opción "Dynamic Content" o "Dynamic Template Data"
2. Verifica que `recovery_link`, `name`, y `app_name` estén en la lista de variables habilitadas
3. Si no están, agrégalas manualmente

### 4. El Nombre de la Variable tiene Problemas

A veces SendGrid tiene problemas con variables que tienen guiones bajos o nombres largos.

**Solución alternativa:** Cambiar el nombre de la variable en el template y en el código:
- En lugar de `recovery_link` usar `recoveryLink` o `recovery_url`

### 5. El Template está usando Handlebars en lugar de Mustache

SendGrid usa Mustache syntax `{{variable}}`, pero algunos templates pueden estar configurados para Handlebars.

**Verificar:** Asegúrate que el template esté usando Mustache, no Handlebars.

### 6. Los Datos NO están llegando a SendGrid

**Verificar logs del servidor PHP:**

Los logs del servidor PHP deberían mostrar:
```
SENDGRID DEBUG: recovery_link en template_data: [URL completa aquí]
SENDGRID DEBUG: JSON completo a enviar: {...}
```

**Si los logs muestran que `recovery_link` está vacío → El problema está en el código**

### 7. SendGrid está rechazando las Variables

SendGrid puede rechazar variables si:
- El template no está configurado como "Dynamic Template"
- Las variables no están declaradas en el template
- Hay un error de sintaxis en el template

---

## 🔧 Solución Rápida: Verificar Logs del Servidor

Ejecuta un test de recuperación de contraseña y revisa los logs del servidor PHP:

```bash
# En el servidor (manigrab.app), revisa los logs
tail -f /var/log/php/error.log | grep "SENDGRID DEBUG"
```

O revisa los logs de Supabase Edge Functions:
- Supabase Dashboard → Edge Functions → send-otp → Logs

**Busca estas líneas:**
- `recovery_link en template_data:` - Debe mostrar la URL completa
- `JSON completo a enviar:` - Debe mostrar el JSON completo con recovery_link

---

## 🔧 Solución Alternativa: Usar HTML Directo

Si el problema persiste, podemos cambiar temporalmente para enviar HTML directo en lugar de usar el template:

**Modificar `server/email_endpoint.php`** para que siempre use HTML directo cuando venga `template_data.recovery_link`.

---

## ✅ Checklist de Verificación

- [ ] El template ID en SendGrid coincide con `d-971362da419640f7be3c3cb7fae9881d`
- [ ] El HTML del template en SendGrid es IDÉNTICO al que me mostraste
- [ ] El template está activo/publicado en SendGrid
- [ ] Las variables dinámicas están habilitadas en SendGrid
- [ ] Los logs del servidor muestran que `recovery_link` se está enviando correctamente
- [ ] El template está configurado como "Dynamic Template" en SendGrid
- [ ] Las variables no tienen espacios: `{{recovery_link}}` NO `{{ recovery_link }}`

---

## 🚨 Si NADA Funciona

**Solución temporal:** Modificar el código para enviar HTML directo en lugar de usar template:

1. En `send-otp/index.ts`, cuando se usa template, también incluir el HTML completo
2. En `email_endpoint.php`, si viene HTML, usar HTML directo en lugar de template

Esto nos permitirá verificar que los datos están llegando correctamente y que el problema está específicamente en el template de SendGrid.

