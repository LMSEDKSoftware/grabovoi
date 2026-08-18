sub init()
    m.grid = m.top.findNode("grid")
    m.grid.observeField("itemSelected", "onItemSelected")
    m.loadingLabel = m.top.findNode("loadingLabel")
    m.countLabel = m.top.findNode("countLabel")
    m.rutinaAviso = m.top.findNode("rutinaAviso")
    m.rutinaTask = m.top.findNode("rutinaTask")
    m.rutinaTask.observeField("done", "onRutinaGuardada")
    m.sequenceIds = []
    ' Modo seleccion: OK marca en vez de abrir, y se guardan solo las
    ' marcadas. Los indices se guardan en el orden en que se fueron
    ' eligiendo, no en el de la lista: en una rutina el orden es parte de
    ' lo que el usuario esta armando.
    m.modoSeleccion = false
    m.ordenSeleccion = []
    m.grid.visible = false
end sub

function StartLoading() as Void
    m.countLabel.text = ""
    m.catalogTask = m.top.findNode("catalogTask")
    m.catalogTask.observeField("done", "onCatalogResponse")
    m.catalogTask.authToken = m.top.authToken

    if m.top.endpointUri <> invalid and m.top.endpointUri <> ""
        m.top.findNode("title").text = m.top.titulo
        m.catalogTask.uri = m.top.endpointUri
    else
        m.top.findNode("title").text = m.top.categoria
        categoriaEscapada = UrlEncode(m.top.categoria)
        ' 1000 en vez de 100: categorias como "Salud" tienen 627
        ' secuencias, el limite viejo dejaba fuera todo lo que pasara de
        ' las primeras 100 (bug reportado). 1000 es tambien el tope real
        ' de Supabase/PostgREST por consulta, no tiene sentido pedir mas.
        m.catalogTask.uri = ApiBase() + "/roku-catalog?categoria=" + categoriaEscapada + "&limit=1000"
    end if

    m.catalogTask.method = "GET"
    print "SequenceListScreen StartLoading uri="; m.catalogTask.uri
    m.catalogTask.control = "RUN"
end function

sub onCatalogResponse(event as Object)
    result = event.GetData()
    if SesionVencida(m.top, result) then return
    print "SequenceListScreen onCatalogResponse code="; result.code; " json_len="; Len(result.json)
    m.loadingLabel.visible = false
    if result.code <> 200
        m.loadingLabel.visible = true
        m.loadingLabel.text = "No se pudo cargar. Presiona atras."
        return
    end if

    data = ParseJsonSafe(result.json)
    if data = invalid or data.secuencias = invalid
        ' Antes esto se quedaba en blanco sin avisar nada (parecia
        ' congelado: ni el "Cargando..." ni un mensaje de error). Ahora
        ' al menos se ve que algo fallo.
        print "SequenceListScreen respuesta invalida o sin 'secuencias'. json="; result.json
        m.loadingLabel.visible = true
        m.loadingLabel.text = "Respuesta inesperada del servidor."
        return
    end if

    m.sequenceIds = []
    root = CreateObject("roSGNode", "ContentNode")
    for each seq in data.secuencias
        imagen = ""
        if seq.imagen_url <> invalid then imagen = seq.imagen_url
        node = root.CreateChild("ContentNode")
        node.AddFields({
            title: seq.nombre,
            subtitle: seq.codigo,
            color: seq.color,
            imageUrl: imagen,
            seleccionado: false
        })
        m.sequenceIds.Push(seq.id)
    end for

    m.countLabel.text = m.sequenceIds.Count().ToStr() + " secuencias"

    if m.sequenceIds.Count() = 0
        m.loadingLabel.visible = true
        if m.top.endpointUri <> invalid and m.top.endpointUri <> ""
            m.loadingLabel.text = "Todavia no hay nada aqui."
        else
            m.loadingLabel.text = "No hay secuencias en esta categoria."
        end if
        return
    end if

    m.grid.content = root
    m.grid.visible = true
    m.grid.setFocus(true)
    MostrarPistaRutina()
end sub

function RestoreFocus() as Void
    m.grid.setFocus(true)
end function

sub onItemSelected()
    index = m.grid.itemSelected
    if index < 0 or index >= m.sequenceIds.Count()
        return
    end if
    if m.modoSeleccion
        AlternarSeleccion(index)
        return
    end if
    m.top.result = { action: "openSequence", id: m.sequenceIds[index] }
end sub

' ---------------------------------------------------------------
' Modo seleccion
' ---------------------------------------------------------------

sub EntrarModoSeleccion()
    m.modoSeleccion = true
    m.ordenSeleccion = []
    MostrarPistaRutina()
end sub

sub SalirModoSeleccion()
    m.modoSeleccion = false
    for each indice in m.ordenSeleccion
        m.grid.content.getChild(indice).seleccionado = false
    end for
    m.ordenSeleccion = []
    MostrarPistaRutina()
end sub

sub AlternarSeleccion(index as Integer)
    nodo = m.grid.content.getChild(index)
    if nodo = invalid then return

    posicion = -1
    for i = 0 to m.ordenSeleccion.Count() - 1
        if m.ordenSeleccion[i] = index
            posicion = i
            exit for
        end if
    end for

    if posicion >= 0
        m.ordenSeleccion.Delete(posicion)
        nodo.seleccionado = false
    else
        if m.ordenSeleccion.Count() >= 30
            ' El servidor recorta a 30; avisar aqui evita que el usuario
            ' siga marcando cosas que nunca se van a guardar.
            m.rutinaAviso.text = "Una rutina admite hasta 30 secuencias. Quita alguna para agregar otra."
            return
        end if
        m.ordenSeleccion.Push(index)
        nodo.seleccionado = true
    end if

    MostrarPistaRutina()
end sub

' ---------------------------------------------------------------
' Guardar esta lista como rutina
' ---------------------------------------------------------------

function NombreDeLaLista() as String
    if m.top.titulo <> invalid and m.top.titulo <> "" then return m.top.titulo
    return m.top.categoria
end function

sub MostrarPistaRutina()
    if m.sequenceIds.Count() = 0
        m.rutinaAviso.text = ""
        return
    end if

    ' Textos cortos a proposito: este aviso vive en el hueco del
    ' encabezado, entre el titulo y el conteo, y ahi caben unos 42
    ' caracteres antes de encimarse con alguno de los dos.
    if not m.modoSeleccion
        m.rutinaAviso.text = "Opciones (*) para armar un pilotaje"
        return
    end if

    cuantas = m.ordenSeleccion.Count()
    if cuantas = 0
        m.rutinaAviso.text = "Marca con OK  ·  Atrás cancela"
    else if cuantas = 1
        m.rutinaAviso.text = "1 elegida  ·  Opciones (*) guarda"
    else
        m.rutinaAviso.text = cuantas.ToStr() + " elegidas  ·  Opciones (*) guarda"
    end if
end sub

sub PedirNombreDeRutina()
    kb = CreateObject("roSGNode", "KeyboardDialog")
    kb.title = "Nombre de tu pilotaje"
    kb.keyboard.text = NombreDeLaLista()
    kb.buttons = ["Guardar", "Cancelar"]
    kb.observeField("buttonSelected", "onNombreDeRutina")
    m.tecladoRutina = kb
    m.top.getScene().dialog = kb
end sub

sub onNombreDeRutina(event as Object)
    boton = event.GetData()
    nombre = m.tecladoRutina.text.Trim()
    m.top.getScene().dialog = invalid
    if boton <> 0 then return
    if nombre = "" then nombre = NombreDeLaLista()

    ' En el orden en que se fueron eligiendo, que es el orden en que se
    ' van a escuchar.
    ids = []
    for each indice in m.ordenSeleccion
        ids.Push(m.sequenceIds[indice])
    end for
    if ids.Count() = 0 then return

    m.rutinaAviso.text = "Guardando " + Chr(34) + nombre + Chr(34) + "..."
    m.rutinaTask.authToken = m.top.authToken
    m.rutinaTask.uri = ApiBase() + "/roku-perfil"
    m.rutinaTask.method = "POST"
    m.rutinaTask.body = FormatJson({ action: "rutina_crear", nombre: nombre, codigo_ids: ids })
    m.rutinaTask.control = "RUN"
end sub

sub onRutinaGuardada(event as Object)
    result = event.GetData()
    if SesionVencida(m.top, result) then return

    if result.code <> 200
        m.rutinaAviso.text = "No se pudo guardar. Intenta de nuevo."
        return
    end if

    data = ParseJsonSafe(result.json)
    total = 0
    if data <> invalid and data.total <> invalid then total = data.total

    SalirModoSeleccion()
    m.rutinaAviso.text = "Pilotaje guardado con " + total.ToStr() + " secuencias. Lo encuentras en Secuencias Combinadas."
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if m.sequenceIds.Count() = 0 then return false

    if key = "options"
        if not m.modoSeleccion
            EntrarModoSeleccion()
        else if m.ordenSeleccion.Count() > 0
            PedirNombreDeRutina()
        else
            m.rutinaAviso.text = "Marca al menos una secuencia con OK antes de guardar."
        end if
        return true
    end if

    ' Dentro del modo seleccion "atras" cancela la seleccion en vez de
    ' salir de la pantalla: irse de golpe perdiendo lo ya marcado seria
    ' lo contrario de lo que espera quien esta armando una rutina.
    if key = "back" and m.modoSeleccion
        SalirModoSeleccion()
        return true
    end if

    return false
end function
