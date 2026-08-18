sub init()
    m.grid = m.top.findNode("grid")
    m.grid.observeField("itemSelected", "onItemSelected")
    m.estadoLabel = m.top.findNode("estadoLabel")
    m.countLabel = m.top.findNode("countLabel")
    m.grid.visible = false

    m.catalogTask = m.top.findNode("catalogTask")
    m.catalogTask.observeField("done", "onCatalogResponse")

    m.terminoActual = invalid
end sub

function StartLoading() as Void
    ShowKeyboard()
end function

sub ShowKeyboard()
    ' StandardKeyboardDialog en todo el canal, aunque aqui no se escriban
    ' credenciales: tener dos teclados distintos segun la pantalla es
    ' peor que unificar, y este ademas admite dictado por voz.
    kb = CreateObject("roSGNode", "StandardKeyboardDialog")
    kb.title = "¿Qué quieres buscar?"
    if m.terminoActual <> invalid then kb.text = m.terminoActual
    kb.buttons = ["Buscar", "Cancelar"]
    kb.observeField("buttonSelected", "onKeyboardButton")
    m.pendingKeyboard = kb
    m.top.getScene().dialog = kb
end sub

sub onKeyboardButton(event as Object)
    index = event.GetData()
    texto = ""
    if index = 0 then texto = m.pendingKeyboard.text.Trim()
    m.top.getScene().dialog = invalid

    if texto <> ""
        m.terminoActual = texto
        EjecutarBusqueda(texto)
    else if m.terminoActual = invalid
        ' Cancelo (o no escribio nada) antes de buscar por primera vez --
        ' no hay nada que mostrar aqui, se vuelve a Home.
        m.top.result = { action: "back" }
    end if
end sub

sub EjecutarBusqueda(texto as String)
    m.estadoLabel.text = "Buscando..."
    m.countLabel.text = ""
    m.grid.visible = false

    m.catalogTask.authToken = m.top.authToken
    m.catalogTask.uri = ApiBase() + "/roku-catalog?q=" + UrlEncode(texto) + "&limit=1000"
    m.catalogTask.method = "GET"
    m.catalogTask.control = "RUN"
end sub

sub onCatalogResponse(event as Object)
    result = event.GetData()
    if result.code <> 200
        m.estadoLabel.text = "No se pudo buscar. Presiona atras."
        return
    end if

    data = ParseJsonSafe(result.json)
    if data = invalid or data.secuencias = invalid
        m.estadoLabel.text = "Respuesta inesperada. Presiona atras."
        return
    end if

    m.items = []
    root = CreateObject("roSGNode", "ContentNode")

    buscarItem = root.CreateChild("ContentNode")
    buscarItem.AddFields({ title: "Buscar de nuevo", subtitle: "Termino actual: " + m.terminoActual, color: "#0C1830", imageUrl: "" })
    m.items.Push({ kind: "buscar", id: "" })

    for each seq in data.secuencias
        imagen = ""
        if seq.imagen_url <> invalid then imagen = seq.imagen_url
        node = root.CreateChild("ContentNode")
        node.AddFields({ title: seq.nombre, subtitle: seq.codigo, color: seq.color, imageUrl: imagen })
        m.items.Push({ kind: "sequence", id: seq.id })
    end for

    m.countLabel.text = data.secuencias.Count().ToStr() + " resultados"

    if data.secuencias.Count() = 0
        m.estadoLabel.text = "Sin resultados para: " + m.terminoActual + ". Selecciona Buscar de nuevo para intentar otra palabra."
    else
        m.estadoLabel.text = "Resultados para: " + m.terminoActual
    end if

    m.grid.content = root
    m.grid.visible = true
    m.grid.setFocus(true)
end sub

function RestoreFocus() as Void
    m.grid.setFocus(true)
end function

sub onItemSelected()
    index = m.grid.itemSelected
    if index < 0 or index >= m.items.Count()
        return
    end if
    item = m.items[index]

    if item.kind = "buscar"
        ShowKeyboard()
    else if item.kind = "sequence"
        m.top.result = { action: "openSequence", id: item.id }
    end if
end sub
