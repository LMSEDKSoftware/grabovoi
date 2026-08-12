' Tarjeta reutilizable (categorías, secuencias, favoritos). Ver el
' comentario del XML sobre la estrategia de imagen/color de respaldo.

sub init()
    m.focusBorder = m.top.findNode("focusBorder")
    m.background = m.top.findNode("background")
    m.image = m.top.findNode("image")
    m.scrim = m.top.findNode("scrim")
    m.titleLabel = m.top.findNode("titleLabel")
    m.subtitleLabel = m.top.findNode("subtitleLabel")
end sub

sub onSizeChanged()
    w = m.top.width
    h = m.top.height
    if w = invalid or h = invalid or w = 0 or h = 0
        return
    end if

    margen = 6
    m.focusBorder.translation = [-margen, -margen]
    m.focusBorder.width = w + margen * 2
    m.focusBorder.height = h + margen * 2

    m.background.width = w
    m.background.height = h
    m.image.width = w
    m.image.height = h

    scrimAltura = h * 0.42
    m.scrim.translation = [0, h - scrimAltura]
    m.scrim.width = w
    m.scrim.height = scrimAltura

    padding = 14
    m.titleLabel.translation = [padding, h - scrimAltura + 10]
    m.titleLabel.width = w - padding * 2

    m.subtitleLabel.translation = [padding, h - 24]
    m.subtitleLabel.width = w - padding * 2

    RenderContent()
end sub

sub onContentChanged()
    RenderContent()
end sub

sub RenderContent()
    content = m.top.itemContent
    if content = invalid
        return
    end if

    if content.title <> invalid
        m.titleLabel.text = content.title
    end if
    if content.subtitle <> invalid
        m.subtitleLabel.text = content.subtitle
    else
        m.subtitleLabel.text = ""
    end if

    color = "#1C2541"
    if content.color <> invalid and content.color <> ""
        color = content.color
    end if
    m.background.color = color

    if content.imageUrl <> invalid and content.imageUrl <> ""
        m.image.uri = content.imageUrl
        m.image.visible = true
    else
        m.image.visible = false
    end if
end sub

sub onFocusChanged()
    m.focusBorder.visible = m.top.itemHasFocus
end sub
