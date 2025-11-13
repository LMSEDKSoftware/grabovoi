import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget para mostrar notificaciones de recompensas obtenidas
class RewardNotification extends StatelessWidget {
  final int cristalesGanados;
  final double? luzCuanticaAnterior;
  final double? luzCuanticaActual;
  final String tipoAccion; // 'repeticion', 'pilotaje_cuantico', 'pilotaje_reto_diario', 'desafio'

  const RewardNotification({
    super.key,
    required this.cristalesGanados,
    this.luzCuanticaAnterior,
    this.luzCuanticaActual,
    this.tipoAccion = 'repeticion',
  });

  @override
  Widget build(BuildContext context) {
    final bool tieneLuzCuantica = luzCuanticaAnterior != null && luzCuanticaActual != null;
    final double porcentajeLuzCuantica = luzCuanticaActual != null ? luzCuanticaActual! : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFFD700).withOpacity(0.2),
            const Color(0xFFFFD700).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título de felicitación
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.celebration,
                color: Color(0xFFFFD700),
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                '¡Felicitaciones!',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFD700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Notificación de cristales ganados
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.diamond,
                  color: Color(0xFFFFD700),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Has recibido $cristalesGanados cristales de energía',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Notificación de luz cuántica si aplica
          if (tieneLuzCuantica && luzCuanticaActual! > luzCuanticaAnterior!) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFFFFD700),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Has incrementado a ${porcentajeLuzCuantica.toInt()}% tu Luz cuántica',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget compacto para mostrar recompensas en botones
class RewardBadge extends StatelessWidget {
  final int cristales;
  final bool mostrarLuzCuantica;
  final double? luzCuanticaPorcentaje;

  const RewardBadge({
    super.key,
    required this.cristales,
    this.mostrarLuzCuantica = false,
    this.luzCuanticaPorcentaje,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '+$cristales',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFD700),
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.diamond,
          color: Color(0xFFFFD700),
          size: 16,
        ),
        if (mostrarLuzCuantica && luzCuanticaPorcentaje != null) ...[
          const SizedBox(width: 8),
          Text(
            '+${luzCuanticaPorcentaje!.toInt()}%',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFD700),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.auto_awesome,
            color: Color(0xFFFFD700),
            size: 16,
          ),
        ],
      ],
    );
  }
}

