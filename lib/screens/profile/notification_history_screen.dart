import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../widgets/glow_background.dart';
import '../../widgets/custom_button.dart';
import '../../models/notification_history_item.dart';
import '../../services/notification_count_service.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() => _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  List<NotificationHistoryItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await NotificationHistory.getHistory();
    setState(() {
      _notifications = history;
      _isLoading = false;
    });
  }

  Future<void> _markAsRead(String id) async {
    if (!mounted) return;
    
    // Marcar como leída
    await NotificationHistory.markAsRead(id);
    
    // Recargar historial
    await _loadHistory();
    
    // Actualizar contador de notificaciones no leídas
    await NotificationCountService().updateCount();
  }

  Future<void> _markAllAsRead() async {
    if (!mounted) return;
    
    // Marcar todas como leídas
    await NotificationHistory.markAllAsRead();
    
    // Recargar historial
    await _loadHistory();
    
    // Actualizar contador de notificaciones no leídas
    await NotificationCountService().updateCount();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todas las notificaciones marcadas como leídas'),
          backgroundColor: Color(0xFFFFD700),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C2541),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Color(0xFFFF6B6B), size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Limpiar Historial',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar todo el historial de notificaciones?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar Todo'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await NotificationHistory.clearHistory();
      _loadHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Historial eliminado'),
            backgroundColor: Color(0xFFFFD700),
          ),
        );
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Hace un momento';
        }
        return 'Hace ${difference.inMinutes} min';
      }
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  IconData _getIconForType(String type) {
    if (type.contains('Milestone') || type.contains('milestone')) {
      return Icons.emoji_events;
    } else if (type.contains('Streak') || type.contains('streak')) {
      return Icons.local_fire_department;
    } else if (type.contains('Energy') || type.contains('energy')) {
      return Icons.bolt;
    } else if (type.contains('Challenge') || type.contains('challenge')) {
      return Icons.workspace_premium;
    } else if (type.contains('Daily') || type.contains('daily')) {
      return Icons.today;
    } else if (type.contains('Morning') || type.contains('morning')) {
      return Icons.wb_sunny;
    } else if (type.contains('Evening') || type.contains('evening')) {
      return Icons.nightlight;
    } else if (type.contains('First') || type.contains('first')) {
      return Icons.celebration;
    }
    return Icons.notifications;
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
          'Historial de Notificaciones',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFFD700),
          ),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all, color: Color(0xFFFFD700)),
              tooltip: 'Marcar todas como leídas',
              onPressed: _markAllAsRead,
            ),
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              tooltip: 'Limpiar historial',
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: GlowBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                  ),
                )
              : _notifications.isEmpty
                  ? _buildEmptyState()
                  : _buildHistoryList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay notificaciones',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tus notificaciones aparecerán aquí cuando las recibas',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: const Color(0xFFFFD700),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationItem(notification);
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationHistoryItem notification) {
    return InkWell(
      onTap: () {
        // Si no está leída, marcarla como leída al hacer clic
        if (!notification.isRead) {
          _markAsRead(notification.id);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              notification.isRead
                  ? Colors.black.withOpacity(0.2)
                  : const Color(0xFFFFD700).withOpacity(0.15),
              Colors.black.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? Colors.white.withOpacity(0.05)
                : const Color(0xFFFFD700).withOpacity(0.3),
            width: notification.isRead ? 1 : 2,
          ),
          boxShadow: notification.isRead
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFFD700).withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Icon(
                _getIconForType(notification.type),
                color: const Color(0xFFFFD700),
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
                      Expanded(
                        child: Text(
                          notification.title,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.bold,
                            color: notification.isRead
                                ? Colors.white70
                                : Colors.white,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFD700),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification.body,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: notification.isRead
                          ? Colors.white60
                          : Colors.white70,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(notification.timestamp),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

