' Helper HTTP reutilizable por todas las pantallas. Corre en su propio
' hilo (es un Task node) para no congelar la interfaz mientras espera
' respuesta del backend. Usa el patrón async + roMessagePort + wait()
' con timeout, porque GetToString() síncrono no expone el código HTTP
' de forma confiable — GetResponseCode() solo existe en roUrlEvent.

sub init()
    m.top.functionName = "doRequest"
end sub

sub doRequest()
    xfer = CreateObject("roUrlTransfer")
    port = CreateObject("roMessagePort")
    xfer.SetPort(port)
    xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    xfer.InitClientCertificates()
    xfer.SetUrl(m.top.uri)
    xfer.AddHeader("Content-Type", "application/json")
    if m.top.authToken <> ""
        xfer.AddHeader("Authorization", "Bearer " + m.top.authToken)
    end if

    ok = false
    if m.top.method = "POST"
        xfer.SetRequest("POST")
        ok = xfer.AsyncPostFromString(m.top.body)
    else
        ok = xfer.AsyncGetToString()
    end if

    if not ok
        m.top.responseCode = -1
        m.top.responseJson = ""
        return
    end if

    msg = wait(15000, port)
    if type(msg) = "roUrlEvent"
        m.top.responseCode = msg.GetResponseCode()
        m.top.responseJson = msg.GetString()
    else
        xfer.AsyncCancel()
        m.top.responseCode = -1
        m.top.responseJson = ""
    end if
end sub
