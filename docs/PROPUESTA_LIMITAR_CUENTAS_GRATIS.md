# Propuesta: Limitar Creación de Múltiples Cuentas Gratuitas

## Problema
Los usuarios pueden crear múltiples cuentas para aprovechar el período de prueba gratuito de 7 días repetidamente, evitando pagar por la suscripción premium.

## Soluciones Propuestas (Ordenadas por Efectividad)

### 1. **Verificación de Email Obligatoria** ⭐⭐⭐⭐⭐ (RECOMENDADA)
**Efectividad: Alta | Complejidad: Baja | Impacto en UX: Mínimo**

#### Descripción
Hacer que la verificación de email sea **obligatoria** antes de activar el período de prueba gratuito. Esto dificulta la creación masiva de cuentas.

#### Implementación
- Modificar `SubscriptionService._checkFreeTrialStatus()` para verificar `is_email_verified = true`
- Solo activar período de prueba si el email está verificado
- Mostrar mensaje claro: "Verifica tu email para activar tu período de prueba gratuito"

#### Ventajas
- ✅ Fácil de implementar
- ✅ Bajo impacto en usuarios legítimos
- ✅ Dificulta creación masiva de cuentas
- ✅ Mejora la calidad de la base de datos

#### Desventajas
- ⚠️ Usuarios pueden usar servicios de email temporales (pero requiere más esfuerzo)

---

### 2. **Detección por Device ID / Android ID** ⭐⭐⭐⭐
**Efectividad: Alta | Complejidad: Media | Impacto en UX: Bajo**

#### Descripción
Rastrear el dispositivo que crea cuentas usando el Android ID o Advertising ID. Limitar a 1-2 cuentas por dispositivo.

#### Implementación
```dart
// Nuevo servicio: device_tracking_service.dart
import 'package:device_info_plus/device_info_plus.dart';

class DeviceTrackingService {
  Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // Android ID
    }
    // iOS: usar identifierForVendor
    return 'unknown';
  }
  
  Future<bool> canCreateAccount() async {
    final deviceId = await getDeviceId();
    // Consultar en Supabase cuántas cuentas tiene este dispositivo
    final count = await _supabase
      .from('device_accounts')
      .select('user_id')
      .eq('device_id', deviceId)
      .count();
    
    return count < 2; // Máximo 2 cuentas por dispositivo
  }
}
```

#### Tabla en Supabase
```sql
CREATE TABLE device_accounts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  device_id TEXT NOT NULL,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(device_id, user_id)
);

CREATE INDEX idx_device_accounts_device_id ON device_accounts(device_id);
```

#### Ventajas
- ✅ Muy efectivo para prevenir abuso
- ✅ No requiere cambios en UX
- ✅ Funciona incluso si cambian de email

#### Desventajas
- ⚠️ Requiere permiso de dispositivo (puede ser rechazado)
- ⚠️ Puede afectar a usuarios que comparten dispositivo
- ⚠️ Usuarios pueden resetear el dispositivo (pero requiere más esfuerzo)

---

### 3. **Rate Limiting por IP** ⭐⭐⭐
**Efectividad: Media | Complejidad: Media | Impacto en UX: Bajo**

#### Descripción
Limitar el número de registros desde la misma IP en un período de tiempo (ej: 3 registros por IP en 24 horas).

#### Implementación
- Crear tabla `registration_attempts` en Supabase
- Registrar cada intento de registro con IP y timestamp
- Verificar antes de permitir registro

#### Tabla en Supabase
```sql
CREATE TABLE registration_attempts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  ip_address INET NOT NULL,
  email TEXT NOT NULL,
  attempted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  success BOOLEAN DEFAULT false
);

CREATE INDEX idx_registration_attempts_ip ON registration_attempts(ip_address, attempted_at);
```

#### Función SQL para verificar
```sql
CREATE OR REPLACE FUNCTION can_register_from_ip(ip INET)
RETURNS BOOLEAN AS $$
DECLARE
  attempt_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO attempt_count
  FROM registration_attempts
  WHERE ip_address = ip
    AND attempted_at > NOW() - INTERVAL '24 hours'
    AND success = true;
  
  RETURN attempt_count < 3; -- Máximo 3 registros por IP en 24 horas
END;
$$ LANGUAGE plpgsql;
```

#### Ventajas
- ✅ Efectivo contra abuso automatizado
- ✅ No requiere cambios en la app móvil
- ✅ Se puede implementar en Supabase Edge Functions

#### Desventajas
- ⚠️ Puede afectar a usuarios en la misma red (oficina, casa compartida)
- ⚠️ Usuarios pueden usar VPN para evadir

---

### 4. **Detección de Patrones de Email** ⭐⭐⭐
**Efectividad: Media | Complejidad: Baja | Impacto en UX: Bajo**

#### Descripción
Detectar emails temporales o patrones sospechosos (ej: `usuario+1@gmail.com`, `usuario+2@gmail.com`, emails de servicios temporales).

#### Implementación
```dart
class EmailValidationService {
  // Lista de dominios de email temporales conocidos
  static const List<String> temporaryEmailDomains = [
    'tempmail.com',
    '10minutemail.com',
    'guerrillamail.com',
    'mailinator.com',
    // ... más dominios
  ];
  
  bool isTemporaryEmail(String email) {
    final domain = email.split('@').last.toLowerCase();
    return temporaryEmailDomains.contains(domain);
  }
  
  bool hasSuspiciousPattern(String email) {
    // Detectar patrones como usuario+1, usuario+2, etc.
    final pattern = RegExp(r'\+(\d+)@');
    return pattern.hasMatch(email);
  }
}
```

#### Ventajas
- ✅ Fácil de implementar
- ✅ Detecta abuso común
- ✅ No afecta a usuarios legítimos

#### Desventajas
- ⚠️ Lista de dominios temporales debe mantenerse actualizada
- ⚠️ Usuarios pueden usar emails reales diferentes

---

### 5. **Sistema de Reputación de Usuario** ⭐⭐⭐⭐
**Efectividad: Alta | Complejidad: Alta | Impacto en UX: Bajo**

#### Descripción
Crear un sistema de "reputación" que rastree el comportamiento del usuario. Usuarios con baja reputación tienen restricciones.

#### Implementación
- Tabla `user_reputation` con score
- Penalizar: múltiples cuentas, comportamiento sospechoso
- Recompensar: uso activo, suscripciones, verificación de email

#### Ventajas
- ✅ Muy efectivo a largo plazo
- ✅ Permite detección de patrones complejos
- ✅ Puede ser usado para otras funcionalidades

#### Desventajas
- ⚠️ Requiere desarrollo significativo
- ⚠️ Necesita mantenimiento continuo

---

## Recomendación: Enfoque Combinado

### Fase 1 (Implementación Inmediata) ⚡
1. **Verificación de Email Obligatoria** - Implementar primero, es la más fácil y efectiva
2. **Detección de Patrones de Email** - Agregar validación básica

### Fase 2 (Implementación a Corto Plazo) 📅
3. **Rate Limiting por IP** - Implementar en Supabase Edge Functions
4. **Detección por Device ID** - Agregar tracking de dispositivos

### Fase 3 (Implementación a Largo Plazo) 🎯
5. **Sistema de Reputación** - Desarrollar sistema completo de scoring

---

## Implementación Recomendada: Verificación de Email Obligatoria

### Cambios Necesarios

#### 1. Modificar `SubscriptionService._checkFreeTrialStatus()`
```dart
Future<void> _checkFreeTrialStatus() async {
  // ... código existente ...
  
  // Verificar que el email esté verificado
  final userData = await _supabase
      .from('users')
      .select('created_at, is_email_verified')
      .eq('id', userId)
      .maybeSingle();
  
  if (userData == null || userData['is_email_verified'] != true) {
    print('⚠️ Email no verificado - período de prueba no activado');
    _isPremium = false;
    _subscriptionExpiryDate = null;
    _subscriptionStatusController.add(false);
    return;
  }
  
  // ... resto del código ...
}
```

#### 2. Modificar `SubscriptionWelcomeModal.shouldShowModal()`
```dart
static Future<bool> shouldShowModal() async {
  // ... código existente ...
  
  // Verificar si el email está verificado
  final userData = await _supabase
      .from('users')
      .select('is_email_verified')
      .eq('id', authService.currentUser!.id)
      .maybeSingle();
  
  if (userData?['is_email_verified'] != true) {
    return false; // No mostrar modal si email no está verificado
  }
  
  // ... resto del código ...
}
```

#### 3. Actualizar UI de Registro
Mostrar mensaje claro sobre verificación de email:
```dart
// En register_screen.dart
Text(
  'Verifica tu email para activar tu período de prueba gratuito de 7 días',
  style: TextStyle(color: Colors.amber),
)
```

---

## Métricas para Monitorear

1. **Tasa de verificación de email**: % de usuarios que verifican su email
2. **Registros por IP**: Detectar IPs con múltiples registros
3. **Registros por dispositivo**: Detectar dispositivos con múltiples cuentas
4. **Conversión a suscripción**: % de usuarios que se suscriben después del período de prueba

---

## Notas Adicionales

- **Balance entre seguridad y UX**: No hacer el proceso tan restrictivo que afecte a usuarios legítimos
- **Mensajes claros**: Si se rechaza un registro, explicar el motivo de forma clara
- **Apelación**: Considerar un proceso para que usuarios legítimos puedan apelar restricciones
- **Monitoreo continuo**: Revisar métricas regularmente y ajustar políticas según sea necesario

