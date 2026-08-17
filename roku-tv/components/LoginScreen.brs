' Pantalla de entrada al canal. Dos caminos que conviven:
'
'   1. Vinculación por QR (lo cómodo): la TV pide un código de 6 dígitos
'      a /roku-device, lo muestra junto al QR, y consulta cada 5 segundos
'      hasta que el usuario lo confirma desde su teléfono en /tv.
'   2. Login on-device con correo y contraseña, con el teclado nativo de
'      Roku. Este NO es opcional: Roku exige que el canal siempre permita
'      iniciar sesión sin salir del televisor, así que vive en el panel
'      derecho, siempre a la vista.
'
' Los dos terminan igual, escribiendo {action:"loggedIn", token} en
' m.top.result, que es lo que MainScene está observando.

sub init()
    m.grupoQr = m.top.findNode("grupoQr")
    m.grupoPassword = m.top.findNode("grupoPassword")

    m.qr = m.top.findNode("qr")
    m.codigoValor = m.top.findNode("codigoValor")
    m.codigoValor.font.size = 76
    m.urlLabel = m.top.findNode("urlLabel")
    m.estado = m.top.findNode("estado")

    m.regenerar = m.top.findNode("regenerar")
    m.regenerar.observeField("itemSelected", "onRegenerarSeleccionado")
    m.opciones = m.top.findNode("opciones")
    m.opciones.observeField("itemSelected", "onOpcionSeleccionada")

    m.menu = m.top.findNode("menu")
    m.menu.observeField("itemSelected", "onMenuSelected")
    m.errorLabel = m.top.findNode("errorLabel")

    m.codeTask = m.top.findNode("codeTask")
    m.codeTask.observeField("done", "onCodigoRecibido")
    m.pollTask = m.top.findNode("pollTask")
    m.pollTask.observeField("done", "onPollRespuesta")
    m.loginTask = m.top.findNode("loginTask")
    m.loginTask.observeField("done", "onLoginResponse")
    m.pollTimer = m.top.findNode("pollTimer")
    m.pollTimer.observeField("fire", "onPollTick")

    ' Identificador estable por canal y por aparato (ver Utils.brs). Se
    ' manda en cada consulta para que un código adivinado no sirva desde
    ' otra televisión.
    m.deviceId = DeviceId()

    m.codigo = ""
    m.pollEnVuelo = false
    m.modo = "qr"
    m.zona = "opciones"

    ' Precargado para pruebas, así con un solo OK ya se puede entrar sin
    ' teclear nada con el control remoto. Quitar cuando el canal deje de
    ' ser interno.
    m.email = "2005.ivan@gmail.com"
    m.password = "123456"

    LlenarLista(m.regenerar, ["Regenerar código"])
    LlenarLista(m.opciones, ["Iniciar sesión con contraseña", "¿No tienes cuenta?"])
    RefreshMenu()

    PedirCodigo()
    m.opciones.setFocus(true)
end sub

sub LlenarLista(lista as Object, textos as Object)
    root = CreateObject("roSGNode", "ContentNode")
    for each texto in textos
        item = root.CreateChild("ContentNode")
        item.title = texto
    end for
    lista.content = root
end sub

' ---------------------------------------------------------------
' Vinculación por QR
' ---------------------------------------------------------------

sub PedirCodigo()
    m.pollTimer.control = "stop"
    m.codigo = ""
    m.codigoValor.text = "------"
    m.qr.uri = ""
    m.urlLabel.text = ""
    m.estado.text = "Generando código..."

    m.codeTask.uri = ApiBase() + "/roku-device"
    m.codeTask.method = "POST"
    m.codeTask.body = FormatJson({ action: "create", device_id: m.deviceId })
    m.codeTask.control = "RUN"
end sub

sub onCodigoRecibido(event as Object)
    result = event.GetData()
    parsed = ParseJsonSafe(result.json)

    if result.code = 200 and parsed <> invalid and parsed.code <> invalid
        m.codigo = parsed.code
        m.codigoValor.text = parsed.code
        m.qr.uri = parsed.qr_url
        m.urlLabel.text = "O visita " + parsed.activate_label
        m.estado.text = "Esperando a que confirmes desde tu teléfono. El código se renueva solo cuando caduca."
        m.pollTimer.control = "start"
    else
        m.codigoValor.text = "------"
        m.estado.text = "No se pudo generar el código. Entra con tu correo y contraseña desde el panel de la derecha."
    end if
end sub

sub onPollTick()
    if m.codigo = "" or m.pollEnVuelo then return
    m.pollEnVuelo = true
    m.pollTask.uri = ApiBase() + "/roku-device"
    m.pollTask.method = "POST"
    m.pollTask.body = FormatJson({ action: "poll", code: m.codigo, device_id: m.deviceId })
    m.pollTask.control = "RUN"
end sub

sub onPollRespuesta(event as Object)
    m.pollEnVuelo = false
    result = event.GetData()
    parsed = ParseJsonSafe(result.json)

    ' Un error de red suelto no debe romper nada: el temporizador sigue
    ' corriendo y el siguiente intento cae 5 segundos después.
    if parsed = invalid or parsed.status = invalid then return

    if parsed.status = "linked" and parsed.access_token <> invalid
        m.pollTimer.control = "stop"
        m.estado.text = "¡Listo! Entrando..."
        m.top.result = { action: "loggedIn", token: parsed.access_token }
    else if parsed.status = "expired"
        ' Caducó (15 minutos) o alguien más lo reclamó. Se pide otro solo,
        ' para que nunca quede un número muerto en la pantalla.
        PedirCodigo()
    end if
end sub

sub onRegenerarSeleccionado()
    PedirCodigo()
end sub

sub onOpcionSeleccionada()
    index = m.opciones.itemSelected
    if index = 0
        MostrarPassword()
    else if index = 1
        m.estado.text = "Crea tu cuenta gratis en la app ManiGraB para celular y luego vincula esta televisión."
    end if
end sub

sub MostrarPassword()
    m.pollTimer.control = "stop"
    m.modo = "password"
    m.grupoQr.visible = false
    m.grupoPassword.visible = true
    m.errorLabel.text = ""
    m.menu.setFocus(true)
    m.menu.jumpToItem = 2
end sub

sub MostrarQr()
    m.modo = "qr"
    m.grupoPassword.visible = false
    m.grupoQr.visible = true
    if m.codigo = ""
        PedirCodigo()
    else
        m.pollTimer.control = "start"
    end if
    EnfocarZona("opciones")
end sub

sub EnfocarZona(zona as String)
    m.zona = zona
    if zona = "regenerar"
        m.regenerar.setFocus(true)
    else
        m.opciones.setFocus(true)
    end if
end sub

' El LabelList se queda con arriba y abajo, y suelta izquierda y derecha
' cuando ya no tiene a dónde ir: eso es lo que deja saltar entre el botón
' de regenerar y el panel de opciones.
function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false

    if m.modo = "password"
        if key = "back"
            MostrarQr()
            return true
        end if
        return false
    end if

    if key = "left" and m.zona = "opciones"
        EnfocarZona("regenerar")
        return true
    end if

    if key = "right" and m.zona = "regenerar"
        EnfocarZona("opciones")
        return true
    end if

    return false
end function

' ---------------------------------------------------------------
' Login on-device con correo y contraseña
' ---------------------------------------------------------------

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
