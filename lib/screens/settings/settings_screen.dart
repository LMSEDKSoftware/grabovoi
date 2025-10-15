import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        children: [
          _buildSection(
            context,
            'Apariencia',
            [
              _buildThemeSelector(context),
              _buildColorSelector(context),
            ],
          ),
          _buildSection(
            context,
            'Notificaciones',
            [
              _buildNotificationToggle(context),
              _buildReminderTimePicker(context),
            ],
          ),
          _buildSection(
            context,
            'Meditación',
            [
              _buildSoundSelector(context),
              _buildDurationSelector(context),
            ],
          ),
          _buildSection(
            context,
            'Accesibilidad',
            [
              _buildTextScaleSelector(context),
              _buildHighContrastToggle(context),
              _buildScreenReaderToggle(context),
            ],
          ),
          _buildSection(
            context,
            'Información',
            [
              ListTile(
                title: const Text('Versión'),
                subtitle: const Text('1.0.0'),
                trailing: const Icon(Icons.info_outline),
              ),
              ListTile(
                title: const Text('Términos y condiciones'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Mostrar términos
                },
              ),
              ListTile(
                title: const Text('Política de privacidad'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Mostrar política
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return ListTile(
          title: const Text('Tema'),
          subtitle: Text(_getThemeModeName(settings.themeMode)),
          trailing: const Icon(Icons.brightness_6),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Seleccionar tema'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text('Claro'),
                      value: ThemeMode.light,
                      groupValue: settings.themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          settings.setThemeMode(value);
                          Navigator.pop(context);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Oscuro'),
                      value: ThemeMode.dark,
                      groupValue: settings.themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          settings.setThemeMode(value);
                          Navigator.pop(context);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Sistema'),
                      value: ThemeMode.system,
                      groupValue: settings.themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          settings.setThemeMode(value);
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Oscuro';
      case ThemeMode.system:
        return 'Sistema';
    }
  }

  Widget _buildColorSelector(BuildContext context) {
    final colors = [
      {'name': 'Lavanda', 'color': const Color(0xFF9B88C4)},
      {'name': 'Azul', 'color': const Color(0xFF88A8C4)},
      {'name': 'Verde', 'color': const Color(0xFF88C4A8)},
      {'name': 'Rosa', 'color': const Color(0xFFC488A8)},
      {'name': 'Terracota', 'color': const Color(0xFFC4A888)},
    ];

    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return ListTile(
          title: const Text('Color de acento'),
          trailing: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: settings.accentColor,
              shape: BoxShape.circle,
            ),
          ),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Seleccionar color'),
                content: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: colors.map((colorData) {
                    return GestureDetector(
                      onTap: () {
                        settings.setAccentColor(colorData['color'] as Color);
                        Navigator.pop(context);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: colorData['color'] as Color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: settings.accentColor == colorData['color']
                                    ? Colors.white
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(colorData['name'] as String),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return SwitchListTile(
          title: const Text('Notificaciones'),
          subtitle: const Text('Recordatorios y alertas'),
          value: settings.notificationsEnabled,
          onChanged: (value) {
            settings.setNotificationsEnabled(value);
          },
        );
      },
    );
  }

  Widget _buildReminderTimePicker(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return ListTile(
          title: const Text('Hora de recordatorio'),
          subtitle: Text(settings.reminderTime.format(context)),
          trailing: const Icon(Icons.access_time),
          enabled: settings.notificationsEnabled,
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: settings.reminderTime,
            );
            if (time != null) {
              settings.setReminderTime(time);
            }
          },
        );
      },
    );
  }

  Widget _buildSoundSelector(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return ListTile(
          title: const Text('Sonido preferido'),
          subtitle: Text(settings.preferredSound),
          trailing: const Icon(Icons.music_note),
          onTap: () {
            // Mostrar selector de sonido
          },
        );
      },
    );
  }

  Widget _buildDurationSelector(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return ListTile(
          title: const Text('Duración predeterminada'),
          subtitle: Text('${settings.defaultMeditationDuration} minutos'),
          trailing: const Icon(Icons.timer),
          onTap: () {
            // Mostrar selector de duración
          },
        );
      },
    );
  }

  Widget _buildTextScaleSelector(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return ListTile(
          title: const Text('Tamaño de texto'),
          subtitle: Slider(
            value: settings.textScale,
            min: 0.8,
            max: 1.5,
            divisions: 7,
            label: '${(settings.textScale * 100).round()}%',
            onChanged: (value) {
              settings.setTextScale(value);
            },
          ),
        );
      },
    );
  }

  Widget _buildHighContrastToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return SwitchListTile(
          title: const Text('Alto contraste'),
          subtitle: const Text('Mejora la visibilidad'),
          value: settings.highContrastMode,
          onChanged: (value) {
            settings.setHighContrastMode(value);
          },
        );
      },
    );
  }

  Widget _buildScreenReaderToggle(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return SwitchListTile(
          title: const Text('Optimizado para lector de pantalla'),
          subtitle: const Text('Mejora compatibilidad con VoiceOver/TalkBack'),
          value: settings.screenReaderOptimized,
          onChanged: (value) {
            settings.setScreenReaderOptimized(value);
          },
        );
      },
    );
  }
}

