' Reproductor dígito por dígito. Replica exactamente el ritmo de
' NumbersVoiceService de la app (280ms entre dígitos, 100ms alrededor
' de "espacio", 1800ms + "nuevamente" + 1800ms entre repeticiones),
' usando los mismos clips de voz servidos desde el bucket público. No
' hay límite de duración de respuesta como en Alexa — Roku es formato
' largo por diseño, por eso esto sí puede sonar completo aquí.

sub init()
    m.audio = m.top.findNode("audio")
    m.audio.observeField("state", "onAudioStateChange")

    m.gapTimer = m.top.findNode("gapTimer")
    m.gapTimer.observeField("fire", "onGapTimerFire")

    m.nombreLabel = m.top.findNode("nombreLabel")
    m.descripcionLabel = m.top.findNode("descripcionLabel")
    m.estadoLabel = m.top.findNode("estadoLabel")

    m.sequenceTask = m.top.findNode("sequenceTask")
    m.sequenceTask.observeField("done", "onSequenceResponse")
    m.sequenceTask.authToken = m.top.authToken
    m.sequenceTask.uri = ApiBase() + "/roku-sequence?id=" + m.top.secuenciaId
    m.sequenceTask.method = "GET"
    m.sequenceTask.control = "RUN"

    m.completeTask = m.top.findNode("completeTask")
    m.completeTask.observeField("done", "onCompleteResponse")
end sub

sub onSequenceResponse(event as Object)
    result = event.GetData()
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
    m.nombreLabel.text = data.nombre
    if data.descripcion <> invalid
        m.descripcionLabel.text = data.descripcion
    end if
    m.estadoLabel.text = "Repite cada numero en voz alta junto con la secuencia."

    m.steps = BuildSteps(data.audio)
    m.stepIndex = 0
    m.startEpoch = CreateObject("roDateTime").AsSeconds()

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
        content = CreateObject("roSGNode", "ContentNode")
        content.url = paso.url
        m.audio.content = content
        m.audio.control = "play"
    else
        m.gapTimer.duration = paso.ms / 1000.0
        m.gapTimer.control = "start"
    end if
end sub

sub onAudioStateChange(event as Object)
    state = event.GetData()
    if state = "finished" or state = "error"
        RunNextStep()
    end if
end sub

sub onGapTimerFire()
    RunNextStep()
end sub

sub FinishPlayback()
    m.estadoLabel.text = "Secuencia completada. Guardando tu progreso..."

    endEpoch = CreateObject("roDateTime").AsSeconds()
    minutos = Int((endEpoch - m.startEpoch) / 60)

    body = { codigo_id: m.top.secuenciaId, codigo: m.codigo, nombre: m.nombre, minutos: minutos }
    m.completeTask.uri = ApiBase() + "/roku-complete"
    m.completeTask.method = "POST"
    m.completeTask.authToken = m.top.authToken
    m.completeTask.body = FormatJson(body)
    m.completeTask.control = "RUN"
end sub

sub onCompleteResponse(event as Object)
    result = event.GetData()
    if result.code = 200
        data = ParseJsonSafe(result.json)
        if data <> invalid and data.cristales_ganados <> invalid
            m.estadoLabel.text = "Ganaste " + data.cristales_ganados.ToStr() + " cristales de energia. Presiona atras para volver."
        else
            m.estadoLabel.text = "Completado. Presiona atras para volver."
        end if
    else
        m.estadoLabel.text = "Completado (no se pudo actualizar tu progreso). Presiona atras."
    end if
end sub
