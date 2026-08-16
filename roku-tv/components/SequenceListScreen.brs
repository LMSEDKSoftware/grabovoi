sub init()
    m.grid = m.top.findNode("grid")
    m.grid.observeField("itemSelected", "onItemSelected")
    m.loadingLabel = m.top.findNode("loadingLabel")
    m.countLabel = m.top.findNode("countLabel")
    m.grid.visible = false
end sub

function StartLoading() as Void
    m.countLabel.text = ""
    m.catalogTask = m.top.findNode("catalogTask")
    m.catalogTask.observeField("done", "onCatalogResponse")
    m.catalogTask.authToken = m.top.authToken

    if m.top.endpointUri <> invalid and m.top.endpointUri <> ""
        m.top.findNode("title").text = m.top.titulo
        m.catalogTask.uri = m.top.endpointUri
    else
        m.top.findNode("title").text = m.top.categoria
        categoriaEscapada = UrlEncode(m.top.categoria)
        ' 1000 en vez de 100: categorias como "Salud" tienen 627
        ' secuencias, el limite viejo dejaba fuera todo lo que pasara de
        ' las primeras 100 (bug reportado). 1000 es tambien el tope real
        ' de Supabase/PostgREST por consulta, no tiene sentido pedir mas.
        m.catalogTask.uri = ApiBase() + "/roku-catalog?categoria=" + categoriaEscapada + "&limit=1000"
    end if

    m.catalogTask.method = "GET"
    print "SequenceListScreen StartLoading uri="; m.catalogTask.uri
    m.catalogTask.control = "RUN"
end function

sub onCatalogResponse(event as Object)
    result = event.GetData()
    print "SequenceListScreen onCatalogResponse code="; result.code; " json_len="; Len(result.json)
    m.loadingLabel.visible = false
    if result.code <> 200
        m.loadingLabel.visible = true
        m.loadingLabel.text = "No se pudo cargar. Presiona atras."
        return
    end if

    data = ParseJsonSafe(result.json)
    if data = invalid or data.secuencias = invalid
        ' Antes esto se quedaba en blanco sin avisar nada (parecia
        ' congelado: ni el "Cargando..." ni un mensaje de error). Ahora
        ' al menos se ve que algo fallo.
        print "SequenceListScreen respuesta invalida o sin 'secuencias'. json="; result.json
        m.loadingLabel.visible = true
        m.loadingLabel.text = "Respuesta inesperada del servidor."
        return
    end if

    m.sequenceIds = []
    root = CreateObject("roSGNode", "ContentNode")
    for each seq in data.secuencias
        imagen = ""
        if seq.imagen_url <> invalid then imagen = seq.imagen_url
        node = root.CreateChild("ContentNode")
        node.AddFields({
            title: seq.nombre,
            subtitle: seq.codigo,
            color: seq.color,
            imageUrl: imagen
        })
        m.sequenceIds.Push(seq.id)
    end for

    m.countLabel.text = m.sequenceIds.Count().ToStr() + " secuencias"

    if m.sequenceIds.Count() = 0
        m.loadingLabel.visible = true
        if m.top.endpointUri <> invalid and m.top.endpointUri <> ""
            m.loadingLabel.text = "Todavia no hay nada aqui."
        else
            m.loadingLabel.text = "No hay secuencias en esta categoria."
        end if
        return
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
    if index < 0 or index >= m.sequenceIds.Count()
        return
    end if
    m.top.result = { action: "openSequence", id: m.sequenceIds[index] }
end sub
