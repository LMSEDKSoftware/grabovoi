# Próximos Pasos Después de Crear los Planes Básicos

## ✅ Lo que ya tienes completado:

- [x] AAB subido con permiso de facturación
- [x] Productos de suscripción creados (`subscription_monthly` y `subscription_yearly`)
- [x] Planes básicos creados (`monthly-basic-plan` y `yearly-basic-plan`)
- [x] Planes básicos activos

## 📋 Próximos Pasos:

### Paso 1: Configurar Precios en los Planes Básicos

Ahora necesitas asignar precios a cada plan básico:

1. **Haz clic en el plan `monthly-basic-plan`** (o en la flecha →)
2. Dentro del plan, busca la sección **"Precios"** o **"Pricing"**
3. **Agrega el precio:**
   - Selecciona México (MXN) o "Todos los países"
   - Precio: **$88.00 MXN**
   - Guarda los cambios

4. **Repite para `yearly-basic-plan`:**
   - Haz clic en el plan `yearly-basic-plan`
   - Ve a la sección **"Precios"**
   - Agrega el precio: **$888.00 MXN**
   - Guarda los cambios

### Paso 2: Configurar Período de Prueba Gratuita

Para cada plan básico:

1. Dentro del plan, busca la sección **"Período de prueba gratuita"** o **"Free trial"**
2. Selecciona **"7 días"**
3. Guarda los cambios

**Hazlo para ambos planes:**
- `monthly-basic-plan` → 7 días gratis
- `yearly-basic-plan` → 7 días gratis

### Paso 3: Verificar que los Planes estén Vinculados Correctamente

1. Ve a **Monetización** → **Productos** → **Suscripciones**
2. Haz clic en **"Suscripción Mensual"** (el producto, no el plan)
3. Verifica que el plan `monthly-basic-plan` esté asignado al producto
4. Haz clic en **"Suscripción Anual"**
5. Verifica que el plan `yearly-basic-plan` esté asignado al producto

### Paso 4: Activar los Productos (si aún no están activos)

1. Ve a **Monetización** → **Productos** → **Suscripciones**
2. Para cada producto (`subscription_monthly` y `subscription_yearly`):
   - Verifica que el estado sea **"Activo"**
   - Si está en "Borrador", haz clic en **"Activar"**

### Paso 5: Verificación Final

Verifica que todo esté correcto:

- [ ] Plan `monthly-basic-plan` tiene precio de $88.00 MXN
- [ ] Plan `yearly-basic-plan` tiene precio de $888.00 MXN
- [ ] Ambos planes tienen período de prueba de 7 días configurado
- [ ] El producto `subscription_monthly` tiene asignado el plan `monthly-basic-plan`
- [ ] El producto `subscription_yearly` tiene asignado el plan `yearly-basic-plan`
- [ ] Ambos productos están **Activos** (no en borrador)

### Paso 6: Probar las Suscripciones

Una vez que todo esté configurado:

1. **Agrega cuentas de prueba** en Google Play Console:
   - Ve a **Configuración** → **Acceso y permisos** → **Cuentas de prueba**
   - Agrega tu cuenta de Gmail como cuenta de prueba

2. **Instala la app en un dispositivo Android** con tu cuenta de prueba

3. **Prueba el flujo completo:**
   - Abre la app
   - Ve a **Perfil** → **Suscripciones**
   - Deberías ver los dos planes disponibles
   - Intenta suscribirte (no se te cobrará con cuenta de prueba)
   - Verifica que el período de prueba de 7 días se active

---

## ⚠️ Notas Importantes:

1. **Los precios deben estar en los planes básicos**, no solo en los productos
2. **El período de prueba se configura en cada plan básico**
3. **Los productos deben estar Activos** para que funcionen en la app
4. **Puede tomar unos minutos** para que los cambios se reflejen en Google Play

---

## 🔍 Si algo no funciona:

1. **Los productos no aparecen en la app:**
   - Verifica que los IDs coincidan exactamente: `subscription_monthly` y `subscription_yearly`
   - Asegúrate de que los productos estén **Activos**
   - Espera unos minutos después de activar

2. **Los precios no se muestran:**
   - Verifica que los precios estén configurados en los planes básicos
   - Asegúrate de que el país/región esté incluido

3. **El período de prueba no funciona:**
   - Verifica que esté configurado en cada plan básico
   - Asegúrate de que sea exactamente "7 días"

---

## ✅ Checklist Final:

- [ ] Precios configurados en ambos planes básicos
- [ ] Período de prueba de 7 días configurado en ambos planes
- [ ] Planes vinculados correctamente a los productos
- [ ] Productos activos (no en borrador)
- [ ] Cuentas de prueba agregadas (para testing)
- [ ] App probada con cuenta de prueba

¡Una vez completados estos pasos, tus suscripciones estarán completamente configuradas y funcionando! 🎉

