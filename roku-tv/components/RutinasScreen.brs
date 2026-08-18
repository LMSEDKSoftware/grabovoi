' Lista de combinaciones guardadas ("Secuencias Combinadas"). Cada una se
' reproduce completa, una secuencia tras otra, sin que haya que tocar el
' control entre medias (ver la cola en PlayerScreen.brs).
'
' Los identificadores internos siguen diciendo "rutina" porque asi se
' llaman las tablas desde la primera migracion; solo cambia lo que lee
' el usuario. Ver el comentario del XML.

sub init()
    m.grid = m.top.findNode("grid")
    m.grid.observeField("itemSelected", "onRutinaSeleccionada")
    m.loadingLabel = m.top.findNode("loadingLabel")
    m.conteo = m.top.findNode("conteo")
    m.ayuda = m.top.findNode("ayuda")

    m.rutinasTask = m.top.findNode("rutinasTask")
    m.rutinasTask.observeField("done", "onRutinasResponse")
    m.borrarTask = m.top.findNode("borrarTask")
    m.borrarTask.observeField("done", "onBorrarResponse")

    m.rutinas = []
end sub

function StartLoading() as Void
    m.loadingLabel.visible = true
    m.loadingLabel.text = "Cargando..."
    m.rutinasTask.authToken = m.top.authToken
    m.rutinasTask.uri = ApiBase() + "/roku-perfil?rutinas=1"
    m.rutinasTask.method = "GET"
    m.rutinasTask.control = "RUN"
end function

function RestoreFocus() as Void
    m.grid.setFocus(true)
end function

sub onRutinasResponse(event as Object)
    result = event.GetData()
    if SesionVencida(m.top, result) then return

    if result.code <> 200
        m.loadingLabel.visible = true
        m.loadingLabel.text = "No se pudieron cargar tus combinaciones. Presiona atras."
        return
    end if

    data = ParseJsonSafe(result.json)
    if data = invalid or data.rutinas = invalid
        m.loadingLabel.visible = true
        m.loadingLabel.text = "Respuesta inesperada. Presiona atras."
        return
    end if

    m.rutinas = data.rutinas
    Pintar()
end sub

sub Pintar()
    cuantas = m.rutinas.Count()
    m.conteo.text = TextoConteo(cuantas)

    if cuantas = 0
        ' Los pasos ya estan en el panel de la derecha, que se queda
        ' visible tambien cuando no hay nada: aqui basta con apuntar a el.
        m.loadingLabel.visible = true
        m.loadingLabel.text = "Todavía no has armado ninguna combinación." + Chr(10) + Chr(10) + "Sigue los pasos de la derecha para crear la primera."
        m.ayuda.visible = false
        m.grid.visible = false
        return
    end if

    m.loadingLabel.visible = false
    m.ayuda.visible = true
    m.grid.visible = true

    root = CreateObject("roSGNode", "ContentNode")
    for each rutina in m.rutinas
        item = root.CreateChild("ContentNode")
        item.title = rutina.nombre
        ' "descripcion" no es un campo propio de ContentNode: hay que
        ' declararlo, igual que hace SequenceListScreen con imageUrl.
        ' Asignarlo directo no lo crearia y RutinaFila lo leeria vacio.
        item.AddFields({ descripcion: TextoSecuencias(rutina.total) })
    end for
    m.grid.content = root
    m.grid.setFocus(true)
end sub

function TextoConteo(cuantas as Integer) as String
    if cuantas = 1 then return "1 combinación"
    return cuantas.ToStr() + " combinaciones"
end function

function TextoSecuencias(cuantas as Dynamic) as String
    if cuantas = invalid then return ""
    if cuantas = 1 then return "1 secuencia"
    return cuantas.ToStr() + " secuencias"
end function

sub onRutinaSeleccionada()
    index = m.grid.itemSelected
    if index < 0 or index >= m.rutinas.Count() then return
    m.top.result = { action: "openRutina", id: m.rutinas[index].id, nombre: m.rutinas[index].nombre }
end sub

sub BorrarSeleccionada()
    index = m.grid.itemFocused
    if index < 0 or index >= m.rutinas.Count() then return

    dialogo = CreateObject("roSGNode", "Dialog")
    dialogo.title = "Borrar combinación"
    dialogo.message = "¿Seguro que quieres borrar " + Chr(34) + m.rutinas[index].nombre + Chr(34) + "? Las secuencias no se borran, solo la combinación."
    dialogo.buttons = ["Borrar", "Cancelar"]
    dialogo.observeField("buttonSelected", "onBorrarConfirmado")
    m.indicePorBorrar = index
    m.dialogo = dialogo
    m.top.getScene().dialog = dialogo
end sub

sub onBorrarConfirmado(event as Object)
    boton = event.GetData()
    m.top.getScene().dialog = invalid
    if boton <> 0 then return

    m.borrarTask.authToken = m.top.authToken
    m.borrarTask.uri = ApiBase() + "/roku-perfil"
    m.borrarTask.method = "POST"
    m.borrarTask.body = FormatJson({ action: "rutina_borrar", id: m.rutinas[m.indicePorBorrar].id })
    m.borrarTask.control = "RUN"
end sub

sub onBorrarResponse(event as Object)
    result = event.GetData()
    if SesionVencida(m.top, result) then return
    ' Se recarga desde el servidor en vez de quitar la fila a mano: es la
    ' unica forma de que la pantalla refleje lo que de verdad quedo.
    StartLoading()
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if key = "options" and m.rutinas.Count() > 0
        BorrarSeleccionada()
        return true
    end if

    return false
end function
