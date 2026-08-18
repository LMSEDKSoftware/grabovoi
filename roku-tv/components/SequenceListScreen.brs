sub init()
    m.grid = m.top.findNode("grid")
    m.grid.observeField("itemSelected", "onItemSelected")
    m.loadingLabel = m.top.findNode("loadingLabel")
    m.countLabel = m.top.findNode("countLabel")
    m.rutinaAviso = m.top.findNode("rutinaAviso")
    m.rutinaTask = m.top.findNode("rutinaTask")
    m.rutinaTask.observeField("done", "onRutinaGuardada")
    m.combinacionesTask = m.top.findNode("combinacionesTask")
    m.combinacionesTask.observeField("done", "onCombinacionesRecibidas")
    m.combinacionesMostradas = []
    m.favoritosTask = m.top.findNode("favoritosTask")
    m.favoritosTask.observeField("done", "onFavoritosRecibidos")
    ' Codigos que ya son favoritos. Como diccionario y no como lista: se
    ' consulta una vez por tarjeta y con 627 secuencias en Salud recorrer
    ' una lista por cada una se nota.
    m.codigosFavoritos = {}
    m.codigosRecienMarcados = []
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

    ' En paralelo, no en cadena: la lista no tiene por que esperar a los
    ' favoritos para dibujarse, y los corazones aparecen en cuanto
    ' lleguen.
    m.favoritosTask.authToken = m.top.authToken
    m.favoritosTask.uri = ApiBase() + "/roku-favoritos"
    m.favoritosTask.method = "GET"
    m.favoritosTask.control = "RUN"
end function

sub onFavoritosRecibidos(event as Object)
    result = event.GetData()
    if result.code <> 200 then return

    data = ParseJsonSafe(result.json)
    if data = invalid or data.secuencias = invalid then return

    m.codigosFavoritos = {}
    for each secuencia in data.secuencias
        if secuencia.codigo <> invalid then m.codigosFavoritos[secuencia.codigo] = true
    end for
    PintarFavoritos()
end sub

' Marca las tarjetas ya dibujadas. Se llama tanto cuando llegan los
' favoritos (si la lista ya estaba) como cuando llega la lista (si los
' favoritos ya estaban): el orden depende de la red.
sub PintarFavoritos()
    if m.grid.content = invalid then return
    for i = 0 to m.grid.content.getChildCount() - 1
        nodo = m.grid.content.getChild(i)
        if nodo <> invalid and nodo.subtitle <> invalid
            nodo.esFavorito = (m.codigosFavoritos[nodo.subtitle] = true)
        end if
    end for
end sub

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
            seleccionado: false,
            esFavorito: false
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
    PintarFavoritos()
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
            m.rutinaAviso.text = "Máximo 30 por combinación"
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

' Al guardar no se asume que la intencion es crear: puede ser sumar a una
' combinacion que ya existe. Se preguntan las dos cosas en el mismo paso
' para no obligar a ir a otra pantalla a mitad de la seleccion.
sub PedirDestino()
    m.rutinaAviso.text = "Cargando tus combinaciones..."
    m.combinacionesTask.authToken = m.top.authToken
    m.combinacionesTask.uri = ApiBase() + "/roku-perfil?rutinas=1"
    m.combinacionesTask.method = "GET"
    m.combinacionesTask.control = "RUN"
end sub

sub onCombinacionesRecibidas(event as Object)
    result = event.GetData()
    if SesionVencida(m.top, result) then return

    combinaciones = []
    if result.code = 200
        data = ParseJsonSafe(result.json)
        if data <> invalid and data.rutinas <> invalid then combinaciones = data.rutinas
    end if

    ' Favoritos va como destino mas, no como tecla aparte: es tambien una
    ' lista, y asi se descubre solo en vez de esconderse en un boton que
    ' nadie adivina. Ademas permite marcar varias de una vez.
    botones = ["Crear una combinación nueva", "Agregar a Mis favoritos"]
    ' Tope de 6: un dialogo de Roku con mas botones deja de caber en
    ' pantalla y hay que desplazarlo a ciegas.
    m.combinacionesMostradas = []
    for each combinacion in combinaciones
        if m.combinacionesMostradas.Count() >= 6 then exit for
        m.combinacionesMostradas.Push(combinacion)
        botones.Push("Agregar a: " + combinacion.nombre)
    end for

    dialogo = CreateObject("roSGNode", "Dialog")
    dialogo.title = "¿Dónde las guardo?"
    dialogo.message = TextoElegidas() + " seleccionada(s)."
    dialogo.buttons = botones
    dialogo.observeField("buttonSelected", "onDestinoElegido")
    m.dialogoDestino = dialogo
    m.top.getScene().dialog = dialogo
    MostrarPistaRutina()
end sub

function TextoElegidas() as String
    cuantas = m.ordenSeleccion.Count()
    if cuantas = 1 then return "1 secuencia"
    return cuantas.ToStr() + " secuencias"
end function

sub onDestinoElegido(event as Object)
    indice = event.GetData()
    m.top.getScene().dialog = invalid

    if indice = 0
        PedirNombreDeRutina()
        return
    end if

    if indice = 1
        AgregarAFavoritos()
        return
    end if

    ' Los dos primeros botones son fijos (crear y favoritos); de ahi en
    ' adelante van las combinaciones existentes.
    posicion = indice - 2
    if posicion < 0 or posicion >= m.combinacionesMostradas.Count() then return
    AgregarACombinacion(m.combinacionesMostradas[posicion])
end sub

sub AgregarAFavoritos()
    ' Favoritos se guarda por CODIGO, no por id: la llave foranea de
    ' usuario_favoritos apunta a codigos_grabovoi.codigo. Mandar el uuid
    ' falla con un error de tipo.
    codigos = []
    for each indice in m.ordenSeleccion
        nodo = m.grid.content.getChild(indice)
        if nodo <> invalid and nodo.subtitle <> invalid then codigos.Push(nodo.subtitle)
    end for
    if codigos.Count() = 0 then return

    ' Se recuerdan para poder pintarles el corazon en cuanto el servidor
    ' confirme, sin volver a pedir la lista entera.
    m.codigosRecienMarcados = codigos
    m.rutinaAviso.text = "Guardando en favoritos..."
    m.rutinaTask.authToken = m.top.authToken
    m.rutinaTask.uri = ApiBase() + "/roku-favoritos"
    m.rutinaTask.method = "POST"
    m.rutinaTask.body = FormatJson({ codigos: codigos })
    m.rutinaTask.control = "RUN"
end sub

sub AgregarACombinacion(combinacion as Object)
    ids = IdsSeleccionados()
    if ids.Count() = 0 then return

    m.rutinaAviso.text = "Agregando..."
    m.rutinaTask.authToken = m.top.authToken
    m.rutinaTask.uri = ApiBase() + "/roku-perfil"
    m.rutinaTask.method = "POST"
    m.rutinaTask.body = FormatJson({ action: "rutina_agregar", id: combinacion.id, codigo_ids: ids })
    m.rutinaTask.control = "RUN"
end sub

' En el orden en que se fueron eligiendo, que es el orden en que se van a
' escuchar.
function IdsSeleccionados() as Object
    ids = []
    for each indice in m.ordenSeleccion
        ids.Push(m.sequenceIds[indice])
    end for
    return ids
end function

' El aviso vive en el hueco del encabezado y ahi caben unos 42
' caracteres; un nombre largo desbordaria sobre el titulo o el conteo.
function NombreCorto(nombre as Dynamic) as String
    if nombre = invalid then return ""
    if Len(nombre) <= 18 then return nombre
    return Left(nombre, 17) + "…"
end function

sub PedirNombreDeRutina()
    kb = CreateObject("roSGNode", "StandardKeyboardDialog")
    kb.title = "Nombre de tu pilotaje"
    kb.text = NombreDeLaLista()
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

    ids = IdsSeleccionados()
    if ids.Count() = 0 then return

    m.rutinaAviso.text = "Guardando..."
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
    SalirModoSeleccion()

    if data = invalid
        m.rutinaAviso.text = "Guardado."
        return
    end if

    ' Las tres respuestas comparten este ApiTask y se distinguen por sus
    ' campos: favoritos trae "agregados", sumar a una combinacion trae
    ' "agregadas", y crear no trae ninguno de los dos.
    if data.agregados <> invalid
        ' Se marcan localmente en vez de volver a pedir la lista: el
        ' servidor ya confirmo, y asi el corazon aparece al instante.
        for each codigo in m.codigosRecienMarcados
            m.codigosFavoritos[codigo] = true
        end for
        m.codigosRecienMarcados = []
        PintarFavoritos()

        if data.agregados = 0
            m.rutinaAviso.text = "Ya estaban en tus favoritos"
        else
            m.rutinaAviso.text = data.agregados.ToStr() + " en Mis favoritos"
        end if
        return
    end if

    if data.agregadas <> invalid
        nombre = NombreCorto(data.nombre)
        if data.agregadas = 0
            if data.lleno = true
                m.rutinaAviso.text = nombre + " ya tiene 30"
            else
                m.rutinaAviso.text = "Ya estaban en " + nombre
            end if
        else
            m.rutinaAviso.text = data.agregadas.ToStr() + " agregadas a " + nombre
        end if
        return
    end if

    total = 0
    if data.total <> invalid then total = data.total
    m.rutinaAviso.text = "Combinación creada con " + total.ToStr()
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
    if not press then return false
    if m.sequenceIds.Count() = 0 then return false

    if key = "options"
        if not m.modoSeleccion
            EntrarModoSeleccion()
        else if m.ordenSeleccion.Count() > 0
            PedirDestino()
        else
            m.rutinaAviso.text = "Marca al menos una con OK"
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
