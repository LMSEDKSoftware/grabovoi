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

function ParseJsonSafe(jsonString as String) as Dynamic
    if jsonString = invalid or jsonString = ""
        return invalid
    end if
    parsed = ParseJson(jsonString)
    return parsed
end function
