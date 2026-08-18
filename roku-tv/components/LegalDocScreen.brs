' Contenido legal de ManiGraB, adaptado para el canal de Roku a partir de
' los mismos documentos de la app movil (pedido explicito del usuario):
' se ajustan las menciones a compras/eliminacion de cuenta (Roku no
' procesa pagos ni gestiona la cuenta, solo actua como visor vinculado a
' una cuenta ya existente) y la "Politica de Cookies" se reemplaza por
' "Almacenamiento en el Dispositivo" (Roku no tiene cookies de
' navegador; lo que si existe es el token de sesion en el registro local).

function Parrafos(lineas as Object) as String
    resultado = ""
    for i = 0 to lineas.Count() - 1
        resultado = resultado + lineas[i]
        if i < lineas.Count() - 1
            resultado = resultado + chr(10) + chr(10)
        end if
    end for
    return resultado
end function

function DocTerminos() as Object
    cuerpo = Parrafos([
        "Bienvenido a ManiGraB. Al acceder o utilizar esta aplicación, su versión web, o el canal de ManiGraB para Roku, aceptas quedar sujeto a los presentes Términos y Condiciones. ManiGraB es operado como un recurso tecnológico independiente. Si no estás de acuerdo con ellos, deberás abstenerte de utilizar el servicio.",
        "1. Descripción del servicio (repositorio tecnológico)" + chr(10) + "ManiGraB es una plataforma tecnológica que funciona como un repositorio dinámico y especializado para la gestión, organización, auditoría técnica y consulta de secuencias numéricas. El servicio actúa exclusivamente como una herramienta de infraestructura de software para administrar información técnica y de armonización personal de dominio público.",
        "Aviso importante: ManiGraB no es una aplicación médica, psicológica ni terapéutica. La plataforma no proporciona diagnósticos ni tratamientos médicos y no sustituye la atención de profesionales de la salud.",
        "2. Independencia y deslinde de marca" + chr(10) + "ManiGraB es una entidad tecnológica totalmente independiente. No tiene afiliación, patrocinio, asociación ni relación oficial con Grigori Grabovoi, sus organizaciones, licenciatarios o sucesores. Cualquier mención a autores, teorías o sistemas de terceros dentro del repositorio se realiza con fines estrictamente referenciales, bibliográficos o de catalogación técnica.",
        "3. Propiedad intelectual" + chr(10) + "El software, los algoritmos de organización, la arquitectura de la base de datos, el diseño de la interfaz, los logotipos y el código fuente son propiedad exclusiva de ManiGraB." + chr(10) + "Sobre las secuencias: ManiGraB no reclama propiedad intelectual sobre las secuencias numéricas individuales de su base de datos pública, tratadas como dominio público o acervo cultural compartido." + chr(10) + "Sobre la herramienta: el pago de suscripciones otorga el derecho de uso de las herramientas de gestión y acceso al repositorio auditado, no la compra de la información en sí misma.",
        "4. Uso del repositorio" + chr(10) + "Permitido: consulta personal, espiritual y educativa; uso de herramientas de auditoría; gestión de un repositorio privado con datos propios del usuario." + chr(10) + "Prohibido: ingeniería inversa o extracción masiva de datos; usar el contenido para sustituir tratamientos médicos profesionales; atribuir a ManiGraB autoría sobre teorías espirituales de terceros.",
        "5. Responsabilidad sobre el contenido y auditoría" + chr(10) + "ManiGraB actúa como compilador de información de libre circulación. Realizamos auditorías técnicas periódicas para priorizar las secuencias con mayor consenso, pero no garantizamos la infalibilidad de los datos. No supervisamos ni nos hacemos responsables del contenido que el usuario cargue de forma privada; el usuario es responsable de la legalidad y precisión de esos datos.",
        "6. Suscripciones y pagos" + chr(10) + "El acceso Premium se gestiona desde la aplicación móvil de ManiGraB (iOS/Android) mediante Apple In-App Purchase y Google Play Billing. ManiGraB no almacena ni procesa datos financieros; renovaciones, cancelaciones y reembolsos están sujetos a los términos de esas tiendas." + chr(10) + "El canal de Roku no procesa pagos ni gestiona suscripciones: funciona como un visor adicional vinculado a tu cuenta de ManiGraB ya existente, usando el mismo estatus Premium administrado desde tu dispositivo móvil.",
        "7. Limitación de responsabilidad" + chr(10) + "El uso de la información gestionada a través de ManiGraB es estrictamente subjetivo y bajo riesgo del usuario. ManiGraB no será responsable por la falta de resultados específicos ni por decisiones personales basadas en el uso de la plataforma.",
        "8. Modificaciones y ley aplicable" + chr(10) + "ManiGraB puede actualizar la arquitectura del repositorio o estos Términos para cumplir con nuevas normativas. Estos Términos se rigen por las leyes de los Estados Unidos Mexicanos; cualquier controversia se resolverá ante los tribunales competentes de ese territorio.",
        "9. Contacto" + chr(10) + "Para soporte técnico o consultas legales: contacto@manigrab.app"
    ])
    return { titulo: "Términos y Condiciones de Uso", subtitulo: "Última actualización: 11 de febrero de 2026", cuerpo: cuerpo }
end function

function DocPrivacidad() as Object
    cuerpo = Parrafos([
        "Esta política aplica a ManiGraB (app móvil, web y canal de Roku) y explica cómo gestionamos tus datos de acuerdo con la LFPDPPP (México) y las normativas de Apple App Store y Google Play Store.",
        "1. Responsable del tratamiento" + chr(10) + "El equipo ManiGraB (contacto@manigrab.app).",
        "2. Datos personales recopilados" + chr(10) + "Correo electrónico, para autenticación; nombre y foto de perfil (opcional); historial de prácticas, cristales y progreso; secuencias personales cargadas por el usuario; datos técnicos básicos del dispositivo." + chr(10) + "En el canal de Roku: solo se guarda un token de sesión vinculado a tu cuenta (generado al iniciar sesión con el código de vinculación), sin solicitar contraseñas ni datos adicionales en el dispositivo Roku.",
        "3. Procesamiento de pagos y suscripciones" + chr(10) + "ManiGraB no recopila ni almacena información financiera. Las suscripciones Premium se procesan mediante Apple In-App Purchase y Google Play Billing desde la app móvil; esos datos están sujetos a los términos de esas plataformas. El canal de Roku no procesa pagos.",
        "4. Uso de la información" + chr(10) + "Para permitir el acceso y sincronización de tu repositorio personal; notificar actualizaciones o auditorías de secuencias; gestionar el estatus de tu cuenta y suscripciones; optimizar la estabilidad técnica del servicio.",
        "5. Derechos ARCO y transparencia" + chr(10) + "Tienes derecho al Acceso, Rectificación, Cancelación y Oposición de tus datos personales, en cualquier momento, escribiendo a contacto@manigrab.app.",
        "6. Eliminación de cuenta y datos personales" + chr(10) + "Desde la app móvil: inicia el borrado desde el menú de Perfil o Configuración en iOS/Android." + chr(10) + "Vía correo: escribe a contacto@manigrab.app con el asunto Eliminar cuenta ManiGraB, validando tu correo de registro." + chr(10) + "El canal de Roku no gestiona la eliminación de cuenta directamente -- funciona solo como un visor vinculado a tu cuenta de ManiGraB, así que este trámite siempre se hace desde la app móvil o por correo, nunca desde el propio Roku." + chr(10) + "El borrado definitivo toma de 3 a 5 días hábiles e incluye tu identidad de cuenta, todo tu repositorio personal de secuencias, y cualquier preferencia guardada en la nube.",
        "7. Seguridad de la infraestructura" + chr(10) + "Usamos infraestructura de alta seguridad (Supabase) con cifrado y políticas de seguridad avanzadas para proteger tu repositorio de datos personal.",
        "8. Cambios a esta política" + chr(10) + "Actualizaremos esta política cuando sea necesario para cumplir nuevas regulaciones. Los cambios se informarán en la app o por correo.",
        "9. Contacto" + chr(10) + "Team ManiGraB. Correo: contacto@manigrab.app."
    ])
    return { titulo: "Política de Privacidad", subtitulo: "Última actualización: 11 de febrero de 2026", cuerpo: cuerpo }
end function

function DocAlmacenamiento() as Object
    cuerpo = Parrafos([
        "El canal de ManiGraB para Roku no utiliza cookies como las de un navegador web -- los dispositivos Roku no tienen ese mecanismo. En su lugar, el canal guarda localmente un único token de sesión cifrado, generado cuando vinculas tu cuenta con el código que se muestra en pantalla.",
        "Ese token sirve exclusivamente para mantener tu sesión iniciada, de modo que no tengas que volver a vincular tu cuenta cada vez que abres el canal. No se usa con fines publicitarios, no se comparte con terceros, y no incluye información financiera ni datos sensibles.",
        "Servicios de terceros: ManiGraB utiliza Supabase para la gestión de autenticación. Este servicio puede emplear tokens de seguridad técnicos, igual que cualquier app con inicio de sesión, únicamente para validar tu identidad y proteger tus datos contra accesos no autorizados.",
        "Cómo controlar este almacenamiento: puedes cerrar sesión en cualquier momento desde Cerrar sesión en el menú principal, lo cual borra ese token del dispositivo. También puedes eliminar todos los datos del canal desde el menú del propio Roku: Configuración, Sistema, Aplicaciones instaladas, ManiGraB, Eliminar datos del canal.",
        "En la app móvil de ManiGraB (iOS/Android), el almacenamiento se rige además por las políticas de privacidad de cada sistema operativo para identificadores publicitarios y de diagnóstico, controlables desde la configuración del teléfono; esto no aplica al canal de Roku.",
        "Actualizaciones: podremos actualizar esta política para reflejar cambios en nuestra infraestructura técnica. Las modificaciones se notificarán en la interfaz de ManiGraB.",
        "Contacto: para dudas técnicas sobre esta política escribe a contacto@manigrab.app."
    ])
    return { titulo: "Almacenamiento en el Dispositivo", subtitulo: "Versión para Roku de la Política de Cookies", cuerpo: cuerpo }
end function

' Mismo deslinde que el modal "Nota Importante" que se reconoce una sola
' vez antes de la primera secuencia (ver StartLoading en PlayerScreen.brs).
' Vive tambien aqui para poder releerlo sin volver a bloquear el
' contenido en cada reproduccion.
function DocSalud() as Object
    cuerpo = Parrafos([
        "Las secuencias numéricas gravitacionales NO sustituyen la atención médica profesional. Siempre consulta con profesionales de la salud para cualquier condición médica. Estas secuencias son herramientas complementarias de bienestar.",
        "ManiGraB no diagnostica, no trata, no cura ni previene ninguna enfermedad. Nada de lo que se muestra o se escucha en este canal debe interpretarse como consejo médico, ni como motivo para suspender, cambiar o retrasar un tratamiento indicado por un profesional de la salud.",
        "Si tienes una condición médica, estás bajo tratamiento, estás embarazada o tienes cualquier duda sobre tu salud, consulta a tu médico antes de incorporar estas prácticas a tu rutina.",
        "Si estás atravesando una emergencia de salud, comunícate de inmediato con los servicios de emergencia de tu país. Este canal no es un servicio de atención ni de acompañamiento en crisis.",
        "Al usar ManiGraB TV reconoces haber leído este aviso y aceptas que el uso de las secuencias es tu decisión personal y bajo tu propia responsabilidad."
    ])
    return { titulo: "Aviso de salud", subtitulo: "Deslinde de responsabilidad médica", cuerpo: cuerpo }
end function

sub init()
    m.title = m.top.findNode("title")
    m.subtitle = m.top.findNode("subtitle")
    m.scrollGroup = m.top.findNode("scrollGroup")
    m.body = m.top.findNode("body")

    m.viewportTop = 96
    m.viewportBottom = 676
    m.scrollY = 0
    m.maxScroll = 0
    m.pasoScroll = 420
end sub

function StartLoading() as Void
    doc = invalid
    if m.top.docId = "terminos"
        doc = DocTerminos()
    else if m.top.docId = "privacidad"
        doc = DocPrivacidad()
    else if m.top.docId = "almacenamiento"
        doc = DocAlmacenamiento()
    else if m.top.docId = "salud"
        doc = DocSalud()
    end if

    if doc = invalid
        m.title.text = "Documento no encontrado"
        return
    end if

    m.title.text = doc.titulo
    m.subtitle.text = doc.subtitulo
    m.body.text = doc.cuerpo

    rect = m.body.boundingRect()
    alturaVisible = m.viewportBottom - m.viewportTop
    m.maxScroll = rect.height - alturaVisible
    if m.maxScroll < 0 then m.maxScroll = 0
    m.scrollY = 0
    m.scrollGroup.translation = [300, m.viewportTop]
    m.top.setFocus(true)
end function

function RestoreFocus() as Void
    m.top.setFocus(true)
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if key = "down"
        nuevo = m.scrollY + m.pasoScroll
        if nuevo > m.maxScroll then nuevo = m.maxScroll
        m.scrollY = nuevo
        m.scrollGroup.translation = [300, m.viewportTop - m.scrollY]
        return true
    else if key = "up"
        nuevo = m.scrollY - m.pasoScroll
        if nuevo < 0 then nuevo = 0
        m.scrollY = nuevo
        m.scrollGroup.translation = [300, m.viewportTop - m.scrollY]
        return true
    end if

    return false
end function
