import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'custom_button.dart';

class FavoriteLabelModal extends StatefulWidget {
  final String codigo;
  final String nombre;
  /// Etiquetas que el usuario ya tiene guardadas (para elegir y no duplicar)
  final List<String> etiquetasExistentes;
  final Function(String etiqueta) onSave;

  const FavoriteLabelModal({
    super.key,
    required this.codigo,
    required this.nombre,
    this.etiquetasExistentes = const [],
    required this.onSave,
  });

  @override
  State<FavoriteLabelModal> createState() => _FavoriteLabelModalState();
}

class _FavoriteLabelModalState extends State<FavoriteLabelModal> {
  final TextEditingController _etiquetaController = TextEditingController();
  final FocusNode _etiquetaFocus = FocusNode();
  /// Índice de la etiqueta existente seleccionada (-1 si ninguna o texto manual)
  int _selectedExistingIndex = -1;

  @override
  void initState() {
    super.initState();
    // Enfocar el campo después de que se construya el modal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _etiquetaFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _etiquetaController.dispose();
    _etiquetaFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      alignment: Alignment.center,
      child: MediaQuery.removeViewInsets(
        removeBottom: true,
        context: context,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1C2541),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFFD700),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Header con título e ícono
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.label,
                      color: Color(0xFFFFD700),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Etiquetar Favorito',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFD700),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Información del código
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Secuencia: ${widget.codigo}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.nombre,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Etiquetas existentes en scroll horizontal (como en favoritos)
              if (widget.etiquetasExistentes.isNotEmpty) ...[
                Text(
                  'Etiquetas que ya usas',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(widget.etiquetasExistentes.length, (i) {
                      final etiqueta = widget.etiquetasExistentes[i];
                      final isSelected = _selectedExistingIndex == i;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedExistingIndex = i;
                            _etiquetaController.text = etiqueta;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFFD700).withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFFFD700).withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            etiqueta,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isSelected ? const Color(0xFFFFD700) : Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Campo para elegir etiqueta existente o escribir una nueva
              TextField(
                controller: _etiquetaController,
                focusNode: _etiquetaFocus,
                onChanged: (_) => setState(() => _selectedExistingIndex = -1),
                maxLength: 30,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZÀ-ÿ0-9\s\-_.,!?'\u0022]"))
                ],
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: widget.etiquetasExistentes.isEmpty
                      ? 'Etiqueta...'
                      : 'Elige una arriba o escribe una nueva',
                  hintStyle: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                  counterText: '', // Ocultar contador de caracteres
                  filled: true,
                  fillColor: const Color(0xFF0B132B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFFFD700),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFFFFD700).withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFFFD700),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancelar',
                      onPressed: () => Navigator.of(context).pop(),
                      isOutlined: true,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Guardar',
                      onPressed: () {
                        final etiqueta = _etiquetaController.text.trim();
                        if (etiqueta.isNotEmpty) {
                          widget.onSave(etiqueta);
                          Navigator.of(context).pop();
                        }
                      },
                      color: const Color(0xFFFFD700),
                    ),
                  ),
                ],
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

