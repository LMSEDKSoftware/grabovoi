# 🔍 RESUMEN DEL PROBLEMA - RECOVERY PASSWORD

## Situación Actual

- ✅ El usuario reporta que **30 correos se enviaron correctamente** antes
- ❌ **Ahora los correos no llegan** o llegan sin las variables correctas
- ✅ **Prueba desde SendGrid funciona** - las variables llegan bien
- ❌ **Algo cambió** en cómo se envían los datos

## Análisis del Código

### Edge Function (TypeScript)

```typescript
serverPayload.template_data = {
  name: userName || 'Usuario',
  app_name: 'ManiGrab',
  recovery_link: templateDataRecoveryLink // URL final validada y trimmeada
}
```

**✅ Esto parece correcto**

### Servidor PHP

```php
$templateData = $data['template_data'] ?? [];

$emailData = [
    'personalizations' => [
        [
            'to' => [['email' => $data['to']]],
            'dynamic_template_data' => $templateData,
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
```

**✅ Esto también parece correcto**

## Posibles Causas

### 1. URL del Servidor Incorrecta
- La Edge Function puede estar usando una URL incorrecta
- Verificar variable `EMAIL_SERVER_URL` en Supabase

### 2. Problema de Serialización JSON
- El objeto `template_data` puede no estar serializándose correctamente
- Verificar que `JSON.stringify(serverPayload)` funcione bien

### 3. Problema en el Servidor Web
- El servidor puede estar rechazando el Content-Type
- Error 415 puede indicar problema de configuración del servidor web

### 4. Variables de Entorno
- Las variables pueden no estar cargadas correctamente en el servidor PHP
- Verificar que `template_data` llegue al servidor

## Qué Verificar

1. **Logs de la Edge Function**: Verificar qué se está enviando exactamente
   - Buscar: `📦 PAYLOAD COMPLETO A ENVIAR AL SERVIDOR`
   - Verificar que `recovery_link` esté presente

2. **Logs del Servidor PHP**: Verificar qué se recibe
   - Buscar: `SENDGRID DEBUG: template_data RAW`
   - Verificar que `recovery_link` esté presente

3. **Logs de SendGrid**: Verificar qué se envía a SendGrid
   - Buscar: `SENDGRID DEBUG: JSON completo a enviar`
   - Verificar estructura de `dynamic_template_data`

4. **URL Correcta**: Verificar que la URL del servidor sea correcta
   - Debe ser: `https://manigrab.app/api/send-email/email_endpoint.php`
   - O: `https://manigrab.app/email_endpoint.php`

## Próximos Pasos

1. Ejecutar el script de diagnóstico completo
2. Revisar logs reales de producción
3. Comparar payload actual vs payload que funcionaba antes
4. Verificar configuración del servidor web (nginx/apache)





