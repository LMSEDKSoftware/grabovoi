' Orquesta la navegación entre pantallas. Cada pantalla hija reporta lo
' que pasó escribiendo en su campo "result" (ej. {action:"loggedIn",
' token:"..."}), y esta escena decide a dónde ir después. No hay una
' pila de historial genérica: cada "atrás" tiene un destino fijo y
' conocido, más simple de razonar y de verificar en el dispositivo real.

sub init()
    m.currentScreen = invalid
    m.currentScreenName = ""
    m.authToken = invalid

    ' Marca de tiempo de arranque del canal, para "Tiempo Sesion" en
    ' EvolucionScreen (se reinicia cada vez que se abre el canal, igual
    ' que AppTimeTracker en la app movil -- no es un dato del servidor).
    m.global.addFields({ rokuSessionEpoch: CreateObject("roDateTime").AsSeconds() })

    m.content = m.top.findNode("content")
    m.sidebar = m.top.findNode("sidebar")
    m.sidebarList = m.top.findNode("sidebarList")
    m.sidebarFocused = false

    ' LabelList nativo, identico al commit 44cff0f -- sin tocar su
    ' apariencia de foco (Roku la dibuja sola). "Informacion Legal" es el
    ' ultimo item, parte de la misma lista y navegacion que el resto.
    root = CreateObject("roSGNode", "ContentNode")
    ' "Combinaciones" y no "Secuencias Combinadas": el sidebar mide 230 y
    ' el nombre largo se cortaba a media palabra.
    for each texto in ["Inicio", "Biblioteca cuántica", "Buscar", "Top ten más usados", "Mis favoritos", "Combinaciones", "Evolución", "Perfil", "Cerrar sesión", "Información Legal"]
        item = root.CreateChild("ContentNode")
        item.title = texto
    end for
    m.sidebarList.content = root
    m.sidebarList.observeField("itemSelected", "onSidebarItemSelected")

    m.checkSessionTask = m.top.findNode("checkSessionTask")
    m.checkSessionTask.observeField("done", "onSessionChecked")
    m.logoutTask = m.top.findNode("logoutTask")

    ShowIntro()
end sub

sub ShowIntro()
    screen = CreateObject("roSGNode", "IntroScreen")
    screen.observeField("result", "onIntroResult")
    screen.callFunc("StartLoading")
    SwapScreen("intro", screen)
end sub

sub onIntroResult(event as Object)
    IniciarFlujoPrincipal()
end sub

sub IniciarFlujoPrincipal()
    saved = LoadToken()
    if saved <> invalid
        m.authToken = saved
        m.checkSessionTask.authToken = saved
        m.checkSessionTask.uri = ApiBase() + "/roku-home"
        m.checkSessionTask.method = "GET"
        m.checkSessionTask.control = "RUN"
    else
        ShowLogin()
    end if
end sub

sub onSidebarItemSelected()
    index = m.sidebarList.itemSelected
    if index = 0
        ShowHome()
    else if index = 1
        ShowCategories()
    else if index = 2
        ShowBuscar()
    else if index = 3
        ShowTopUsados()
    else if index = 4
        ShowFavoritos()
    else if index = 5
        ShowRutinas()
    else if index = 6
        ShowEvolucion()
    else if index = 7
        ShowPerfil()
    else if index = 8
        CerrarSesion()
    else if index = 9
        ShowLegal()
    end if
end sub

' Cerrar sesion completo. Antes esto solo borraba el token del registro
' del propio Roku: la fila en el servidor seguia viva y el token seguia
' sirviendo los 90 dias completos, asi que la sesion se iba con el
' aparato si se vendia o se devolvia.
'
' El aviso al servidor se manda y no se espera respuesta: si la red esta
' caida igual hay que sacar al usuario de aqui, y el token local ya no va
' a existir para reintentarlo. Por eso logoutTask no tiene observador.
sub CerrarSesion()
    if m.authToken <> invalid
        m.logoutTask.uri = ApiBase() + "/roku-perfil"
        m.logoutTask.method = "POST"
        m.logoutTask.authToken = m.authToken
        m.logoutTask.body = FormatJson({ action: "logout" })
        m.logoutTask.control = "RUN"
    end if
    CerrarSesionLocal()
end sub

' Solo el lado del aparato. Se usa cuando el servidor YA invalido la
' sesion por su cuenta (un 401 en cualquier pantalla): avisarle otra vez
' no tendria sentido.
sub CerrarSesionLocal()
    ClearToken()
    m.authToken = invalid
    ShowLogin()
end sub

' Todas las pantallas reportan por el mismo campo "result", asi que
' basta un observador extra en SwapScreen para atrapar la sesion vencida
' una sola vez, en vez de repetir la comprobacion en los diez
' manejadores especificos. Los dos observadores conviven: el especifico
' de cada pantalla ignora esta accion.
sub onResultGlobal(event as Object)
    result = event.GetData()
    if result <> invalid and result.action = "sessionExpired"
        CerrarSesionLocal()
    end if
end sub

sub EnfocarSidebar()
    m.sidebarFocused = true
    m.sidebarList.setFocus(true)
end sub

sub EnfocarContenido()
    m.sidebarFocused = false
    if m.currentScreen <> invalid
        ' Las pantallas son Group planos: setFocus(true) sobre el Group
        ' no delega el foco a la grilla/lista interna, asi que las
        ' flechas se quedaban sin nadie que las escuchara despues de
        ' volver del sidebar. Cada pantalla implementa RestoreFocus()
        ' para reenfocar su propio nodo navegable (grid/rows/contenido).
        m.currentScreen.callFunc("RestoreFocus")
    end if
end sub

sub onSessionChecked(event as Object)
    result = event.GetData()
    if result.code = 200
        ShowHome()
    else
        ' El servidor ya rechazo este token, no hay nada que avisarle.
        CerrarSesionLocal()
    end if
end sub

sub SwapScreen(name as String, node as Object)
    if m.currentScreen <> invalid
        m.content.removeChild(m.currentScreen)
    end if
    m.currentScreen = node
    m.currentScreenName = name
    m.content.appendChild(node)
    node.observeField("result", "onResultGlobal")

    ' El sidebar es permanente para todas las pantallas autenticadas,
    ' excepto login (sin cuenta no hay nada que navegar) y player (que la
    ' mirada se centre en la secuencia, sin distracciones alrededor).
    m.sidebar.visible = (name <> "login" and name <> "player" and name <> "intro")
    m.sidebarFocused = false
    node.setFocus(true)
end sub

sub ShowLogin()
    screen = CreateObject("roSGNode", "LoginScreen")
    screen.observeField("result", "onLoginResult")
    SwapScreen("login", screen)
end sub

sub onLoginResult(event as Object)
    result = event.GetData()
    if result.action = "loggedIn"
        m.authToken = result.token
        SaveToken(result.token)
        ShowHome()
    end if
end sub

sub ShowHome()
    screen = CreateObject("roSGNode", "HomeScreen")
    screen.authToken = m.authToken
    screen.observeField("result", "onHomeResult")
    screen.callFunc("StartLoading")
    SwapScreen("home", screen)
end sub

sub onHomeResult(event as Object)
    result = event.GetData()
    if result.action = "logout"
        CerrarSesion()
    else if result.action = "openCategories"
        ShowCategories()
    else if result.action = "openSequence"
        ShowPlayer(result.id)
    end if
end sub

sub ShowCategories()
    screen = CreateObject("roSGNode", "CategoryScreen")
    screen.authToken = m.authToken
    screen.observeField("result", "onCategoriesResult")
    screen.callFunc("StartLoading")
    SwapScreen("categories", screen)
end sub

sub onCategoriesResult(event as Object)
    result = event.GetData()
    print "MainScene onCategoriesResult action="; result.action
    if result.action = "back"
        ShowHome()
    else if result.action = "openCategory"
        ShowSequenceList(result.categoria)
    end if
end sub

sub ShowSequenceList(categoria as String)
    print "MainScene ShowSequenceList categoria="; categoria
    screen = CreateObject("roSGNode", "SequenceListScreen")
    screen.authToken = m.authToken
    screen.categoria = categoria
    screen.observeField("result", "onSequenceListResult")
    screen.callFunc("StartLoading")
    print "MainScene ShowSequenceList StartLoading llamado, haciendo SwapScreen"
    SwapScreen("sequenceList", screen)
    print "MainScene ShowSequenceList SwapScreen completado"
end sub

sub onSequenceListResult(event as Object)
    result = event.GetData()
    if result.action = "back"
        ShowCategories()
    else if result.action = "openSequence"
        ShowPlayer(result.id)
    end if
end sub

sub ShowPlayer(secuenciaId as String)
    screen = CreateObject("roSGNode", "PlayerScreen")
    screen.authToken = m.authToken
    screen.secuenciaId = secuenciaId
    screen.observeField("result", "onPlayerResult")
    screen.callFunc("StartLoading")
    SwapScreen("player", screen)
end sub

sub onPlayerResult(event as Object)
    result = event.GetData()
    if result.action = "back"
        ShowHome()
    else if result.action = "openSequence"
        ' Secuencia sincronica elegida en la pantalla de "Secuencia
        ' Activada" -- una pantalla de reproductor nueva y limpia, igual
        ' que cuando se abre desde Home/SequenceList.
        ShowPlayer(result.id)
    end if
end sub

sub ShowBuscar()
    screen = CreateObject("roSGNode", "SearchScreen")
    screen.authToken = m.authToken
    screen.observeField("result", "onBuscarResult")
    screen.callFunc("StartLoading")
    SwapScreen("buscar", screen)
end sub

sub onBuscarResult(event as Object)
    result = event.GetData()
    if result.action = "back"
        ShowHome()
    else if result.action = "openSequence"
        ShowPlayer(result.id)
    end if
end sub

' Favoritos y top-usados reutilizan SequenceListScreen (misma grilla que
' Biblioteca cuantica) pero apuntando a un endpoint fijo en vez de armar
' la URL desde una categoria -- ver el campo endpointUri en
' SequenceListScreen.xml/.brs.
sub ShowFavoritos()
    screen = CreateObject("roSGNode", "SequenceListScreen")
    screen.authToken = m.authToken
    screen.titulo = "Mis favoritos"
    screen.endpointUri = ApiBase() + "/roku-favoritos"
    screen.observeField("result", "onFavoritosResult")
    screen.callFunc("StartLoading")
    SwapScreen("favoritos", screen)
end sub

sub onFavoritosResult(event as Object)
    result = event.GetData()
    if result.action = "back"
        ShowHome()
    else if result.action = "openSequence"
        ShowPlayer(result.id)
    end if
end sub

sub ShowTopUsados()
    screen = CreateObject("roSGNode", "SequenceListScreen")
    screen.authToken = m.authToken
    screen.titulo = "Top ten más usados"
    screen.endpointUri = ApiBase() + "/roku-top-usados"
    screen.observeField("result", "onTopUsadosResult")
    screen.callFunc("StartLoading")
    SwapScreen("topUsados", screen)
end sub

sub onTopUsadosResult(event as Object)
    result = event.GetData()
    if result.action = "back"
        ShowHome()
    else if result.action = "openSequence"
        ShowPlayer(result.id)
    end if
end sub

sub ShowRutinas()
    screen = CreateObject("roSGNode", "RutinasScreen")
    screen.authToken = m.authToken
    screen.observeField("result", "onRutinasResult")
    screen.callFunc("StartLoading")
    SwapScreen("rutinas", screen)
end sub

sub onRutinasResult(event as Object)
    result = event.GetData()
    if result.action = "back"
        ShowHome()
    else if result.action = "openRutina"
        ' El reproductor se encarga de pedir la rutina y armar su cola; asi
        ' esta escena no necesita otro ApiTask ni esperar una respuesta
        ' antes de poder cambiar de pantalla.
        screen = CreateObject("roSGNode", "PlayerScreen")
        screen.authToken = m.authToken
        screen.rutinaId = result.id
        screen.observeField("result", "onPlayerResult")
        screen.callFunc("StartLoading")
        SwapScreen("player", screen)
    end if
end sub

sub ShowEvolucion()
    screen = CreateObject("roSGNode", "EvolucionScreen")
    screen.authToken = m.authToken
    screen.observeField("result", "onEvolucionResult")
    screen.callFunc("StartLoading")
    SwapScreen("evolucion", screen)
end sub

sub onEvolucionResult(event as Object)
    result = event.GetData()
    if result.action = "back"
        ShowHome()
    end if
end sub

sub ShowPerfil()
    screen = CreateObject("roSGNode", "PerfilScreen")
    screen.authToken = m.authToken
    screen.observeField("result", "onPerfilResult")
    screen.callFunc("StartLoading")
    SwapScreen("perfil", screen)
end sub

sub onPerfilResult(event as Object)
    result = event.GetData()
    if result.action = "back"
        ShowHome()
    else if result.action = "logout"
        CerrarSesion()
    end if
end sub

sub ShowLegal()
    screen = CreateObject("roSGNode", "LegalScreen")
    screen.observeField("result", "onLegalResult")
    screen.callFunc("StartLoading")
    SwapScreen("legal", screen)
end sub

sub onLegalResult(event as Object)
    result = event.GetData()
    if result.action = "back"
        ShowHome()
    else if result.action = "openDoc"
        ShowLegalDoc(result.docId)
    end if
end sub

sub ShowLegalDoc(docId as String)
    screen = CreateObject("roSGNode", "LegalDocScreen")
    screen.docId = docId
    screen.observeField("result", "onLegalDocResult")
    screen.callFunc("StartLoading")
    SwapScreen("legalDoc", screen)
end sub

sub onLegalDocResult(event as Object)
    result = event.GetData()
    if result.action = "back"
        ShowLegal()
    end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press
        return false
    end if

    if key = "options" and m.sidebar.visible
        if m.sidebarFocused
            EnfocarContenido()
        else
            EnfocarSidebar()
        end if
        return true
    end if

    ' "Izquierda" enfoca el sidebar y "derecha" devuelve el foco al
    ' contenido -- simetrico, sin necesidad de texto aclaratorio. Esto
    ' solo llega aqui cuando el nodo enfocado ya no tiene a donde moverse
    ' en esa direccion (ej. primera/ultima columna de la grilla, o ya
    ' parado en el sidebar), asi que no compite con la navegacion normal.
    if key = "left" and not m.sidebarFocused and m.sidebar.visible
        EnfocarSidebar()
        return true
    end if

    if key = "right" and m.sidebarFocused
        EnfocarContenido()
        return true
    end if

    if key = "back" and m.sidebarFocused
        EnfocarContenido()
        return true
    end if

    if key = "back"
        if m.currentScreenName = "home"
            ' En home, "atrás" sale de la app (comportamiento estándar de Roku).
            return false
        else if m.currentScreenName = "categories"
            ShowHome()
            return true
        else if m.currentScreenName = "sequenceList"
            ShowCategories()
            return true
        else if m.currentScreenName = "player"
            ShowHome()
            return true
        else if m.currentScreenName = "favoritos" or m.currentScreenName = "topUsados" or m.currentScreenName = "evolucion" or m.currentScreenName = "perfil" or m.currentScreenName = "buscar" or m.currentScreenName = "legal" or m.currentScreenName = "rutinas"
            ShowHome()
            return true
        else if m.currentScreenName = "legalDoc"
            ShowLegal()
            return true
        end if
    end if
    return false
end function
