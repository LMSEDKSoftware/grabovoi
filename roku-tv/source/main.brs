sub Main(args as Object)
    screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    scene = screen.CreateScene("MainScene")
    screen.Show()

    ' Vigilancia de memoria. El analisis estatico de Roku la exige
    ' (criterio de Monitoring): si el canal se pasa del limite, el sistema
    ' lo mata sin avisar, y estos eventos son la unica forma de enterarse
    ' antes de que pase.
    monitor = CreateObject("roAppMemoryMonitor")
    if monitor <> invalid
        monitor.SetMessagePort(port)
        monitor.EnableMemoryWarningEvent(true)
        monitor.EnableLowGeneralMemoryEvent(true)
        print "memoria: limite del canal="; monitor.GetChannelMemoryLimit(); " disponible="; monitor.GetChannelAvailableMemory(); " usado%="; monitor.GetMemoryLimitPercent()
    end if

    ' Deep linking: Roku puede pedir que el canal arranque en un contenido
    ' concreto (busqueda, "continuar viendo", voz). Hace falta declarar
    ' supports_input_launch=1 en el manifest Y atender los eventos, o la
    ' certificacion lo rechaza (criterio 5.2).
    ' Un deep link son DOS datos: contentId dice que abrir y mediaType
    ' como abrirlo. Declarar supports_input_launch y leer solo el primero
    ' no cuenta como soportarlo.
    if args <> invalid and args.contentId <> invalid and args.contentId <> ""
        if args.mediaType <> invalid then scene.deepLinkMediaType = args.mediaType
        scene.deepLinkContentId = args.contentId
    end if

    entrada = CreateObject("roInput")
    entrada.SetMessagePort(port)

    while true
        msg = wait(0, port)
        msgType = type(msg)

        if msgType = "roSGScreenEvent"
            if msg.IsScreenClosed()
                return
            end if
        else if msgType = "roInputEvent"
            ' Peticion de arranque estando el canal ya abierto.
            if msg.IsInput()
                info = msg.GetInfo()
                if info <> invalid and info.contentId <> invalid and info.contentId <> ""
                    if info.mediaType <> invalid then scene.deepLinkMediaType = info.mediaType
                    scene.deepLinkContentId = info.contentId
                end if
            end if
        else if msgType = "roAppMemoryNotificationEvent"
            ' No se libera nada por ahora: queda en consola para poder
            ' diagnosticar un cierre inesperado.
            if msg.isMemoryWarning()
                print "memoria: aviso, el canal se acerca a su limite"
            else if msg.isLowGeneralMemory()
                print "memoria: el sistema anda justo de memoria general"
            end if
        end if
    end while
end sub
