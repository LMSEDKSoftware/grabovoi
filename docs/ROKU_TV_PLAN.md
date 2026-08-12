# ManiGraB TV (Roku) — Plan de implementación

## Corrección importante al análisis de ChatGPT (verificado contra la doc oficial de Roku)

El texto que compartiste propone "Manigraph Account ←→ Roku Identity" sin
concretar el mecanismo, y sugiere algo parecido al patrón "rendezvous"
(código en la TV, lo activas en tu teléfono/computadora — el que usan
Netflix o YouTube). **Ese patrón está explícitamente prohibido por Roku
para apps públicas.**

De [developer.roku.com/dev/docs/on-device-authentication](https://developer.roku.com/dev/docs/on-device-authentication):

> "On-device authentication deprecates the 'rendezvous' registration
> method... Sign-up and sign-in workflows are prohibited from including
> external webpages, links to off-device promotional or marketing
> materials, or utilizing off-device sign-up or sign-in mechanisms."

Esto cambia la arquitectura de login por completo respecto a lo que
construimos para Alexa:

- **Alexa:** login vía página web (`alexa-oauth-authorize.js`), abierta
  dentro de la app de Alexa. Es el patrón estándar de "Authorization Code
  Grant".
- **Roku:** el login tiene que pasar **enteramente dentro del canal**,
  con el control remoto, usando el teclado en pantalla nativo de Roku.
  Nada de páginas web externas, nada de "activa en manigrab.app/tv", y
  nada de login con Google/Facebook vía OAuth de terceros (tampoco está
  permitido).

La buena noticia: esto en realidad **simplifica** el backend respecto a
Alexa. No hace falta replicar `alexa-oauth-authorize.js` ni
`alexa-oauth-token`. El canal de Roku llama directo a un endpoint tipo
`POST /roku-login` con email + password (capturados con el teclado en
pantalla), que valida contra Supabase Auth exactamente como lo hace hoy
la app — y devuelve un token opaco de larga duración, con el mismo
patrón de `alexa_account_links` pero para Roku.

**Segunda corrección:** ChatGPT presenta Direct-to-Play (deep linking +
Roku Search, activable por voz) como algo "interesante para después". La
documentación dice lo contrario:

> "Public apps must implement Direct to Play to pass certification."

Es un requisito de certificación, no una mejora opcional. Hay que
contemplarlo desde el diseño del MVP, no como fase tardía. Un detalle
técnico que se deriva de esto: **el contenido enlazado por voz/búsqueda
debe reanudar automáticamente desde el bookmark, sin pantalla de "¿quieres
continuar?"** — eso obliga a tener el tracking de progreso bien resuelto
desde temprano, no como feature de pulido.

Lo que sí confirmé correcto de tu texto: registro de desarrollador y
publicación en el Roku Channel Store son gratis, y SceneGraph/BrightScript
es efectivameente el stack a usar.

## La ventaja que Roku sí tiene y Alexa no

Esta sesión terminamos abandonando "voz propia + música de fondo" en
Alexa por límites de la plataforma: una respuesta no puede pasar de 240
segundos, el límite de clips por respuesta obliga a pre-mezclar todo en
un solo MP3, y la interfaz de audio (APLA) tiene soporte incierto según
el dispositivo — nunca pudimos confirmarlo en un Echo Dot real.

**Ninguna de esas restricciones existe en Roku.** Es una plataforma de
video/audio de formato largo por diseño. El pipeline que ya construimos
y quedó sin usar —`scripts/render_alexa_audio.py`, que mezcla la voz
grabada de la app (`assets/audios/voice_numbers/`) con música de fondo
(`assets/audios/crystal_bowls.mp3` y las otras 4 pistas) replicando
exactamente el ritmo de `NumbersVoiceService`— **se puede reutilizar
directo para Roku**, sin ninguna de las limitaciones que lo mataron en
Alexa. Es la funcionalidad diferenciadora que no logramos entregar en
voz, y aquí sí es viable.

## Mapeo del modelo de datos: qué ya existe vs. qué es nuevo

| Concepto (del texto de ChatGPT) | Estado real |
|---|---|
| `user` | Ya existe — `auth.users` de Supabase |
| `sequence` | Ya existe — `codigos_grabovoi` (biblioteca abierta) y `codigos_premium` (gateada por cristales) |
| `favorite` | Ya existe — `usuario_favoritos` |
| `history` / "continuar" | **Ya existe pero no se usa** — `user_code_history` (id, user_id, code_id, code_name, usage_count, last_used, total_time_minutes). 0 filas hoy; nadie lo llena, ni siquiera la app. Hay que empezar a escribirlo. |
| `session` (progreso, racha, cristales) | Ya existe — `usuario_progreso`, `user_rewards`, y el RPC `otorgar_recompensa_repeticion()` que ya escribimos para Alexa, reutilizable tal cual |
| `routine` | **No existe en ningún lado.** Ni en el schema ni en el código Flutter (solo aparece la palabra en un tipo de notificación, no como feature real). Genuinamente nuevo. |
| `device` (vincular Roku a la cuenta) | Nuevo, pero mismo patrón que `alexa_account_links` — se replica la forma, no la lógica de OAuth (por la restricción de auth explicada arriba) |

## Arquitectura propuesta

```
                    Supabase (ya existe)
                    ├── codigos_grabovoi / codigos_premium
                    ├── usuario_favoritos
                    ├── usuario_progreso / user_rewards
                    ├── user_code_history        ← empezar a usar
                    ├── otorgar_recompensa_repeticion() (RPC)
                    ├── obtener_codigo_del_dia() (RPC)
                    └── NUEVO: roku_account_links, rutinas, rutina_items
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                      │
   App Flutter          Alexa (Vercel)          Roku (nuevo)
   (ya existe)           (ya existe)          BrightScript/SceneGraph
                                                       │
                                          ┌────────────┴────────────┐
                                     roku-auth.js              roku-catalog.js
                                     (login on-device,          roku-player.js
                                      Supabase Auth)            (reutiliza
                                                                 render_alexa_audio.py)
```

Nuevo backend: 2-3 funciones Vercel (mismo patrón que `alexa-vercel/`,
podría vivir en el mismo proyecto o uno hermano `roku-vercel/`):

- `POST /roku/login` — email+password → valida con Supabase Auth →
  emite token opaco (tabla `roku_account_links`, igual patrón que
  `alexa_account_links`)
- `GET /roku/catalog` — lista/busca en `codigos_grabovoi`, con
  categorías (reutiliza el mismo filtro clínico `TERMINOS_CLINICOS` que
  ya existe en `alexa-skill.js` para descartar nombres tipo "Tumores
  cavidad nasal" del catálogo navegable — el mismo problema de
  contenido aplica aquí)
- `GET /roku/sequence/:codigo` — detalle + URL del audio (pre-renderizado
  si existe en `alexa_audio_cache`, o generado on-demand)

## Fases del MVP (no 500 videos — de acuerdo con ChatGPT en esto)

**Fase 0 — Fundación (1-2 días)**
- Cuenta de desarrollador Roku (gratis)
- Proyecto SceneGraph "hola mundo" corriendo en un Roku físico
- Definir el JSON de "experiencia" (como propone ChatGPT: secuencia,
  duración, visual, fondo, audio, repetición) — esto es lo que hace que
  no necesitemos producir contenido en masa

**Fase 1 — Catálogo sin cuenta (demo-able rápido)**
- Pantalla de inicio, categorías, buscador, ficha de secuencia
- Todo contra `codigos_grabovoi` vía REST de Supabase, sin auth
- Reproductor: dígito por dígito con `<Audio>` node + visual simple
  (partículas o similar), replicando el ritmo de `NumbersVoiceService`
- Espejo exacto de lo que hicimos con el flujo de "cortesía" en Alexa:
  demostrable sin que el usuario tenga cuenta

**Fase 2 — Login on-device + cuenta vinculada**
- Pantalla de login con teclado en pantalla (patrón obligatorio de Roku)
- `roku_account_links` + endpoint `/roku/login`
- Sincroniza favoritos, progreso, cristales

**Fase 3 — Experiencia completa**
- Reutilizar `render_alexa_audio.py` para generar (o generar on-demand
  y cachear) el audio de voz+música completo por secuencia
- "Continuar" usando `user_code_history` (ya existe, solo hay que
  escribirle)
- Secuencia del día (mismo RPC `obtener_codigo_del_dia()`)

**Fase 4 — Rutinas** (feature nueva, no crítica para el MVP)
- Tablas nuevas: `rutinas` (user_id, nombre) + `rutina_items`
  (rutina_id, codigo_id, orden)
- Se puede crear primero desde la app/web y que Roku solo las consuma,
  antes de construir la UI de creación en el propio Roku

**Fase 5 — Certificación**
- Implementar Direct-to-Play (obligatorio, no opcional — ver arriba):
  Roku Search + deep linking + `roInput` + reanudación automática desde
  bookmark sin pantalla de confirmación
- Ficha del canal, íconos (mismo logo que ya usamos para Alexa,
  `assets/icons/app_icon.png`, solo hay que generar los tamaños que pida
  Roku)
- Enviar a certificación

## Lo que NO haría todavía

- **No** producir contenido en video pre-grabado en masa — de acuerdo
  con ChatGPT, el reproductor parametrizado + el pipeline de audio que
  ya existe cubre esto sin producción manual.
- **No** copiar el flujo OAuth de Alexa — está prohibido por las reglas
  de Roku, hay que construir el login on-device desde cero (aunque es
  más simple, no más complejo).
- **No** diseñar el modelo de monetización todavía (Free/Premium/
  Experience que sugiere ChatGPT) — es una decisión de negocio tuya, no
  técnica; se puede montar sobre esta arquitectura cuando la definas,
  sin bloquear el MVP.
- **No** prometer resultados médicos/económicos en la copy del canal —
  mismo criterio que ya aplicamos en la ficha de Alexa.

## Decisiones que te tocan a ti antes de empezar a programar

1. ¿El MVP arranca en Fase 1 (catálogo sin cuenta, demo rápido) o
   quieres saltar directo a cuenta vinculada?
2. ¿Reutilizamos el mismo proyecto Vercel de Alexa o uno separado para
   Roku? (Técnicamente da igual, es cuestión de organización)
3. ¿Rutinas se crean primero desde la app/web, o necesitas que Roku
   también pueda crearlas desde el día uno?
