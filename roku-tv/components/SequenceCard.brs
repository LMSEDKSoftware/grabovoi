' Tarjeta reutilizable (categorías, secuencias, favoritos). Ver el
' comentario del XML sobre la estrategia de imagen/color de respaldo.
'
' MarkupGrid sí asigna los campos width/height a cada tarjeta (según su
' propia documentación), pero RowList no lo garantiza igual — su propio
' ejemplo de renderizador de item ni siquiera declara esos campos. Sin
' ellos, background/scrim/labels se quedaban en tamaño 0: la tarjeta
' existía y se podía navegar, pero era invisible, mezclada con el fondo.
' Por eso el layout NO depende de que nos avisen el tamaño: se aplica
' un tamaño por defecto ya en init(), y si el tamaño real llega después,
' se vuelve a aplicar. 280x170 coincide con itemSize/rowItemSize de
' HomeScreen, CategoryScreen y SequenceListScreen.

sub init()
    print "SequenceCard init() arrancando"
    m.focusBorder = m.top.findNode("focusBorder")
    m.background = m.top.findNode("background")
    m.image = m.top.findNode("image")
    m.scrim = m.top.findNode("scrim")
    m.titleLabel = m.top.findNode("titleLabel")
    m.subtitleLabel = m.top.findNode("subtitleLabel")
    m.marcaFondo = m.top.findNode("marcaFondo")
    m.marcaLabel = m.top.findNode("marcaLabel")
    m.contenidoObservado = invalid
    m.subtitleAbajo = false
    print "SequenceCard nodos encontrados: focusBorder="; m.focusBorder <> invalid; " background="; m.background <> invalid; " titleLabel="; m.titleLabel <> invalid

    ' onChange="onContentChanged" ya esta declarado en el <field> del XML;
    ' un observeField() manual aqui duplicaba la llamada a RenderContent().

    Layout(280, 170)
    print "SequenceCard Layout(280,170) aplicado"
    RenderContent()
end sub

sub onSizeChanged()
    w = m.top.width
    h = m.top.height
    print "SequenceCard onSizeChanged w="; w; " h="; h
    if w = invalid or h = invalid or w = 0 or h = 0
        return
    end if
    Layout(w, h)
end sub

sub Layout(w as Float, h as Float)
    margen = 6
    m.focusBorder.translation = [-margen, -margen]
    m.focusBorder.width = w + margen * 2
    m.focusBorder.height = h + margen * 2

    m.background.width = w
    m.background.height = h
    m.image.width = w
    m.image.height = h

    padding = 14

    scrimAltura = h * 0.5
    m.scrim.translation = [0, h - scrimAltura]
    m.scrim.width = w
    m.scrim.height = scrimAltura

    if m.subtitleAbajo
        ' Categorias: el conteo ("N secuencias") va debajo del nombre,
        ' dentro del mismo recuadro -- arriba a la izquierda solo tiene
        ' sentido para el codigo de una secuencia individual, pedido
        ' explicito de separar ambos casos.
        m.titleLabel.translation = [padding, h - scrimAltura + 6]
        m.titleLabel.height = scrimAltura * 0.55
        m.subtitleLabel.translation = [padding, h - scrimAltura + scrimAltura * 0.55 + 2]
    else
        ' Codigo arriba a la izquierda, directo sobre la imagen (sin
        ' scrim); titulo abajo, hasta 2 lineas.
        m.subtitleLabel.translation = [padding, 8]
        m.titleLabel.translation = [padding, h - scrimAltura + 8]
        m.titleLabel.height = scrimAltura - 16
    end if
    m.titleLabel.width = w - padding * 2
    m.subtitleLabel.width = w - padding * 2

    lado = 34
    m.marcaFondo.translation = [w - lado - 8, 8]
    m.marcaFondo.width = lado
    m.marcaFondo.height = lado
    m.marcaLabel.translation = [w - lado - 8, 12]
    m.marcaLabel.width = lado
end sub

sub onContentChanged()
    print "SequenceCard onContentChanged disparado"
    RenderContent()
end sub

sub RenderContent()
    content = m.top.itemContent
    print "SequenceCard RenderContent content invalido="; content = invalid
    if content = invalid
        return
    end if
    print "SequenceCard RenderContent hasField(title)="; content.hasField("title"); " hasField(color)="; content.hasField("color"); " title="; content.title; " color="; content.color

    m.subtitleAbajo = false
    if content.hasField("subtitleAbajo") and content.subtitleAbajo = true then m.subtitleAbajo = true

    if content.hasField("title") and content.title <> invalid
        m.titleLabel.text = content.title
    else
        m.titleLabel.text = ""
    end if

    if content.hasField("subtitle") and content.subtitle <> invalid
        m.subtitleLabel.text = content.subtitle
    else
        m.subtitleLabel.text = ""
    end if

    color = "#13213B"
    if content.hasField("color") and content.color <> invalid and content.color <> ""
        color = content.color
    end if
    m.background.color = color

    if content.hasField("imageUrl") and content.imageUrl <> invalid and content.imageUrl <> ""
        m.image.uri = content.imageUrl
        m.image.visible = true
    else
        m.image.visible = false
    end if

    print "SequenceCard RenderContent aplicado. background.color="; m.background.color; " background.width="; m.background.width; " background.height="; m.background.height; " titleLabel.text="; m.titleLabel.text

    ' MarkupGrid recicla las tarjetas entre elementos, asi que hay que
    ' soltar el nodo anterior antes de escuchar el nuevo: si no, una
    ' tarjeta seguiria reaccionando a los cambios de una secuencia que ya
    ' no muestra.
    '
    ' Se observa el campo suelto y no basta con itemContent: cambiar
    ' "seleccionado" DENTRO del nodo no vuelve a disparar onContentChanged,
    ' que solo salta cuando cambia el nodo entero.
    if m.contenidoObservado <> invalid
        m.contenidoObservado.unobserveField("seleccionado")
    end if
    if content.hasField("seleccionado")
        content.observeField("seleccionado", "onSeleccionChanged")
        m.contenidoObservado = content
    else
        m.contenidoObservado = invalid
    end if
    PintarMarca()

    ' m.subtitleAbajo pudo haber cambiado arriba; Layout() depende de el
    ' para decidir donde va el subtitulo, asi que se vuelve a aplicar.
    w = m.top.width
    h = m.top.height
    if w = invalid or w = 0 then w = 280
    if h = invalid or h = 0 then h = 170
    Layout(w, h)
end sub

sub onSeleccionChanged()
    PintarMarca()
end sub

sub PintarMarca()
    marcada = false
    content = m.top.itemContent
    if content <> invalid and content.hasField("seleccionado") and content.seleccionado = true
        marcada = true
    end if
    m.marcaFondo.visible = marcada
    m.marcaLabel.visible = marcada
end sub

sub onFocusChanged()
    m.focusBorder.visible = m.top.itemHasFocus
end sub
