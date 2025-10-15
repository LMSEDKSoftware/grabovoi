import 'package:flutter/foundation.dart';
// import '../services/database_service.dart';

class FavoritesProvider with ChangeNotifier {
  // final DatabaseService _db = DatabaseService();
  
  Set<String> _favoriteIds = {};
  bool _isLoading = false;

  Set<String> get favoriteIds => _favoriteIds;
  bool get isLoading => _isLoading;

  bool isFavorite(String codeId) {
    return _favoriteIds.contains(codeId);
  }

  Future<void> loadFavorites(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Mock: cargar favoritos desde memoria local
      await Future.delayed(const Duration(milliseconds: 300));
      // _favoriteIds ya contiene los favoritos guardados en memoria
    } catch (e) {
      print('Error cargando favoritos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String userId, String codeId) async {
    if (_favoriteIds.contains(codeId)) {
      _favoriteIds.remove(codeId);
      notifyListeners();
      print('Favorito eliminado (mock): $codeId');
    } else {
      _favoriteIds.add(codeId);
      notifyListeners();
      print('Favorito agregado (mock): $codeId');
    }
  }
}

