import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Configuraciones
  ThemeMode _themeMode = ThemeMode.system;
  Color _accentColor = const Color(0xFF9B88C4);
  bool _notificationsEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  String _preferredSound = 'bells';
  int _defaultMeditationDuration = 10;
  bool _focusModeEnabled = false;
  double _textScale = 1.0;
  bool _highContrastMode = false;
  bool _screenReaderOptimized = false;

  // Getters
  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
  bool get notificationsEnabled => _notificationsEnabled;
  TimeOfDay get reminderTime => _reminderTime;
  String get preferredSound => _preferredSound;
  int get defaultMeditationDuration => _defaultMeditationDuration;
  bool get focusModeEnabled => _focusModeEnabled;
  double get textScale => _textScale;
  bool get highContrastMode => _highContrastMode;
  bool get screenReaderOptimized => _screenReaderOptimized;

  Future<void> init() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
    _isInitialized = true;
    notifyListeners();
  }

  void _loadSettings() {
    final themeModeStr = _prefs.getString('theme_mode') ?? 'system';
    _themeMode = ThemeMode.values.firstWhere(
      (e) => e.name == themeModeStr,
      orElse: () => ThemeMode.system,
    );

    final colorValue = _prefs.getInt('accent_color');
    if (colorValue != null) {
      _accentColor = Color(colorValue);
    }

    _notificationsEnabled = _prefs.getBool('notifications_enabled') ?? true;
    
    final reminderHour = _prefs.getInt('reminder_hour') ?? 9;
    final reminderMinute = _prefs.getInt('reminder_minute') ?? 0;
    _reminderTime = TimeOfDay(hour: reminderHour, minute: reminderMinute);

    _preferredSound = _prefs.getString('preferred_sound') ?? 'bells';
    _defaultMeditationDuration = _prefs.getInt('default_meditation_duration') ?? 10;
    _focusModeEnabled = _prefs.getBool('focus_mode_enabled') ?? false;
    _textScale = _prefs.getDouble('text_scale') ?? 1.0;
    _highContrastMode = _prefs.getBool('high_contrast_mode') ?? false;
    _screenReaderOptimized = _prefs.getBool('screen_reader_optimized') ?? false;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString('theme_mode', mode.name);
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    await _prefs.setInt('accent_color', color.value);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    await _prefs.setBool('notifications_enabled', enabled);
    notifyListeners();
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    _reminderTime = time;
    await _prefs.setInt('reminder_hour', time.hour);
    await _prefs.setInt('reminder_minute', time.minute);
    notifyListeners();
  }

  Future<void> setPreferredSound(String sound) async {
    _preferredSound = sound;
    await _prefs.setString('preferred_sound', sound);
    notifyListeners();
  }

  Future<void> setDefaultMeditationDuration(int minutes) async {
    _defaultMeditationDuration = minutes;
    await _prefs.setInt('default_meditation_duration', minutes);
    notifyListeners();
  }

  Future<void> setFocusModeEnabled(bool enabled) async {
    _focusModeEnabled = enabled;
    await _prefs.setBool('focus_mode_enabled', enabled);
    notifyListeners();
  }

  Future<void> setTextScale(double scale) async {
    _textScale = scale;
    await _prefs.setDouble('text_scale', scale);
    notifyListeners();
  }

  Future<void> setHighContrastMode(bool enabled) async {
    _highContrastMode = enabled;
    await _prefs.setBool('high_contrast_mode', enabled);
    notifyListeners();
  }

  Future<void> setScreenReaderOptimized(bool enabled) async {
    _screenReaderOptimized = enabled;
    await _prefs.setBool('screen_reader_optimized', enabled);
    notifyListeners();
  }
}

