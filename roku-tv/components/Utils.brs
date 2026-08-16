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

function ClearToken() as Void
    sec = CreateObject("roRegistrySection", "ManiGraBTV")
    sec.Delete("access_token")
    sec.Flush()
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
