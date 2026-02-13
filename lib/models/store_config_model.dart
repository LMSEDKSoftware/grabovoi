/// Paquete de cristales (compra con MXN)
class PaqueteCristales {
  final String id;
  final int cantidadCristales;
  final int precioMxn;
  final bool activo;
  final int orden;

  PaqueteCristales({
    required this.id,
    required this.cantidadCristales,
    required this.precioMxn,
    this.activo = true,
    this.orden = 0,
  });

  factory PaqueteCristales.fromJson(Map<String, dynamic> json) {
    return PaqueteCristales(
      id: json['id'] as String,
      cantidadCristales: (json['cantidad_cristales'] ?? 0) as int,
      precioMxn: (json['precio_mxn'] ?? 0) as int,
      activo: (json['activo'] ?? true) as bool,
      orden: (json['orden'] ?? 0) as int,
    );
  }
}

/// Elemento de tienda (Voz numérica, Ancla de Continuidad, etc.)
class ElementoTienda {
  final String id;
  final String tipo; // voz_numerica, ancla_continuidad
  final String nombre;
  final String? descripcion;
  final int costoCristales;
  final String? icono;
  final bool activo;
  final int orden;
  final Map<String, dynamic> metadata;

  ElementoTienda({
    required this.id,
    required this.tipo,
    required this.nombre,
    this.descripcion,
    required this.costoCristales,
    this.icono,
    this.activo = true,
    this.orden = 0,
    this.metadata = const {},
  });

  int get maxAnclas => (metadata['max_anclas'] as num?)?.toInt() ?? 2;

  factory ElementoTienda.fromJson(Map<String, dynamic> json) {
    return ElementoTienda(
      id: json['id'] as String,
      tipo: json['tipo'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      costoCristales: (json['costo_cristales'] ?? 0) as int,
      icono: json['icono'] as String?,
      activo: (json['activo'] ?? true) as bool,
      orden: (json['orden'] ?? 0) as int,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}
