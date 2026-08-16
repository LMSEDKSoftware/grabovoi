sub init()
    m.grid = m.top.findNode("grid")
    m.grid.observeField("itemSelected", "onItemSelected")

    m.docIds = ["privacidad", "terminos", "almacenamiento"]
    titulos = ["Política de Privacidad", "Términos y Condiciones de Uso", "Almacenamiento en el Dispositivo"]

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
