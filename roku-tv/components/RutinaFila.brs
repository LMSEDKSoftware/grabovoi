sub init()
    m.borde = m.top.findNode("borde")
    m.fondo = m.top.findNode("fondo")
    m.nombre = m.top.findNode("nombre")
    m.total = m.top.findNode("total")
    Layout(700, 86)
    RenderContent()
end sub

sub onSizeChanged()
    w = m.top.width
    h = m.top.height
    if w = invalid or h = invalid or w = 0 or h = 0
        return
    end if
    Layout(w, h)
end sub

sub Layout(w as Float, h as Float)
    m.borde.width = w
    m.borde.height = h
    m.fondo.width = w - 4
    m.fondo.height = h - 4
    m.nombre.width = w - 48
    m.total.width = w - 48
end sub

sub onContentChanged()
    RenderContent()
end sub

sub RenderContent()
    content = m.top.itemContent
    if content = invalid then return

    if content.hasField("title") and content.title <> invalid
        m.nombre.text = content.title
    else
        m.nombre.text = ""
    end if

    if content.hasField("descripcion") and content.descripcion <> invalid
        m.total.text = content.descripcion
    else
        m.total.text = ""
    end if
end sub

sub onFocusChanged()
    ' Mismo indicador que las tarjetas de sugerencia del reproductor: el
    ' borde dorado aparece y desaparece, sin rellenar la fila.
    if m.top.itemHasFocus
        m.borde.opacity = 1
    else
        m.borde.opacity = 0
    end if
end sub
