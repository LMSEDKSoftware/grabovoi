'use strict';

// Backend del skill de Alexa de ManiGraB, como función serverless de
// Vercel (Node.js). Migrado desde Supabase Edge Functions (Deno) porque
// ese endpoint fallaba el handshake TLS cuando el cliente no manda SNI
// (confirmado con openssl s_client -noservername: "handshake failure"
// en Supabase, pero funciona bien en Vercel/GitHub/httpbin). Se mantiene
// la misma verificación de firma de Amazon escrita a mano con
// node-forge (aquí sí hace falta, a diferencia de Lambda, porque este
// sigue siendo un endpoint HTTPS "propio").
//
// Dos experiencias en un mismo skill:
//  - Cuenta vinculada: repeticiones completas, cristales, progreso,
//    favoritos. Es la experiencia "de verdad".
//  - Sin vincular: lee la secuencia una sola vez y engancha con la
//    invitación a la app. Es el canal de adquisición.

const forge = require('node-forge');
const { createClient } = require('@supabase/supabase-js');

const SIGNATURE_CERT_URL_PATTERN = /^https:\/\/s3\.amazonaws\.com(:443)?\/echo\.api\/.*$/i;
const TIMESTAMP_TOLERANCE_MS = 150_000;
const REPETICIONES_POR_SESION = 10;
const REPETICIONES_MIN = 1;
const REPETICIONES_MAX = 30;

const INVITACION_CORTA =
  'Vincula tu cuenta de Mani Grab desde la app de Alexa, o descárgala en mani grab punto app, para repetirla las veces que quieras y guardar tu progreso.';

const CARD_INVITACION = {
  type: 'Simple',
  title: 'Descubre más en ManiGraB',
  content:
    'Vincula tu cuenta desde la app de Alexa, o descarga ManiGraB en manigrab.app para repetir tus secuencias las veces que quieras, guardar tu progreso, ganar cristales de energía y explorar miles de secuencias más.',
};

// Propósito hablado -> cómo buscarlo. `terminos` son las palabras que
// deben aparecer en el NOMBRE de la secuencia (es lo que da relevancia
// real), y `categoria` es solo el último recurso.
//
// Buscar solo por categoría daba resultados absurdos: "para la salud"
// devolvía "Tumores cavidad nasal" y "para la ansiedad" devolvía
// "Empatía", porque escogía al azar entre cientos de la categoría. Por
// eso el nombre manda y la categoría es el respaldo.
const PROPOSITOS = {
  salud: { terminos: ['salud', 'sanación', 'bienestar', 'vitalidad'], categoria: 'Salud' },
  sanacion: { terminos: ['sanación', 'salud', 'regeneración'], categoria: 'Salud' },
  dolor: { terminos: ['dolor', 'alivio'], categoria: 'Salud' },
  cuerpo: { terminos: ['cuerpo', 'salud', 'regeneración'], categoria: 'Salud' },
  dinero: { terminos: ['dinero', 'abundancia', 'prosperidad', 'riqueza'], categoria: 'Abundancia' },
  abundancia: { terminos: ['abundancia', 'prosperidad', 'dinero'], categoria: 'Abundancia' },
  prosperidad: { terminos: ['prosperidad', 'abundancia', 'dinero'], categoria: 'Abundancia' },
  riqueza: { terminos: ['riqueza', 'abundancia', 'dinero'], categoria: 'Abundancia' },
  trabajo: { terminos: ['empleo', 'trabajo', 'negocio'], categoria: 'Empleo' },
  empleo: { terminos: ['empleo', 'trabajo'], categoria: 'Empleo' },
  amor: { terminos: ['amor', 'pareja', 'amar'], categoria: 'Amor' },
  pareja: { terminos: ['pareja', 'amor', 'relación'], categoria: 'Amor' },
  relaciones: { terminos: ['relación', 'familia', 'armonía'], categoria: 'Relaciones' },
  familia: { terminos: ['familia', 'familiar'], categoria: 'Relaciones' },
  proteccion: { terminos: ['protección', 'proteger', 'escudo'], categoria: 'Protección' },
  ansiedad: { terminos: ['ansiedad', 'calma', 'nervios', 'tranquilidad'], categoria: 'Emociones' },
  estres: { terminos: ['estrés', 'calma', 'relajación', 'tranquilidad'], categoria: 'Emociones' },
  miedo: { terminos: ['miedo', 'temor', 'valor'], categoria: 'Emociones' },
  emociones: { terminos: ['emocional', 'emociones', 'equilibrio'], categoria: 'Emociones' },
  tristeza: { terminos: ['tristeza', 'depresión', 'ánimo', 'alegría'], categoria: 'Emociones' },
  paz: { terminos: ['paz', 'armonía', 'tranquilidad'], categoria: 'Armonía' },
  armonia: { terminos: ['armonía', 'paz', 'equilibrio'], categoria: 'Armonía' },
  exito: { terminos: ['éxito', 'triunfo', 'logro'], categoria: 'Éxito' },
  suerte: { terminos: ['suerte', 'fortuna', 'éxito'], categoria: 'Éxito' },
  mente: { terminos: ['mental', 'mente', 'claridad'], categoria: 'Mental' },
  claridad: { terminos: ['claridad', 'mental', 'decisiones'], categoria: 'Mental' },
  concentracion: { terminos: ['concentración', 'enfoque', 'memoria', 'estudio'], categoria: 'Mental' },
  espiritualidad: { terminos: ['espiritual', 'alma', 'conexión'], categoria: 'Espiritualidad' },
  conciencia: { terminos: ['conciencia', 'despertar'], categoria: 'Conciencia' },
  limpieza: { terminos: ['limpieza', 'purificación', 'energías negativas'], categoria: 'Limpieza' },
  liberacion: { terminos: ['liberación', 'liberar', 'soltar'], categoria: 'Liberación' },
  crecimiento: { terminos: ['crecimiento', 'personal', 'evolución'], categoria: 'Crecimiento' },
  peso: { terminos: ['peso', 'adelgazar'], categoria: 'Peso' },
  belleza: { terminos: ['belleza', 'piel', 'juventud'], categoria: 'Belleza' },
  energia: { terminos: ['energía', 'vitalidad', 'fuerza'], categoria: 'Energía' },
  manifestacion: { terminos: ['manifestación', 'manifestar', 'deseo'], categoria: 'Manifestación' },
};

// La biblioteca tiene secuencias con nombres clínicos muy específicos
// ("Tumores cavidad nasal", "Leucemia"...). En la app se ven en su
// contexto, con su fuente y su descripción; leerlos por voz como
// respuesta a "dame una secuencia para la salud" suena a promesa médica
// y es justo lo que Amazon revisa en certificación. Por voz servimos
// solo secuencias de bienestar general.
const TERMINOS_CLINICOS = [
  'cáncer', 'cancer', 'tumor', 'leucemia', 'sida', 'vih', 'covid',
  'diabetes', 'hepatitis', 'cirrosis', 'infarto', 'ictus', 'epilepsia',
  'esclerosis', 'alzheimer', 'parkinson', 'artritis', 'asma', 'úlcera',
  'ulcera', 'quiste', 'hernia', 'anemia', 'neumonía', 'neumonia',
  'tuberculosis', 'psoriasis', 'lupus', 'fibromialgia', 'embolia',
  'trombosis', 'gangrena', 'sífilis', 'sifilis', 'herpes', 'meningitis',
  // Marcadores genéricos de nombre clínico. "síndrome" solo ya filtra
  // casos como "Síndrome de estrés respiratorio en recién nacidos", que
  // aparecía al pedir una secuencia "para el estrés".
  'síndrome', 'sindrome', 'carcinoma', 'metástasis', 'metastasis',
  'quimioterapia', 'recién nacido', 'recien nacido', 'crónic', 'cronic',
  'infección', 'infeccion', 'trastorno', 'patología', 'patologia',
  'aguda', 'agudo', 'postoperatorio', 'post operatorio', 'insuficiencia',
];

function esClinico(nombre) {
  const n = normalizar(nombre);
  return TERMINOS_CLINICOS.some((t) => n.includes(normalizar(t)));
}

function normalizar(s) {
  return String(s || '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .trim();
}

function escapeXml(s) {
  return String(s)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');
}

function readRawBody(req) {
  return new Promise((resolve, reject) => {
    let data = '';
    req.on('data', (chunk) => { data += chunk; });
    req.on('end', () => resolve(data));
    req.on('error', reject);
  });
}

async function verifyAlexaSignature(rawBody, signatureCertChainUrl, signature) {
  if (!signatureCertChainUrl || !signature) {
    return { ok: false, reason: 'faltan headers Signature/SignatureCertChainUrl' };
  }
  if (!SIGNATURE_CERT_URL_PATTERN.test(signatureCertChainUrl)) {
    return { ok: false, reason: `SignatureCertChainUrl fuera del dominio esperado: ${signatureCertChainUrl}` };
  }

  let certResp;
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 4000);
    certResp = await fetch(signatureCertChainUrl, { signal: controller.signal });
    clearTimeout(timeout);
  } catch (e) {
    return { ok: false, reason: `no se pudo descargar el certificado de Amazon (${e.message || e})` };
  }
  if (!certResp.ok) {
    return { ok: false, reason: `no se pudo descargar el certificado de Amazon (HTTP ${certResp.status})` };
  }
  const pem = await certResp.text();

  let cert;
  try {
    cert = forge.pki.certificateFromPem(pem);
  } catch (_e) {
    return { ok: false, reason: 'no se pudo parsear el certificado' };
  }

  const now = new Date();
  if (now < cert.validity.notBefore || now > cert.validity.notAfter) {
    return { ok: false, reason: 'certificado expirado o aún no válido' };
  }

  const altNamesExt = cert.getExtension('subjectAltName');
  const hasEchoApi = altNamesExt?.altNames?.some((a) => a.value === 'echo-api.amazon.com');
  if (!hasEchoApi) {
    return { ok: false, reason: 'el certificado no incluye echo-api.amazon.com en su SAN' };
  }

  const md = forge.md.sha1.create();
  md.update(rawBody, 'utf8');

  let signatureBytes;
  try {
    signatureBytes = forge.util.decode64(signature);
  } catch (_e) {
    return { ok: false, reason: 'firma con codificación base64 inválida' };
  }

  let verified = false;
  try {
    verified = cert.publicKey.verify(md.digest().bytes(), signatureBytes);
  } catch (_e) {
    return { ok: false, reason: 'error verificando la firma RSA' };
  }
  if (!verified) {
    return { ok: false, reason: 'la firma no coincide con el cuerpo de la solicitud' };
  }

  return { ok: true };
}

function isTimestampFresh(requestTimestamp) {
  if (!requestTimestamp) return false;
  const reqTime = new Date(requestTimestamp).getTime();
  if (Number.isNaN(reqTime)) return false;
  return Math.abs(Date.now() - reqTime) <= TIMESTAMP_TOLERANCE_MS;
}

function alexaResponse({ ssml, shouldEndSession, card, reprompt, sessionAttributes }) {
  const response = {
    outputSpeech: { type: 'SSML', ssml },
    shouldEndSession,
  };
  if (card) response.card = card;
  if (reprompt) {
    response.reprompt = { outputSpeech: { type: 'SSML', ssml: `<speak>${reprompt}</speak>` } };
  }
  const payload = { version: '1.0', response };
  if (sessionAttributes) payload.sessionAttributes = sessionAttributes;
  return payload;
}

// Mismo ritmo que NumbersVoiceService en la app (voz numérica): cada
// dígito por separado con una pausa de 280ms entre ellos (no todo el
// número leído de corrido), y entre cada repetición completa de la
// secuencia, "nuevamente" con 1.8s de pausa antes y después — igual que
// _gapBetweenDigits/_pauseBeforeNuevamente/_pauseAfterNuevamente en
// lib/services/numbers_voice_service.dart.
function digitosSsml(codigo) {
  return String(codigo)
    .replace(/[^0-9]/g, '')
    .split('')
    .map((d) => `<say-as interpret-as="digits">${d}</say-as>`)
    .join('<break time="280ms"/>');
}

function repeticionesSsml(codigo, veces) {
  const uno = digitosSsml(codigo);
  return Array.from({ length: veces })
    .map(() => uno)
    .join('<break time="1800ms"/>nuevamente<break time="1800ms"/>');
}

function recordarSecuencia(secuencia, extra) {
  return {
    ultimaSecuencia: {
      codigo: secuencia.codigo,
      nombre: secuencia.nombre ?? null,
      descripcion: secuencia.descripcion ?? null,
    },
    ...extra,
  };
}

// --- Acceso a datos -------------------------------------------------

async function obtenerCodigoDelDia(admin) {
  const { data, error } = await admin.rpc('obtener_codigo_del_dia');
  if (error || !data || data.length === 0) {
    console.error('obtener_codigo_del_dia falló:', error);
    return null;
  }
  return data[0];
}

function elegirAlAzar(filas) {
  const limpias = (filas || []).filter((f) => f.nombre && !esClinico(f.nombre));
  if (limpias.length === 0) return null;
  return limpias[Math.floor(Math.random() * limpias.length)];
}

// Busca una secuencia por propósito hablado. El orden importa: primero
// por NOMBRE (que es lo que hace que la respuesta sea relevante), y solo
// si no hay nada, por categoría. Solo toca codigos_grabovoi (la
// biblioteca abierta) — las de codigos_premium se quedan en la app a
// propósito, no se regalan por voz.
async function buscarPorProposito(admin, propositoHablado) {
  const norm = normalizar(propositoHablado);
  if (!norm) return null;

  let config = PROPOSITOS[norm];
  if (!config) {
    const clave = Object.keys(PROPOSITOS).find((k) => norm.includes(k) || k.includes(norm));
    if (clave) config = PROPOSITOS[clave];
  }

  // 1) Por nombre, con los términos del propósito (o lo que dijo el
  //    usuario si no lo tenemos mapeado).
  const terminos = config?.terminos ?? [propositoHablado];
  for (const termino of terminos) {
    const { data } = await admin
      .from('codigos_grabovoi')
      .select('codigo, nombre, descripcion, categoria')
      .ilike('nombre', `%${termino}%`)
      .not('descripcion', 'is', null)
      .limit(25);
    const elegida = elegirAlAzar(data);
    if (elegida) return elegida;
  }

  // 2) Respaldo: cualquiera de la categoría.
  if (config?.categoria) {
    const { data } = await admin
      .from('codigos_grabovoi')
      .select('codigo, nombre, descripcion, categoria')
      .eq('categoria', config.categoria)
      .not('descripcion', 'is', null)
      .limit(100);
    const elegida = elegirAlAzar(data);
    if (elegida) return elegida;
  }

  return null;
}

async function obtenerFavorita(admin, userId) {
  const { data: favs } = await admin
    .from('usuario_favoritos')
    .select('codigo_id')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(1);
  if (!favs || favs.length === 0) return null;

  const { data } = await admin
    .from('codigos_grabovoi')
    .select('codigo, nombre, descripcion, categoria')
    .eq('id', favs[0].codigo_id)
    .limit(1);
  return data && data.length > 0 ? data[0] : null;
}

async function otorgarRecompensa(admin, userId, secuencia) {
  const { data, error } = await admin.rpc('otorgar_recompensa_repeticion', {
    p_user_id: userId,
    p_codigo: secuencia.codigo,
    p_codigo_nombre: secuencia.nombre ?? secuencia.codigo,
    p_origen: 'alexa',
  });
  if (error) {
    console.error('otorgar_recompensa_repeticion falló:', error);
    return null;
  }
  return data;
}

// --- Handlers con cuenta vinculada ----------------------------------

// Núcleo compartido: lee una secuencia N veces, acredita cristales y
// cierra ofreciendo qué hacer después. Lo usan la repetición diaria, la
// búsqueda por propósito, la favorita y el "otra vez".
async function repetirSecuencia(admin, userId, secuencia, { intro, veces }) {
  const recompensa = await otorgarRecompensa(admin, userId, secuencia);

  let cierre;
  if (!recompensa) {
    cierre = 'Completaste tu repetición.';
  } else if (recompensa.ya_otorgada) {
    cierre = 'Completaste tu repetición. Ya habías recibido tus cristales por esta secuencia hoy.';
  } else {
    cierre = `Excelente trabajo. Ganaste ${recompensa.cristales_ganados ?? 3} cristales de energía.`;
    if (recompensa.dias_consecutivos > 1) {
      cierre += ` Llevas ${recompensa.dias_consecutivos} días seguidos.`;
    }
  }

  const seguimiento = ' ¿Quieres otra secuencia, o saber qué significa esta?';

  const ssml =
    `<speak>${intro}<break time="800ms"/>` +
    `${repeticionesSsml(secuencia.codigo, veces)}<break time="800ms"/>` +
    `${escapeXml(cierre)}${escapeXml(seguimiento)}</speak>`;

  return alexaResponse({
    ssml,
    shouldEndSession: false,
    reprompt: 'Puedes pedirme otra secuencia, preguntarme qué significa, o decir, para.',
    sessionAttributes: recordarSecuencia(secuencia),
  });
}

async function handleRepeticionDiaria(admin, userId, veces) {
  const secuencia = await obtenerCodigoDelDia(admin);
  if (!secuencia) {
    return alexaResponse({
      ssml: '<speak>No pude encontrar la secuencia de hoy. Intenta de nuevo en un momento, o revisa la app.</speak>',
      shouldEndSession: true,
    });
  }

  const intro = secuencia.nombre
    ? `Vamos a repetir tu secuencia del día, para ${escapeXml(secuencia.nombre)}. Repite cada número en voz alta junto conmigo.`
    : 'Vamos a repetir tu secuencia del día. Repite cada número en voz alta junto conmigo.';

  return repetirSecuencia(admin, userId, secuencia, { intro, veces });
}

async function handleSecuenciaPorProposito(admin, userId, proposito, veces) {
  const secuencia = await buscarPorProposito(admin, proposito);
  if (!secuencia) {
    return alexaResponse({
      ssml: `<speak>No encontré una secuencia para ${escapeXml(proposito || 'eso')}. Puedes pedirme una para la salud, el dinero, el amor, la protección, el trabajo, o la ansiedad.</speak>`,
      shouldEndSession: false,
      reprompt: 'Dime para qué quieres una secuencia.',
    });
  }

  const intro = `Encontré esta secuencia, para ${escapeXml(secuencia.nombre)}. Repite cada número en voz alta junto conmigo.`;
  return repetirSecuencia(admin, userId, secuencia, { intro, veces });
}

async function handleMiFavorita(admin, userId, veces) {
  const secuencia = await obtenerFavorita(admin, userId);
  if (!secuencia) {
    return alexaResponse({
      ssml: '<speak>Todavía no tienes secuencias favoritas. Marca una como favorita en la app de Mani Grab y te la repito cuando quieras.</speak>',
      shouldEndSession: false,
      reprompt: 'Puedes pedirme tu secuencia del día, o una para la salud o el dinero.',
    });
  }

  const intro = `Tu favorita es, ${escapeXml(secuencia.nombre)}. Repite cada número en voz alta junto conmigo.`;
  return repetirSecuencia(admin, userId, secuencia, { intro, veces });
}

async function handleMiProgreso(admin, userId) {
  const [{ data: progreso }, { data: rewards }] = await Promise.all([
    admin
      .from('usuario_progreso')
      .select('dias_consecutivos, total_pilotajes, nivel_energetico')
      .eq('user_id', userId)
      .maybeSingle(),
    admin
      .from('user_rewards')
      .select('cristales_energia, luz_cuantica')
      .eq('user_id', userId)
      .maybeSingle(),
  ]);

  if (!progreso && !rewards) {
    return alexaResponse({
      ssml: '<speak>Todavía no tienes actividad registrada. Di, repite mi secuencia del día, para empezar.</speak>',
      shouldEndSession: false,
      reprompt: 'Di, repite mi secuencia del día, para empezar.',
    });
  }

  const dias = progreso?.dias_consecutivos ?? 0;
  const pilotajes = progreso?.total_pilotajes ?? 0;
  const nivel = Math.round(progreso?.nivel_energetico ?? 0);
  const cristales = rewards?.cristales_energia ?? 0;
  const luz = Math.round(rewards?.luz_cuantica ?? 0);

  const partes = [
    dias > 0 ? `Llevas ${dias} ${dias === 1 ? 'día' : 'días'} seguidos` : 'Aún no tienes una racha activa',
    `has completado ${pilotajes} ${pilotajes === 1 ? 'pilotaje' : 'pilotajes'}`,
    `tienes ${cristales} cristales de energía`,
    `tu nivel energético está en ${nivel} por ciento`,
    `y tu luz cuántica en ${luz} por ciento`,
  ];

  const cierre =
    luz >= 100
      ? ' Ya puedes canjear una meditación especial en la Tienda Cuántica de la app.'
      : ' ¿Quieres hacer tu repetición del día?';

  return alexaResponse({
    ssml: `<speak>${escapeXml(partes.join(', '))}.${escapeXml(cierre)}</speak>`,
    shouldEndSession: false,
    reprompt: 'Di, repite mi secuencia del día, o pregúntame por otra secuencia.',
  });
}

function handleExplicarSecuencia(sessionAttributes) {
  const ultima = sessionAttributes?.ultimaSecuencia;
  if (!ultima) {
    return alexaResponse({
      ssml: '<speak>Primero pídeme una secuencia y con gusto te explico para qué sirve.</speak>',
      shouldEndSession: false,
      reprompt: 'Di, repite mi secuencia del día, o pídeme una para la salud o el dinero.',
    });
  }

  const texto = ultima.descripcion
    ? `${ultima.nombre ? `${ultima.nombre}. ` : ''}${ultima.descripcion}`
    : `Esta secuencia se usa para ${ultima.nombre ?? 'tu propósito del día'}. En la app de Mani Grab encuentras la explicación completa.`;

  return alexaResponse({
    ssml: `<speak>${escapeXml(texto)}<break time="500ms"/>¿Quieres que la repitamos otra vez?</speak>`,
    shouldEndSession: false,
    reprompt: '¿Quieres que la repitamos otra vez?',
    sessionAttributes,
  });
}

// --- Handlers sin cuenta vinculada ----------------------------------

// Experiencia "de cortesía" para quien NO ha vinculado su cuenta: en vez
// de bloquear con la tarjeta de LinkAccount de una, le regalamos la
// secuencia UNA vez (no las repeticiones completas ni cristales — eso es
// lo que la cuenta vinculada da de más) y lo invitamos a la app.
function respuestaCortesia(secuencia, { intro, incluirInvitacion = true }) {
  const cuerpo =
    `<speak>${intro}<break time="800ms"/>` +
    `${digitosSsml(secuencia.codigo)}<break time="1000ms"/>` +
    (incluirInvitacion ? `${escapeXml(INVITACION_CORTA)}<break time="400ms"/>` : '') +
    `¿Quieres otra secuencia, o saber qué significa esta?</speak>`;

  return alexaResponse({
    ssml: cuerpo,
    shouldEndSession: false,
    reprompt: 'Puedes pedirme una secuencia para la salud, el dinero o el amor, o preguntarme qué significa esta.',
    card: CARD_INVITACION,
    sessionAttributes: recordarSecuencia(secuencia),
  });
}

async function handleCortesiaDelDia(admin) {
  const secuencia = await obtenerCodigoDelDia(admin);
  if (!secuencia) {
    return alexaResponse({
      ssml: '<speak>No pude encontrar la secuencia de hoy. Intenta de nuevo en un momento.</speak>',
      shouldEndSession: true,
    });
  }

  const intro = secuencia.nombre
    ? `Bienvenido a Mani Grab. Esta es la secuencia del día, para ${escapeXml(secuencia.nombre)}.`
    : 'Bienvenido a Mani Grab. Esta es la secuencia del día.';

  return respuestaCortesia(secuencia, { intro });
}

async function handleCortesiaPorProposito(admin, proposito) {
  const secuencia = await buscarPorProposito(admin, proposito);
  if (!secuencia) {
    return alexaResponse({
      ssml: `<speak>No encontré una secuencia para ${escapeXml(proposito || 'eso')}. Puedes pedirme una para la salud, el dinero, el amor, la protección, el trabajo, o la ansiedad.</speak>`,
      shouldEndSession: false,
      reprompt: 'Dime para qué quieres una secuencia.',
    });
  }

  const intro = `Esta secuencia es para ${escapeXml(secuencia.nombre)}.`;
  return respuestaCortesia(secuencia, { intro });
}

function handleCortesiaRequiereCuenta(mensaje) {
  return alexaResponse({
    ssml: `<speak>${escapeXml(mensaje)} ${escapeXml(INVITACION_CORTA)}</speak>`,
    shouldEndSession: false,
    reprompt: 'Puedes pedirme la secuencia del día, o una para la salud, el dinero o el amor.',
    card: CARD_INVITACION,
  });
}

// --- Utilidades de slots --------------------------------------------

function leerSlot(request, nombre) {
  const slot = request?.intent?.slots?.[nombre];
  if (!slot) return null;
  const resuelto =
    slot.resolutions?.resolutionsPerAuthority?.find((r) => r.status?.code === 'ER_SUCCESS_MATCH')
      ?.values?.[0]?.value?.name;
  return resuelto || slot.value || null;
}

function leerVeces(request) {
  const crudo = leerSlot(request, 'veces');
  const n = Number.parseInt(crudo, 10);
  if (!Number.isFinite(n)) return REPETICIONES_POR_SESION;
  return Math.min(REPETICIONES_MAX, Math.max(REPETICIONES_MIN, n));
}

// --- Handler principal ----------------------------------------------

async function handler(req, res) {
  try {
    if (req.method !== 'POST') {
      res.status(405).send('Method not allowed');
      return;
    }

    const rawBody = await readRawBody(req);
    const signature = req.headers['signature'];
    const certChainUrl = req.headers['signaturecertchainurl'];

    const skipVerify = process.env.ALEXA_SKIP_SIGNATURE_VERIFY === 'true';
    if (!skipVerify) {
      const verification = await verifyAlexaSignature(rawBody, certChainUrl, signature);
      if (!verification.ok) {
        console.error('Firma de Alexa rechazada:', verification.reason);
        res.status(401).send('Invalid request signature');
        return;
      }
    } else {
      console.warn('ALEXA_SKIP_SIGNATURE_VERIFY=true — verificación de firma DESACTIVADA (solo para depurar)');
    }

    let payload;
    try {
      payload = JSON.parse(rawBody);
    } catch (_e) {
      res.status(400).send('Invalid JSON');
      return;
    }

    if (!skipVerify && !isTimestampFresh(payload?.request?.timestamp)) {
      res.status(401).send('Stale request');
      return;
    }

    const expectedSkillId = process.env.ALEXA_SKILL_ID;
    const actualSkillId =
      payload?.session?.application?.applicationId ?? payload?.context?.System?.application?.applicationId;
    if (expectedSkillId && actualSkillId !== expectedSkillId) {
      console.error(`applicationId inesperado: ${actualSkillId}`);
      res.status(401).send('Application ID mismatch');
      return;
    }

    const admin = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY);

    const accessToken = payload?.session?.user?.accessToken ?? payload?.context?.System?.user?.accessToken;

    let userId = null;
    if (accessToken) {
      const { data: link } = await admin
        .from('alexa_account_links')
        .select('user_id, access_token_expires_at')
        .eq('access_token', accessToken)
        .maybeSingle();
      if (link && new Date(link.access_token_expires_at) > new Date()) {
        userId = link.user_id;
      }
    }

    const requestType = payload?.request?.type;
    const sessionAttributes = payload?.session?.attributes ?? {};

    if (requestType === 'LaunchRequest') {
      if (!userId) {
        res.status(200).json(await handleCortesiaDelDia(admin));
        return;
      }
      res.status(200).json(
        alexaResponse({
          ssml: '<speak>Bienvenido a Mani Grab. Puedes decir, repite mi secuencia del día, pedirme una secuencia para algo en concreto, o preguntarme cómo vas.</speak>',
          shouldEndSession: false,
          reprompt: 'Di, repite mi secuencia del día, para comenzar.',
        }),
      );
      return;
    }

    if (requestType === 'IntentRequest') {
      const request = payload.request;
      const intentName = request?.intent?.name;
      const veces = leerVeces(request);
      const ultima = sessionAttributes?.ultimaSecuencia;

      switch (intentName) {
        case 'IniciarRepeticionDiariaIntent':
          res.status(200).json(
            userId
              ? await handleRepeticionDiaria(admin, userId, veces)
              : await handleCortesiaDelDia(admin),
          );
          return;

        case 'SecuenciaPorPropositoIntent': {
          const proposito = leerSlot(request, 'proposito');
          res.status(200).json(
            userId
              ? await handleSecuenciaPorProposito(admin, userId, proposito, veces)
              : await handleCortesiaPorProposito(admin, proposito),
          );
          return;
        }

        case 'MiFavoritaIntent':
          res.status(200).json(
            userId
              ? await handleMiFavorita(admin, userId, veces)
              : handleCortesiaRequiereCuenta(
                  'Para guardar y escuchar tus secuencias favoritas necesitas tu cuenta de Mani Grab.',
                ),
          );
          return;

        case 'MiProgresoIntent':
          res.status(200).json(
            userId
              ? await handleMiProgreso(admin, userId)
              : handleCortesiaRequiereCuenta(
                  'Para llevar tu racha, tus cristales y tu nivel energético necesitas tu cuenta de Mani Grab.',
                ),
          );
          return;

        case 'ExplicarSecuenciaIntent':
          res.status(200).json(handleExplicarSecuencia(sessionAttributes));
          return;

        case 'RepetirDeNuevoIntent':
        case 'AMAZON.RepeatIntent':
        case 'AMAZON.YesIntent': {
          if (!ultima) {
            res.status(200).json(
              userId
                ? await handleRepeticionDiaria(admin, userId, veces)
                : await handleCortesiaDelDia(admin),
            );
            return;
          }
          if (!userId) {
            res.status(200).json(
              respuestaCortesia(ultima, {
                intro: 'Aquí va otra vez.',
                incluirInvitacion: false,
              }),
            );
            return;
          }
          res.status(200).json(
            await repetirSecuencia(admin, userId, ultima, {
              intro: 'Vamos otra vez. Repite cada número en voz alta junto conmigo.',
              veces,
            }),
          );
          return;
        }

        case 'AMAZON.HelpIntent':
          res.status(200).json(
            alexaResponse({
              ssml: userId
                ? '<speak>Puedes decir: repite mi secuencia del día, para tu práctica diaria y ganar cristales. Dame una secuencia para la salud, o para el dinero, el amor, la protección o la ansiedad. Repite mi favorita. Cómo voy, para escuchar tu progreso. O, qué significa, después de cualquier secuencia.</speak>'
                : '<speak>Puedes decir: dame la secuencia del día, o, dame una secuencia para la salud, el dinero, el amor o la protección. Te la leo de cortesía. Para repetirla las veces que quieras, llevar tu racha y ganar cristales, vincula tu cuenta de Mani Grab desde la app de Alexa.</speak>',
              shouldEndSession: false,
              reprompt: 'Dime qué secuencia quieres escuchar.',
              card: userId ? undefined : CARD_INVITACION,
            }),
          );
          return;

        case 'AMAZON.StopIntent':
        case 'AMAZON.CancelIntent':
        case 'AMAZON.NoIntent':
          res.status(200).json(
            alexaResponse({ ssml: '<speak>Hasta pronto. Que tengas un gran día.</speak>', shouldEndSession: true }),
          );
          return;

        default:
          res.status(200).json(
            alexaResponse({
              ssml: '<speak>No entendí eso. Puedes decir, repite mi secuencia del día, o, dame una secuencia para la salud.</speak>',
              shouldEndSession: false,
              reprompt: 'Di, repite mi secuencia del día, o pídeme una secuencia para algo en concreto.',
              sessionAttributes,
            }),
          );
          return;
      }
    }

    // SessionEndedRequest y cualquier otro tipo: cerrar sin hablar.
    res.status(200).json(alexaResponse({ ssml: '<speak></speak>', shouldEndSession: true }));
  } catch (e) {
    const message = e instanceof Error ? `${e.name}: ${e.message}` : String(e);
    console.error('Error no controlado en alexa-skill:', message, e instanceof Error ? e.stack : '');
    const debugMode = process.env.ALEXA_DEBUG_MODE === 'true';
    res.status(200).json(
      alexaResponse({
        ssml: debugMode
          ? `<speak>Error interno: ${escapeXml(message.slice(0, 400))}</speak>`
          : '<speak>Tuve un problema interno. Intenta de nuevo en un momento.</speak>',
        shouldEndSession: true,
      }),
    );
  }
}

handler.config = { api: { bodyParser: false } };
module.exports = handler;
