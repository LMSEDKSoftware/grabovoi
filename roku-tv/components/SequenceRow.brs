' Ver el comentario del XML. Mismo motivo que SequenceCard.brs para no
' depender de que MarkupGrid nos avise el tamano real: se aplica un
' tamano por defecto ya en init() (900x110, el mismo que itemSize en
' HomeScreen.xml) y si el tamano real llega despues se vuelve a aplicar.

sub init()
    m.focusBorder = m.top.findNode("focusBorder")
    m.heroBorder = m.top.findNode("heroBorder")
    m.card = m.top.findNode("card")
    m.posterBg = m.top.findNode("posterBg")
    m.poster = m.top.findNode("poster")
    m.shade = m.top.findNode("shade")
    m.numberLabel = m.top.findNode("numberLabel")
    m.kickerLabel = m.top.findNode("kickerLabel")
    m.titleLabel = m.top.findNode("titleLabel")
    m.subtitleLabel = m.top.findNode("subtitleLabel")
    m.rewardBg = m.top.findNode("rewardBg")
    m.rewardLabel = m.top.findNode("rewardLabel")
    m.destacada = false

    Layout(900, 110)
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
    margen = 8

    m.focusBorder.translation = [-margen, -margen]
    m.focusBorder.width = w + margen * 2
    m.focusBorder.height = h + margen * 2

    heroMargen = 3
    m.heroBorder.translation = [-heroMargen, -heroMargen]
    m.heroBorder.width = w + heroMargen * 2
    m.heroBorder.height = h + heroMargen * 2

    m.card.width = w
    m.card.height = h

    posterW = 210
    posterH = h - margen * 2
    m.posterBg.translation = [margen, margen]
    m.posterBg.width = posterW
    m.posterBg.height = posterH
    m.poster.translation = [margen, margen]
    m.poster.width = posterW
    m.poster.height = posterH
    m.shade.translation = [margen, margen]
    m.shade.width = posterW
    m.shade.height = posterH

    m.numberLabel.translation = [margen, margen + posterH / 2 - 14]
    m.numberLabel.width = posterW

    textoX = posterW + margen * 3
    textoW = w - textoX - margen

    rewardW = 170
    rewardH = 30
    m.rewardBg.translation = [w - rewardW - margen, h - rewardH - margen]
    m.rewardBg.width = rewardW
    m.rewardBg.height = rewardH
    m.rewardLabel.translation = [w - rewardW - margen, h - rewardH - margen + 6]
    m.rewardLabel.width = rewardW

    ' La fila destacada (secuencia del dia) mete un renglon extra arriba
    ' del titulo (el "kicker"), y el subtitulo comparte renglon con la
    ' recompensa a su derecha en vez de ir debajo (mismo layout que la
    ' app movil: "Toca para pilotar" + chip, uno al lado del otro).
    if m.destacada
        m.kickerLabel.translation = [textoX, 6]
        m.titleLabel.translation = [textoX, 30]
        m.subtitleLabel.translation = [textoX, h - rewardH - margen + 6]
        m.subtitleLabel.width = textoW - rewardW - 14
    else
        m.titleLabel.translation = [textoX, h * 0.22]
        m.subtitleLabel.translation = [textoX, h * 0.62]
        m.subtitleLabel.width = textoW
    end if
    m.kickerLabel.width = textoW
    m.titleLabel.width = textoW
end sub

sub onContentChanged()
    RenderContent()
end sub

sub RenderContent()
    content = m.top.itemContent
    if content = invalid
        return
    end if

    m.destacada = false
    if content.hasField("destacada") and content.destacada = true then m.destacada = true
    m.heroBorder.visible = m.destacada
    m.kickerLabel.visible = m.destacada
    m.rewardBg.visible = m.destacada
    m.rewardLabel.visible = m.destacada

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

    if content.hasField("numero") and content.numero <> invalid and content.numero <> ""
        m.numberLabel.text = content.numero
        m.numberLabel.visible = true
    else
        m.numberLabel.visible = false
    end if

    ' La tarjeta SIEMPRE se queda del mismo color oscuro; el color de
    ' categoria solo rellena la miniatura mientras no hay portada real.
    color = "#13213B"
    if content.hasField("color") and content.color <> invalid and content.color <> ""
        color = content.color
    end if
    m.posterBg.color = color

    if content.hasField("imageUrl") and content.imageUrl <> invalid and content.imageUrl <> ""
        m.poster.uri = content.imageUrl
        m.poster.visible = true
        m.shade.visible = true
    else
        m.poster.visible = false
        m.shade.visible = false
    end if

    ' m.destacada pudo haber cambiado arriba; Layout() depende de el para
    ' decidir donde van titulo/subtitulo, asi que se vuelve a aplicar.
    w = m.top.width
    h = m.top.height
    if w = invalid or w = 0 then w = 900
    if h = invalid or h = 0 then h = 110
    Layout(w, h)
end sub

sub onFocusChanged()
    m.focusBorder.visible = m.top.itemHasFocus
end sub
