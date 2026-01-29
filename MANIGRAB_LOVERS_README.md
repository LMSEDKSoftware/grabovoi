# ManiGrabLovers - Gestión de Accesos Premium por Administradores

## Descripción

ManiGrabLovers es una funcionalidad que permite a los administradores otorgar accesos premium (mensuales o anuales) a usuarios sin necesidad de que estos compren la suscripción a través de Google Play Store.

## Características

- ✅ Los administradores pueden otorgar suscripciones premium ingresando solo el email del usuario
- ✅ Soporte para suscripciones mensuales (30 días) y anuales (365 días)
- ✅ Búsqueda automática del UID del usuario por email
- ✅ Gestión completa: otorgar, ver y revocar suscripciones
- ✅ Lista de todas las suscripciones ManiGrabLovers activas

## Configuración Inicial

### 1. Ejecutar Políticas RLS en Supabase

Para que los administradores puedan gestionar suscripciones, es necesario ejecutar el script SQL que crea las políticas de seguridad:

1. Ve al **SQL Editor** de tu proyecto en Supabase
2. Abre el archivo `database/manigrab_lovers_rls_policies.sql`
3. Ejecuta el script completo

Este script crea políticas que permiten a los administradores:
- Ver todas las suscripciones
- Insertar suscripciones para cualquier usuario
- Actualizar suscripciones (activar/desactivar)
- Eliminar suscripciones

### 2. Verificar que el Usuario es Administrador

Asegúrate de que el usuario que va a gestionar las suscripciones esté en la tabla `users_admin`. Puedes usar el script `scripts/add_admin_user.sql` para agregar administradores.

## Uso de la Funcionalidad

### Acceder a ManiGrabLovers

1. Inicia sesión como administrador en la app
2. Ve al **Perfil** (Profile)
3. En la sección de botones de administrador, encontrarás el botón **"ManiGrabLovers"** (con icono de corazón rosa)
4. Toca el botón para abrir la pantalla de gestión

### Otorgar una Suscripción

1. En la pantalla de ManiGrabLovers, ingresa el **email** del usuario al que deseas otorgar acceso premium
2. Selecciona el tipo de suscripción:
   - **Mensual**: Acceso por 30 días
   - **Anual**: Acceso por 365 días
3. Toca el botón **"Otorgar Acceso"**
4. La app buscará automáticamente el usuario por email y le otorgará la suscripción

**Nota**: Si el usuario ya tiene una suscripción activa, esta será desactivada y se creará una nueva con la fecha de expiración correspondiente.

### Ver Suscripciones Activas

En la parte inferior de la pantalla de ManiGrabLovers, verás una lista de todas las suscripciones ManiGrabLovers activas, mostrando:
- Nombre y email del usuario
- Tipo de suscripción (Mensual/Anual)
- Fecha de expiración

### Revocar una Suscripción

1. En la lista de suscripciones activas, encuentra la suscripción que deseas revocar
2. Toca el botón **"Revocar"** en la tarjeta de la suscripción
3. Confirma la acción en el diálogo que aparece
4. La suscripción será desactivada inmediatamente

## Product IDs Utilizados

Los siguientes `product_id` se utilizan para identificar las suscripciones ManiGrabLovers:

- `manigrab_lovers_monthly`: Suscripción mensual (30 días)
- `manigrab_lovers_yearly`: Suscripción anual (365 días)

Estos product_ids son reconocidos automáticamente por el `SubscriptionService` y otorgan acceso premium completo a la aplicación.

## Integración con el Sistema de Suscripciones

El sistema de suscripciones existente (`SubscriptionService`) reconoce automáticamente las suscripciones ManiGrabLovers porque:

1. Se almacenan en la misma tabla `user_subscriptions`
2. Tienen el campo `is_active = true` cuando están activas
3. El `SubscriptionService` verifica cualquier suscripción activa sin importar el `product_id`

**No se requieren cambios adicionales** en el código de verificación de suscripciones.

## Estructura de Datos

Las suscripciones ManiGrabLovers se almacenan en la tabla `user_subscriptions` con la siguiente estructura:

```sql
{
  user_id: UUID,                    -- ID del usuario
  product_id: TEXT,                 -- 'manigrab_lovers_monthly' o 'manigrab_lovers_yearly'
  purchase_id: TEXT,                -- ID único generado automáticamente
  transaction_date: TIMESTAMPTZ,    -- Fecha de otorgamiento
  expires_at: TIMESTAMPTZ,          -- Fecha de expiración
  is_active: BOOLEAN,               -- true si está activa
  created_at: TIMESTAMPTZ           -- Fecha de creación
}
```

## Seguridad

- ✅ Solo los usuarios en la tabla `users_admin` pueden acceder a esta funcionalidad
- ✅ Las políticas RLS aseguran que solo los administradores puedan gestionar suscripciones
- ✅ Se valida el formato de email antes de otorgar suscripciones
- ✅ Se verifica que el usuario exista antes de crear la suscripción

## Troubleshooting

### Error: "Usuario no encontrado con el email: ..."

**Causa**: El email ingresado no corresponde a ningún usuario registrado en la aplicación.

**Solución**: 
- Verifica que el email esté escrito correctamente
- Asegúrate de que el usuario haya creado una cuenta en la app
- El email debe coincidir exactamente con el usado en el registro (case-insensitive)

### Error: "No tienes permisos de administrador"

**Causa**: El usuario actual no está en la tabla `users_admin`.

**Solución**: 
- Ejecuta el script `scripts/add_admin_user.sql` para agregar el usuario como administrador
- O usa el método `AdminService.agregarAdmin(userId)` desde código

### Las suscripciones no se reconocen como premium

**Causa**: Las políticas RLS pueden estar bloqueando el acceso.

**Solución**:
- Verifica que hayas ejecutado `database/manigrab_lovers_rls_policies.sql`
- Asegúrate de que el usuario administrador esté en `users_admin`
- Verifica que las políticas RLS estén habilitadas en la tabla `user_subscriptions`

## Archivos Relacionados

- `lib/services/admin_service.dart`: Servicio con métodos para gestionar suscripciones
- `lib/screens/admin/manigrab_lovers_screen.dart`: Pantalla de gestión de suscripciones
- `lib/screens/profile/profile_screen.dart`: Perfil donde se accede a ManiGrabLovers
- `database/manigrab_lovers_rls_policies.sql`: Políticas RLS para administradores
- `lib/services/subscription_service.dart`: Servicio que verifica suscripciones (ya compatible)

## Notas Importantes

1. **Desactivación automática**: Cuando se otorga una nueva suscripción ManiGrabLovers, cualquier suscripción activa previa del usuario es desactivada automáticamente.

2. **Búsqueda por email**: El sistema busca usuarios en la tabla `users` por email. Si un usuario se registró con Google OAuth, asegúrate de usar el email de su cuenta de Google.

3. **Expiración**: Las suscripciones expiradas se marcan automáticamente como `is_active = false` cuando el `SubscriptionService` verifica el estado.

4. **Purchase ID**: El `purchase_id` se genera automáticamente con el formato `manigrab_lovers_admin_[timestamp]` para distinguirlo de compras de Play Store.
