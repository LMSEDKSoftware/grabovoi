sub init()
    m.menu = m.top.findNode("menu")
    m.menu.observeField("itemSelected", "onMenuSelected")
    m.loadingLabel = m.top.findNode("loadingLabel")
    m.menu.visible = false

    m.catalogTask = m.top.findNode("catalogTask")
    m.catalogTask.observeField("done", "onCatalogResponse")
end sub

function StartLoading() as Void
    m.top.findNode("title").text = m.top.categoria

    escaper = CreateObject("roUrlTransfer")
    categoriaEscapada = escaper.Escape(m.top.categoria)

    m.catalogTask.authToken = m.top.authToken
    m.catalogTask.uri = ApiBase() + "/roku-catalog?categoria=" + categoriaEscapada + "&limit=100"
    m.catalogTask.method = "GET"
    m.catalogTask.control = "RUN"
end function

sub onCatalogResponse(event as Object)
    result = event.GetData()
    m.loadingLabel.visible = false
    if result.code <> 200
        m.loadingLabel.visible = true
        m.loadingLabel.text = "No se pudo cargar la categoria."
        return
    end if

    data = ParseJsonSafe(result.json)
    if data = invalid or data.secuencias = invalid
        return
    end if

    m.sequenceIds = []
    root = CreateObject("roSGNode", "ContentNode")
    for each seq in data.secuencias
        node = root.CreateChild("ContentNode")
        node.title = seq.nombre
        m.sequenceIds.Push(seq.id)
    end for

    if m.sequenceIds.Count() = 0
        m.loadingLabel.visible = true
        m.loadingLabel.text = "No hay secuencias en esta categoria."
        return
    end if

    m.menu.content = root
    m.menu.visible = true
    m.menu.setFocus(true)
end sub

sub onMenuSelected()
    index = m.menu.itemSelected
    if index < 0 or index >= m.sequenceIds.Count()
        return
    end if
    m.top.result = { action: "openSequence", id: m.sequenceIds[index] }
end sub
