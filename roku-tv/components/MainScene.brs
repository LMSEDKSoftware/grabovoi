' Orquesta la navegación entre pantallas. Cada pantalla hija reporta lo
' que pasó escribiendo en su campo "result" (ej. {action:"loggedIn",
' token:"..."}), y esta escena decide a dónde ir después. No hay una
' pila de historial genérica: cada "atrás" tiene un destino fijo y
' conocido, más simple de razonar y de verificar en el dispositivo real.

sub init()
    m.currentScreen = invalid
    m.currentScreenName = ""
    m.authToken = invalid

    m.content = m.top.findNode("content")
    m.sidebar = m.top.findNode("sidebar")
    m.sidebarList = m.top.findNode("sidebarList")
    m.sidebarFocused = false

    root = CreateObject("roSGNode", "ContentNode")
    ' Solo "Home" y "Library" llevan a algo real por ahora; el resto se ve
    ' pero no hace nada todavia (no hay pantallas detras de esas secciones).
    for each texto in ["Home", "Library", "Most Searched", "My Sequences", "Active Sequences", "Settings"]
        item = root.CreateChild("ContentNode")
        item.title = texto
    end for
    m.sidebarList.content = root
    m.sidebarList.observeField("itemSelected", "onSidebarItemSelected")

    task = m.top.findNode("checkSessionTask")
    task.observeField("done", "onSessionChecked")

    saved = LoadToken()
    if saved <> invalid
        m.authToken = saved
        task.authToken = saved
        task.uri = ApiBase() + "/roku-home"
        task.method = "GET"
        task.control = "RUN"
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
    end if
    ' Los demas indices (Most Searched/My Sequences/Active Sequences/
    ' Settings) todavia no tienen pantalla propia -- no hacen nada.
end sub

sub EnfocarSidebar()
    m.sidebarFocused = true
    m.sidebarList.setFocus(true)
end sub

sub EnfocarContenido()
    m.sidebarFocused = false
    if m.currentScreen <> invalid
        m.currentScreen.setFocus(true)
    end if
end sub

sub onSessionChecked(event as Object)
    result = event.GetData()
    if result.code = 200
        ShowHome()
    else
        ClearToken()
        m.authToken = invalid
        ShowLogin()
    end if
end sub

sub SwapScreen(name as String, node as Object)
    if m.currentScreen <> invalid
        m.content.removeChild(m.currentScreen)
    end if
    m.currentScreen = node
    m.currentScreenName = name
    m.content.appendChild(node)

    ' El sidebar es permanente para todas las pantallas autenticadas,
    ' excepto login (sin cuenta no hay nada que navegar) y player (que la
    ' mirada se centre en la secuencia, sin distracciones alrededor).
    m.sidebar.visible = (name <> "login" and name <> "player")
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
        ClearToken()
        m.authToken = invalid
        ShowLogin()
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
        end if
    end if
    return false
end function
