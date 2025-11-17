import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../models/notification_preferences.dart';
import '../../models/notification_history_item.dart';
import '../../services/notification_scheduler.dart';
import '../../services/notification_service.dart';
import '../../scripts/test_all_notifications.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  late NotificationPreferences _preferences;
  bool _isLoading = true;
  
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
  
  Future<void> _updatePreferences(NotificationPreferences newPrefs) async {
    setState(() {
      _preferences = newPrefs;
    });
    await newPrefs.save();
    await NotificationScheduler().updatePreferences(newPrefs);
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
          'Configurar Notificaciones',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFD700),
          ),
        ),
      ),
      body: GlowBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado
                Text(
                  'Personaliza tus notificaciones para mantenerte conectado con tu práctica cuántica.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Toggle principal
                _buildMainToggle(),
                const SizedBox(height: 24),
                
                if (_preferences.enabled) ...[
                  // Recordatorios
                  _buildSectionTitle('Recordatorios Diarios'),
                  const SizedBox(height: 16),
                  _buildToggle(
                    title: 'Código del Día',
                    subtitle: 'Recibe el código Grabovoi diario a las 9:00 AM',
                    value: _preferences.dailyCodeReminders,
                    onChanged: (val) => _updatePreferences(_preferences.copyWith(dailyCodeReminders: val)),
                  ),
                  const SizedBox(height: 12),
                  _buildToggle(
                    title: 'Rutina Matutina',
                    subtitle: 'Recordatorio para comenzar el día con energía',
                    value: _preferences.morningReminders,
                    onChanged: (val) => _updatePreferences(_preferences.copyWith(morningReminders: val)),
                  ),
                  const SizedBox(height: 12),
                  _buildToggle(
                    title: 'Rutina Vespertina',
                    subtitle: 'Recordatorio para completar tu práctica',
                    value: _preferences.eveningReminders,
                    onChanged: (val) => _updatePreferences(_preferences.copyWith(eveningReminders: val)),
                  ),
                  const SizedBox(height: 32),
                  
                  // Progreso
                  _buildSectionTitle('Progreso y Logros'),
                  const SizedBox(height: 16),
                  _buildToggle(
                    title: 'Rachas en Riesgo',
                    subtitle: 'Avisos cuando tu racha puede perderse',
                    value: _preferences.streakReminders,
                    onChanged: (val) => _updatePreferences(_preferences.copyWith(streakReminders: val)),
                  ),
                  const SizedBox(height: 12),
                  _buildToggle(
                    title: 'Celebración de Hitos',
                    subtitle: 'Felicitaciones por logros alcanzados',
                    value: _preferences.achievementCelebrations,
                    onChanged: (val) => _updatePreferences(_preferences.copyWith(achievementCelebrations: val)),
                  ),
                  const SizedBox(height: 12),
                  _buildToggle(
                    title: 'Alertas de Energía',
                    subtitle: 'Notificaciones sobre tu nivel energético',
                    value: _preferences.energyLevelAlerts,
                    onChanged: (val) => _updatePreferences(_preferences.copyWith(energyLevelAlerts: val)),
                  ),
                  const SizedBox(height: 32),
                  
                  // Desafíos
                  _buildSectionTitle('Desafíos'),
                  const SizedBox(height: 16),
                  _buildToggle(
                    title: 'Recordatorios de Desafíos',
                    subtitle: 'Avisos sobre tus desafíos activos',
                    value: _preferences.challengeReminders,
                    onChanged: (val) => _updatePreferences(_preferences.copyWith(challengeReminders: val)),
                  ),
                  const SizedBox(height: 32),
                  
                  // Contenido
                  _buildSectionTitle('Contenido Personalizado'),
                  const SizedBox(height: 16),
                  _buildToggle(
                    title: 'Mensajes Motivacionales',
                    subtitle: 'Inspiración semanal para tu práctica',
                    value: _preferences.motivationalMessages,
                    onChanged: (val) => _updatePreferences(_preferences.copyWith(motivationalMessages: val)),
                  ),
                  const SizedBox(height: 12),
                  _buildToggle(
                    title: 'Resumen Semanal',
                    subtitle: 'Recibe tus estadísticas cada domingo',
                    value: _preferences.weeklySummaries,
                    onChanged: (val) => _updatePreferences(_preferences.copyWith(weeklySummaries: val)),
                  ),
                  const SizedBox(height: 32),
                  
                  // Opciones de audio
                  _buildSectionTitle('Opciones de Sonido'),
                  const SizedBox(height: 16),
                  _buildToggle(
                    title: 'Reproducir Sonido',
                    subtitle: 'Activar sonidos en notificaciones',
                    value: _preferences.soundEnabled,
                    onChanged: (val) => _updatePreferences(_preferences.copyWith(soundEnabled: val)),
                  ),
                  const SizedBox(height: 12),
                  _buildToggle(
                    title: 'Vibración',
                    subtitle: 'Vibrar al recibir notificaciones',
                    value: _preferences.vibrationEnabled,
                    onChanged: (val) => _updatePreferences(_preferences.copyWith(vibrationEnabled: val)),
                  ),
                  const SizedBox(height: 32),
                ],
                
                // Botón de prueba (solo si las notificaciones están habilitadas)
                if (_preferences.enabled) ...[
                  _buildTestSection(),
                  const SizedBox(height: 24),
                ],
                
                // Botón guardar
                CustomButton(
                  text: 'Guardar Cambios',
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Configuración de notificaciones guardada'),
                        backgroundColor: Color(0xFFFFD700),
                      ),
                    );
                  },
                  icon: Icons.check,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildMainToggle() {
    return Container(
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
          Icon(
            Icons.notifications_active,
            color: const Color(0xFFFFD700),
            size: 32,
          ),
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
                  'Activa o desactiva todas las notificaciones',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _preferences.enabled,
            onChanged: (val) => _updatePreferences(_preferences.copyWith(enabled: val)),
            activeColor: const Color(0xFFFFD700),
            activeTrackColor: const Color(0xFFFFD700).withOpacity(0.5),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: const Color(0xFFFFD700),
      ),
    );
  }
  
  Widget _buildToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFFFD700),
            activeTrackColor: const Color(0xFFFFD700).withOpacity(0.5),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTestSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.purple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.science,
                color: Colors.blue,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Probar Notificaciones',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Envía todas las notificaciones disponibles para verificar que funcionan correctamente. Las notificaciones se enviarán respetando el rate limiting (máximo 2 por minuto).',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1C2541),
                        title: Text(
                          'Probar Notificaciones',
                          style: GoogleFonts.inter(color: Colors.white),
                        ),
                        content: Text(
                          'Se enviarán todas las notificaciones disponibles (18 notificaciones). Esto tomará aproximadamente 9 minutos debido al rate limiting (máximo 2 notificaciones por minuto).\n\n¿Deseas continuar?',
                          style: GoogleFonts.inter(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              'Cancelar',
                              style: GoogleFonts.inter(color: Colors.grey),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              'Continuar',
                              style: GoogleFonts.inter(color: const Color(0xFFFFD700)),
                            ),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirm == true && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('🧪 Iniciando prueba de notificaciones...'),
                          backgroundColor: Colors.blue,
                          duration: Duration(seconds: 2),
                        ),
                      );
                      
                      // Enviar todas las notificaciones con delays
                      TestAllNotifications.sendAllTestNotifications(
                        delaySeconds: 30, // 30 segundos = máximo 2 por minuto
                      ).catchError((error) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ Error: $error'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      });
                    }
                  },
                  icon: Icon(Icons.send, color: Colors.white),
                  label: Text(
                    'Enviar Todas (30s entre cada una)',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('⚡ Enviando notificaciones rápidamente...'),
                        backgroundColor: Colors.purple,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    
                    // Enviar todas rápidamente (el rate limiting las procesará)
                    TestAllNotifications.sendAllNotificationsRapid().catchError((error) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('❌ Error: $error'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    });
                  },
                  icon: Icon(Icons.flash_on, color: Colors.purple),
                  label: Text(
                    'Enviar Rápidamente (con rate limiting)',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: Colors.purple,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple,
                    side: BorderSide(color: Colors.purple),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

