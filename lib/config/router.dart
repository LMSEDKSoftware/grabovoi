import 'package:go_router/go_router.dart';

import '../screens/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/onboarding/questionnaire_screen.dart';
import '../screens/home/mystical_home_screen.dart';
import '../screens/codes/codes_library_screen.dart';
import '../screens/codes/code_detail_screen.dart';
import '../screens/tracker/tracker_screen.dart';
import '../screens/meditation/meditations_screen.dart';
import '../screens/meditation/meditation_player_screen.dart';
import '../screens/journal/journal_screen.dart';
import '../screens/journal/journal_entry_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/pilotaje/pilotaje_screen.dart';
import '../screens/pilotaje/pilotaje_guia_screen.dart';
import '../screens/pilotaje/pilotaje_tipos_screen.dart';
import '../screens/pilotaje/pilotaje_avanzado_screen.dart';
import '../screens/pilotaje/pilotaje_personalizado_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/questionnaire',
      builder: (context, state) => const QuestionnaireScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const MysticalHomeScreen(),
    ),
    // Códigos Sagrados - Funcionalidad principal
    GoRoute(
      path: '/codes',
      builder: (context, state) => const CodesLibraryScreen(),
    ),
    GoRoute(
      path: '/codes/:id',
      builder: (context, state) {
        final codeId = state.pathParameters['id']!;
        return CodeDetailScreen(codeId: codeId);
      },
    ),
    // Ritual de Repetición
    GoRoute(
      path: '/tracker',
      builder: (context, state) => const TrackerScreen(),
    ),
    // Meditación Guiada
    GoRoute(
      path: '/meditations',
      builder: (context, state) => const MeditationsScreen(),
    ),
    GoRoute(
      path: '/meditations/:id',
      builder: (context, state) {
        final meditationId = state.pathParameters['id']!;
        return MeditationPlayerScreen(meditationId: meditationId);
      },
    ),
    // Diario Místico
    GoRoute(
      path: '/journal',
      builder: (context, state) => const JournalScreen(),
    ),
    GoRoute(
      path: '/journal/new',
      builder: (context, state) => const JournalEntryScreen(),
    ),
    GoRoute(
      path: '/journal/:id',
      builder: (context, state) {
        final entryId = state.pathParameters['id']!;
        return JournalEntryScreen(entryId: entryId);
      },
    ),
    // Configuración
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    // Pilotaje Consciente
    GoRoute(
      path: '/pilotaje',
      builder: (context, state) => const PilotajeScreen(),
    ),
    GoRoute(
      path: '/pilotaje/guia',
      builder: (context, state) => const PilotajeGuiaScreen(),
    ),
    GoRoute(
      path: '/pilotaje/tipos',
      builder: (context, state) => const PilotajeTiposScreen(),
    ),
    GoRoute(
      path: '/pilotaje/avanzado',
      builder: (context, state) => const PilotajeAvanzadoScreen(),
    ),
    GoRoute(
      path: '/pilotaje/personalizado',
      builder: (context, state) => const PilotajePersonalizadoScreen(),
    ),
  ],
);