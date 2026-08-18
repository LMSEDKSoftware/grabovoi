' Reproductor dígito por dígito. Replica exactamente el ritmo de
' NumbersVoiceService de la app (280ms entre dígitos, 100ms alrededor
' de "espacio", 1800ms + "nuevamente" + 1800ms entre repeticiones),
' usando los mismos clips de voz servidos desde el bucket público. No
' hay límite de duración de respuesta como en Alexa — Roku es formato
' largo por diseño, por eso esto sí puede sonar completo aquí.

' Segundos que dura la cortinilla de instrucciones al principio de cada
' video narrado. NO es una estimacion: es un archivo unico y fijo
' (output/intro_cortinilla/intro_cortinilla.mp4, ver
' scripts/generar_intro_cortinilla.py) que se antepone por copia de
' stream a TODAS las secuencias, asi que el corte cae siempre en el mismo
' instante. Si algun dia se regenera la cortinilla con otra duracion, hay
' que actualizar este numero.
function DuracionIntro() as Float
    return 36.5
end function

sub init()
    m.bgVideo = m.top.findNode("bgVideo")
    m.bgVideo.observeField("state", "onBgVideoStateChange")
    m.bgVideo.observeField("position", "onBgVideoPosition")
    m.saltarGrupo = m.top.findNode("saltarGrupo")
    m.saltarLabel = m.top.findNode("saltarLabel")
    m.saltarRestante = 0
    m.saltarTimer = m.top.findNode("saltarTimer")
    m.saltarTimer.observeField("fire", "onSaltarTimerFire")
    ' Una sola oportunidad por secuencia: una vez que se tomo o se dejo
    ' pasar, el boton no vuelve (si no, un rebuffeo a media cortinilla lo
    ' resucitaria a la mitad de las instrucciones).
    m.saltarConsumido = false
    m.bgImagen = m.top.findNode("bgImagen")
    m.scrimJugador = m.top.findNode("scrimJugador")

    m.audio = m.top.findNode("audio")
    m.audio.observeField("state", "onAudioStateChange")

    m.gapTimer = m.top.findNode("gapTimer")
    m.gapTimer.observeField("fire", "onGapTimerFire")

    m.nombreGrupo = m.top.findNode("nombreGrupo")
    m.nombreLabel = m.top.findNode("nombreLabel")
    m.codigoGrupo = m.top.findNode("codigoGrupo")
    m.codigoLabel = m.top.findNode("codigoLabel")
    m.estadoLabel = m.top.findNode("estadoLabel")

    m.sequenceTask = m.top.findNode("sequenceTask")
    m.sequenceTask.observeField("done", "onSequenceResponse")

    m.completeTask = m.top.findNode("completeTask")
    m.completeTask.observeField("done", "onCompleteResponse")

    m.completionGrupo = m.top.findNode("completionGrupo")
    m.completionSubtitulo = m.top.findNode("completionSubtitulo")
    m.completionCristales = m.top.findNode("completionCristales")
    m.completionCombinar = m.top.findNode("completionCombinar")
    m.sugerencia1Grupo = m.top.findNode("sugerencia1Grupo")
    m.sugerencia1Borde = m.top.findNode("sugerencia1Borde")
    m.sugerencia1Codigo = m.top.findNode("sugerencia1Codigo")
    m.sugerencia1Nombre = m.top.findNode("sugerencia1Nombre")
    m.sugerencia1Categoria = m.top.findNode("sugerencia1Categoria")
    m.sugerencia2Grupo = m.top.findNode("sugerencia2Grupo")
    m.sugerencia2Borde = m.top.findNode("sugerencia2Borde")
    m.sugerencia2Codigo = m.top.findNode("sugerencia2Codigo")
    m.sugerencia2Nombre = m.top.findNode("sugerencia2Nombre")
    m.sugerencia2Categoria = m.top.findNode("sugerencia2Categoria")
    m.volverMenuGrupo = m.top.findNode("volverMenuGrupo")
    m.volverMenuBorde = m.top.findNode("volverMenuBorde")

    m.disclaimerGrupo = m.top.findNode("disclaimerGrupo")

    m.rutinaTask = m.top.findNode("rutinaTask")
    m.rutinaTask.observeField("done", "onRutinaResponse")
    m.colaLabel = m.top.findNode("colaLabel")

    ' Cola de secuencias por reproducir. Con una secuencia suelta tiene un
    ' solo elemento; con una rutina, todas sus secuencias en orden.
    m.cola = []
    m.colaIndex = 0
end sub

function StartLoading() as Void
    ' Deslinde de responsabilidad medica (mismo texto que el modal "Nota
    ' Importante" de la app movil). Se reconoce UNA vez por aparato: Roku
    ' no acepta friccion repetida delante del contenido, y un aviso que
    ' hay que despachar en cada secuencia deja de leerse. Queda siempre
    ' disponible en Informacion Legal.
    if DisclaimerAceptado()
        EmpezarSecuencia()
        return
    end if
    m.disclaimerGrupo.visible = true
    m.top.setFocus(true)
end function

sub EmpezarSecuencia()
    m.disclaimerGrupo.visible = false

    if m.top.rutinaId <> ""
        m.estadoLabel.text = "Preparando tu pilotaje..."
        m.rutinaTask.authToken = m.top.authToken
        m.rutinaTask.uri = ApiBase() + "/roku-perfil?rutina=" + m.top.rutinaId
        m.rutinaTask.method = "GET"
        m.rutinaTask.control = "RUN"
        return
    end if

    m.cola = [m.top.secuenciaId]
    m.colaIndex = 0
    CargarSecuenciaDeLaCola()
end sub

sub onRutinaResponse(event as Object)
    result = event.GetData()
    if SesionVencida(m.top, result) then return

    if result.code <> 200
        m.estadoLabel.text = "No se pudo cargar la combinación. Presiona atras."
        return
    end if

    data = ParseJsonSafe(result.json)
    if data = invalid or data.secuencias = invalid or data.secuencias.Count() = 0
        m.estadoLabel.text = "Esa combinación no tiene secuencias. Presiona atras."
        return
    end if

    m.cola = []
    for each secuencia in data.secuencias
        m.cola.Push(secuencia.id)
    end for
    m.colaIndex = 0
    CargarSecuenciaDeLaCola()
end sub

sub CargarSecuenciaDeLaCola()
    m.saltarConsumido = false
    ActualizarColaLabel()
    m.sequenceTask.authToken = m.top.authToken
    m.sequenceTask.uri = ApiBase() + "/roku-sequence?id=" + m.cola[m.colaIndex]
    m.sequenceTask.method = "GET"
    m.sequenceTask.control = "RUN"
end sub

sub ActualizarColaLabel()
    if m.cola.Count() <= 1
        m.colaLabel.visible = false
        return
    end if
    m.colaLabel.text = "Secuencia " + (m.colaIndex + 1).ToStr() + " de " + m.cola.Count().ToStr()
    m.colaLabel.visible = true
end sub

sub onSequenceResponse(event as Object)
    result = event.GetData()
    if SesionVencida(m.top, result) then return
    if result.code <> 200
        m.estadoLabel.text = "No se pudo cargar la secuencia. Presiona atras."
        return
    end if

    data = ParseJsonSafe(result.json)
    if data = invalid or data.audio = invalid
        m.estadoLabel.text = "Respuesta inesperada. Presiona atras."
        return
    end if

    m.codigo = data.codigo
    m.nombre = data.nombre
    m.categoria = ""
    if data.categoria <> invalid then m.categoria = data.categoria
    CentrarNombre(data.nombre)
    m.estadoLabel.text = ""

    ' Se guardan para el modo de respaldo (digito por digito), por si el
    ' video narrado falla o todavia no existe para esta secuencia/voz.
    m.datosAudio = data.audio
    m.imagenUrl = ""
    if data.imagen_url <> invalid then m.imagenUrl = data.imagen_url

    m.startEpoch = CreateObject("roDateTime").AsSeconds()

    if data.video_narrado_url <> invalid and data.video_narrado_url <> ""
        print "PlayerScreen intentando video narrado="; data.video_narrado_url
        contentVideo = CreateObject("roSGNode", "ContentNode")
        contentVideo.url = data.video_narrado_url
        m.bgVideo.content = contentVideo
        m.bgVideo.control = "play"
        m.bgVideo.visible = true
    else
        print "PlayerScreen sin video_narrado_url, va directo a modo digito por digito"
        IniciarModoDigitoPorDigito()
    end if
end sub

sub CentrarNombre(nombre as String)
    ' Mismo patron que CentrarCodigo: el Label sin escalar mide su propio
    ' ancho, y ese ancho x2 (el scale del grupo) es lo que se centra.
    m.nombreLabel.text = nombre
    rect = m.nombreLabel.boundingRect()
    x = (1280 - rect.width * 2) / 2
    m.nombreGrupo.translation = [x, 50]
end sub

sub CentrarCodigo(codigo as String)
    ' El Label NO tiene scale propio (eso evita ambiguedad en
    ' boundingRect); el scale=[4,4] esta en el Group que lo contiene
    ' (codigoGrupo). Se mide el Label sin escalar (confiable) y se
    ' calcula la traduccion del GRUPO en X y en Y para que, ya escalado,
    ' el texto quede exactamente en el centro de la pantalla -- que es
    ' donde cae el cruce de la esfera del video de fondo.
    m.codigoLabel.text = FormatearCodigo(codigo)
    rect = m.codigoLabel.boundingRect()
    x = (1280 - rect.width * 4) / 2
    y = (720 - rect.height * 4) / 2
    m.codigoGrupo.translation = [x, y]
end sub

function FormatearCodigo(codigo as String) as String
    texto = ""
    for i = 1 to Len(codigo)
        c = Mid(codigo, i, 1)
        if c = "_"
            texto = texto + "  "
        else
            texto = texto + c
        end if
    end for
    return texto
end function

sub onBgVideoStateChange(event as Object)
    state = event.GetData()
    print "PlayerScreen bgVideo state="; state

    if state = "error"
        print "PlayerScreen video narrado fallo (errorCode="; m.bgVideo.errorCode; " errorMsg="; m.bgVideo.errorMsg; "), usando modo digito por digito"
        OcultarSaltar()
        IniciarModoDigitoPorDigito()
    else if state = "playing"
        ' Solo tiene sentido ofrecer el salto si de verdad seguimos dentro
        ' de la cortinilla. Al volver de un seek tambien pasa por aqui.
        if not m.saltarConsumido and m.bgVideo.position < DuracionIntro()
            MostrarSaltar()
        end if
    else if state = "finished"
        ' El video narrado ya trae las repeticiones con voz incrustada:
        ' terminar significa que la secuencia completa ya se reprodujo.
        OcultarSaltar()
        FinishPlayback()
    end if
end sub

sub MostrarSaltar()
    m.saltarRestante = 5
    SaltarTexto()
    m.saltarGrupo.visible = true
    m.saltarTimer.control = "start"
end sub

sub SaltarTexto()
    m.saltarLabel.text = "Saltar instrucciones (" + m.saltarRestante.ToStr() + ")"
end sub

' Lo esconde y lo da por consumido. Es el unico camino para quitarlo, lo
' dispare quien lo dispare: el temporizador, el fin de la cortinilla, o
' el propio usuario al presionarlo.
sub OcultarSaltar()
    m.saltarTimer.control = "stop"
    m.saltarGrupo.visible = false
    m.saltarConsumido = true
end sub

' El temporizador late cada segundo: cada latido baja la cuenta, y al
' llegar a cero el boton se retira.
sub onSaltarTimerFire()
    m.saltarRestante = m.saltarRestante - 1
    if m.saltarRestante <= 0
        OcultarSaltar()
    else
        SaltarTexto()
    end if
end sub

sub onBgVideoPosition(event as Object)
    if not m.saltarGrupo.visible then return
    ' Por si la cortinilla termina antes de que se cumplan los 5 segundos
    ' (por ejemplo si el video entro tarde en "playing").
    if event.GetData() >= DuracionIntro()
        OcultarSaltar()
    end if
end sub

sub SaltarIntro()
    OcultarSaltar()
    m.bgVideo.seek = DuracionIntro()
end sub

sub IniciarModoDigitoPorDigito()
    m.bgVideo.control = "stop"
    m.bgVideo.visible = false

    ' Solo aqui se dibuja el codigo en pantalla: el video narrado ya lo
    ' trae horneado, este overlay es exclusivo del respaldo.
    CentrarCodigo(m.codigo)
    m.codigoGrupo.visible = true

    if m.imagenUrl <> ""
        m.bgImagen.uri = m.imagenUrl
        m.bgImagen.visible = true
    end if

    print "PlayerScreen voz="; m.datosAudio.voz; " tokens="; m.datosAudio.tokens.Count()

    m.steps = BuildSteps(m.datosAudio)
    print "PlayerScreen pasos totales construidos="; m.steps.Count()
    m.stepIndex = 0

    RunNextStep()
end sub

function BuildSteps(audio as Object) as Object
    steps = []
    reps = 10

    repSteps = []
    for each token in audio.tokens
        if token = "_"
            repSteps.Push({ type: "silence", ms: audio.gaps_ms.espacio })
            repSteps.Push({ type: "clip", url: audio.clips.espacio })
            repSteps.Push({ type: "silence", ms: audio.gaps_ms.espacio })
        else
            repSteps.Push({ type: "clip", url: audio.clips[token] })
            repSteps.Push({ type: "silence", ms: audio.gaps_ms.digito })
        end if
    end for

    for r = 1 to reps
        for each s in repSteps
            steps.Push(s)
        end for
        if r < reps
            steps.Push({ type: "silence", ms: audio.gaps_ms.nuevamente })
            steps.Push({ type: "clip", url: audio.clips.nuevamente })
            steps.Push({ type: "silence", ms: audio.gaps_ms.nuevamente })
        end if
    end for

    return steps
end function

sub RunNextStep()
    if m.steps = invalid or m.stepIndex >= m.steps.Count()
        FinishPlayback()
        return
    end if

    paso = m.steps[m.stepIndex]
    m.stepIndex = m.stepIndex + 1

    if paso.type = "clip"
        print "PlayerScreen paso "; m.stepIndex; "/"; m.steps.Count(); " CLIP url="; paso.url
        content = CreateObject("roSGNode", "ContentNode")
        content.url = paso.url
        content.contentType = "audio"
        content.streamFormat = "mp3"
        m.audio.content = content
        m.audio.control = "play"
    else
        print "PlayerScreen paso "; m.stepIndex; "/"; m.steps.Count(); " SILENCIO ms="; paso.ms
        m.gapTimer.duration = paso.ms / 1000.0
        m.gapTimer.control = "start"
    end if
end sub

sub onAudioStateChange(event as Object)
    state = event.GetData()
    print "PlayerScreen audio state="; state

    if state = "error"
        print "PlayerScreen audio errorCode="; m.audio.errorCode; " errorMsg="; m.audio.errorMsg
        m.estadoLabel.text = "Error de audio " + m.audio.errorCode.ToStr() + ": " + m.audio.errorMsg
        ' No avanzamos en error: antes esto saltaba en silencio al
        ' siguiente paso y sonaba "cortado". Mejor detenerse y que el
        ' error quede visible en pantalla + consola.
        return
    end if

    if state = "finished"
        RunNextStep()
    end if
end sub

sub onGapTimerFire()
    RunNextStep()
end sub

sub FinishPlayback()
    m.estadoLabel.text = "Secuencia completada. Guardando tu progreso..."

    ' m.startEpoch se fija al cargar la secuencia, no al empezar cada
    ' pasada: en una sesion continua esto cuenta el tiempo real de las
    ' repeticiones, y se registra un solo completado por secuencia.
    endEpoch = CreateObject("roDateTime").AsSeconds()
    minutos = Int((endEpoch - m.startEpoch) / 60)

    body = { codigo_id: m.cola[m.colaIndex], codigo: m.codigo, nombre: m.nombre, categoria: m.categoria, minutos: minutos }
    m.completeTask.uri = ApiBase() + "/roku-complete"
    m.completeTask.method = "POST"
    m.completeTask.authToken = m.top.authToken
    m.completeTask.body = FormatJson(body)
    m.completeTask.control = "RUN"
end sub

sub onCompleteResponse(event as Object)
    result = event.GetData()

    ' Quedan secuencias en la rutina: se encadena la siguiente sin
    ' mostrar la pantalla de "Secuencia Activada", que es justo lo que
    ' obligaria a tomar el control a media sesion.
    if m.colaIndex + 1 < m.cola.Count()
        m.colaIndex = m.colaIndex + 1
        m.estadoLabel.text = ""
        m.bgVideo.control = "stop"
        m.bgVideo.visible = false
        m.codigoGrupo.visible = false
        m.bgImagen.visible = false
        CargarSecuenciaDeLaCola()
        return
    end if

    cristales = invalid
    sincronicos = []
    if result.code = 200
        data = ParseJsonSafe(result.json)
        if data <> invalid
            if data.cristales_ganados <> invalid then cristales = data.cristales_ganados
            if data.sincronicos <> invalid then sincronicos = data.sincronicos
        end if
    end if
    m.colaLabel.visible = false
    MostrarCompletion(cristales, sincronicos)
end sub

sub MostrarCompletion(cristales as Dynamic, sincronicos as Object)
    ' Mismos textos que SequenciaActivadaModal en la app (lib/widgets/
    ' sequencia_activada_modal.dart), pidieron reutilizarlos tal cual.
    m.completionSubtitulo.text = "¡Excelente trabajo! Has completado tu sesión de campo energético."

    if cristales <> invalid and cristales > 0
        m.completionCristales.text = "¡Felicitaciones! Has recibido " + cristales.ToStr() + " cristales de energía"
    else
        m.completionCristales.text = ""
    end if

    m.completionOpciones = []

    cuantas = 0
    if sincronicos <> invalid then cuantas = sincronicos.Count()

    if cuantas >= 1
        sug = sincronicos[0]
        m.sugerencia1Codigo.text = sug.codigo
        m.sugerencia1Nombre.text = sug.nombre
        m.sugerencia1Categoria.text = sug.categoria
        m.sugerencia1Grupo.visible = true
        m.completionOpciones.Push({ tipo: "sincronico", id: sug.id, borde: m.sugerencia1Borde })
    else
        m.sugerencia1Grupo.visible = false
    end if

    if cuantas >= 2
        sug = sincronicos[1]
        m.sugerencia2Codigo.text = sug.codigo
        m.sugerencia2Nombre.text = sug.nombre
        m.sugerencia2Categoria.text = sug.categoria
        m.sugerencia2Grupo.visible = true
        m.completionOpciones.Push({ tipo: "sincronico", id: sug.id, borde: m.sugerencia2Borde })
    else
        m.sugerencia2Grupo.visible = false
    end if

    m.completionCombinar.visible = (cuantas > 0)
    if cuantas > 0
        m.volverMenuGrupo.translation = [440, 620]
    else
        m.volverMenuGrupo.translation = [440, 460]
    end if

    m.completionOpciones.Push({ tipo: "volver", id: invalid, borde: m.volverMenuBorde })
    m.completionIndex = 0

    ActualizarFocoCompletion()
    m.completionGrupo.visible = true
end sub

sub ActualizarFocoCompletion()
    for each opcion in m.completionOpciones
        opcion.borde.opacity = 0
    end for
    m.completionOpciones[m.completionIndex].borde.opacity = 1
end sub

sub SeleccionarOpcionCompletion()
    opcion = m.completionOpciones[m.completionIndex]
    if opcion.tipo = "sincronico"
        m.top.result = { action: "openSequence", id: opcion.id }
    else
        m.top.result = { action: "back" }
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    ' Aviso "Nota Importante": mientras esta visible, solo OK ("Entendido",
    ' reconocimiento explicito) o "atras" (cancelar) hacen algo -- se
    ' bloquea cualquier otra tecla para no interactuar con la pantalla de
    ' atras, que todavia no termino de cargar.
    if m.disclaimerGrupo <> invalid and m.disclaimerGrupo.visible
        if key = "OK"
            GuardarDisclaimerAceptado()
            EmpezarSecuencia()
        else if key = "back"
            m.top.result = { action: "back" }
        end if
        return true
    end if

    ' Saltar la cortinilla de instrucciones. Solo se traga el OK: "atras"
    ' y lo demas siguen su camino normal (salir del reproductor).
    if m.saltarGrupo <> invalid and m.saltarGrupo.visible and key = "OK"
        SaltarIntro()
        return true
    end if

    if m.completionGrupo = invalid or not m.completionGrupo.visible then return false

    ultimo = m.completionOpciones.Count() - 1

    if key = "right"
        if m.completionIndex = 0 and ultimo >= 2
            m.completionIndex = 1
            ActualizarFocoCompletion()
        end if
        return true
    else if key = "left"
        if m.completionIndex = 1
            m.completionIndex = 0
            ActualizarFocoCompletion()
        end if
        return true
    else if key = "down"
        if m.completionIndex < ultimo
            m.completionIndex = ultimo
            ActualizarFocoCompletion()
        end if
        return true
    else if key = "up"
        if m.completionIndex = ultimo and ultimo > 0
            m.completionIndex = 0
            ActualizarFocoCompletion()
        end if
        return true
    else if key = "OK"
        SeleccionarOpcionCompletion()
        return true
    end if

    return false
end function
