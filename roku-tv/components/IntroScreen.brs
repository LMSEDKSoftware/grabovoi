sub init()
    m.video = m.top.findNode("video")
    m.video.observeField("state", "onVideoStateChanged")
    m.rescate = m.top.findNode("rescate")
    m.rescate.observeField("fire", "onRescate")
    m.terminado = false
end sub

function StartLoading() as Void
    content = CreateObject("roSGNode", "ContentNode")
    content.url = "pkg:/video/intro.mp4"
    m.video.content = content
    m.video.control = "play"
    m.video.setFocus(true)
    m.rescate.control = "start"
end function

sub onVideoStateChanged()
    ' Se imprime siempre: si la cortinilla vuelve a fallar, la consola de
    ' depuracion dice en que estado se quedo, que es justo el dato que
    ' hizo falta la vez pasada y no estaba.
    print "intro: estado del video = "; m.video.state
    if m.video.state = "finished" or m.video.state = "error"
        Terminar()
    end if
end sub

' El video nunca dijo ni "terminado" ni "error". Pasa de largo igual.
sub onRescate()
    print "intro: el video no termino a tiempo (estado "; m.video.state; "), se salta"
    Terminar()
end sub

sub Terminar()
    if m.terminado then return
    m.terminado = true
    m.rescate.control = "stop"
    m.video.control = "stop"
    m.top.result = { action: "done" }
end sub

' Cualquier tecla salta la cortinilla, incluido "back" -- no tiene
' sentido que "atras" cierre el canal durante una intro que se puede
' saltar.
function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    Terminar()
    return true
end function
