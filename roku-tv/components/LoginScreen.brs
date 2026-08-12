' Login on-device: Roku prohíbe para apps públicas cualquier login que
' pase por fuera del canal (nada de "activa en manigrab.app/tv"), así
' que esto se resuelve con el teclado nativo de Roku, capturando el
' texto directo en pantalla. Ver docs/ROKU_TV_PLAN.md.

sub init()
    m.email = ""
    m.password = ""

    m.menu = m.top.findNode("menu")
    m.menu.observeField("itemSelected", "onMenuSelected")
    m.errorLabel = m.top.findNode("errorLabel")

    m.loginTask = m.top.findNode("loginTask")
    m.loginTask.observeField("done", "onLoginResponse")

    RefreshMenu()
    m.menu.setFocus(true)
end sub

sub RefreshMenu()
    root = CreateObject("roSGNode", "ContentNode")

    emailItem = root.CreateChild("ContentNode")
    if m.email = ""
        emailItem.title = "Correo electronico: (vacio)"
    else
        emailItem.title = "Correo electronico: " + m.email
    end if

    passwordItem = root.CreateChild("ContentNode")
    if m.password = ""
        passwordItem.title = "Contrasena: (vacia)"
    else
        mask = ""
        for i = 1 to Len(m.password)
            mask = mask + "*"
        end for
        passwordItem.title = "Contrasena: " + mask
    end if

    enterItem = root.CreateChild("ContentNode")
    enterItem.title = "Entrar"

    m.menu.content = root
end sub

sub onMenuSelected()
    index = m.menu.itemSelected
    if index = 0
        ShowKeyboard(false)
    else if index = 1
        ShowKeyboard(true)
    else if index = 2
        DoLogin()
    end if
end sub

sub ShowKeyboard(secure as Boolean)
    kb = CreateObject("roSGNode", "KeyboardDialog")
    if secure
        kb.title = "Escribe tu contrasena"
        kb.keyboard.textEditBox.secureMode = true
        kb.keyboard.text = m.password
    else
        kb.title = "Escribe tu correo electronico"
        kb.keyboard.text = m.email
    end if
    kb.buttons = ["OK", "Cancelar"]
    kb.observeField("buttonSelected", "onKeyboardButton")
    m.pendingSecure = secure
    m.pendingKeyboard = kb
    m.top.getScene().dialog = kb
end sub

sub onKeyboardButton(event as Object)
    index = event.GetData()
    if index = 0
        ' El teclado de Roku a veces deja un espacio de más al final
        ' (autocompletado/sugerencias). Sin recortarlo, Supabase Auth
        ' rechaza credenciales que en pantalla se ven idénticas a las
        ' correctas.
        text = m.pendingKeyboard.text.Trim()
        if m.pendingSecure
            m.password = text
        else
            m.email = LCase(text)
        end if
        RefreshMenu()
    end if
    m.top.getScene().dialog = invalid
end sub

sub DoLogin()
    m.errorLabel.text = ""
    if m.email = "" or m.password = ""
        m.errorLabel.text = "Escribe tu correo y contrasena."
        return
    end if
    body = { email: m.email, password: m.password }
    m.loginTask.uri = ApiBase() + "/roku-login"
    m.loginTask.method = "POST"
    m.loginTask.body = FormatJson(body)
    m.loginTask.control = "RUN"
end sub

sub onLoginResponse(event as Object)
    result = event.GetData()
    code = result.code
    parsed = ParseJsonSafe(result.json)

    if code = 200 and parsed <> invalid and parsed.access_token <> invalid
        m.top.result = { action: "loggedIn", token: parsed.access_token }
    else
        if parsed <> invalid and parsed.message <> invalid
            m.errorLabel.text = parsed.message
        else
            m.errorLabel.text = "No se pudo iniciar sesion. Intenta de nuevo."
        end if
    end if
end sub
