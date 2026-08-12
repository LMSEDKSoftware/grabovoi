sub init()
    m.grid = m.top.findNode("grid")
    m.grid.observeField("itemSelected", "onItemSelected")
    m.loadingLabel = m.top.findNode("loadingLabel")
    m.grid.visible = false
end sub

function StartLoading() as Void
    m.top.findNode("title").text = m.top.categoria

    escaper = CreateObject("roUrlTransfer")
    categoriaEscapada = escaper.Escape(m.top.categoria)

    m.catalogTask = m.top.findNode("catalogTask")
    m.catalogTask.observeField("done", "onCatalogResponse")
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
        node.AddFields({
            title: seq.nombre,
            subtitle: seq.codigo,
            color: seq.color,
            imageUrl: ""
        })
        m.sequenceIds.Push(seq.id)
    end for

    if m.sequenceIds.Count() = 0
        m.loadingLabel.visible = true
        m.loadingLabel.text = "No hay secuencias en esta categoria."
        return
    end if

    m.grid.content = root
    m.grid.visible = true
    m.grid.setFocus(true)
end sub

sub onItemSelected()
    index = m.grid.itemSelected
    if index < 0 or index >= m.sequenceIds.Count()
        return
    end if
    m.top.result = { action: "openSequence", id: m.sequenceIds[index] }
end sub
