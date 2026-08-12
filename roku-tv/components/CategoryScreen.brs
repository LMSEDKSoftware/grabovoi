sub init()
    m.grid = m.top.findNode("grid")
    m.grid.observeField("itemSelected", "onItemSelected")
    m.loadingLabel = m.top.findNode("loadingLabel")
    m.grid.visible = false

    m.catalogTask = m.top.findNode("catalogTask")
    m.catalogTask.observeField("done", "onCatalogResponse")
end sub

function StartLoading() as Void
    m.catalogTask.authToken = m.top.authToken
    m.catalogTask.uri = ApiBase() + "/roku-catalog"
    m.catalogTask.method = "GET"
    m.catalogTask.control = "RUN"
end function

sub onCatalogResponse(event as Object)
    result = event.GetData()
    m.loadingLabel.visible = false
    if result.code <> 200
        m.loadingLabel.visible = true
        m.loadingLabel.text = "No se pudo cargar el catalogo."
        return
    end if

    data = ParseJsonSafe(result.json)
    if data = invalid or data.categorias = invalid
        return
    end if

    m.categoryNames = []
    root = CreateObject("roSGNode", "ContentNode")
    for each cat in data.categorias
        node = root.CreateChild("ContentNode")
        node.AddFields({
            title: cat.nombre,
            subtitle: cat.total.ToStr() + " secuencias",
            color: cat.color,
            imageUrl: ""
        })
        m.categoryNames.Push(cat.nombre)
    end for

    m.grid.content = root
    m.grid.visible = true
    m.grid.setFocus(true)
end sub

sub onItemSelected()
    index = m.grid.itemSelected
    if index < 0 or index >= m.categoryNames.Count()
        return
    end if
    m.top.result = { action: "openCategory", categoria: m.categoryNames[index] }
end sub
