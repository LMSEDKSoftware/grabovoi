import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../repositories/codigos_repository.dart';
import '../../services/diario_service.dart';

class NuevaEntradaDiarioScreen extends StatefulWidget {
  final String codigo;
  final String? nombre;

  const NuevaEntradaDiarioScreen({
    super.key,
    required this.codigo,
    this.nombre,
  });

  @override
  State<NuevaEntradaDiarioScreen> createState() => _NuevaEntradaDiarioScreenState();
}

class _NuevaEntradaDiarioScreenState extends State<NuevaEntradaDiarioScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _intencionController = TextEditingController();
  final _sensacionesController = TextEditingController();
  final _gratitudController = TextEditingController();
  final _horasSuenoController = TextEditingController(text: '8');
  
  // Estado del formulario
  String? _estadoAnimo;
  bool _hizoEjercicio = false;
  bool _isLoading = false;
  
  // Opciones para dropdowns
  List<String> _codigosDisponibles = ['Ninguno'];
  Map<String, String> _codigosConTitulos = {}; // Mapa de código -> título
  final List<Map<String, String>> _estadosAnimo = [
    {'value': 'feliz', 'emoji': '😊', 'label': 'Feliz'},
    {'value': 'tranquilo', 'emoji': '😌', 'label': 'Tranquilo'},
    {'value': 'energizado', 'emoji': '⚡', 'label': 'Energizado'},
    {'value': 'grato', 'emoji': '🙏', 'label': 'Grato'},
    {'value': 'neutral', 'emoji': '😐', 'label': 'Neutral'},
    {'value': 'cansado', 'emoji': '😴', 'label': 'Cansado'},
    {'value': 'estresado', 'emoji': '😩', 'label': 'Estresado'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCodigos();
  }

  @override
  void dispose() {
    _intencionController.dispose();
    _sensacionesController.dispose();
    _gratitudController.dispose();
    _horasSuenoController.dispose();
    super.dispose();
  }

  Future<void> _loadCodigos() async {
    try {
      final codigos = CodigosRepository().codigos;
      final codigosList = <String>['Ninguno'];
      final codigosConTitulos = <String, String>{'Ninguno': ''};
      
      // Agregar códigos con sus títulos
      for (final codigo in codigos) {
        codigosList.add(codigo.codigo);
        codigosConTitulos[codigo.codigo] = codigo.nombre;
      }
      
      // Si el código del widget no está en la lista, agregarlo
      if (widget.codigo.isNotEmpty && !codigosList.contains(widget.codigo)) {
        codigosList.insert(1, widget.codigo);
        // Buscar el título del código si existe
        final codigoEncontrado = codigos.firstWhere(
          (c) => c.codigo == widget.codigo,
          orElse: () => codigos.first,
        );
        codigosConTitulos[widget.codigo] = codigoEncontrado.nombre;
      }
      
      // Eliminar duplicados manteniendo el orden
      final codigosUnicos = <String>[];
      final codigosConTitulosUnicos = <String, String>{};
      for (final codigo in codigosList) {
        if (!codigosUnicos.contains(codigo)) {
          codigosUnicos.add(codigo);
          codigosConTitulosUnicos[codigo] = codigosConTitulos[codigo] ?? '';
        }
      }
      
      setState(() {
        _codigosDisponibles = codigosUnicos;
        _codigosConTitulos = codigosConTitulosUnicos;
        // Si el código del widget no está en la lista, agregarlo para mostrar su título
        if (widget.codigo.isNotEmpty && !_codigosConTitulos.containsKey(widget.codigo)) {
          final codigoEncontrado = codigos.firstWhere(
            (c) => c.codigo == widget.codigo,
            orElse: () => codigos.isNotEmpty ? codigos.first : codigos.first,
          );
          _codigosConTitulos[widget.codigo] = codigoEncontrado.nombre;
        }
      });
    } catch (e) {
      print('Error cargando códigos: $e');
    }
  }
  
  String _getDisplayTextForCodigo(String codigo) {
    final titulo = _codigosConTitulos[codigo];
    if (codigo == 'Ninguno' || titulo == null || titulo.isEmpty) {
      return codigo;
    }
    return '$codigo - $titulo';
  }

  Future<void> _guardarEntrada() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final diarioService = DiarioService();
      await diarioService.guardarEntrada(
        codigo: widget.codigo.isNotEmpty ? widget.codigo : null,
        intencion: _intencionController.text.trim(),
        estadoAnimo: _estadoAnimo,
        sensaciones: _sensacionesController.text.trim().isEmpty 
            ? null 
            : _sensacionesController.text.trim(),
        horasSueno: int.tryParse(_horasSuenoController.text),
        hizoEjercicio: _hizoEjercicio,
        gratitud: _gratitudController.text.trim().isEmpty 
            ? null 
            : _gratitudController.text.trim(),
        fecha: DateTime.now(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Entrada guardada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Retornar true para indicar éxito
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar entrada: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlowBackground(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFFFD700)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Row(
            children: [
              const Icon(Icons.calendar_today, color: Color(0xFFFFD700), size: 24),
              const SizedBox(width: 12),
              Text(
                'Nueva Entrada',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFD700),
                ),
              ),
            ],
          ),
          centerTitle: false,
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registra tu práctica de hoy',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),

                // Secuencia Utilizada (solo lectura - viene de la sesión terminada)
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Secuencia Utilizada',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.tag,
                                  color: Color(0xFFFFD700),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.codigo.isNotEmpty
                                        ? (_codigosConTitulos.containsKey(widget.codigo) && _codigosConTitulos[widget.codigo]!.isNotEmpty
                                            ? '${widget.codigo} - ${_codigosConTitulos[widget.codigo]}'
                                            : widget.codigo)
                                        : 'Sin código',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Estado de Ánimo
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado de Ánimo',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _estadoAnimo,
                      decoration: InputDecoration(
                        hintText: '¿Cómo te sientes?',
                        hintStyle: GoogleFonts.inter(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      dropdownColor: const Color(0xFF1C2541),
                      style: GoogleFonts.inter(color: Colors.white),
                      items: _estadosAnimo.map((estado) {
                        return DropdownMenuItem(
                          value: estado['value'],
                          child: Row(
                            children: [
                              Text(estado['emoji']!),
                              const SizedBox(width: 12),
                              Text(estado['label']!),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _estadoAnimo = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Intención (obligatorio)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Intención',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '*',
                          style: TextStyle(color: Colors.red, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _intencionController,
                      decoration: InputDecoration(
                        hintText: '¿Qué deseas manifestar o trabajar hoy?',
                        hintStyle: GoogleFonts.inter(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: GoogleFonts.inter(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La intención es obligatoria';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Sensaciones y Resultados
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sensaciones y Resultados',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _sensacionesController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Describe cómo te sientes durante y después de la práctica...',
                        hintStyle: GoogleFonts.inter(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Horas de Sueño y Ejercicio
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Horas de Sueño',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _horasSuenoController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            style: GoogleFonts.inter(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hice ejercicio hoy',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _hizoEjercicio 
                                    ? const Color(0xFFFFD700) 
                                    : Colors.white.withOpacity(0.3),
                                width: _hizoEjercicio ? 2 : 1,
                              ),
                            ),
                            child: CheckboxListTile(
                              title: Text(
                                'Ejercicio',
                                style: GoogleFonts.inter(color: Colors.white),
                              ),
                              value: _hizoEjercicio,
                              onChanged: (value) {
                                setState(() {
                                  _hizoEjercicio = value ?? false;
                                });
                              },
                              activeColor: const Color(0xFFFFD700),
                              checkColor: Colors.black,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Gratitud
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gratitud',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _gratitudController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: '¿Por qué estás agradecido/a hoy?',
                        hintStyle: GoogleFonts.inter(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Botón Guardar
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: _isLoading ? 'Guardando...' : 'Guardar Entrada',
                    onPressed: _isLoading ? null : _guardarEntrada,
                    color: const Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

