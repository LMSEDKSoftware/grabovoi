import 'package:flutter/foundation.dart';

class PilotageStateService extends ChangeNotifier {
  static final PilotageStateService _instance = PilotageStateService._internal();
  factory PilotageStateService() => _instance;
  PilotageStateService._internal();

  bool _isPilotageActive = false;
  bool _isRepetitionActive = false;

  // Getters
  bool get isPilotageActive => _isPilotageActive;
  bool get isRepetitionActive => _isRepetitionActive;
  
  bool get isAnyPilotageActive => _isPilotageActive || _isRepetitionActive;

  // Métodos para actualizar estado
  void setPilotageActive(bool value) {
    _isPilotageActive = value;
    notifyListeners();
  }

  void setRepetitionActive(bool value) {
    _isRepetitionActive = value;
    notifyListeners();
  }

  void resetAllPilotageStates() {
    _isPilotageActive = false;
    _isRepetitionActive = false;
    notifyListeners();
  }
}

