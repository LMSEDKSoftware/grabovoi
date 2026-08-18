sub Main(args as Object)
    screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    scene = screen.CreateScene("MainScene")
    screen.Show()

    while true
        msg = wait(0, port)
        msgType = type(msg)
        if msgType = "roSGScreenEvent"
            if msg.IsScreenClosed()
                return
            end if
        end if
    end while
end sub

' Punto de entrada propio del salvapantallas: Roku NO llama a Main() para
' esto, llama a RunScreenSaver(). Corre en su propio proceso, sin sesion
' ni token, por eso ScreensaverScene no pide nada al servidor.
sub RunScreenSaver()
    screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    scene = screen.CreateScene("ScreensaverScene")
    screen.Show()

    while true
        msg = wait(0, port)
        if type(msg) = "roSGScreenEvent"
            if msg.IsScreenClosed()
                return
            end if
        end if
    end while
end sub
