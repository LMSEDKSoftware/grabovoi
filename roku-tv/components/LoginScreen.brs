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

    m.email = ""
    m.password = ""

    m.tiendaRoku = m.top.findNode("tiendaRoku")
    m.tiendaRoku.observeField("userData", "onDatosRoku")
    m.correoTask = m.top.findNode("correoTask")
    m.correoTask.observeField("done", "onCorreoVerificado")
    m.correoRoku = ""

    LlenarLista(m.regenerar, ["Regenerar código"])
    LlenarLista(m.opciones, ["Usar mi cuenta de Roku", "Iniciar sesión con contraseña", "¿No tienes cuenta?"])
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
        PedirCorreoARoku()
    else if index = 1
        MostrarPassword()
    else if index = 2
        m.estado.text = "Crea tu cuenta gratis en la app ManiGraB para celular y luego vincula esta televisión."
    end if
end sub

' ---------------------------------------------------------------
' Entrar con la cuenta de Roku
' ---------------------------------------------------------------

' Roku abre su propio dialogo pidiendo permiso para compartir los datos
' de la cuenta del televisor. Es lo que exige el criterio RP 2.1, y de
' paso ahorra teclear un correo entero con el control remoto.
sub PedirCorreoARoku()
    m.pollTimer.control = "stop"
    m.estado.text = "Pidiendo permiso para usar el correo de tu cuenta Roku..."
    m.tiendaRoku.command = "getUserData"
end sub

sub onDatosRoku(event as Object)
    datos = event.GetData()

    ' invalid = el usuario dijo que no, o el televisor no tiene ese dato.
    ' No es un error: simplemente se sigue por los otros caminos.
    if datos = invalid or datos.email = invalid or datos.email = ""
        m.estado.text = "No se compartió ningún correo. Puedes entrar con el código QR o con tu contraseña."
        m.pollTimer.control = "start"
        return
    end if

    m.correoRoku = LCase(datos.email)
    m.estado.text = "Buscando tu cuenta de ManiGraB..."

    m.correoTask.uri = ApiBase() + "/roku-device"
    m.correoTask.method = "POST"
    m.correoTask.body = FormatJson({ action: "verificar_correo", email: m.correoRoku, device_id: m.deviceId })
    m.correoTask.control = "RUN"
end sub

sub onCorreoVerificado(event as Object)
    result = event.GetData()
    parsed = ParseJsonSafe(result.json)

    if result.code <> 200 or parsed = invalid or parsed.existe = invalid
        m.estado.text = "No se pudo comprobar tu cuenta. Entra con el código QR o con tu contraseña."
        m.pollTimer.control = "start"
        return
    end if

    if parsed.existe = true
        ' Hay cuenta con ese correo. Se salta directo a la contraseña, ya
        ' relleno: es el unico dato que falta.
        '
        ' A proposito NO se entra con solo el correo: el servidor no puede
        ' comprobar que esta peticion venga de verdad de este televisor,
        ' asi que dejar entrar sin contrasena permitiria abrir la cuenta
        ' de cualquiera sabiendo su correo.
        m.email = m.correoRoku
        RefreshMenu()
        MostrarPassword()
        m.menu.jumpToItem = 1
        m.errorLabel.text = ""
        return
    end if

    ' No hay cuenta: no se puede crear desde aqui, porque el registro y la
    ' suscripcion viven en la app movil.
    m.estado.text = "No encontramos una cuenta de ManiGraB con " + m.correoRoku + ". Descarga la app en tu celular, regístrate gratis, y vuelve aquí para vincular esta televisión."
    m.pollTimer.control = "start"
end sub

sub MostrarPassword()
    m.pollTimer.control = "stop"
    m.modo = "password"
    m.grupoQr.visible = false
    m.grupoPassword.visible = true
    m.errorLabel.text = ""
    m.menu.setFocus(true)
    ' Arranca en "Correo electronico": ya no hay credenciales precargadas,
    ' asi que el primer paso siempre es escribir el correo.
    m.menu.jumpToItem = 0
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
    ' StandardKeyboardDialog y no KeyboardDialog: el criterio 4.12 exige
    ' teclado por voz para correo, PIN y contrasenas, y el viejo no lo
    ' soporta. El analisis estatico lo marca como ERROR.
    '
    ' Ojo con la forma: aqui el texto y el modo seguro son campos del
    ' propio dialogo, no de un nodo keyboard anidado como antes.
    kb = CreateObject("roSGNode", "StandardKeyboardDialog")
    if secure
        kb.title = "Escribe tu contrasena"
        kb.secureMode = true
        kb.text = m.password
    else
        kb.title = "Escribe tu correo electronico"
        kb.text = m.email
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
