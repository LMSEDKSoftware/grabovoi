' Orquesta la navegación entre pantallas. Cada pantalla hija reporta lo
' que pasó escribiendo en su campo "result" (ej. {action:"loggedIn",
' token:"..."}), y esta escena decide a dónde ir después. No hay una
' pila de historial genérica: cada "atrás" tiene un destino fijo y
' conocido, más simple de razonar y de verificar en el dispositivo real.

sub init()
    m.currentScreen = invalid
    m.currentScreenName = ""
    m.authToken = invalid

    task = m.top.findNode("checkSessionTask")
    task.observeField("responseCode", "onSessionChecked")

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

sub onSessionChecked(event as Object)
    code = event.GetData()
    if code = 200
        ShowHome()
    else
        ClearToken()
        m.authToken = invalid
        ShowLogin()
    end if
end sub

sub SwapScreen(name as String, node as Object)
    if m.currentScreen <> invalid
        m.top.removeChild(m.currentScreen)
    end if
    m.currentScreen = node
    m.currentScreenName = name
    m.top.appendChild(node)
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
    SwapScreen("categories", screen)
end sub

sub onCategoriesResult(event as Object)
    result = event.GetData()
    if result.action = "back"
        ShowHome()
    else if result.action = "openCategory"
        ShowSequenceList(result.categoria)
    end if
end sub

sub ShowSequenceList(categoria as String)
    screen = CreateObject("roSGNode", "SequenceListScreen")
    screen.authToken = m.authToken
    screen.categoria = categoria
    screen.observeField("result", "onSequenceListResult")
    SwapScreen("sequenceList", screen)
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
