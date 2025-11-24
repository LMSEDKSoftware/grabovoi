# Configuración de Suscripciones en Google Play Console

## ⚠️ IMPORTANTE: Orden de Pasos

**SÍ necesitas subir un AAB con el permiso de FACTURACIÓN primero** para que Google Play Console active las funciones de monetización. Sigue estos pasos en orden:

### Paso 0: Verificar que la App esté Creada

1. Ve a **Google Play Console** → Selecciona tu app
2. Si es la primera vez, completa la información básica de la app (nombre, descripción, etc.)
3. **NO necesitas publicar la app**, solo tenerla creada

### Paso 1: Generar y Subir AAB con Permiso de Facturación

1. El código ya incluye el permiso `com.android.vending.BILLING` en el AndroidManifest.xml
2. Genera el AAB usando el script `BUILD_AAB.sh` (ya está generado: versionCode 5)
3. Sube el AAB a Google Play Console:
   - Ve a **Producción** → **Lanzamientos** → **Producción** (o usa una pista de prueba)
   - Sube el archivo `app-release.aab`
   - **NO necesitas publicarlo**, solo subirlo para que Google lo procese
4. Espera a que Google procese el AAB (puede tomar unos minutos)

### Paso 2: Verificar que Aparezca la Opción de Suscripciones

Después de subir el AAB con el permiso de facturación:

1. Ve a **Monetización** en el menú lateral
2. Deberías ver la opción **Suscripciones**
3. Si aún no aparece, espera unos minutos más o recarga la página

### Paso 3: Crear los Productos de Suscripción

Una vez que aparezca la opción de Suscripciones:

1. Ve a **Monetización** → **Productos** → **Suscripciones**
2. Haz clic en **Crear suscripción**

Crea dos productos con los siguientes IDs:

#### Producto 1: Suscripción Mensual
- **ID del producto**: `subscription_monthly`
- **Nombre**: "Suscripción Mensual"
- **Descripción**: "Acceso completo a todas las funciones premium por 1 mes"
- **Precio**: $88.00 MXN (o equivalente en tu moneda)
- **Período de facturación**: Mensual
- **Período de prueba gratuita**: 7 días
- **Período de gracia**: 3 días (opcional)

#### Producto 2: Suscripción Anual
- **ID del producto**: `subscription_yearly`
- **Nombre**: "Suscripción Anual"
- **Descripción**: "Acceso completo a todas las funciones premium por 1 año. Ahorra más con el plan anual."
- **Precio**: $888.00 MXN (o equivalente en tu moneda)
- **Período de facturación**: Anual
- **Período de prueba gratuita**: 7 días
- **Período de gracia**: 3 días (opcional)

### 2. Configurar el Período de Prueba Gratuita

Para ambos productos:
1. En la sección "Período de prueba gratuita", selecciona "7 días"
2. Esto permitirá que los usuarios prueben la app gratis durante 7 días antes de que se les cobre

### 3. Configurar Renovación Automática

- Ambos productos deben tener **renovación automática** habilitada
- Los usuarios pueden cancelar en cualquier momento desde Google Play

### 4. Publicar los Productos

1. Guarda los productos como **Borrador** primero
2. Una vez configurados correctamente, **actívalos**
3. Los productos deben estar activos antes de que los usuarios puedan comprarlos

**Nota**: Puedes crear y activar los productos ANTES de subir el AAB. Los productos funcionarán una vez que subas una versión de la app que incluya el código de suscripciones.

### 5. Subir el AAB con Código de Suscripciones

1. Genera el AAB con el código de suscripciones incluido (ya lo tienes)
2. Sube el AAB a Google Play Console en **Producción** → **Lanzamientos** → **Producción** (o en una pista de prueba)
3. Los productos de suscripción que creaste estarán disponibles para esa versión de la app

### 6. Verificar en la App

Los IDs de productos en el código deben coincidir exactamente con los configurados en Google Play Console:

```dart
static const String monthlyProductId = 'subscription_monthly';
static const String yearlyProductId = 'subscription_yearly';
```

**⚠️ IMPORTANTE**: Los IDs deben coincidir EXACTAMENTE (mayúsculas/minúsculas, guiones, etc.)

### 7. Testing

Para probar las suscripciones:

1. **Usa una cuenta de prueba**: Agrega cuentas de prueba en Google Play Console
2. **Compila en modo release**: Las compras solo funcionan en builds firmados
3. **Prueba el flujo completo**:
   - Iniciar período de prueba
   - Comprar suscripción mensual
   - Comprar suscripción anual
   - Restaurar compras

### Notas Importantes

- **Puedes crear los productos ANTES de subir el AAB** - no es necesario esperar
- Los productos deben estar **activos** en Google Play Console para que funcionen
- El período de prueba de 7 días se aplica automáticamente cuando el usuario se suscribe
- Los usuarios pueden cancelar en cualquier momento desde Google Play
- Las suscripciones se renuevan automáticamente hasta que el usuario las cancele
- El código maneja automáticamente el estado de suscripción y el período de prueba

### Solución de Problemas

**Si no ves la opción "Monetización" o "Suscripciones":**

1. Verifica que la app esté completamente creada en Google Play Console
2. Completa toda la información requerida de la app (categoría, contenido, etc.)
3. Espera unas horas - Google puede tardar en activar las funciones de monetización
4. Verifica que tengas permisos de administrador en la cuenta de Google Play Console
5. Si aún no aparece, intenta crear una versión de prueba primero (aunque no la publiques)

**Si los productos no aparecen en la app después de subir el AAB:**

1. Verifica que los IDs coincidan exactamente (case-sensitive)
2. Asegúrate de que los productos estén **activos** (no solo guardados como borrador)
3. Espera unos minutos después de activar los productos
4. Verifica que estés usando un build firmado (release), no debug

### Esquema de Base de Datos

Ejecuta el archivo `user_subscriptions_schema.sql` en Supabase SQL Editor para crear la tabla necesaria para almacenar las suscripciones.

### Verificación de Estado

El servicio `SubscriptionService` verifica automáticamente:
- Si el usuario está en período de prueba (7 días gratis)
- Si tiene una suscripción activa
- La fecha de expiración de la suscripción
- Restaura compras anteriores

