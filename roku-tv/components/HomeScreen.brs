sub init()
    m.rows = m.top.findNode("rows")
    m.rows.observeField("itemSelected", "onItemSelected")
    m.progressLabel = m.top.findNode("progressLabel")
    m.loadingLabel = m.top.findNode("loadingLabel")
    m.rows.visible = false

    m.homeTask = m.top.findNode("homeTask")
    m.homeTask.observeField("done", "onHomeResponse")
end sub

function StartLoading() as Void
    m.homeTask.authToken = m.top.authToken
    m.homeTask.uri = ApiBase() + "/roku-home"
    m.homeTask.method = "GET"
    m.homeTask.control = "RUN"
end function

sub onHomeResponse(event as Object)
    result = event.GetData()
    m.loadingLabel.visible = false

    if result.code <> 200
        m.progressLabel.text = "No se pudo cargar tu cuenta. Intenta de nuevo."
        return
    end if

    data = ParseJsonSafe(result.json)
    if data = invalid
        m.progressLabel.text = "Respuesta inesperada del servidor."
        return
    end if

    p = data.progreso
    m.progressLabel.text = "Racha: " + p.dias_consecutivos.ToStr() + " dias | Cristales: " + p.cristales_energia.ToStr() + " | Nivel: " + Int(p.nivel_energetico).ToStr() + "%"

    m.items = []
    root = CreateObject("roSGNode", "ContentNode")

    if data.secuencia_del_dia <> invalid and data.secuencia_del_dia.id <> invalid
        dia = data.secuencia_del_dia
        colorDia = "#13213B"
        if dia.color <> invalid and dia.color <> "" then colorDia = dia.color
        imagenDia = ""
        if dia.imagen_url <> invalid then imagenDia = dia.imagen_url
        AddItem(root, { title: dia.nombre, subtitle: "Tu secuencia de hoy - repetir ahora", numero: dia.codigo, color: colorDia, imageUrl: imagenDia, kind: "sequence", id: dia.id })
    end if

    if data.favoritos.Count() > 0
        for each fav in data.favoritos
            colorFav = "#13213B"
            if fav.color <> invalid and fav.color <> "" then colorFav = fav.color
            imagenFav = ""
            if fav.imagen_url <> invalid then imagenFav = fav.imagen_url
            AddItem(root, { title: fav.nombre, subtitle: "Favorita - " + fav.categoria, numero: fav.codigo, color: colorFav, imageUrl: imagenFav, kind: "sequence", id: fav.id })
        end for
    end if

    if data.continuar.Count() > 0
        for each c in data.continuar
            AddItem(root, { title: c.code_name, subtitle: "Continuar - " + c.usage_count.ToStr() + " veces", numero: "", color: "#13213B", imageUrl: "", kind: "sequence", id: c.code_id })
        end for
    end if

    AddItem(root, { title: "Explorar por categoria", subtitle: "Ver toda la biblioteca", numero: "", color: "#0C1830", imageUrl: "", kind: "categories", id: "" })
    AddItem(root, { title: "Cerrar sesion", subtitle: "", numero: "", color: "#0C1830", imageUrl: "", kind: "logout", id: "" })

    m.rows.content = root
    m.rows.visible = true
    m.rows.setFocus(true)
end sub

sub AddItem(root as Object, it as Object)
    node = root.CreateChild("ContentNode")
    node.AddFields({ title: it.title, subtitle: it.subtitle, numero: it.numero, color: it.color, imageUrl: it.imageUrl })
    m.items.Push({ kind: it.kind, id: it.id })
end sub

sub onItemSelected()
    index = m.rows.itemSelected
    if index < 0 or index >= m.items.Count()
        return
    end if
    item = m.items[index]

    if item.kind = "sequence"
        m.top.result = { action: "openSequence", id: item.id }
    else if item.kind = "categories"
        m.top.result = { action: "openCategories" }
    else if item.kind = "logout"
        m.top.result = { action: "logout" }
    end if
end sub
