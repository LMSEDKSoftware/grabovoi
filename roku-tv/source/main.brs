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
        print "memoria: limite del canal="; monitor.GetChannelMemoryLimit(); " disponible="; monitor.GetChannelAvailableMemory(); " usado%="; monitor.GetMemoryLimitPercent()
    end if

    ' EnableLowGeneralMemoryEvent SI existe, pero en otro objeto: es de
    ' ifDeviceInfo (roDeviceInfo), no de roAppMemoryMonitor. La vez pasada
    ' se llamo sobre "monitor" y truena con "Member function not found"
    ' -- confirmado con la consola del aparato -- porque monitor.avisa de
    ' limites del CANAL, y esto avisa de memoria general del SISTEMA; son
    ' dos fuentes de aviso distintas, cada una en su propio objeto.
    ' Fuente: developer.roku.com/dev/docs/ifdeviceinfo (metodo vive ahi,
    ' no en ifAppMemoryMonitor).
    infoDispositivo = CreateObject("roDeviceInfo")
    if infoDispositivo <> invalid
        infoDispositivo.SetMessagePort(port)
        infoDispositivo.EnableLowGeneralMemoryEvent(true)
    end if

    ' Deep linking: Roku puede pedir que el canal arranque en un contenido
    ' concreto (busqueda, "continuar viendo", voz). Hace falta declarar
    ' supports_input_launch=1 en el manifest Y atender los eventos, o la
    ' certificacion lo rechaza (criterio 5.2).
    ' Un deep link son DOS datos: contentId dice que abrir y mediaType
    ' como abrirlo. Declarar supports_input_launch y leer solo el primero
    ' no cuenta como soportarlo.
    ' Se comprueba el tipo, no solo que no sea invalid. En un arranque
    ' normal args llega vacio, y pedirle .contentId a algo que no sea un
    ' arreglo asociativo revienta Main entero: el canal se cerraria de
    ' golpe antes de entrar al bucle de mensajes.
    if type(args) = "roAssociativeArray" and args.contentId <> invalid and args.contentId <> ""
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
            ' diagnosticar un cierre inesperado. Se consulta unicamente
            ' isMemoryWarning, que es el evento que se pidio arriba.
            if msg.isMemoryWarning()
                print "memoria: aviso, el canal se acerca a su limite"
            end if
        else if msgType = "roDeviceInfoEvent"
            ' Lo que llega aqui de memoria es "generalMemoryLevel" dentro
            ' de GetInfo(): "normal", "low" o "critical". No hay un
            ' isLowGeneralMemory() -- el predicado que existe en este
            ' evento es isStatusMessage(), y adentro se mira el nivel.
            if msg.isStatusMessage()
                info = msg.GetInfo()
                if info <> invalid and info.generalMemoryLevel <> invalid and info.generalMemoryLevel <> "normal"
                    print "memoria: el sistema anda con nivel general "; info.generalMemoryLevel
                end if
            end if
        end if
    end while
end sub
