import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/glow_background.dart';

/// Muestra si esta cuenta ya vinculó Alexa y/o Roku. Lee la función SQL
/// dispositivos_vinculados() -- las tablas de vínculo tienen RLS sin
/// ninguna política (a propósito, guardan tokens en texto), así que esta
/// función es la única puerta: solo devuelve booleano + fecha, nunca el
/// token.
class LinkedDevicesScreen extends StatefulWidget {
  const LinkedDevicesScreen({super.key});

  @override
  State<LinkedDevicesScreen> createState() => _LinkedDevicesScreenState();
}

class _LinkedDevicesScreenState extends State<LinkedDevicesScreen> {
  bool _cargando = true;
  String? _error;
  bool _alexaVinculado = false;
  DateTime? _alexaDesde;
  bool _rokuVinculado = false;
  DateTime? _rokuDesde;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final fila = await Supabase.instance.client
          .rpc('dispositivos_vinculados')
          .single();
      if (!mounted) return;
      setState(() {
        _alexaVinculado = fila['alexa_vinculado'] == true;
        _alexaDesde = fila['alexa_desde'] != null ? DateTime.tryParse(fila['alexa_desde']) : null;
        _rokuVinculado = fila['roku_vinculado'] == true;
        _rokuDesde = fila['roku_desde'] != null ? DateTime.tryParse(fila['roku_desde']) : null;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo consultar el estado. Intenta de nuevo en un momento.';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Dispositivos vinculados',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFD700),
          ),
        ),
      ),
      body: GlowBackground(
        child: SafeArea(
          child: _cargando
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aquí ves con qué asistentes y televisores está vinculada tu cuenta de ManiGraB.',
                        style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
                      ),
                      const SizedBox(height: 24),
                      if (_error != null)
                        Text(_error!, style: const TextStyle(color: Color(0xFFFF7777)))
                      else ...[
                        _DispositivoCard(
                          icono: Icons.mic,
                          nombre: 'Alexa',
                          vinculado: _alexaVinculado,
                          desde: _alexaDesde,
                          ayudaNoVinculado:
                              'Di "abre secuencias numéricas" a tu Alexa y sigue las instrucciones para vincular tu cuenta.',
                        ),
                        const SizedBox(height: 16),
                        _DispositivoCard(
                          icono: Icons.tv,
                          nombre: 'Roku (ManiGraB TV)',
                          vinculado: _rokuVinculado,
                          desde: _rokuDesde,
                          ayudaNoVinculado:
                              'Abre el canal ManiGraB TV en tu Roku y escanea el código QR, o inicia sesión con tu correo desde el control remoto.',
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _DispositivoCard extends StatelessWidget {
  final IconData icono;
  final String nombre;
  final bool vinculado;
  final DateTime? desde;
  final String ayudaNoVinculado;

  const _DispositivoCard({
    required this.icono,
    required this.nombre,
    required this.vinculado,
    required this.desde,
    required this.ayudaNoVinculado,
  });

  @override
  Widget build(BuildContext context) {
    final acento = vinculado ? const Color(0xFF4CAF50) : const Color(0xFFFFD700);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [acento.withValues(alpha: 0.12), acento.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: acento.withValues(alpha: 0.35), width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: acento, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      nombre,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      vinculado ? Icons.check_circle : Icons.circle_outlined,
                      color: acento,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  vinculado
                      ? (desde != null
                          ? 'Vinculado desde el ${DateFormat('dd/MM/yyyy').format(desde!)}'
                          : 'Vinculado')
                      : ayudaNoVinculado,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
