sub init()
    m.heroGrid = m.top.findNode("heroGrid")
    m.heroGrid.observeField("itemSelected", "onHeroItemSelected")
    m.favoritasTitle = m.top.findNode("favoritasTitle")
    m.favoritasGrid = m.top.findNode("favoritasGrid")
    m.favoritasGrid.observeField("itemSelected", "onFavoritaItemSelected")
    m.recientesTitle = m.top.findNode("recientesTitle")
    m.recientesGrid = m.top.findNode("recientesGrid")
    m.recientesGrid.observeField("itemSelected", "onRecienteItemSelected")
    m.fraseLabel = m.top.findNode("fraseLabel")
    m.progressLabel = m.top.findNode("progressLabel")
    m.loadingLabel = m.top.findNode("loadingLabel")
    m.heroGrid.visible = false
    m.favoritasTitle.visible = false
    m.favoritasGrid.visible = false
    m.recientesTitle.visible = false
    m.recientesGrid.visible = false

    m.hasHero = false
    m.focusZone = "hero"
    m.heroId = invalid
    m.favoritosIds = []
    m.recientesIds = []

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
    if SesionVencida(m.top, result) then return
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

    frase = "La energía fluye contigo. Cada día es más poderoso."
    if data.frase_del_dia <> invalid and data.frase_del_dia <> "" then frase = data.frase_del_dia
    m.fraseLabel.text = frase

    p = data.progreso
    m.progressLabel.text = "Racha: " + p.dias_consecutivos.ToStr() + " dias | Cristales: " + p.cristales_energia.ToStr() + " | Nivel: " + Int(p.nivel_energetico).ToStr() + "%"

    ' "Tu secuencia diaria" -- sin cambios de diseño, solo se movio a su
    ' propia grilla de 1x1 (antes vivia junto con favoritas/continuar en
    ' una sola lista vertical).
    m.hasHero = false
    m.heroId = invalid
    heroRoot = CreateObject("roSGNode", "ContentNode")
    if data.secuencia_del_dia <> invalid and data.secuencia_del_dia.id <> invalid
        dia = data.secuencia_del_dia
        colorDia = "#13213B"
        if dia.color <> invalid and dia.color <> "" then colorDia = dia.color
        imagenDia = ""
        if dia.imagen_url <> invalid then imagenDia = dia.imagen_url
        item = heroRoot.CreateChild("ContentNode")
        item.AddFields({ title: dia.nombre, subtitle: "Selecciona para pilotar", numero: dia.codigo, color: colorDia, imageUrl: imagenDia, destacada: true })
        m.hasHero = true
        m.heroId = dia.id
    end if
    m.heroGrid.content = heroRoot
    m.heroGrid.visible = m.hasHero

    ' "Tus favoritas": slider horizontal (mas items que columnas visibles
    ' = se desplaza solo hacia el lado).
    m.favoritosIds = []
    favoritasRoot = CreateObject("roSGNode", "ContentNode")
    for each fav in data.favoritos
        colorFav = "#13213B"
        if fav.color <> invalid and fav.color <> "" then colorFav = fav.color
        imagenFav = ""
        if fav.imagen_url <> invalid then imagenFav = fav.imagen_url
        item = favoritasRoot.CreateChild("ContentNode")
        item.AddFields({ title: fav.nombre, subtitle: fav.codigo, color: colorFav, imageUrl: imagenFav })
        m.favoritosIds.Push(fav.id)
    end for
    m.favoritasGrid.content = favoritasRoot
    m.favoritasTitle.visible = (m.favoritosIds.Count() > 0)
    m.favoritasGrid.visible = (m.favoritosIds.Count() > 0)

    ' "Recientes": mismo patron.
    m.recientesIds = []
    recientesRoot = CreateObject("roSGNode", "ContentNode")
    for each c in data.continuar
        colorC = "#13213B"
        if c.color <> invalid and c.color <> "" then colorC = c.color
        imagenC = ""
        if c.imagen_url <> invalid then imagenC = c.imagen_url
        codigoC = ""
        if c.codigo <> invalid then codigoC = c.codigo
        item = recientesRoot.CreateChild("ContentNode")
        item.AddFields({ title: c.code_name, subtitle: codigoC, color: colorC, imageUrl: imagenC })
        m.recientesIds.Push(c.code_id)
    end for
    m.recientesGrid.content = recientesRoot
    m.recientesTitle.visible = (m.recientesIds.Count() > 0)
    m.recientesGrid.visible = (m.recientesIds.Count() > 0)

    ' "Explorar por categoria" y "Cerrar sesion" ya no van aqui como
    ' filas -- ahora viven en el sidebar ("Biblioteca cuantica" y
    ' "Cerrar sesion"), que es permanente en todas las pantallas
    ' autenticadas.

    RestoreFocus()
end sub

function RestoreFocus() as Void
    if m.hasHero
        m.focusZone = "hero"
        m.heroGrid.setFocus(true)
    else if m.favoritosIds.Count() > 0
        m.focusZone = "favoritas"
        m.favoritasGrid.setFocus(true)
    else
        m.focusZone = "recientes"
        m.recientesGrid.setFocus(true)
    end if
end function

sub onHeroItemSelected()
    if m.heroId <> invalid
        m.top.result = { action: "openSequence", id: m.heroId }
    end if
end sub

sub onFavoritaItemSelected()
    index = m.favoritasGrid.itemSelected
    if index >= 0 and index < m.favoritosIds.Count()
        m.top.result = { action: "openSequence", id: m.favoritosIds[index] }
    end if
end sub

sub onRecienteItemSelected()
    index = m.recientesGrid.itemSelected
    if index >= 0 and index < m.recientesIds.Count()
        m.top.result = { action: "openSequence", id: m.recientesIds[index] }
    end if
end sub

' "Abajo"/"arriba" se mueven entre la tarjeta destacada y los dos
' sliders. Solo llega aqui cuando la grilla enfocada ya no tiene a donde
' moverse en esa direccion por su cuenta (mismo patron que left/right
' del sidebar en MainScene.brs).
function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if key = "down"
        if m.focusZone = "hero" and m.favoritosIds.Count() > 0
            m.focusZone = "favoritas"
            m.favoritasGrid.setFocus(true)
            return true
        else if m.focusZone = "hero" and m.recientesIds.Count() > 0
            m.focusZone = "recientes"
            m.recientesGrid.setFocus(true)
            return true
        else if m.focusZone = "favoritas" and m.recientesIds.Count() > 0
            m.focusZone = "recientes"
            m.recientesGrid.setFocus(true)
            return true
        end if
    end if

    if key = "up"
        if m.focusZone = "recientes" and m.favoritosIds.Count() > 0
            m.focusZone = "favoritas"
            m.favoritasGrid.setFocus(true)
            return true
        else if (m.focusZone = "recientes" or m.focusZone = "favoritas") and m.hasHero
            m.focusZone = "hero"
            m.heroGrid.setFocus(true)
            return true
        end if
    end if

    return false
end function
