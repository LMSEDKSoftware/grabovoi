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
    print "CategoryScreen StartLoading uri="; m.catalogTask.uri
    m.catalogTask.control = "RUN"
end function

sub onCatalogResponse(event as Object)
    result = event.GetData()
    print "CategoryScreen onCatalogResponse code="; result.code; " json_len="; Len(result.json)
    m.loadingLabel.visible = false
    if result.code <> 200
        print "CategoryScreen error, json="; result.json
        m.loadingLabel.visible = true
        m.loadingLabel.text = "No se pudo cargar el catalogo. (codigo " + result.code.ToStr() + ")"
        return
    end if

    data = ParseJsonSafe(result.json)
    if data = invalid or data.categorias = invalid
        print "CategoryScreen respuesta invalida o sin 'categorias'. json="; result.json
        m.loadingLabel.visible = true
        m.loadingLabel.text = "Respuesta inesperada del servidor."
        return
    end if

    m.categoryNames = []
    root = CreateObject("roSGNode", "ContentNode")
    for each cat in data.categorias
        imagen = ""
        if cat.imagen_url <> invalid then imagen = cat.imagen_url
        node = root.CreateChild("ContentNode")
        node.AddFields({
            title: cat.nombre,
            subtitle: cat.total.ToStr() + " secuencias",
            color: cat.color,
            imageUrl: imagen
        })
        m.categoryNames.Push(cat.nombre)
    end for

    m.grid.content = root
    m.grid.visible = true
    m.grid.setFocus(true)
end sub

sub onItemSelected()
    index = m.grid.itemSelected
    print "CategoryScreen onItemSelected index="; index; " total="; m.categoryNames.Count()
    if index < 0 or index >= m.categoryNames.Count()
        return
    end if
    print "CategoryScreen abriendo categoria="; m.categoryNames[index]
    m.top.result = { action: "openCategory", categoria: m.categoryNames[index] }
end sub
