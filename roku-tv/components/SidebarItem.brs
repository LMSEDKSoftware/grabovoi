sub init()
    m.label = m.top.findNode("label")
    m.colorNormal = "#B9C4D8"
    Layout(230, 44)
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
    m.label.translation = [10, h / 2 - 12]
    m.label.width = w - 20
end sub

sub onContentChanged()
    RenderContent()
end sub

sub RenderContent()
    content = m.top.itemContent
    if content = invalid then return

    if content.hasField("title") and content.title <> invalid
        m.label.text = content.title
    else
        m.label.text = ""
    end if

    m.colorNormal = "#B9C4D8"
    if content.hasField("color") and content.color <> invalid and content.color <> ""
        m.colorNormal = content.color
    end if
    m.label.color = m.colorNormal
end sub

sub onFocusChanged()
    ' Sin rectangulo propio: solo el color del texto cambia, igual que el
    ' LabelList original (focusedColor="#0C1830"). El recuadro de foco lo
    ' pone Roku automaticamente.
    if m.top.itemHasFocus
        m.label.color = "#0C1830"
    else
        m.label.color = m.colorNormal
    end if
end sub
