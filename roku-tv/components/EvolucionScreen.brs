sub init()
    m.loadingLabel = m.top.findNode("loadingLabel")
    m.contenido = m.top.findNode("contenido")
    m.rachaValor = m.top.findNode("rachaValor")
    m.rachaValor.font.size = 50
    m.tiempoTotalValor = m.top.findNode("tiempoTotalValor")
    m.secuenciasUsadasValor = m.top.findNode("secuenciasUsadasValor")
    m.totalPilotajesValor = m.top.findNode("totalPilotajesValor")
    m.tiempoSesionValor = m.top.findNode("tiempoSesionValor")
    m.sesionesValor = m.top.findNode("sesionesValor")
    m.nivelValor = m.top.findNode("nivelValor")

    m.perfilTask = m.top.findNode("perfilTask")
    m.perfilTask.observeField("done", "onPerfilResponse")
end sub

function StartLoading() as Void
    m.perfilTask.authToken = m.top.authToken
    m.perfilTask.uri = ApiBase() + "/roku-perfil"
    m.perfilTask.method = "GET"
    m.perfilTask.control = "RUN"
end function

' "Xh Ym" / "Xh" / "Xm" -- mismo formato que _buildStatsGrid() en
' evolucion_screen.dart de la app movil.
function FormatearMinutos(totalMin as Integer) as String
    horas = totalMin \ 60
    mins = totalMin mod 60
    if horas > 0
        if mins > 0 then return horas.ToStr() + "h " + mins.ToStr() + "m"
        return horas.ToStr() + "h"
    end if
    return mins.ToStr() + "m"
end function

sub onPerfilResponse(event as Object)
    result = event.GetData()
    m.loadingLabel.visible = false

    if result.code <> 200
        m.loadingLabel.visible = true
        m.loadingLabel.text = "No se pudo cargar. Presiona atras."
        return
    end if

    data = ParseJsonSafe(result.json)
    if data = invalid or data.progreso = invalid
        m.loadingLabel.visible = true
        m.loadingLabel.text = "Respuesta inesperada. Presiona atras."
        return
    end if

    p = data.progreso
    m.rachaValor.text = p.dias_consecutivos.ToStr()
    m.tiempoTotalValor.text = FormatearMinutos(Int(p.total_minutos))
    m.secuenciasUsadasValor.text = p.secuencias_usadas.ToStr()
    m.totalPilotajesValor.text = p.total_pilotajes.ToStr()
    m.sesionesValor.text = p.total_sesiones.ToStr()
    m.nivelValor.text = Int(p.nivel_energetico).ToStr()

    ' Tiempo de la sesion actual del canal (no viene del servidor -- se
    ' reinicia cada vez que se abre el canal, igual que AppTimeTracker en
    ' la app movil). MainScene.brs guarda el epoch de arranque en
    ' m.global al iniciar.
    if m.global.hasField("rokuSessionEpoch")
        ahoraEpoch = CreateObject("roDateTime").AsSeconds()
        minutosSesion = Int((ahoraEpoch - m.global.rokuSessionEpoch) / 60)
        m.tiempoSesionValor.text = FormatearMinutos(minutosSesion)
    else
        m.tiempoSesionValor.text = "0m"
    end if

    m.contenido.visible = true
    m.contenido.setFocus(true)
end sub

function RestoreFocus() as Void
    m.contenido.setFocus(true)
end function
