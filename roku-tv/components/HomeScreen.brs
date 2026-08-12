sub init()
    m.rows = m.top.findNode("rows")
    m.rows.observeField("rowItemSelected", "onRowItemSelected")
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

    m.rowsData = []
    root = CreateObject("roSGNode", "ContentNode")

    if data.secuencia_del_dia <> invalid and data.secuencia_del_dia.id <> invalid
        AddRow(root, "Tu secuencia del dia", [{
            title: data.secuencia_del_dia.nombre,
            subtitle: "Repetir ahora",
            color: "#FFD700",
            imageUrl: "",
            kind: "sequence",
            id: data.secuencia_del_dia.id
        }])
    end if

    if data.favoritos.Count() > 0
        items = []
        for each fav in data.favoritos
            items.Push({ title: fav.nombre, subtitle: fav.categoria, color: "#8338EC", imageUrl: "", kind: "sequence", id: fav.id })
        end for
        AddRow(root, "Tus favoritas", items)
    end if

    if data.continuar.Count() > 0
        items = []
        for each c in data.continuar
            items.Push({ title: c.code_name, subtitle: c.usage_count.ToStr() + " veces", color: "#1E90FF", imageUrl: "", kind: "sequence", id: c.code_id })
        end for
        AddRow(root, "Continuar", items)
    end if

    AddRow(root, "Mas", [
        { title: "Explorar por categoria", subtitle: "", color: "#00CED1", imageUrl: "", kind: "categories", id: "" },
        { title: "Cerrar sesion", subtitle: "", color: "#555555", imageUrl: "", kind: "logout", id: "" }
    ])

    print "HomeScreen filas construidas: "; m.rowsData.Count(); " | root hijos: "; root.GetChildCount()
    for i = 0 to root.GetChildCount() - 1
        fila = root.GetChild(i)
        print "  fila "; i; " titulo="; fila.title; " items="; fila.GetChildCount()
    end for

    m.rows.content = root
    m.rows.visible = true
    m.rows.setFocus(true)
    print "HomeScreen m.rows.content asignado, visible=true"
end sub

sub AddRow(root as Object, titulo as String, items as Object)
    row = root.CreateChild("ContentNode")
    row.title = titulo
    fila = []
    for each it in items
        node = row.CreateChild("ContentNode")
        node.AddFields({ title: it.title, subtitle: it.subtitle, color: it.color, imageUrl: it.imageUrl })
        fila.Push({ kind: it.kind, id: it.id })
    end for
    m.rowsData.Push(fila)
end sub

sub onRowItemSelected(event as Object)
    indices = event.GetData()
    rowIndex = indices[0]
    itemIndex = indices[1]
    if rowIndex < 0 or rowIndex >= m.rowsData.Count()
        return
    end if
    fila = m.rowsData[rowIndex]
    if itemIndex < 0 or itemIndex >= fila.Count()
        return
    end if
    item = fila[itemIndex]

    if item.kind = "sequence"
        m.top.result = { action: "openSequence", id: item.id }
    else if item.kind = "categories"
        m.top.result = { action: "openCategories" }
    else if item.kind = "logout"
        m.top.result = { action: "logout" }
    end if
end sub
