import 'package:flutter/foundation.dart';
import '../models/grabovoi_code.dart';
// import '../services/database_service.dart';
import '../data/mock_data.dart';

class CodesProvider with ChangeNotifier {
  // final DatabaseService _db = DatabaseService();
  
  List<GrabovoiCode> _codes = [];
  List<GrabovoiCode> _filteredCodes = [];
  bool _isLoading = false;
  String? _selectedCategory;
  String _searchQuery = '';

  List<GrabovoiCode> get codes => _filteredCodes;
  bool get isLoading => _isLoading;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  Future<void> loadCodes() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Usar datos mock en lugar de base de datos
      await Future.delayed(const Duration(milliseconds: 500)); // Simular carga
      _codes = MockData.getCodes();
      _filterCodes();
    } catch (e) {
      print('Error cargando códigos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(String? category) {
    _selectedCategory = category;
    _filterCodes();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _filterCodes();
    notifyListeners();
  }

  void _filterCodes() {
    _filteredCodes = _codes.where((code) {
      final matchesCategory = _selectedCategory == null || 
          code.category == _selectedCategory;
      
      final matchesSearch = _searchQuery.isEmpty ||
          code.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          code.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          code.code.contains(_searchQuery);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<GrabovoiCode?> getCodeById(String id) async {
    try {
      // Buscar en los datos mock
      return _codes.firstWhere((code) => code.id == id);
    } catch (e) {
      print('Error obteniendo código: $e');
      return null;
    }
  }

  Future<void> incrementPopularity(String codeId) async {
    try {
      // En modo mock, solo incrementamos localmente
      final index = _codes.indexWhere((code) => code.id == codeId);
      if (index != -1) {
        _codes[index] = _codes[index].copyWith(
          popularityScore: _codes[index].popularityScore + 1,
        );
      }
    } catch (e) {
      print('Error incrementando popularidad: $e');
    }
  }

  List<GrabovoiCode> getRecommendedCodes({int limit = 5}) {
    final sorted = List<GrabovoiCode>.from(_codes)
      ..sort((a, b) => b.popularityScore.compareTo(a.popularityScore));
    return sorted.take(limit).toList();
  }
}

