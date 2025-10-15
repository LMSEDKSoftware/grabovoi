import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/data/latest.dart' as tz;

import 'config/theme.dart';
import 'config/router.dart';
import 'providers/auth_provider.dart';
import 'providers/codes_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/meditation_provider.dart';
import 'providers/journal_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/tracker_provider.dart';
// import 'services/notification_service.dart';

// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Hive
  await Hive.initFlutter();
  
  // TODO: Descomentar cuando tengas Supabase configurado
  // Inicializar Supabase
  // await Supabase.initialize(
  //   url: 'TU_SUPABASE_URL',
  //   anonKey: 'TU_SUPABASE_ANON_KEY',
  // );
  
  // TODO: Descomentar para notificaciones
  // Inicializar timezone para notificaciones
  // tz.initializeTimeZones();
  
  // Inicializar notificaciones
  // await NotificationService.initialize();
  
  // Configurar orientación preferida
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => CodesProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => MeditationProvider()),
        ChangeNotifierProvider(create: (_) => JournalProvider()),
        ChangeNotifierProvider(create: (_) => TrackerProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp.router(
            title: 'Manifestación Numérica Grabovoi',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(settings.accentColor),
            darkTheme: AppTheme.darkTheme(settings.accentColor),
            themeMode: settings.themeMode,
            routerConfig: appRouter,
            locale: const Locale('es', 'ES'),
          );
        },
      ),
    );
  }
}

