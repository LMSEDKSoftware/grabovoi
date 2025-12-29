# 🚨 ACCIÓN INMEDIATA: Corregir Email Sin Links

## ✅ Lo que está CORRECTO

1. ✅ El template HTML que me mostraste es PERFECTO
2. ✅ El código está construyendo los datos correctamente
3. ✅ Las variables están bien escritas en el template

## ❌ El PROBLEMA

El template HTML está perfecto, PERO el problema está en **cómo está configurado el template en SendGrid**. SendGrid puede no estar reemplazando las variables por alguna de estas razones:

---

## 🔧 ACCIÓN 1: Verificar el Template en SendGrid (5 minutos)

### Paso 1: Ir al Template
1. Ve a: https://app.sendgrid.com/email_templates
2. Busca: **Template ID: `d-971362da419640f7be3c3cb7fae9881d`**
3. Haz clic en "Edit"

### Paso 2: Verificar Configuración
Verifica estas cosas en orden:

**A. ¿El template está como "Dynamic Template"?**
- En la configuración del template, debe decir "Dynamic Template" o "Transactional Template"
- Si dice "Classic Template", **ESE ES EL PROBLEMA** → Los classic templates NO soportan variables dinámicas

**B. ¿El HTML es el mismo?**
- Copia el HTML del template en SendGrid
- Compáralo con el HTML que me mostraste
- ¿Son idénticos? Si NO, **ESE ES EL PROBLEMA**

**C. ¿Las variables tienen espacios?**
- Busca en el HTML: `{{recovery_link}}`
- Verifica que NO haya espacios: `{{ recovery_link }}` está MAL
- Verifica que sea exactamente: `{{recovery_link}}` (sin espacios)

### Paso 3: Si el Template NO está como "Dynamic Template"
**SOLUCIÓN:**
1. Crea un NUEVO template
2. Selecciona "Dynamic Template" o "Transactional Template"
3. Copia tu HTML exacto
4. Guarda el template
5. Copia el nuevo Template ID
6. Actualiza en el código: cambia `d-971362da419640f7be3c3cb7fae9881d` por el nuevo ID

---

## 🔧 ACCIÓN 2: Revisar los Logs (10 minutos)

Para verificar qué se está enviando realmente:

### Paso 1: Ejecutar Test
1. Solicita recuperación de contraseña para un email de prueba
2. Revisa los logs inmediatamente

### Paso 2: Revisar Logs del Servidor PHP
Si tienes acceso al servidor (manigrab.app):

```bash
# Conectarte al servidor y revisar logs
tail -f /var/log/php/error.log | grep "SENDGRID DEBUG"
```

Busca estas líneas:
```
SENDGRID DEBUG: recovery_link en template_data: [¿Aparece la URL aquí?]
SENDGRID DEBUG: JSON completo a enviar: {...}
```

**Si `recovery_link` aparece vacío** → Problema en el código (pero creo que no es este caso)
**Si `recovery_link` aparece con URL** → Los datos están bien, problema en SendGrid

### Paso 3: Revisar Logs de Supabase
1. Ve a: Supabase Dashboard → Edge Functions → send-otp → Logs
2. Busca las líneas que dicen:
   - `📦 PAYLOAD COMPLETO A ENVIAR AL SERVIDOR:`
   - `recovery_link en template_data:`

**Comparte estos logs conmigo** para verificar qué se está enviando.

---

## 🔧 ACCIÓN 3: Solución Temporal - Usar HTML Directo

Si el problema persiste, podemos usar HTML directo temporalmente:

He modificado el código para que **también incluya HTML directo** como fallback. El servidor PHP ahora recibe tanto el template_id como el HTML con variables ya reemplazadas.

**Para forzar HTML directo**, modifica `server/email_endpoint.php` línea ~155:

**Cambiar:**
```php
$useTemplate = !empty($data['template_id']) || (!empty($templateRecovery) && !empty($data['template_data']));
```

**Por:**
```php
$useTemplate = false; // Temporalmente deshabilitar templates, usar HTML directo
```

Esto hará que siempre use HTML directo en lugar del template.

---

## 📋 RESUMEN DE VERIFICACIÓN

Marca con ✅ lo que verifiques:

- [ ] Template en SendGrid tiene ID: `d-971362da419640f7be3c3cb7fae9881d`
- [ ] Template está configurado como **"Dynamic Template"** (NO "Classic Template")
- [ ] HTML en SendGrid es IDÉNTICO al que me mostraste
- [ ] Variables NO tienen espacios: `{{recovery_link}}` (NO `{{ recovery_link }}`)
- [ ] Template está en estado "Active" o "Published"
- [ ] Logs muestran que `recovery_link` se envía con valor
- [ ] Email se envía correctamente según SendGrid Activity

---

## 🎯 Lo Más Probable

Basado en que tu template HTML está perfecto, lo más probable es que:

1. **El template NO esté configurado como "Dynamic Template"** → Los classic templates no soportan variables dinámicas
2. **El template activo en SendGrid sea diferente** → Puede haber múltiples versiones y estar usando una antigua

**Empieza verificando esto primero**, es lo más rápido y probable que sea la causa.

---

## 📞 Si Necesitas Ayuda

Comparte conmigo:
1. Una captura de pantalla de la configuración del template en SendGrid (que muestre si es Dynamic o Classic)
2. Los logs del servidor PHP (líneas con "SENDGRID DEBUG")
3. Los logs de Supabase Edge Functions (la parte del payload)

Con eso podré identificar exactamente dónde está el problema.

