sub init()
    m.menu = m.top.findNode("menu")
    m.menu.observeField("itemSelected", "onMenuSelected")
    m.progressLabel = m.top.findNode("progressLabel")
    m.loadingLabel = m.top.findNode("loadingLabel")
    m.menu.visible = false

    m.homeTask = m.top.findNode("homeTask")
    m.homeTask.observeField("responseCode", "onHomeResponse")
    m.homeTask.authToken = m.top.authToken
    m.homeTask.uri = ApiBase() + "/roku-home"
    m.homeTask.method = "GET"
    m.homeTask.control = "RUN"
end sub

sub onHomeResponse(event as Object)
    code = event.GetData()
    m.loadingLabel.visible = false

    if code <> 200
        m.progressLabel.text = "No se pudo cargar tu cuenta. Intenta de nuevo."
        return
    end if

    data = ParseJsonSafe(m.homeTask.responseJson)
    if data = invalid
        m.progressLabel.text = "Respuesta inesperada del servidor."
        return
    end if

    p = data.progreso
    m.progressLabel.text = "Racha: " + p.dias_consecutivos.ToStr() + " dias | Cristales: " + p.cristales_energia.ToStr() + " | Nivel: " + Int(p.nivel_energetico).ToStr() + "%"

    m.menuData = []
    root = CreateObject("roSGNode", "ContentNode")

    if data.secuencia_del_dia <> invalid and data.secuencia_del_dia.id <> invalid
        AddItem(root, "Repetir secuencia del dia: " + data.secuencia_del_dia.nombre, "sequence", data.secuencia_del_dia.id)
    end if

    AddItem(root, "Explorar por categoria", "categories", "")

    for each fav in data.favoritos
        AddItem(root, "Favorita: " + fav.nombre, "sequence", fav.id)
    end for

    for each item in data.continuar
        AddItem(root, "Continuar: " + item.code_name, "sequence", item.code_id)
    end for

    AddItem(root, "Cerrar sesion", "logout", "")

    m.menu.content = root
    m.menu.visible = true
    m.menu.setFocus(true)
end sub

sub AddItem(root as Object, title as String, kind as String, id as String)
    node = root.CreateChild("ContentNode")
    node.title = title
    m.menuData.Push({ kind: kind, id: id })
end sub

sub onMenuSelected()
    index = m.menu.itemSelected
    if index < 0 or index >= m.menuData.Count()
        return
    end if
    item = m.menuData[index]
    if item.kind = "sequence"
        m.top.result = { action: "openSequence", id: item.id }
    else if item.kind = "categories"
        m.top.result = { action: "openCategories" }
    else if item.kind = "logout"
        m.top.result = { action: "logout" }
    end if
end sub
