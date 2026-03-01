import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import '../services/permissions_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modal para solicitar permisos de forma amigable después del login
class PermissionsRequestModal extends StatefulWidget {
  const PermissionsRequestModal({super.key});

  /// Verificar si se debe mostrar el modal
  static Future<bool> shouldShowModal() async {
    if (Platform.isAndroid) {
      return false; // Solo mostrar en iOS
    }

    final prefs = await SharedPreferences.getInstance();
    final hasSeenModal = prefs.getBool('permissions_modal_shown') ?? false;

    // Si ya se mostró, no mostrar de nuevo
    if (hasSeenModal) {
      return false;
    }

    // Verificar si los permisos ya están otorgados
    final permissionsService = PermissionsService();
    final status = await permissionsService.checkPermissionsStatus();

    // Si ya tiene todos los permisos, no mostrar
    if (status['notifications'] == true && status['photos'] == true) {
      // Marcar como visto para no mostrar de nuevo
      await prefs.setBool('permissions_modal_shown', true);
      return false;
    }

    return true;
  }

  @override
  State<PermissionsRequestModal> createState() =>
      _PermissionsRequestModalState();
}

class _PermissionsRequestModalState extends State<PermissionsRequestModal> {
  bool _isRequesting = false;
  bool _notificationsGranted = false;
  bool _photosGranted = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentPermissions();
  }

  Future<void> _checkCurrentPermissions() async {
    final permissionsService = PermissionsService();
    final status = await permissionsService.checkPermissionsStatus();

    setState(() {
      _notificationsGranted = status['notifications'] ?? false;
      _photosGranted = status['photos'] ?? false;
    });
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isRequesting = true;
    });

    try {
      final permissionsService = PermissionsService();

      // Solicitar permisos
      await permissionsService.requestInitialPermissions();

      // Verificar estado después de solicitar
      await _checkCurrentPermissions();

      // Marcar como visto
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('permissions_modal_shown', true);

      // Si se otorgaron los permisos, cerrar el modal
      if (_notificationsGranted && _photosGranted) {
        if (mounted) {
          Navigator.of(context).pop();

          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Permisos otorgados correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Si no se otorgaron todos, mostrar mensaje
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '⚠ Algunos permisos no fueron otorgados. La opción de Fotos aparecerá en Configuración > MANIGRAB cuando intentes usar la galería por primera vez (por ejemplo, al seleccionar un avatar).'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 6),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error solicitando permisos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al solicitar permisos: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
      }
    }
  }

  Future<void> _skipPermissions() async {
    // Marcar como visto para no mostrar de nuevo
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permissions_modal_shown', true);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active,
                size: 40,
                color: Color(0xFFFFD700),
              ),
            ),
            const SizedBox(height: 24),

            // Título
            const Text(
              'Permisos Necesarios',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Descripción
            const Text(
              'Para brindarte la mejor experiencia, necesitamos algunos permisos:',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Lista de permisos
            _buildPermissionItem(
              icon: Icons.notifications,
              title: 'Notificaciones',
              description: 'Para recordarte tus rutinas y logros',
              granted: _notificationsGranted,
            ),
            const SizedBox(height: 16),
            _buildPermissionItem(
              icon: Icons.photo_library,
              title: 'Fotos',
              description: 'Para seleccionar tu avatar y guardar imágenes',
              granted: _photosGranted,
            ),
            const SizedBox(height: 32),

            // Botones
            Row(
              children: [
                // Botón "Más tarde"
                Expanded(
                  child: TextButton(
                    onPressed: _isRequesting ? null : _skipPermissions,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                    ),
                    child: const Text(
                      'Más tarde',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Botón "Permitir"
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isRequesting ? null : _requestPermissions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isRequesting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : const Text(
                            'Permitir',
                            style: TextStyle(
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

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required bool granted,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: granted
                ? Colors.green.withOpacity(0.2)
                : const Color(0xFFFFD700).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: granted ? Colors.green : const Color(0xFFFFD700),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: granted ? Colors.green : Colors.white,
                    ),
                  ),
                  if (granted) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
