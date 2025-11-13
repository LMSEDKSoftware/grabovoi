# Script para Activar Acceso Premium para Pruebas

## 📋 Instrucciones

Este script te permite activar acceso Premium temporalmente en tu cuenta para poder probar todas las funcionalidades de la app sin necesidad de contratar el servicio.

## 🔧 Opción 1: Desde Supabase SQL Editor (Recomendado)

1. Ve a tu proyecto en **Supabase Dashboard**
2. Navega a **SQL Editor**
3. Abre el archivo `ACTIVAR_PREMIUM_TEST.sql`
4. Reemplaza `'TU_EMAIL_AQUI'` con tu email de usuario
5. Ejecuta el script completo
6. Verifica que se haya creado la suscripción con la consulta al final del script

## 🔧 Opción 2: Consulta Rápida por Email

Si prefieres hacerlo más rápido, ejecuta esta consulta directamente en SQL Editor:

```sql
-- Reemplaza 'TU_EMAIL_AQUI' con tu email
INSERT INTO user_subscriptions (
    user_id,
    product_id,
    purchase_id,
    transaction_date,
    expires_at,
    is_active
)
SELECT 
    u.id,
    'subscription_yearly',
    'test_premium_' || gen_random_uuid()::text,
    NOW(),
    NOW() + INTERVAL '1 year',
    true
FROM auth.users u
WHERE u.email = 'TU_EMAIL_AQUI'
ON CONFLICT DO NOTHING;
```

## 📱 Después de Activar

1. **Cierra completamente la app** en tu dispositivo Android
2. **Vuelve a abrirla** (esto fuerza que se recargue el estado de suscripción)
3. Deberías tener acceso completo a todas las funciones Premium

## ⚠️ Notas Importantes

- La suscripción de prueba expirará en 1 año
- Puedes extenderla ejecutando el script nuevamente
- Esta suscripción es solo para pruebas, no se cobrará nada
- El `purchase_id` tiene el prefijo `test_premium_` para identificarlo fácilmente

## 🔍 Verificar tu User ID

Si necesitas encontrar tu `user_id`, ejecuta esta consulta:

```sql
SELECT id, email, created_at 
FROM auth.users 
WHERE email = 'TU_EMAIL_AQUI';
```

## 🗑️ Desactivar Acceso Premium

Si quieres volver a ser usuario gratuito para probar las restricciones:

```sql
-- Reemplaza 'TU_EMAIL_AQUI' con tu email
UPDATE user_subscriptions
SET is_active = false
WHERE user_id IN (
    SELECT id FROM auth.users WHERE email = 'TU_EMAIL_AQUI'
);
```


