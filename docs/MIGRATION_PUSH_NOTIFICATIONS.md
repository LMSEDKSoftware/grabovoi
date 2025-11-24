# 🚀 Plan de Migración: Notificaciones Push (Server-Side)

## 🎯 Recomendación: Firebase Cloud Messaging (FCM) + Supabase Edge Functions

La mejor opción para tu stack actual (Flutter + Supabase) es utilizar **Firebase Cloud Messaging (FCM)** orquestado por **Supabase Edge Functions**.

### ¿Por qué esta opción?
1.  **Estándar de la Industria**: FCM es la solución nativa de Google y tiene la mejor entrega en Android e iOS.
2.  **Costo**: FCM es gratuito. Supabase Edge Functions tiene una capa gratuita generosa.
3.  **Control Total**: Mueves la lógica de "cuándo notificar" del dispositivo del usuario (que puede estar apagado o sin batería) al servidor (que siempre está activo).
4.  **Integración Perfecta**: Supabase se integra naturalmente con FCM mediante Edge Functions y Webhooks.

---

## 🏗️ Nueva Arquitectura

### 1. Frontend (Flutter App)
*   **Responsabilidad Actual**: Calcular horarios, verificar rachas, programar alarmas locales.
*   **Nueva Responsabilidad**: Solo **recibir y mostrar**.
    *   Solicitar permisos de notificación.
    *   Obtener el `FCM Token` (identificador único del dispositivo).
    *   Guardar este token en tu base de datos Supabase.
    *   Escuchar mensajes entrantes (`FirebaseMessaging.onMessage`).

### 2. Backend (Supabase)
*   **Tabla `user_fcm_tokens`**: Para guardar los tokens de los usuarios (relación 1:N, un usuario puede tener varios dispositivos).
*   **Supabase Edge Functions**: Pequeños servidores (TypeScript/Deno) que contienen la lógica:
    *   `send-push`: Función genérica para enviar a FCM.
    *   `check-streaks`: Función que corre periódicamente para verificar rachas de todos los usuarios.
*   **pg_cron (Cron Jobs)**: Programador de tareas en la base de datos que dispara las Edge Functions.
    *   Ej: "Ejecutar `check-streaks` cada hora".
    *   Ej: "Enviar `daily-quote` a las 9:00 AM".

---

## 🗺️ Hoja de Ruta de Implementación

### Fase 1: Configuración Base
1.  Crear proyecto en **Firebase Console**.
2.  Configurar `flutter_fire` en la app.
3.  Crear tabla en Supabase:
    ```sql
    create table user_fcm_tokens (
      id uuid default gen_random_uuid() primary key,
      user_id uuid references auth.users not null,
      token text not null,
      device_type text, -- 'android', 'ios'
      last_active timestamp with time zone default now(),
      unique(user_id, token)
    );
    ```

### 4. Variables de Entorno (Supabase Edge Functions)
Para que las Edge Functions puedan comunicarse con Firebase, necesitas configurar las siguientes variables de entorno en tu proyecto de Supabase (Settings -> Edge Functions -> Secrets):

*   `FIREBASE_PROJECT_ID`: El ID de tu proyecto en Firebase Console.
*   `FIREBASE_CLIENT_EMAIL`: El email de la cuenta de servicio (service account) de Firebase.
*   `FIREBASE_PRIVATE_KEY`: La clave privada de la cuenta de servicio (¡Cuidado con los saltos de línea!).

Puedes obtener estos valores generando una nueva clave privada en **Firebase Console -> Project Settings -> Service accounts**.

### Fase 2: Lógica en el Servidor (Edge Functions)
1.  Crear una Edge Function `send-push` que use la `service-account` de Firebase para enviar mensajes.
2.  Crear lógica para eventos del sistema (ej: cuando se inserta un registro en `user_achievements`, un **Database Webhook** llama a `send-push` para felicitar al usuario).

### Fase 3: Migración de Lógica Programada (Cron)
1.  **Rachas**: En lugar de que la app verifique 30 mins, un cron job en Supabase ejecuta:
    ```sql
    select cron.schedule('0 * * * *', $$
      select net.http_post(
          url:='https://project.supabase.co/functions/v1/check-streaks',
          headers:='{"Content-Type": "application/json", "Authorization": "Bearer SERVICE_KEY"}'
      );
    $$);
    ```
    La función `check-streaks` busca usuarios inactivos > 24h y les envía la push.

2.  **Recordatorios Diarios**: Un cron job selecciona a los usuarios según su `preferred_time` (guardado en BD) y envía la notificación.

---

## ⚖️ Comparación

| Característica | Local Notifications (Actual) | Push Notifications (FCM) |
| :--- | :--- | :--- |
| **Fiabilidad** | Baja (Depende de que la app corra en fondo) | Alta (Gestionado por el OS) |
| **Persistencia** | Se pierden si se desinstala/borra datos | Se gestionan desde el servidor |
| **Lógica** | Descentralizada (en cada móvil) | Centralizada (en tu backend) |
| **Marketing** | Imposible (no puedes enviar promos nuevas) | Posible (puedes enviar campañas a todos) |
| **Complejidad** | Baja | Media (requiere backend logic) |

## 💡 Conclusión
Migrar a FCM + Supabase Edge Functions profesionalizará tu aplicación, aumentará la retención (al asegurar que las alertas de racha lleguen incluso si la app lleva días cerrada) y te abrirá la puerta a notificaciones de marketing y comunidad.
