import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferences {
  final bool enabled;
  final bool streakReminders;
  final bool challengeReminders;
  final bool achievementCelebrations;
  final bool dailyCodeReminders;
  final bool motivationalMessages;
  final bool weeklySummaries;
  final bool energyLevelAlerts;
  final bool morningReminders;
  final bool eveningReminders;
  final String preferredMorningTime; // formato "HH:MM"
  final String preferredEveningTime; // formato "HH:MM"
  final List<int> silentDays; // 0=domingo, 6=sábado
  final bool soundEnabled;
  final bool vibrationEnabled;

  const NotificationPreferences({
    this.enabled = true,
    this.streakReminders = true,
    this.challengeReminders = true,
    this.achievementCelebrations = true,
    this.dailyCodeReminders = true,
    this.motivationalMessages = true,
    this.weeklySummaries = true,
    this.energyLevelAlerts = true,
    this.morningReminders = true,
    this.eveningReminders = true,
    this.preferredMorningTime = '08:00',
    this.preferredEveningTime = '19:00',
    this.silentDays = const [], // Por defecto ningún día silencioso
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  NotificationPreferences copyWith({
    bool? enabled,
    bool? streakReminders,
    bool? challengeReminders,
    bool? achievementCelebrations,
    bool? dailyCodeReminders,
    bool? motivationalMessages,
    bool? weeklySummaries,
    bool? energyLevelAlerts,
    bool? morningReminders,
    bool? eveningReminders,
    String? preferredMorningTime,
    String? preferredEveningTime,
    List<int>? silentDays,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      streakReminders: streakReminders ?? this.streakReminders,
      challengeReminders: challengeReminders ?? this.challengeReminders,
      achievementCelebrations: achievementCelebrations ?? this.achievementCelebrations,
      dailyCodeReminders: dailyCodeReminders ?? this.dailyCodeReminders,
      motivationalMessages: motivationalMessages ?? this.motivationalMessages,
      weeklySummaries: weeklySummaries ?? this.weeklySummaries,
      energyLevelAlerts: energyLevelAlerts ?? this.energyLevelAlerts,
      morningReminders: morningReminders ?? this.morningReminders,
      eveningReminders: eveningReminders ?? this.eveningReminders,
      preferredMorningTime: preferredMorningTime ?? this.preferredMorningTime,
      preferredEveningTime: preferredEveningTime ?? this.preferredEveningTime,
      silentDays: silentDays ?? this.silentDays,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }

  // Guardar en SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    await prefs.setBool('notifications_streak', streakReminders);
    await prefs.setBool('notifications_challenge', challengeReminders);
    await prefs.setBool('notifications_achievements', achievementCelebrations);
    await prefs.setBool('notifications_daily_code', dailyCodeReminders);
    await prefs.setBool('notifications_motivational', motivationalMessages);
    await prefs.setBool('notifications_weekly_summary', weeklySummaries);
    await prefs.setBool('notifications_energy_alerts', energyLevelAlerts);
    await prefs.setBool('notifications_morning', morningReminders);
    await prefs.setBool('notifications_evening', eveningReminders);
    await prefs.setString('notifications_morning_time', preferredMorningTime);
    await prefs.setString('notifications_evening_time', preferredEveningTime);
    await prefs.setStringList('notifications_silent_days', silentDays.map((d) => d.toString()).toList());
    await prefs.setBool('notifications_sound', soundEnabled);
    await prefs.setBool('notifications_vibration', vibrationEnabled);
  }

  // Cargar de SharedPreferences
  static Future<NotificationPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationPreferences(
      enabled: prefs.getBool('notifications_enabled') ?? true,
      streakReminders: prefs.getBool('notifications_streak') ?? true,
      challengeReminders: prefs.getBool('notifications_challenge') ?? true,
      achievementCelebrations: prefs.getBool('notifications_achievements') ?? true,
      dailyCodeReminders: prefs.getBool('notifications_daily_code') ?? true,
      motivationalMessages: prefs.getBool('notifications_motivational') ?? true,
      weeklySummaries: prefs.getBool('notifications_weekly_summary') ?? true,
      energyLevelAlerts: prefs.getBool('notifications_energy_alerts') ?? true,
      morningReminders: prefs.getBool('notifications_morning') ?? true,
      eveningReminders: prefs.getBool('notifications_evening') ?? true,
      preferredMorningTime: prefs.getString('notifications_morning_time') ?? '08:00',
      preferredEveningTime: prefs.getString('notifications_evening_time') ?? '19:00',
      silentDays: (prefs.getStringList('notifications_silent_days') ?? []).map((d) => int.parse(d)).toList(),
      soundEnabled: prefs.getBool('notifications_sound') ?? true,
      vibrationEnabled: prefs.getBool('notifications_vibration') ?? true,
    );
  }

  bool isDaySilent(int dayOfWeek) {
    return silentDays.contains(dayOfWeek);
  }
}

