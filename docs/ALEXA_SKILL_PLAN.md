# ManiGraB en Alexa — Plan de implementación (fin de semana)

## Set completo de interacciones (implementado)

El skill dejó de ser "una sola cosa" (la repetición diaria) y ahora es
una experiencia conversacional con dos niveles según si la cuenta está
vinculada o no. El modelo de interacción listo para pegar en la consola
está en `docs/alexa_interaction_model_es-MX.json`.

| Intent | Qué dice el usuario | Con cuenta | Sin cuenta |
|---|---|---|---|
| `IniciarRepeticionDiariaIntent` | "repite mi secuencia del día", "…{n} veces" | N repeticiones (1–30, por defecto 10) + cristales + racha | la lee 1 vez + invitación |
| `SecuenciaPorPropositoIntent` | "dame una secuencia para la ansiedad / el dinero / el amor" | busca, repite N veces + cristales | la lee 1 vez + invitación |
| `MiFavoritaIntent` | "repite mi favorita" | su última favorita de la app | invita a crear cuenta |
| `MiProgresoIntent` | "cómo voy", "cuántos cristales tengo" | racha, pilotajes, cristales, nivel energético, luz cuántica | invita a crear cuenta |
| `ExplicarSecuenciaIntent` | "qué significa", "para qué sirve" | descripción de la última secuencia leída | igual (funciona sin cuenta) |
| `RepetirDeNuevoIntent` / `AMAZON.RepeatIntent` / `YesIntent` | "otra vez", "repítela" | repite la última | repite la última |

**La sesión ya no se cierra** después de cada respuesta: cada una termina
ofreciendo el siguiente paso y tiene `reprompt`, así que se puede
encadenar ("dame una para el dinero" → "qué significa" → "otra vez").
El estado va en `sessionAttributes.ultimaSecuencia`.

### Calidad de la búsqueda por propósito

La primera versión escogía al azar dentro de la categoría y daba
respuestas incoherentes, verificado contra datos reales: "para la salud"
devolvía *"Tumores cavidad nasal"*, "para la ansiedad" devolvía
*"Empatía"*, "energía" devolvía *"Potenciar efectos del incienso"*.

Se corrigió a **búsqueda por nombre primero** (`PROPOSITOS` mapea cada
propósito hablado a los términos que deben aparecer en el nombre), con
la categoría solo como respaldo. Resultado tras el cambio: salud →
"Restauración de la salud", ansiedad → "Eliminar ansiedad", dinero →
"Dinero fácil y honesto", mente → "Purificación mental".

### Filtro clínico (importante para certificación)

La biblioteca contiene secuencias con nombres clínicos muy específicos
("Tumores cavidad nasal", "Leucemia", "Síndrome de estrés respiratorio
en recién nacidos"). En la app se ven con su fuente y contexto; **leerlos
por voz** como respuesta a "dame una secuencia para la salud" suena a
promesa médica y es exactamente lo que Amazon revisa en certificación.

`TERMINOS_CLINICOS` + `esClinico()` en `alexa-vercel/api/alexa-skill.js`
excluyen esas secuencias **solo del canal de voz**. La app no cambia.
Esto materializa la "precaución legal/regulatoria" que quedó anotada en
el Roadmap v2.

## Token de account linking: duración (bug resuelto)

Síntoma: la app de Alexa decía "Vinculada" pero el skill respondía como
si el usuario no tuviera cuenta.

Causa: `ACCESS_TOKEN_TTL_SECONDS` era **1 hora**. Verificado en vivo en
`alexa_account_links`: el vínculo se creó 13:31, el token expiraba 14:31,
y a las 14:34 ya fallaba. Alexa **nunca llamó al refresh** (el
`updated_at` de la fila jamás se movió), así que seguía mandando un token
caducado y `userId` quedaba en `null` → caía al flujo de cortesía.

Fix: TTL a **90 días** en `supabase/functions/alexa-oauth-token/index.ts`.
Es un token opaco nuestro, no un JWT de Supabase, así que su duración la
decidimos nosotros. El `refresh_token` sigue funcionando como respaldo.

## Voz propia + música de fondo (implementado)

Alexa no puede reproducir 90 clips sueltos en una respuesta (límite: 5 en
SSML, ~15 en APLA), y tampoco sirve renderizar en vivo porque corta la
respuesta a los ~8 segundos. La solución es pre-renderizar **un solo
MP3** por (secuencia × voz) con la voz grabada de la app ya mezclada con
la música, y que Alexa solo reproduzca ese archivo.

- `scripts/render_alexa_audio.py` — mezcla con ffmpeg replicando
  exactamente `NumbersVoiceService`: 280 ms entre dígitos, 100 ms
  alrededor de `espacio.mp3`, 1800 ms → `nuevamente.mp3` → 1800 ms entre
  repeticiones. Ajusta las repeticiones a la baja cuando el código es
  largo (el peor de la biblioteca, 19 tokens, no cabe en 10).
- `scripts/publicar_alexa_audio.py` — renderiza las 3 voces, sube al
  bucket público `alexa` y registra en `alexa_audio_cache`.
- El skill busca `alexa_audio_cache` por (código, `user_rewards.voice_gender`).
  Si hay, responde con APLA reproduciendo el MP3. Si no (búsquedas por
  propósito, favoritas), usa un **Mixer** de APLA con la voz de Alexa
  sobre la misma música. Nunca se queda sin respuesta.

**Calibración del volumen de música.** El primer intento copió el 0.4 de
la app y la música quedó a −42 dB: presente pero inaudible. Dos causas
sumadas: en la app la música va en un reproductor aparte a su volumen
natural (aquí es una mezcla, no es lo mismo), y `amix` normaliza
dividiendo entre el número de entradas, lo que costaba otros 6 dB sin
que se note en el comando. Se corrigió con `normalize=0` y
`--volumen-musica` como parámetro. Referencia: música 15–20 dB por
debajo de la voz.

## Pendiente en la consola de Alexa (no es código)

1. **Build → Account Linking → activar "Allow users to enable skill
   without account linking"**. Sin esto Alexa corta la invocación antes
   de llegar a nuestro endpoint y responde "no sé cómo ayudarte con eso"
   a cualquiera que no haya vinculado — el flujo de cortesía completo es
   inalcanzable.
2. **Build → JSON Editor**: pegar `docs/alexa_interaction_model_es-MX.json`
   y reconstruir el modelo (es lo que da de alta los intents nuevos).
3. **Distribution**: la ficha sigue con la plantilla por defecto
   ("Alexa abre hola mundo", "Sample Short Description"). Hay que
   escribirla antes de certificar.

## Causa raíz real de "No puedo conectarme con la Skill solicitada" (resuelto)

**No era SNI.** Era el selector "SSL certificate type" en Build → Endpoint:
teníamos seleccionado *"My development endpoint has a certificate from a
trusted certificate authority"* (Trusted), pero el certificado real del
dominio (`*.vercel.app`, y también aplica a cualquier `*.supabase.co`) es
un **certificado wildcard**, no uno emitido específicamente para el
hostname exacto. Amazon distingue `Trusted` de `Wildcard` como tipos
separados en el manifest (`sslCertificateType`), y con el tipo
equivocado Alexa nunca completa la conexión — sin importar qué tan bien
esté todo lo demás (firma, cadena de certificado, protección de
Vercel, timeouts: todo eso se descartó en el camino, pero no era la
causa).

**Fix:** cambiar el dropdown a *"My development endpoint is a
sub-domain of a domain that has a wildcard certificate from a
certificate authority"*, reconstruir el modelo, y listo. El endpoint
quedó funcionando en `https://alexa-vercel-lovat.vercel.app/api/alexa-skill`.

**Segundo hallazgo, ya con el endpoint conectado:** la app de Alexa
mostraba el HTML del login (`alexa-oauth-authorize`) como texto plano
crudo en vez de renderizarlo, con acentos rotos ("sesiÃ³n"). Causa:
Supabase Edge Functions fuerza `Content-Type: text/plain` +
`Content-Security-Policy: sandbox` en cualquier respuesta que no sea
JSON — es una política deliberada de la plataforma (para que su
dominio compartido `*.supabase.co` no pueda usarse para servir HTML
arbitrario tipo phishing), no algo corregible desde el código de la
función. **Fix:** se movió también `alexa-oauth-authorize` a Vercel
(`https://alexa-vercel-lovat.vercel.app/api/alexa-oauth-authorize`).
`alexa-oauth-token` se quedó en Supabase sin problema porque solo
devuelve JSON, nunca HTML.

**Estado final de la arquitectura:**
- `alexa-skill` → Vercel (código en el repo: `alexa-vercel/api/alexa-skill.js`)
- `alexa-oauth-authorize` → Vercel (código en el repo: `alexa-vercel/api/alexa-oauth-authorize.js`)
- `alexa-oauth-token` → Supabase (sin cambios, `supabase/functions/alexa-oauth-token`, nunca tuvo el problema)

Las versiones viejas en `supabase/functions/alexa-skill` y
`supabase/functions/alexa-oauth-authorize` se borraron del repo (quedan
desplegadas en Supabase pero sin tráfico — no se pudieron borrar del
proyecto por permisos del token de la API; borrarlas ahí es opcional,
manual, desde el dashboard).

## Ritmo de voz — igualado al de la app (resuelto)

Alexa leía el código completo de corrido (ej. "siete uno nueve ocho...")
sin pausas entre dígitos, solo pausaba entre repeticiones completas.
Se corrigió `alexa-skill.js` para leer cada dígito por separado con
**280ms** de pausa entre ellos, y decir "nuevamente" con **1.8s** de
pausa antes y después entre cada repetición completa — exactamente los
mismos tiempos que usa `NumbersVoiceService` en la app
(`_gapBetweenDigits`, `_pauseBeforeNuevamente`, `_pauseAfterNuevamente`
en `lib/services/numbers_voice_service.dart`).

Nota para el futuro: si algún día se vuelve a mover el endpoint a un
dominio con certificado *no* wildcard (ej. un dominio propio con
certificado dedicado), hay que regresar el selector a `Trusted`.

## Roadmap v2 (evaluado, ninguno bloquea el MVP de este fin de semana)

Ideas propuestas para después del MVP, evaluadas para decidir en qué
momento tiene sentido cada una:

1. **Búsqueda semántica por intención** ("dame una secuencia para
   concentración"): requiere un slot de dictado libre + matching contra
   el catálogo. Build grande aparte, no toca la arquitectura actual.
2. **Modo práctica con duración elegible (3/5/10 min)**: extensión del
   intent de repetición que ya existe (agregar un slot). Barato de
   sumar después, no urgente.
3. **Favoritos e historial por voz** ("repite mi favorita", "qué usé
   ayer"): la más barata de las cuatro — `usuario_favoritos` y
   `user_actions` ya tienen los datos, y el account linking ya
   construido resuelve el `user_id` igual para estos intents.
   **Recomendado como el primer follow-up**, apenas el MVP funcione.
4. **Rutinas personalizadas** ("comienza mi rutina de mañana"): no es
   una extensión de Alexa, es una función que hoy no existe ni en la
   app ni en la base de datos (secuencia de códigos + orden +
   duración). Debería diseñarse primero en la app y exponerse por
   Alexa después — proyecto de producto aparte, no de este fin de
   semana.
5. **Quick Links de adquisición**: solo aplica a skills certificados y
   publicados en el Store. Irrelevante hasta después de certificar.

**Único punto con ventana de tiempo real**: al llegar a la pestaña
**Distribution** para escribir la descripción pública del skill y las
frases de ejemplo (para certificación), presentar ManiGraB como
herramienta de consulta/práctica — evitar cualquier frase que Amazon
pueda leer como afirmación médica o de eficacia garantizada, ya que la
certificación revisa esto explícitamente. No requiere cambios de
código, solo cuidado al redactar esa sección cuando lleguemos ahí.


## Estado actual

✅ Migración aplicada (`alexa_account_links`, `alexa_auth_codes`,
`otorgar_recompensa_repeticion()`, `obtener_codigo_del_dia()`).
✅ `alexa-oauth-authorize`, `alexa-oauth-token`, `alexa-skill` desplegados.
✅ Flujo OAuth probado de punta a punta (login → code → tokens) con un
usuario de prueba real, ya eliminado.
✅ Lógica de intents probada (LaunchRequest, repetición con recompensa,
dedupe del mismo día, LinkAccount cuando no hay cuenta vinculada,
StopIntent) con la verificación de firma temporalmente desactivada.
✅ Confirmado que sin firma válida el endpoint responde 401 (la seguridad
está activa por defecto).
⏳ **Pendiente y es lo único que falta**: terminar Account Linking en la
consola (scope sin espacios: `manigrab`), guardar, y probar con una
request real firmada por Amazon en el simulador — esa parte de la
verificación de firma nunca se pudo probar contra Amazon de verdad porque
no hay forma de simular su firma sin su clave privada.

✅ Skill creado en la consola: "ManiGraB", Spanish (Mexico), Custom,
Provision your own. Interaction model reemplazado por el JSON de la
sección 5 (invocation name `mani grab`). Endpoint HTTPS configurado.
✅ Redirect URLs reales de Amazon confirmadas y ya restringidas en
`alexa-oauth-authorize` (rechaza cualquier `redirect_uri` que no sea uno
de estos tres, para que el formulario de login no sea un open redirect):
- `https://alexa.amazon.co.jp/api/skill/link/MA45M5GO4O4EN`
- `https://pitangui.amazon.com/api/skill/link/MA45M5GO4O4EN`
- `https://layla.amazon.com/api/skill/link/MA45M5GO4O4EN`

### Datos para configurar el skill en la consola

- Endpoint HTTPS: `https://whtiazgcxdnemrrgjjqf.supabase.co/functions/v1/alexa-skill`
- Authorization URI: `https://whtiazgcxdnemrrgjjqf.supabase.co/functions/v1/alexa-oauth-authorize`
- Access Token URI: `https://whtiazgcxdnemrrgjjqf.supabase.co/functions/v1/alexa-oauth-token`
- Client ID: `10118a652e994425248544a4c814a1dd`
- Client Secret: (el mismo que ya está guardado como secret de Supabase — pídemelo cuando vayas a configurar Account Linking)
- Certificado SSL: "My development endpoint has a certificate from a trusted certificate authority" (Supabase ya tiene TLS válido)


## 0. Expectativa realista

Lo que **sí** es alcanzable este fin de semana: un skill funcional, con
account linking real, que repite un código Grabovoi por voz y otorga
cristales igual que la app — probable en **tu propia cuenta de Amazon**
usando el simulador de la consola de desarrollo o tu Echo/celular
personal, sin publicarlo.

Lo que **no** es alcanzable este fin de semana: la certificación pública
de Amazon para que aparezca en el Alexa Skills Store. Esa revisión la
hace un humano de Amazon y toma típicamente 5–7 días hábiles (más si
piden cambios), independientemente de qué tan listo esté el código.
Contenido de bienestar/espiritualidad a veces recibe una revisión más
detallada. Conclusión: build + test este fin de semana, someter a
certificación la próxima semana.

## 1. Arquitectura

```
Echo/App Alexa
     |
     |  HTTPS (JSON, firmado por Amazon)
     v
Supabase Edge Function: alexa-skill        <-- NUEVA
     |  valida firma de Amazon
     |  resuelve access_token -> user_id (tabla alexa_account_links)
     |  llama a otorgar_recompensa_repeticion() (función Postgres) <-- NUEVA
     v
Supabase (Postgres + Auth existentes)
     ^
     |  OAuth2 (Authorization Code Grant)
     |
Supabase Edge Function: alexa-oauth-authorize / alexa-oauth-token  <-- NUEVAS
     ^
     |  el usuario inicia sesión con su cuenta ManiGraB ya existente
     |
Pantalla web de login (reutiliza AuthServiceSimple / Supabase Auth)
```

No hace falta AWS Lambda: Alexa acepta un **endpoint HTTPS propio**
("Provision your own") como backend del skill, y ya tenemos Supabase
Edge Functions corriendo en Deno con TLS válido — mismo patrón que
`send-push`, `admin-users`, etc.

## 2. Lo que necesitas hacer TÚ (cuenta Amazon, decisiones de producto)

- [ ] Crear cuenta gratuita en developer.amazon.com si no tienes.
- [ ] Decidir el **nombre de invocación** (invocation name). Reglas de
      Amazon: 2+ palabras, minúsculas, sin "skill"/"aplicación"/"Alexa",
      sin caracteres especiales. Sugerencias a probar en la consola
      (algunas pueden estar tomadas o rechazadas):
      - "mani grab"
      - "código grabovoi"
      - "mi grabovoi"
- [ ] Decidir si el MVP del fin de semana repite **solo el código del
      día** (más simple, reusa `daily_code_assignments`) o también
      permite pedir un código específico por número hablado (más
      complejo: Alexa transcribe dígitos hablados con errores
      frecuentes tipo "cinco veinte setecientos cuarenta y uno").
      **Recomendación: solo código del día para el MVP**, agregar
      código específico después.
- [ ] Decidir duración/repeticiones: ¿leer el código en loop por ~2
      minutos (como el Campo Energético) o un número fijo de veces
      (ej. 10x)? **Recomendación: número fijo (10x) es mucho más simple
      de implementar en una sola respuesta SSML** que simular un timer
      de 2 minutos a través de múltiples turnos de conversación.

## 3. Modelo de datos nuevo (yo lo puedo crear ahora)

```sql
-- Vincula un usuario de ManiGraB con el access_token opaco que Alexa
-- va a mandar en cada request tras el account linking. No reutilizamos
-- JWT de Supabase (expiran en ~1h) — Alexa necesita un token de larga
-- duración que nosotros controlamos.
create table public.alexa_account_links (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  access_token text not null unique,
  refresh_token text not null unique,
  access_token_expires_at timestamptz not null,
  created_at timestamptz not null default now()
);

-- Códigos de autorización de un solo uso (paso intermedio del OAuth,
-- vida útil de ~5 minutos)
create table public.alexa_auth_codes (
  code text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  redirect_uri text not null,
  created_at timestamptz not null default now(),
  used boolean not null default false
);
```

RLS: ambas tablas solo accesibles por `service_role` (los edge
functions), ningún acceso directo desde el cliente Flutter.

## 4. Account linking (OAuth2 Authorization Code Grant)

Esto es lo más "de una sola vez": el usuario lo hace una vez desde la
app de Alexa, no en cada repetición.

1. Usuario en la app de Alexa: "Habilitar skill" → Alexa abre
   `alexa-oauth-authorize?client_id=...&redirect_uri=...&state=...`
   (edge function nueva, sirve una página HTML simple).
2. La página pide email+contraseña de ManiGraB (o, más simple para el
   fin de semana, un magic link/OTP) y valida contra Supabase Auth.
3. Al autenticar, genera un `code` aleatorio en `alexa_auth_codes` y
   redirige a `redirect_uri` de Amazon con `?code=...&state=...`.
4. Alexa llama a `alexa-oauth-token` (POST) con ese `code` →
   la función valida, genera `access_token`/`refresh_token` opacos,
   los guarda en `alexa_account_links` y los devuelve en el formato
   OAuth estándar (`access_token`, `token_type: bearer`,
   `expires_in`, `refresh_token`).
5. Desde ahí, cada request del skill trae
   `request.session.user.accessToken` — el edge function del skill
   busca ese token en `alexa_account_links` para saber quién habla.

Configuración correspondiente en la consola de Alexa (pestaña
"Account Linking" del Build):
- Authorization URI: `https://<proyecto>.supabase.co/functions/v1/alexa-oauth-authorize`
- Access Token URI: `https://<proyecto>.supabase.co/functions/v1/alexa-oauth-token`
- Client ID / Client Secret: los definimos nosotros (strings random,
  guardados como secret de la edge function)
- Scope: puede ir vacío o `manigrab:repetir`

## 5. Interaction Model (intents)

JSON para pegar directo en el editor de la consola de Alexa (pestaña
"JSON Editor" del Build), invocación de ejemplo `mani grab`:

```json
{
  "interactionModel": {
    "languageModel": {
      "invocationName": "mani grab",
      "intents": [
        { "name": "AMAZON.CancelIntent", "samples": [] },
        { "name": "AMAZON.StopIntent", "samples": [] },
        { "name": "AMAZON.HelpIntent", "samples": [] },
        { "name": "AMAZON.FallbackIntent", "samples": [] },
        {
          "name": "IniciarRepeticionDiariaIntent",
          "samples": [
            "repite mi código del día",
            "inicia mi repetición",
            "quiero pilotar mi código",
            "empieza mi sesión",
            "repite mi secuencia de hoy"
          ]
        }
      ],
      "types": []
    }
  }
}
```

Flujo de una sola vuelta (sin manejo de sesión multi-turno, más simple
para el fin de semana):

1. `LaunchRequest` → saluda y pregunta si quiere repetir el código del
   día ("Bienvenido a Mani Grab. Di 'repite mi código del día' para
   comenzar tu repetición.").
2. `IniciarRepeticionDiariaIntent` → el edge function:
   - resuelve `user_id` desde el access token,
   - consulta `daily_code_assignments` para el código de hoy de ese
     usuario (mismo query que ya usa `DailyCodeService`),
   - arma una respuesta SSML que repite el código 10 veces con pausas,
   - llama a `otorgar_recompensa_repeticion(user_id, codigo_id)` (ver
     sección 6),
   - responde con el resultado ("Ganaste 3 cristales de energía").

Ejemplo de SSML para leer dígito a dígito (igual estilo que "voz
numérica" en la app):

```xml
<speak>
  Vamos a repetir tu código del día, 5 2 0 7 4 1 8, diez veces.
  <break time="800ms"/>
  <say-as interpret-as="digits">5207418</say-as><break time="1500ms"/>
  <say-as interpret-as="digits">5207418</say-as><break time="1500ms"/>
  ... (x10) ...
  Excelente trabajo. Ganaste 3 cristales de energía.
</speak>
```

`interpret-as="digits"` hace que Alexa lea cada dígito por separado
("cinco dos cero siete cuatro uno ocho"), no como número completo —
exactamente el comportamiento de "voz numérica" que ya existe en la
app.

## 6. Reutilizar la lógica de recompensas (no duplicarla)

Hoy `recompensarPorRepeticion()` vive **solo en Dart**
(`lib/services/rewards_service.dart`), ejecutándose en el cliente.
Alexa no puede llamar a Dart. Dos caminos:

**Opción A (recomendada, más limpia):** portar la lógica a una función
Postgres `otorgar_recompensa_repeticion(p_user_id uuid, p_codigo_id
text)` (SECURITY DEFINER) que hace lo mismo que hace hoy el Dart
(chequea `yaSeOtorgaronRecompensas`/inserta en
`user_rewarded_actions`, suma `cristales_energia` en `user_rewards`,
actualiza `luz_cuantica` por racha). El edge function de Alexa la
llama por RPC. Es más trabajo el primer día, pero deja **una sola
fuente de verdad** que tanto la app como Alexa (y cualquier superficie
futura) usan — evita que un día se corrija el dedupe en un lado y no
en el otro.

**Opción B (atajo para ir más rápido):** el edge function de Alexa
duplica la misma lógica de `recompensarPorRepeticion` directamente en
TypeScript, igual que ya hace `admin-users` para otras cosas. Funciona
para el fin de semana, pero corre el riesgo de divergir del
comportamiento de la app con el tiempo (ej. si mañana cambian las
reglas de dedupe solo en el Dart).

Dado que ya hicimos este mismo tipo de "server-authoritative" para
notificaciones y compras esta sesión, mi recomendación es la Opción A
si el tiempo alcanza el sábado; si no, empezar con B el sábado y migrar
a A el domingo.

## 7. El punto técnico más delicado: verificar la firma de Amazon

Como el endpoint es "propio" (no Lambda), **Amazon exige** que cada
request se valide antes de procesarlo, si no cualquiera podría
llamar al endpoint haciéndose pasar por Alexa:

1. Verificar que el header `SignatureCertChainUrl` apunte a
   `https://s3.amazonaws.com/echo.api/...` (dominio y ruta exactos).
2. Descargar ese certificado, verificar que no esté expirado y que su
   SAN incluya `echo-api.amazon.com`.
3. Verificar el header `Signature` (firma RSA-SHA1 del body crudo)
   contra la clave pública de ese certificado.
4. Verificar que `request.timestamp` esté dentro de ±150 segundos
   (anti-replay).

En Deno esto se hace con `Web Crypto API` (`crypto.subtle`) — no hay
un SDK oficial de Alexa para Deno, así que esta pieza la escribo a
mano como una función `verifyAlexaRequest()` reutilizable dentro del
edge function. Es la parte que más tiempo va a tomar, pero es un
patrón conocido (hay implementaciones de referencia en Node que puedo
traducir).

**Atajo si el tiempo aprieta:** en desarrollo/testing dentro de la
consola de Alexa (antes de certificar), Amazon permite deshabilitar
esta validación para acelerar pruebas — lo dejamos activo desde el
principio de todas formas porque es requisito para certificar después
y no vale la pena hacerlo dos veces.

## 8. Checklist de implementación, en orden

1. [ ] Migración SQL: `alexa_account_links`, `alexa_auth_codes`,
       función `otorgar_recompensa_repeticion`.
2. [ ] Edge function `alexa-oauth-authorize` (página de login simple).
3. [ ] Edge function `alexa-oauth-token` (intercambio code → tokens).
4. [ ] Edge function `alexa-skill`:
       - `verifyAlexaRequest()`
       - resolver `user_id` desde el access token
       - manejar `LaunchRequest`, `IniciarRepeticionDiariaIntent`,
         `AMAZON.HelpIntent`, `AMAZON.StopIntent/CancelIntent`,
         `AMAZON.FallbackIntent`
       - armar el SSML de repetición
       - llamar a la recompensa
5. [ ] Crear el skill en la consola de Alexa: nombre de invocación,
       interaction model (JSON de la sección 5), endpoint HTTPS,
       account linking (sección 4).
6. [ ] Probar en el simulador de texto de la consola (no necesita
       Echo físico).
7. [ ] Probar de voz en tu celular con la app de Alexa o un Echo.
8. [ ] (la próxima semana) Enviar a certificación si todo funciona.

## 9. Lo que puedo empezar a construir ahora mismo

Si quieres, arranco ya con lo que no depende de decisiones tuyas en la
consola de Amazon:
- la migración SQL completa (paso 1),
- la función Postgres `otorgar_recompensa_repeticion` (Opción A),
- el edge function `alexa-skill` con verificación de firma incluida,
  dejando el nombre de invocación como variable fácil de cambiar.

Lo único que sí necesito de ti antes de probar de punta a punta: la
cuenta de Amazon Developer creada y el nombre de invocación elegido
(sección 2), para configurar el account linking con las URLs reales.
