import 'package:flutter/material.dart';

// ============================================
// 🚀 PLANTILLA LIMPIA PARA VERSIÓN 2.0
// ============================================
// 
// Este es un punto de partida completamente limpio.
// Toda la configuración de compilación está lista.
// ¡Solo diseña tu app!

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Nueva App V2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}

// ============================================
// 🏠 PANTALLA PRINCIPAL
// ============================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Versión 2.0'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono grande
              Icon(
                Icons.rocket_launch,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),
              
              // Título
              Text(
                '¡Hola Mundo!',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Subtítulo
              Text(
                'Versión 2.0 - Configuración Lista',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),
              
              // Botón principal
              FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('¡Todo funciona! Empieza a crear tu app'),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Empezar'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Botón secundario
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.info_outline),
                label: const Text('Información'),
              ),
              const SizedBox(height: 64),
              
              // Info técnica
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✅ Configuración Lista:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text('• Android SDK 34 (min 21)'),
                    const Text('• JDK 17 configurado'),
                    const Text('• AGP 8.3.2'),
                    const Text('• Flutter 3.24.5'),
                    const Text('• Material 3'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Agregar',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ============================================
// 💡 PRÓXIMOS PASOS:
// ============================================
//
// 1. Renombra este archivo a main.dart (o copia su contenido)
// 2. Crea tu estructura de carpetas:
//    - lib/screens/
//    - lib/widgets/
//    - lib/theme/
//    - lib/models/
//
// 3. Ve agregando pantallas una por una
// 4. Compila frecuentemente: flutter build apk --release
// 5. Haz commits regulares: git add . && git commit -m "..."
//
// ============================================

