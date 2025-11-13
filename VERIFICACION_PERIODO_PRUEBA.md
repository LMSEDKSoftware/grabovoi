# 🧪 Script de Verificación del Período de Prueba de 7 Días

## ✅ Verificaciones Implementadas

Este documento describe cómo verificar que el sistema de período de prueba de 7 días funciona correctamente.

## 📋 Checklist de Verificación

### 1. Verificación Automática en Código

El código ahora incluye logs detallados que te permitirán verificar el funcionamiento:

```dart
// Logs que deberías ver cuando un usuario nuevo se registra:
🔍 Iniciando verificación de estado de suscripción...
🔍 Usuario autenticado: true
🔍 User ID: [USER_ID]
🔍 No se encontró suscripción activa en Supabase
🔍 Verificando estado de período de prueba...
🔍 Usuario autenticado: true
🔍 User ID: [USER_ID]
🔍 Clave de período de prueba: free_trial_start_[USER_ID]
🔍 Valor encontrado: null
✅ Período de prueba iniciado automáticamente. Expira: [FECHA]
✅ Usuario ahora tiene acceso premium: true
```

### 2. Pasos para Verificar Manualmente

#### Paso 1: Crear Usuario Nuevo

1. Ejecuta la aplicación:
   ```bash
   flutter run
   ```

2. Crea un usuario completamente nuevo (email que nunca hayas usado antes)

3. Observa los logs en la consola. Deberías ver:
   - ✅ `Período de prueba iniciado automáticamente`
   - ✅ `Usuario ahora tiene acceso premium: true`

#### Paso 2: Verificar Acceso Premium

Después de crear el usuario, verifica que puede acceder a:

- ✅ Biblioteca Cuántica (no debería mostrar modal de suscripción)
- ✅ Desafíos (no debería mostrar modal de suscripción)
- ✅ Evolución (no debería mostrar modal de suscripción)
- ✅ Pilotaje Cuántico (no debería mostrar modal de suscripción)
- ✅ Código del Día en Home (debería poder hacer pilotaje)

#### Paso 3: Verificar SharedPreferences

Para verificar que el período de prueba se guardó correctamente:

**Opción A: Usando Flutter DevTools**
1. Abre Flutter DevTools
2. Ve a la pestaña "Inspector"
3. Busca SharedPreferences
4. Busca la clave: `free_trial_start_[USER_ID]`
5. Verifica que el valor es una fecha ISO válida

**Opción B: Usando código de debug**
Agrega este código temporalmente en cualquier pantalla después del login:

```dart
final prefs = await SharedPreferences.getInstance();
final userId = AuthServiceSimple().currentUser!.id;
final trialKey = 'free_trial_start_$userId';
final trialValue = prefs.getString(trialKey);
print('🔍 DEBUG - Trial Key: $trialKey');
print('🔍 DEBUG - Trial Value: $trialValue');
```

#### Paso 4: Verificar Persistencia

1. Cierra completamente la aplicación
2. Vuelve a abrirla
3. Inicia sesión con el mismo usuario
4. Verifica que:
   - Los logs muestran: `✅ Usuario en período de prueba. Expira: [FECHA]`
   - El usuario sigue teniendo acceso premium
   - El valor en SharedPreferences es el mismo

#### Paso 5: Verificar Expiración (Opcional)

Para verificar que el período expira correctamente después de 7 días:

**Opción A: Esperar 7 días reales** (no recomendado para pruebas)

**Opción B: Simular expiración modificando SharedPreferences**
1. Obtén el USER_ID del usuario
2. Modifica manualmente SharedPreferences para cambiar la fecha de inicio a hace 8 días
3. Reinicia la app
4. Verifica que:
   - Los logs muestran: `⚠️ Período de prueba expirado - usuario gratuito`
   - El usuario NO puede acceder a funciones premium
   - Se muestra el modal de suscripción requerida

## 🔍 Puntos de Verificación en el Código

### Verificación 1: Inicialización del Servicio

**Archivo:** `lib/main.dart`
- ✅ El servicio se inicializa incluso si IAP no está disponible
- ✅ Se llama a `checkSubscriptionStatus()` después de inicializar

### Verificación 2: Después de Registro

**Archivo:** `lib/services/auth_service_simple.dart`
- ✅ Después de `signUp()`, se llama a `SubscriptionService().checkSubscriptionStatus()`
- ✅ Logs muestran: `✅ Estado de suscripción verificado después de registro`

### Verificación 3: Después de Login

**Archivo:** `lib/services/auth_service_simple.dart`
- ✅ Después de `signIn()`, se llama a `SubscriptionService().checkSubscriptionStatus()`
- ✅ Logs muestran: `✅ Estado de suscripción verificado después de login`

### Verificación 4: En AuthWrapper

**Archivo:** `lib/widgets/auth_wrapper.dart`
- ✅ Cuando el usuario ya está autenticado al iniciar la app, se verifica el estado
- ✅ Logs muestran: `✅ Estado de suscripción verificado después de autenticación`

### Verificación 5: Lógica del Período de Prueba

**Archivo:** `lib/services/subscription_service.dart`
- ✅ Si no existe `free_trial_start_[USER_ID]` en SharedPreferences, se crea automáticamente
- ✅ Se establece `_isPremium = true` cuando se inicia el período de prueba
- ✅ La fecha de expiración es 7 días después del inicio

## 🐛 Troubleshooting

### Problema: Usuario nuevo NO obtiene período de prueba

**Solución:**
1. Verifica los logs de la consola para ver qué está pasando
2. Asegúrate de que el usuario está completamente autenticado antes de verificar
3. Verifica que SharedPreferences está funcionando correctamente
4. Revisa que no hay errores en `_checkFreeTrialStatus()`

### Problema: El período de prueba no persiste después de cerrar la app

**Solución:**
1. Verifica que SharedPreferences está guardando correctamente
2. Asegúrate de que el USER_ID es el mismo antes y después del login
3. Verifica que `checkSubscriptionStatus()` se llama después del login

### Problema: Usuario tiene acceso premium pero no debería

**Solución:**
1. Verifica la fecha de expiración en SharedPreferences
2. Verifica que el cálculo de expiración es correcto (7 días)
3. Verifica que la lógica de comparación de fechas funciona

## 📊 Métricas de Éxito

Un sistema funcionando correctamente debería:

- ✅ 100% de usuarios nuevos obtienen período de prueba automáticamente
- ✅ El período de prueba dura exactamente 7 días
- ✅ El período de prueba persiste después de cerrar/abrir la app
- ✅ Los usuarios sin período de prueba activo son tratados como gratuitos
- ✅ Los logs muestran claramente el estado en cada paso

## 🎯 Próximos Pasos

Después de verificar que todo funciona:

1. ✅ Remover logs de debug excesivos (mantener solo los importantes)
2. ✅ Agregar métricas/analytics para rastrear conversión de período de prueba a suscripción
3. ✅ Considerar agregar notificaciones cuando el período de prueba está por expirar

