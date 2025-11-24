# Configuración del Plan Básico - Google Play Console

## 📋 Para Suscripción Mensual

### ID del Plan Básico
```
monthly-basic-plan
```
**Reglas:**
- ✅ Comienza con letra minúscula
- ✅ Solo contiene letras minúsculas y guiones
- ✅ Máximo 63 caracteres (actual: 18 caracteres)
- ⚠️ **NO se puede cambiar después** - elige bien

**Alternativas si prefieres:**
- `monthly-plan`
- `mensual-basico`
- `plan-mensual`

### Tipo
**Selecciona:** ✅ **Renovación automática**

**Razón:**
- Los usuarios realizan pagos recurrentes cada mes
- El plan se renueva automáticamente
- Los usuarios pueden cancelar cuando quieran
- Es el tipo estándar para suscripciones mensuales

### Etiquetas (Opcional)
```
premium, mensual, ilimitado
```
O puedes dejarlo vacío si prefieres.

---

## 📋 Para Suscripción Anual

### ID del Plan Básico
```
yearly-basic-plan
```
**Reglas:**
- ✅ Comienza con letra minúscula
- ✅ Solo contiene letras minúsculas y guiones
- ✅ Máximo 63 caracteres (actual: 18 caracteres)
- ⚠️ **NO se puede cambiar después** - elige bien

**Alternativas si prefieres:**
- `yearly-plan`
- `anual-basico`
- `plan-anual`

### Tipo
**Selecciona:** ✅ **Renovación automática**

**Razón:**
- Los usuarios realizan pagos recurrentes cada año
- El plan se renueva automáticamente
- Los usuarios pueden cancelar cuando quieran
- Es el tipo estándar para suscripciones anuales

### Etiquetas (Opcional)
```
premium, anual, ilimitado, ahorro
```
O puedes dejarlo vacío si prefieres.

---

## ⚠️ IMPORTANTE

1. **El ID del plan es diferente al ID del producto:**
   - ID del producto: `subscription_monthly` / `subscription_yearly`
   - ID del plan básico: `monthly-basic-plan` / `yearly-basic-plan`

2. **El ID del plan NO afecta el código de la app:**
   - El código usa los IDs de producto (`subscription_monthly` y `subscription_yearly`)
   - El ID del plan es solo para organización interna en Google Play Console

3. **Tipo siempre debe ser "Renovación automática":**
   - Para suscripciones mensuales y anuales recurrentes
   - NO uses "Prepagado" ni "Cuotas" para estos casos

4. **Etiquetas son opcionales:**
   - Solo ayudan a organizar los planes en Google Play Console
   - No afectan la funcionalidad

---

## ✅ Checklist Rápido

### Plan Mensual:
- [ ] ID del plan: `monthly-basic-plan`
- [ ] Tipo: ✅ Renovación automática
- [ ] Etiquetas: (opcional) `premium, mensual, ilimitado`
- [ ] Continuar con configuración de precios

### Plan Anual:
- [ ] ID del plan: `yearly-basic-plan`
- [ ] Tipo: ✅ Renovación automática
- [ ] Etiquetas: (opcional) `premium, anual, ilimitado, ahorro`
- [ ] Continuar con configuración de precios

