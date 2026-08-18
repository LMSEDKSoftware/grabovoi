sub init()
    m.grid = m.top.findNode("grid")
    m.grid.observeField("itemSelected", "onItemSelected")

    ' "Aviso de salud" es el mismo texto del modal que se reconoce una
    ' sola vez antes de la primera secuencia; aqui queda para releerlo
    ' cuando se quiera, sin volver a bloquear el contenido.
    m.docIds = ["privacidad", "terminos", "almacenamiento", "salud"]
    titulos = ["Política de Privacidad", "Términos y Condiciones de Uso", "Almacenamiento en el Dispositivo", "Aviso de salud"]

    root = CreateObject("roSGNode", "ContentNode")
    for each t in titulos
        item = root.CreateChild("ContentNode")
        item.title = t
        item.AddFields({ color: "#F4F1E8" })
    end for
    m.grid.content = root
    m.grid.setFocus(true)
end sub

function StartLoading() as Void
    ' No hay datos que cargar -- el contenido de esta pantalla es fijo.
end function

function RestoreFocus() as Void
    m.grid.setFocus(true)
end function

sub onItemSelected()
    index = m.grid.itemSelected
    if index < 0 or index >= m.docIds.Count()
        return
    end if
    m.top.result = { action: "openDoc", docId: m.docIds[index] }
end sub
