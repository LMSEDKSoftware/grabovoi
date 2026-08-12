sub init()
    m.menu = m.top.findNode("menu")
    m.menu.observeField("itemSelected", "onMenuSelected")
    m.loadingLabel = m.top.findNode("loadingLabel")
    m.menu.visible = false

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
        node.title = cat.nombre + " (" + cat.total.ToStr() + ")"
        m.categoryNames.Push(cat.nombre)
    end for

    m.menu.content = root
    m.menu.visible = true
    m.menu.setFocus(true)
end sub

sub onMenuSelected()
    index = m.menu.itemSelected
    if index < 0 or index >= m.categoryNames.Count()
        return
    end if
    m.top.result = { action: "openCategory", categoria: m.categoryNames[index] }
end sub
