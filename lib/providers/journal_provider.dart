import 'package:flutter/foundation.dart';
import '../models/journal_entry.dart';
// import '../services/database_service.dart';

class JournalProvider with ChangeNotifier {
  // final DatabaseService _db = DatabaseService();
  
  List<JournalEntry> _entries = [];
  bool _isLoading = false;

  List<JournalEntry> get entries => _entries;
  bool get isLoading => _isLoading;

  Future<void> loadEntries(String userId, {int? limit}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Mock: mantener entradas en memoria
      await Future.delayed(const Duration(milliseconds: 300));
      // _entries ya contiene las entradas guardadas
    } catch (e) {
      print('Error cargando entradas: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveEntry(JournalEntry entry, String userId) async {
    try {
      // Mock: guardar en memoria
      final index = _entries.indexWhere((e) => e.id == entry.id);
      if (index != -1) {
        _entries[index] = entry;
      } else {
        _entries.insert(0, entry);
      }
      notifyListeners();
      print('Entrada guardada (mock): ${entry.id}');
    } catch (e) {
      print('Error guardando entrada: $e');
      rethrow;
    }
  }

  Future<void> deleteEntry(String entryId, String userId) async {
    try {
      // Mock: eliminar de memoria
      _entries.removeWhere((e) => e.id == entryId);
      notifyListeners();
      print('Entrada eliminada (mock): $entryId');
    } catch (e) {
      print('Error eliminando entrada: $e');
      rethrow;
    }
  }

  Future<JournalEntry?> getEntryById(String id) async {
    try {
      return _entries.firstWhere((e) => e.id == id);
    } catch (e) {
      print('Error obteniendo entrada: $e');
      return null;
    }
  }

  JournalEntry? getTodayEntry() {
    final today = DateTime.now();
    try {
      return _entries.firstWhere(
        (entry) =>
            entry.date.year == today.year &&
            entry.date.month == today.month &&
            entry.date.day == today.day,
      );
    } catch (e) {
      return null;
    }
  }

  Map<String, double> getAverageMoodRatings({int days = 7}) {
    final now = DateTime.now();
    final recentEntries = _entries.where((entry) {
      return now.difference(entry.date).inDays <= days;
    }).toList();

    if (recentEntries.isEmpty) {
      return {};
    }

    final Map<String, List<int>> moodData = {};
    
    for (final entry in recentEntries) {
      entry.moodRatings.forEach((mood, rating) {
        moodData.putIfAbsent(mood, () => []).add(rating);
      });
    }

    return moodData.map((mood, ratings) {
      final average = ratings.reduce((a, b) => a + b) / ratings.length;
      return MapEntry(mood, average);
    });
  }
}

