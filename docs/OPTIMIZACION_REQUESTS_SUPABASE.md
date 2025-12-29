# Optimización de Requests a Supabase

## Problemas Identificados

1. **Múltiples consultas individuales a `codigos_titulos_relacionados`**
   - Se hacen ~50+ consultas individuales cuando podrían ser 1 batch query
   
2. **Consultas duplicadas a las mismas tablas**
   - `users`, `user_subscriptions`, `user_challenges`, `usuario_progreso`, `daily_code_assignments` se consultan múltiples veces desde diferentes pantallas

3. **Sin caché local**
   - Datos que no cambian frecuentemente se consultan cada vez

4. **Sin debouncing/throttling**
   - Múltiples llamadas simultáneas al mismo endpoint

## Soluciones Propuestas

### 1. Servicio de Caché Centralizado
- Caché en memoria para datos del usuario (TTL: 5 minutos)
- Caché persistente para datos estáticos (códigos, configuraciones)
- Invalidación inteligente cuando los datos cambian

### 2. Batch Queries para Códigos Relacionados
- Agrupar múltiples códigos en una sola consulta usando `inFilter`
- Reducir de 50+ requests a 1-2 requests

### 3. Servicio Centralizado de Datos del Usuario
- Un solo servicio que carga todos los datos del usuario de una vez
- Evitar múltiples llamadas desde diferentes pantallas

### 4. Debouncing/Throttling
- Evitar múltiples llamadas simultáneas al mismo endpoint
- Usar un sistema de "request queue" para agrupar llamadas similares

### 5. Fix de app_config
- Manejar el error 500 y usar valores por defecto
- No reintentar si falla


