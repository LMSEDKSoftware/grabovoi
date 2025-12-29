# ✅ Verificación Paso a Paso del Template en SendGrid

## 🔍 El Template HTML que me mostraste está PERFECTO

Tu template tiene todas las variables correctamente configuradas. Si los links no aparecen, el problema está en la **configuración del template en SendGrid**, NO en el diseño.

---

## 📋 PASOS PARA VERIFICAR EN SENDGRID

### 1. Verificar que estás editando el Template Correcto

1. Ve a: https://app.sendgrid.com/email_templates
2. Busca el template con ID: **`d-971362da419640f7be3c3cb7fae9881d`**
3. Haz clic en "Edit" para abrir el editor
4. **Verifica que el HTML que ves sea EXACTAMENTE el mismo que me mostraste**

⚠️ **Problema común:** Puede haber múltiples templates con nombres similares. Asegúrate de estar editando el correcto por el ID.

---

### 2. Verificar que el Template está ACTIVO/PUBLICADO

1. En la página del template, busca el estado:
   - ✅ Debe estar en estado **"Active"** o **"Published"**
   - ❌ Si está en **"Draft"**, puede que SendGrid esté usando una versión antigua

2. Si hay múltiples versiones:
   - Verifica cuál versión está activa
   - Publica la versión correcta si es necesario

---

### 3. Verificar que el Template está configurado como DYNAMIC TEMPLATE

1. En el editor del template, busca en la configuración:
   - Debe estar marcado como **"Dynamic Template"** o **"Transactional Template"**
   - NO debe estar como **"Classic Template"** (los classic templates no soportan variables dinámicas)

2. Si NO está como Dynamic Template:
   - Crea un nuevo template dinámico
   - Copia tu HTML
   - Guárdalo con el mismo ID o actualiza el ID en el código

---

### 4. Verificar que las Variables están DECLARADAS en SendGrid

En algunos casos, SendGrid requiere que las variables estén explícitamente declaradas:

1. En el editor del template, busca una sección llamada:
   - **"Dynamic Content"** o
   - **"Template Variables"** o
   - **"Variable Settings"**

2. Verifica que estas variables estén en la lista:
   - `name`
   - `app_name`
   - `recovery_link`

3. Si NO están en la lista:
   - Agrégalas manualmente
   - O asegúrate de que el template reconozca las variables automáticamente

---

### 5. Verificar el FORMATO de las Variables en el HTML

Asegúrate que NO haya espacios dentro de las llaves:

✅ **Correcto:**
```html
{{recovery_link}}
{{name}}
{{app_name}}
```

❌ **Incorrecto (con espacios):**
```html
{{ recovery_link }}
{{ name }}
{{ app_name }}
```

❌ **Incorrecto (con espacios y guiones):**
```html
{{recovery-link}}
{{recovery_link }}
```

---

### 6. Verificar que el Template NO tenga URLs Hardcodeadas

Busca en el HTML del template cualquier URL hardcodeada:

❌ **Si encuentras algo como esto:**
```html
<a href="https://manigrab.app/reset-password" class="button">
```

✅ **Debe ser:**
```html
<a href="{{recovery_link}}" class="button">
```

---

### 7. Verificar los Logs del Servidor PHP

Para verificar que los datos están llegando correctamente:

1. Ejecuta un test de recuperación de contraseña
2. Revisa los logs del servidor PHP:
   ```bash
   # Busca en los logs del servidor
   grep "SENDGRID DEBUG" /var/log/php/error.log
   ```

3. Verifica que aparezcan estas líneas:
   ```
   SENDGRID DEBUG: recovery_link en template_data: https://...
   SENDGRID DEBUG: JSON completo a enviar: {...}
   ```

4. Si `recovery_link` aparece en los logs con valor → Los datos están llegando correctamente
5. Si `recovery_link` está vacío en los logs → El problema está en el código

---

### 8. Verificar en SendGrid Activity

1. Ve a SendGrid → Activity
2. Busca el último email enviado de recuperación de contraseña
3. Haz clic en "View Details"
4. Verifica:
   - ✅ El email fue enviado correctamente
   - ✅ El template ID es correcto
   - ⚠️ Verifica si hay algún error o advertencia

---

## 🚨 Si TODAVÍA NO Funciona

### Opción 1: Usar HTML Directo Temporalmente

He modificado el código para que también incluya HTML directo como fallback. El servidor PHP puede usar HTML directo si el template falla.

Para forzar HTML directo, modifica `server/email_endpoint.php`:

```php
// Cambiar esta línea:
$useTemplate = !empty($data['template_id']) || (!empty($templateRecovery) && !empty($data['template_data']));

// Por esta (fuerza HTML directo):
$useTemplate = false; // Temporalmente deshabilitar templates
```

### Opción 2: Crear un Nuevo Template en SendGrid

1. Crea un nuevo template dinámico en SendGrid
2. Copia tu HTML exacto
3. Guarda el template
4. Copia el nuevo Template ID
5. Actualiza el código con el nuevo Template ID

---

## ✅ Checklist Final

- [ ] Template ID es correcto: `d-971362da419640f7be3c3cb7fae9881d`
- [ ] El HTML en SendGrid es IDÉNTICO al que me mostraste
- [ ] Template está en estado "Active" o "Published"
- [ ] Template está configurado como "Dynamic Template"
- [ ] Las variables NO tienen espacios: `{{recovery_link}}` NO `{{ recovery_link }}`
- [ ] NO hay URLs hardcodeadas en el template
- [ ] Los logs muestran que `recovery_link` se está enviando con valor
- [ ] El email se envió correctamente según SendGrid Activity

---

## 🔧 Próximo Paso: Revisar los Logs

**Lo más importante ahora es revisar los LOGS para ver qué se está enviando realmente.**

Si puedes, ejecuta un test de recuperación de contraseña y compárteme:
1. Los logs de Supabase Edge Functions (send-otp)
2. Los logs del servidor PHP (especialmente las líneas que dicen "SENDGRID DEBUG")

Con eso podremos verificar exactamente qué se está enviando a SendGrid.

