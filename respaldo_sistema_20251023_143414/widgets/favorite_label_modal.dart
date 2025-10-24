import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FavoriteLabelModal extends StatefulWidget {
  final String codigo;
  final String nombre;
  final Function(String etiqueta) onSave;

  const FavoriteLabelModal({
    super.key,
    required this.codigo,
    required this.nombre,
    required this.onSave,
  });

  @override
  State<FavoriteLabelModal> createState() => _FavoriteLabelModalState();
}

class _FavoriteLabelModalState extends State<FavoriteLabelModal> {
  final TextEditingController _etiquetaController = TextEditingController();
  final FocusNode _etiquetaFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _etiquetaController.text = 'Favorito'; // Valor por defecto
    // Enfocar el campo después de que se construya el modal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _etiquetaFocus.requestFocus();
      _etiquetaController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _etiquetaController.text.length,
      );
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
      child: Container(
        margin: const EdgeInsets.all(20),
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
                    'Código: ${widget.codigo}',
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
            
            // Campo de etiqueta
            Text(
              'Etiqueta',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _etiquetaController,
              focusNode: _etiquetaFocus,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'Ej: trabajo, hijo mayor, mi suerte...',
                hintStyle: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 14,
                ),
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
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final etiqueta = _etiquetaController.text.trim();
                      if (etiqueta.isNotEmpty) {
                        widget.onSave(etiqueta);
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                    ),
                    child: Text(
                      'Guardar',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

