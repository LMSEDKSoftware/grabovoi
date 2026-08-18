' Compartido por todas las pantallas: URL base del backend (el mismo
' proyecto Vercel de Alexa, endpoints /api/roku-*), y persistencia del
' token de sesión en el registro del dispositivo.

function ApiBase() as String
    return "https://alexa-vercel-lovat.vercel.app/api"
end function

function SaveToken(token as String) as Void
    sec = CreateObject("roRegistrySection", "ManiGraBTV")
    sec.Write("access_token", token)
    sec.Flush()
end function

function LoadToken() as Dynamic
    sec = CreateObject("roRegistrySection", "ManiGraBTV")
    if sec.Exists("access_token")
        return sec.Read("access_token")
    end if
    return invalid
end function

' El correo de la cuenta conectada, al lado del token. Se guarda en el
' aparato a proposito: la TV ya lo conoce en el momento del login, asi que
' pintarlo no tiene por que costar una ida al servidor ni esperar su
' respuesta. Es solo para mostrar; nada se autoriza con este dato.
function SaveEmail(email as String) as Void
    sec = CreateObject("roRegistrySection", "ManiGraBTV")
    sec.Write("account_email", email)
    sec.Flush()
end function

function LoadEmail() as String
    sec = CreateObject("roRegistrySection", "ManiGraBTV")
    if sec.Exists("account_email")
        return sec.Read("account_email")
    end if
    return ""
end function

function ClearToken() as Void
    sec = CreateObject("roRegistrySection", "ManiGraBTV")
    sec.Delete("access_token")
    sec.Delete("account_email")
    sec.Flush()
end function

' Un 401 significa que el token ya no vale: caducó a los 90 días, o se
' cerró sesión desde otra televisión. Antes cualquier respuesta que no
' fuera 200 se veía igual (una pantalla vacía sin explicación), así que
' una sesión vencida era indistinguible de un backend caído. Cada
' pantalla llama esto como primera línea de su manejador de respuesta;
' MainScene escucha el caso en un solo lugar y devuelve al login.
function SesionVencida(top as Object, result as Object) as Boolean
    if result.code = 401
        top.result = { action: "sessionExpired" }
        return true
    end if
    return false
end function

' El aviso de salud se reconoce UNA vez por aparato, no antes de cada
' secuencia: Roku rechaza la fricción repetida delante del contenido, y
' un modal que hay que despachar cada vez deja de leerse a la tercera.
' Queda consultable cuando se quiera desde Información Legal.
function DisclaimerAceptado() as Boolean
    sec = CreateObject("roRegistrySection", "ManiGraBTV")
    if sec.Exists("disclaimer_aceptado")
        return (sec.Read("disclaimer_aceptado") = "1")
    end if
    return false
end function

function GuardarDisclaimerAceptado() as Void
    sec = CreateObject("roRegistrySection", "ManiGraBTV")
    sec.Write("disclaimer_aceptado", "1")
    sec.Flush()
end function

' Identificador estable de este aparato para este canal, usado en la
' vinculación por QR: se manda al pedir el código y al consultarlo, para
' que un número adivinado no sirva desde otra televisión.
'
' Lo ideal es GetChannelClientId (lo da Roku y no cambia). El respaldo en
' el registro existe solo por si roDeviceInfo no estuviera disponible: lo
' único que importa es que el valor no cambie entre pedir el código y
' reclamarlo.
function DeviceId() as String
    info = CreateObject("roDeviceInfo")
    if info <> invalid
        id = info.GetChannelClientId()
        if id <> invalid and id <> "" then return id
    end if

    sec = CreateObject("roRegistrySection", "ManiGraBTV")
    if sec.Exists("device_id")
        guardado = sec.Read("device_id")
        if guardado <> invalid and guardado <> "" then return guardado
    end if

    generado = "tv-" + CreateObject("roDateTime").AsSeconds().ToStr() + "-" + Rnd(999999).ToStr()
    sec.Write("device_id", generado)
    sec.Flush()
    return generado
end function

' "2025-10-24T03:41:09+00:00" -> "24 de octubre de 2025" (PerfilScreen).
function FormatearFechaCorta(iso as String) as String
    if iso = invalid or iso = ""
        return ""
    end if
    dt = CreateObject("roDateTime")
    dt.FromISO8601String(iso)
    meses = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"]
    mes = meses[dt.GetMonth() - 1]
    return dt.GetDayOfMonth().ToStr() + " de " + mes + " de " + dt.GetYear().ToStr()
end function

function ParseJsonSafe(jsonString as String) as Dynamic
    if jsonString = invalid or jsonString = ""
        return invalid
    end if
    parsed = ParseJson(jsonString)
    return parsed
end function

' Percent-encoding para usar en query strings. NO usar roUrlTransfer.Escape()
' para esto: roUrlTransfer es un componente MAIN|TASK-only, y crearlo desde
' el hilo de render (el de cualquier Group normal, como una pantalla) falla
' en silencio -- "escaper" queda Invalid y la siguiente linea truena con un
' error real que cuelga la app entera (visto en consola: "creating MAIN|
' TASK-only component failed on RENDER thread"). roByteArray si funciona en
' cualquier hilo.
function UrlEncode(texto as String) as String
    seguros = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~"
    bytes = CreateObject("roByteArray")
    bytes.FromAsciiString(texto)
    resultado = ""
    for i = 0 to bytes.Count() - 1
        b = bytes[i]
        c = Chr(b)
        if b >= 32 and b < 127 and Instr(1, seguros, c) > 0
            resultado = resultado + c
        else
            hexStr = UCase(StrI(b, 16).Trim())
            if Len(hexStr) = 1 then hexStr = "0" + hexStr
            resultado = resultado + "%" + hexStr
        end if
    end for
    return resultado
end function
