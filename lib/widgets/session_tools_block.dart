import 'package:flutter/material.dart';
import 'streamed_music_controller.dart';

/// Bloque unificado reutilizable: selector de color, descripción, repetición guiada (opcional) y control de audio.
/// Si [hasGuidedRepetition] es false (usuario no tiene el ítem de la tienda cuántica), la sección
/// "Repetición guiada" se oculta y el control de audio queda inmediatamente debajo de la descripción.
class SessionToolsBlock extends StatelessWidget {
  /// Contenido del selector de color (Row de colores + fullscreen).
  final Widget colorSelectorChild;

  /// Contenido de la card de descripción (título, descripción, etc.).
  final Widget descriptionChild;

  /// Si el usuario tiene adquirida la repetición guiada (voz numérica) en la tienda cuántica.
  /// Cuando false, la card "Repetición guiada" no se muestra y el audio se recorre hacia arriba.
  final bool hasGuidedRepetition;

  /// Contenido del toggle de repetición guiada (solo usado si [hasGuidedRepetition] es true).
  final Widget voiceToggleChild;

  /// Callback al tocar la card de repetición guiada (solo si [hasGuidedRepetition] es true).
  final VoidCallback? onVoiceToggle;

  /// Key para el [StreamedMusicController] (ej. ValueKey(seed) para forzar rebuild).
  final Key? musicControllerKey;

  /// autoPlay para el reproductor de música.
  final bool musicAutoPlay;

  /// isActive para el reproductor de música.
  final bool musicIsActive;

  const SessionToolsBlock({
    super.key,
    required this.colorSelectorChild,
    required this.descriptionChild,
    required this.hasGuidedRepetition,
    required this.voiceToggleChild,
    this.onVoiceToggle,
    this.musicControllerKey,
    this.musicAutoPlay = false,
    this.musicIsActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1) Color
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1a1a2e).withOpacity(0.82),
                  const Color(0xFF16213e).withOpacity(0.82),
                  const Color(0xFF0f3460).withOpacity(0.82),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.25),
                width: 1,
              ),
            ),
            child: Center(child: colorSelectorChild),
          ),
          // 2) Descripción
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1a1a2e).withOpacity(0.82),
                  const Color(0xFF16213e).withOpacity(0.82),
                  const Color(0xFF0f3460).withOpacity(0.82),
                ],
              ),
              border: Border(
                top: BorderSide(
                  color: const Color(0xFFFFD700).withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: descriptionChild,
          ),
          // 3) Repetición guiada (solo si el usuario tiene el ítem en la tienda cuántica)
          if (hasGuidedRepetition)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onVoiceToggle,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1a1a2e).withOpacity(0.82),
                        const Color(0xFF16213e).withOpacity(0.82),
                        const Color(0xFF0f3460).withOpacity(0.82),
                      ],
                    ),
                    border: Border(
                      top: BorderSide(
                        color: const Color(0xFFFFD700).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Center(child: voiceToggleChild),
                ),
              ),
            ),
          // 4) Audio
          StreamedMusicController(
            key: musicControllerKey,
            autoPlay: musicAutoPlay,
            isActive: musicIsActive,
            embeddedInBlock: true,
          ),
        ],
      ),
    );
  }
}
