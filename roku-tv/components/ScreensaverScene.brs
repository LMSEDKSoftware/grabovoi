' Salvapantallas del canal. Corre aislado del canal normal (Roku lo
' lanza como su propia escena, sin sesion ni token), asi que todo lo que
' muestra sale de aqui, sin red.

' Frases del catalogo de ManiGraB, no una sola fija: la idea es que quien
' deje la TV encendida siga viendo algo distinto cada vez.
function Frases() as Object
    return [
        "Respira. Tu campo energético ya está en movimiento.",
        "Lo que sostienes con calma, se ordena solo.",
        "La intención clara no necesita esfuerzo.",
        "Cada secuencia es una conversación con lo posible.",
        "Estás exactamente donde tienes que estar.",
        "La constancia pesa más que la intensidad.",
        "Tu atención es la herramienta; el número es el puente."
    ]
end function

sub init()
    m.flotante = m.top.findNode("flotante")
    m.frase = m.top.findNode("frase")
    m.movimiento = m.top.findNode("movimiento")
    m.movimiento.observeField("fire", "onMover")

    m.frases = Frases()
    ' El indice arranca en un punto distinto en cada arranque: sin esto
    ' siempre se veria la misma frase primero.
    m.indice = CreateObject("roDateTime").AsSeconds() MOD m.frases.Count()

    ' Posiciones seguras dentro del area visible de un televisor. El grupo
    ' mide unos 420x320, asi que ninguna esquina se sale ni queda pegada
    ' al borde.
    m.posiciones = [[120, 130], [700, 120], [660, 340], [140, 350]]
    m.posicion = 0

    Refrescar()
    m.movimiento.control = "start"
end sub

sub onMover()
    m.posicion = (m.posicion + 1) MOD m.posiciones.Count()
    m.indice = (m.indice + 1) MOD m.frases.Count()
    Refrescar()
end sub

sub Refrescar()
    m.flotante.translation = m.posiciones[m.posicion]
    m.frase.text = m.frases[m.indice]
end sub
