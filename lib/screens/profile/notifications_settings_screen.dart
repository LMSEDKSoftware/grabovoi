import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/glow_background.dart';
import '../../models/notification_preferences.dart';
import '../../services/notification_scheduler.dart';

/// Un solo interruptor general: enciende o apaga TODAS las notificaciones
/// (los recordatorios diarios locales y los avisos que manda el servidor:
/// desafíos, rachas, hitos, resumen semanal, etc.). Antes esta pantalla
/// mostraba interruptores por categoría que en su mayoría no hacían nada
/// real (la preferencia solo vivía en el dispositivo, nunca llegaba al
/// servidor), así que se simplificó a lo único que de verdad se puede
/// controlar de forma confiable.
class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  late NotificationPreferences _preferences;
  bool _isLoading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await NotificationPreferences.load();
    setState(() {
      _preferences = prefs;
      _isLoading = false;
    });
  }

  Future<void> _setEnabled(bool enabled) async {
    setState(() {
      _preferences = _preferences.copyWith(enabled: enabled);
      _saving = true;
    });

    await _preferences.save();

    // Servidor primero, e independiente de lo local: send-push consulta esta
    // columna antes de enviar cualquier push (desafíos, rachas, hitos,
    // resumen semanal, etc.), así que es la parte que de verdad importa.
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client
            .from('users')
            .update({'notifications_enabled': enabled})
            .eq('id', userId);
      }
    } catch (e) {
      debugPrint('⚠️ Error sincronizando con el servidor: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ No se pudo guardar: $e'), backgroundColor: Colors.red),
        );
      }
    }

    // Local: reprograma/cancela los recordatorios diarios en el dispositivo.
    // No aplica en web; un fallo aquí no debe tapar que el guardado en el
    // servidor (lo que de verdad detiene los pushes) sí haya funcionado.
    try {
      await NotificationScheduler().updatePreferences(_preferences);
    } catch (e) {
      debugPrint('⚠️ Error reprogramando notificaciones locales: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B132B),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
          ),
        ),
      );
    }

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
          'Notificaciones',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFD700),
          ),
        ),
      ),
      body: GlowBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activa o desactiva todas las notificaciones de ManiGraB: recordatorios diarios, desafíos, rachas, hitos y resúmenes.',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFD700).withOpacity(0.1),
                        const Color(0xFFFFD700).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active, color: Color(0xFFFFD700), size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notificaciones',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _preferences.enabled ? 'Activadas' : 'Desactivadas',
                              style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      _saving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFD700)),
                            )
                          : Switch(
                              value: _preferences.enabled,
                              onChanged: _setEnabled,
                              activeColor: const Color(0xFFFFD700),
                              activeTrackColor: const Color(0xFFFFD700).withOpacity(0.5),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
