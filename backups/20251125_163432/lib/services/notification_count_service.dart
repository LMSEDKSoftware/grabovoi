import 'dart:async';
import '../models/notification_history_item.dart';

/// Servicio compartido para gestionar el conteo de notificaciones no leídas
/// Permite que múltiples widgets se suscriban y actualicen el conteo
class NotificationCountService {
  static final NotificationCountService _instance = NotificationCountService._internal();
  factory NotificationCountService() => _instance;
  NotificationCountService._internal();

  final StreamController<int> _countController = StreamController<int>.broadcast();
  Timer? _updateTimer;
  int _currentCount = 0;

  /// Stream del conteo de notificaciones
  Stream<int> get countStream => _countController.stream;

  /// Conteo actual
  int get currentCount => _currentCount;

  /// Inicializar el servicio y comenzar a actualizar el conteo periódicamente
  void initialize() {
    // Cargar el conteo inicial
    _updateCount();
    
    // Actualizar el conteo cada 5 segundos
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _updateCount();
    });
  }

  /// Actualizar el conteo manualmente
  Future<void> updateCount() async {
    await _updateCount();
  }

  /// Actualizar el conteo desde la fuente de datos
  Future<void> _updateCount() async {
    try {
      final count = await NotificationHistory.getUnreadCount();
      if (_currentCount != count) {
        _currentCount = count;
        _countController.add(count);
      }
    } catch (e) {
      print('Error actualizando conteo de notificaciones: $e');
    }
  }

  /// Limpiar recursos
  void dispose() {
    _updateTimer?.cancel();
    _countController.close();
  }
}

