sub init()
    m.loadingLabel = m.top.findNode("loadingLabel")
    m.contenido = m.top.findNode("contenido")
    m.emailValor = m.top.findNode("emailValor")
    m.miembroDesdeValor = m.top.findNode("miembroDesdeValor")
    m.resumenValor = m.top.findNode("resumenValor")

    m.perfilTask = m.top.findNode("perfilTask")
    m.perfilTask.observeField("done", "onPerfilResponse")
end sub

function StartLoading() as Void
    m.perfilTask.authToken = m.top.authToken
    m.perfilTask.uri = ApiBase() + "/roku-perfil"
    m.perfilTask.method = "GET"
    m.perfilTask.control = "RUN"
end function

sub onPerfilResponse(event as Object)
    result = event.GetData()
    if SesionVencida(m.top, result) then return
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

    correo = ""
    if data.email <> invalid then correo = data.email
    m.emailValor.text = correo

    fecha = ""
    if data.miembro_desde <> invalid then fecha = FormatearFechaCorta(data.miembro_desde)
    if fecha <> ""
        m.miembroDesdeValor.text = "Miembro desde " + fecha
    else
        m.miembroDesdeValor.text = ""
    end if

    p = data.progreso
    m.resumenValor.text = "Racha de " + p.dias_consecutivos.ToStr() + " dias  -  Nivel " + Int(p.nivel_energetico).ToStr() + "%  -  " + p.cristales_energia.ToStr() + " cristales de energia  -  " + p.total_pilotajes.ToStr() + " secuencias pilotadas"

    m.contenido.visible = true
    m.contenido.setFocus(true)
end sub

function RestoreFocus() as Void
    m.contenido.setFocus(true)
end function
