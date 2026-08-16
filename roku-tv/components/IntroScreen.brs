sub init()
    m.video = m.top.findNode("video")
    m.video.observeField("state", "onVideoStateChanged")
    m.terminado = false
end sub

function StartLoading() as Void
    content = CreateObject("roSGNode", "ContentNode")
    content.url = "pkg:/video/intro.mp4"
    m.video.content = content
    m.video.control = "play"
    m.video.setFocus(true)
end function

sub onVideoStateChanged()
    if m.video.state = "finished" or m.video.state = "error"
        Terminar()
    end if
end sub

sub Terminar()
    if m.terminado then return
    m.terminado = true
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
